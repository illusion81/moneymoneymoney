import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/home_layout.dart';
import 'package:moneymoneymoney/models/shop_item.dart';
import 'package:moneymoneymoney/screens/homestead_screen.dart';
import 'package:moneymoneymoney/services/shop_service.dart';

ShopState _withOwned(Set<String> extra) {
  final base = ShopService().initialState();
  return ShopState(
    ownedItemIds: {...base.ownedItemIds, ...extra},
    equippedItemIds: base.equippedItemIds,
  );
}

void main() {
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1000,
      2600,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('shows an empty state and a Shop button when no decorations are owned', (
    tester,
  ) async {
    var shopTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: HomesteadScreen(
          shopState: ShopService().initialState(),
          layout: const HomeLayoutState(placements: []),
          onPlace: (_, _, _) {},
          onRemove: (_) {},
          onShowForest: () {},
          onShowCalendar: () {},
          onShowReport: () {},
          onShowAchievements: () {},
          onShowShop: () => shopTapped = true,
          onExportImage: (_) async {},
        ),
      ),
    );

    expect(find.textContaining('Shop'), findsWidgets);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Go to Shop'));
    await tester.pumpAndSettle();

    expect(shopTapped, isTrue);
  });

  testWidgets('an owned, unplaced decoration appears in the inventory tray', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomesteadScreen(
          shopState: _withOwned({'deco-garden-lantern'}),
          layout: const HomeLayoutState(placements: []),
          onPlace: (_, _, _) {},
          onRemove: (_) {},
          onShowForest: () {},
          onShowCalendar: () {},
          onShowReport: () {},
          onShowAchievements: () {},
          onShowShop: () {},
          onExportImage: (_) async {},
        ),
      ),
    );

    expect(
      find.byKey(const Key('tray-item-deco-garden-lantern')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('placed-item-deco-garden-lantern')),
      findsNothing,
    );
  });

  testWidgets('a placed decoration renders on the canvas, not the tray', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomesteadScreen(
          shopState: _withOwned({'deco-garden-lantern'}),
          layout: const HomeLayoutState(
            placements: [
              DecorationPlacement(
                itemId: 'deco-garden-lantern',
                dx: 0.5,
                dy: 0.5,
              ),
            ],
          ),
          onPlace: (_, _, _) {},
          onRemove: (_) {},
          onShowForest: () {},
          onShowCalendar: () {},
          onShowReport: () {},
          onShowAchievements: () {},
          onShowShop: () {},
          onExportImage: (_) async {},
        ),
      ),
    );

    expect(
      find.byKey(const Key('placed-item-deco-garden-lantern')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('tray-item-deco-garden-lantern')),
      findsNothing,
    );
  });

  testWidgets('long-pressing a placed decoration calls onRemove', (
    tester,
  ) async {
    String? removedId;

    await tester.pumpWidget(
      MaterialApp(
        home: HomesteadScreen(
          shopState: _withOwned({'deco-garden-lantern'}),
          layout: const HomeLayoutState(
            placements: [
              DecorationPlacement(
                itemId: 'deco-garden-lantern',
                dx: 0.5,
                dy: 0.5,
              ),
            ],
          ),
          onPlace: (_, _, _) {},
          onRemove: (id) => removedId = id,
          onShowForest: () {},
          onShowCalendar: () {},
          onShowReport: () {},
          onShowAchievements: () {},
          onShowShop: () {},
          onExportImage: (_) async {},
        ),
      ),
    );

    await tester.longPress(
      find.byKey(const Key('placed-item-deco-garden-lantern')),
    );
    await tester.pumpAndSettle();

    expect(removedId, 'deco-garden-lantern');
  });

  testWidgets('dragging a tray item onto the canvas calls onPlace with a fractional offset', (
    tester,
  ) async {
    String? placedId;
    double? placedDx;
    double? placedDy;

    await tester.pumpWidget(
      MaterialApp(
        home: HomesteadScreen(
          shopState: _withOwned({'deco-garden-lantern'}),
          layout: const HomeLayoutState(placements: []),
          onPlace: (id, dx, dy) {
            placedId = id;
            placedDx = dx;
            placedDy = dy;
          },
          onRemove: (_) {},
          onShowForest: () {},
          onShowCalendar: () {},
          onShowReport: () {},
          onShowAchievements: () {},
          onShowShop: () {},
          onExportImage: (_) async {},
        ),
      ),
    );

    final trayItem = find.byKey(const Key('tray-item-deco-garden-lantern'));
    final canvas = find.byKey(const Key('homestead-canvas'));

    await tester.drag(trayItem, tester.getCenter(canvas) - tester.getCenter(trayItem));
    await tester.pumpAndSettle();

    expect(placedId, 'deco-garden-lantern');
    expect(placedDx, isNotNull);
    expect(placedDy, isNotNull);
    expect(placedDx! >= 0.0 && placedDx! <= 1.0, isTrue);
    expect(placedDy! >= 0.0 && placedDy! <= 1.0, isTrue);
  });

  testWidgets(
    'tapping Export image captures the boundary and forwards its bytes',
    (tester) async {
      Uint8List? exported;
      final fakeBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      GlobalKey? capturedKey;

      await tester.pumpWidget(
        MaterialApp(
          home: HomesteadScreen(
            shopState: _withOwned({'deco-garden-lantern'}),
            layout: const HomeLayoutState(
              placements: [
                DecorationPlacement(
                  itemId: 'deco-garden-lantern',
                  dx: 0.5,
                  dy: 0.5,
                ),
              ],
            ),
            onPlace: (_, _, _) {},
            onRemove: (_) {},
            onShowForest: () {},
            onShowCalendar: () {},
            onShowReport: () {},
            onShowAchievements: () {},
            onShowShop: () {},
            onExportImage: (bytes) async => exported = bytes,
            captureBoundary: (key) async {
              capturedKey = key;
              return fakeBytes;
            },
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('export-image-button')));
      await tester.pumpAndSettle();

      expect(capturedKey, isNotNull);
      expect(exported, fakeBytes);
    },
  );
}
