import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/forest_day.dart';
import 'package:moneymoneymoney/models/home_layout.dart';
import 'package:moneymoneymoney/models/shop_item.dart';
import 'package:moneymoneymoney/screens/homestead_screen.dart';
import 'package:moneymoneymoney/services/isometric_grid.dart';
import 'package:moneymoneymoney/services/shop_service.dart';

ShopState _withOwned(Set<String> extra) {
  final base = ShopService().initialState();
  return ShopState(
    ownedItemIds: {...base.ownedItemIds, ...extra},
    equippedItemIds: base.equippedItemIds,
  );
}

const _geometry = IsoGridGeometry(
  tileWidth: kHomeTileWidth,
  tileHeight: kHomeTileHeight,
);

/// The global screen position of a grid cell's center, for tapping it.
Offset _cellScreenCenter(WidgetTester tester, int row, int col) {
  final gridTopLeft = tester.getTopLeft(
    find.byKey(const Key('homestead-grid')),
  );
  return gridTopLeft +
      kHomeGridOrigin +
      _geometry.cellCenter(row: row, col: col);
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

  testWidgets(
    'shows an empty state and a Shop button when no decorations are owned',
    (tester) async {
      var shopTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HomesteadScreen(
            shopState: ShopService().initialState(),
            days: const [],
            layout: const HomeLayoutState(placements: []),
            onPlace: (_, _, _) {},
            onRemove: (_) {},
            onShowForest: () {},
            onShowSpending: () {},
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
    },
  );

  testWidgets('fake social and investment icon links show demo messages', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomesteadScreen(
          shopState: ShopService().initialState(),
          days: const [],
          layout: const HomeLayoutState(placements: []),
          onPlace: (_, _, _) {},
          onRemove: (_) {},
          onShowForest: () {},
          onShowSpending: () {},
          onShowCalendar: () {},
          onShowReport: () {},
          onShowAchievements: () {},
          onShowShop: () {},
          onExportImage: (_) async {},
        ),
      ),
    );

    await tester.tap(find.byTooltip('Share to Instagram'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Instagram demo link'), findsOneWidget);

    await tester.tap(find.byTooltip('Share to TikTok'));
    await tester.pumpAndSettle();
    expect(find.textContaining('TikTok demo link'), findsOneWidget);

    await tester.tap(find.byTooltip('CommBank investment link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('CommBank investing demo link'), findsOneWidget);
  });

  testWidgets('an owned, unplaced decoration appears in the inventory tray', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomesteadScreen(
          shopState: _withOwned({'deco-garden-lantern'}),
          days: const [],
          layout: const HomeLayoutState(placements: []),
          onPlace: (_, _, _) {},
          onRemove: (_) {},
          onShowForest: () {},
          onShowSpending: () {},
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

  testWidgets('a placed decoration renders on the grid, not the tray', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomesteadScreen(
          shopState: _withOwned({'deco-garden-lantern'}),
          days: const [],
          layout: const HomeLayoutState(
            placements: [
              DecorationPlacement(
                itemId: 'deco-garden-lantern',
                row: 2,
                col: 2,
              ),
            ],
          ),
          onPlace: (_, _, _) {},
          onRemove: (_) {},
          onShowForest: () {},
          onShowSpending: () {},
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
          days: const [],
          layout: const HomeLayoutState(
            placements: [
              DecorationPlacement(
                itemId: 'deco-garden-lantern',
                row: 2,
                col: 2,
              ),
            ],
          ),
          onPlace: (_, _, _) {},
          onRemove: (id) => removedId = id,
          onShowForest: () {},
          onShowSpending: () {},
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

  testWidgets(
    'selecting a tray item then tapping an empty grid cell places it there',
    (tester) async {
      String? placedId;
      int? placedRow;
      int? placedCol;

      await tester.pumpWidget(
        MaterialApp(
          home: HomesteadScreen(
            shopState: _withOwned({'deco-garden-lantern'}),
            days: const [],
            layout: const HomeLayoutState(placements: []),
            onPlace: (id, row, col) {
              placedId = id;
              placedRow = row;
              placedCol = col;
            },
            onRemove: (_) {},
            onShowForest: () {},
            onShowSpending: () {},
            onShowCalendar: () {},
            onShowReport: () {},
            onShowAchievements: () {},
            onShowShop: () {},
            onExportImage: (_) async {},
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('tray-item-deco-garden-lantern')));
      await tester.pumpAndSettle();
      await tester.tapAt(_cellScreenCenter(tester, 3, 2));
      await tester.pumpAndSettle();

      expect(placedId, 'deco-garden-lantern');
      expect(placedRow, 3);
      expect(placedCol, 2);
    },
  );

  testWidgets(
    'tapping an empty cell without a selected tray item does nothing',
    (tester) async {
      var placeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: HomesteadScreen(
            shopState: _withOwned({'deco-garden-lantern'}),
            days: const [],
            layout: const HomeLayoutState(placements: []),
            onPlace: (_, _, _) => placeCalled = true,
            onRemove: (_) {},
            onShowForest: () {},
            onShowSpending: () {},
            onShowCalendar: () {},
            onShowReport: () {},
            onShowAchievements: () {},
            onShowShop: () {},
            onExportImage: (_) async {},
          ),
        ),
      );

      await tester.tapAt(_cellScreenCenter(tester, 3, 2));
      await tester.pumpAndSettle();

      expect(placeCalled, isFalse);
    },
  );

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
            days: const [],
            layout: const HomeLayoutState(
              placements: [
                DecorationPlacement(
                  itemId: 'deco-garden-lantern',
                  row: 2,
                  col: 2,
                ),
              ],
            ),
            onPlace: (_, _, _) {},
            onRemove: (_) {},
            onShowForest: () {},
            onShowSpending: () {},
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

  testWidgets('switching the stats period recomputes the savings chart', (
    tester,
  ) async {
    final days = [
      ForestDay(
        date: DateTime(2026, 8, 3),
        status: TreeStatus.healthy,
        treeLevel: 1,
        spending: 30,
        dailyBudget: 50,
        actionCompleted: true,
        message: '',
      ),
      ForestDay(
        date: DateTime(2026, 8, 20),
        status: TreeStatus.healthy,
        treeLevel: 1,
        spending: 40,
        dailyBudget: 50,
        actionCompleted: true,
        message: '',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: HomesteadScreen(
          shopState: ShopService().initialState(),
          days: days,
          layout: const HomeLayoutState(placements: []),
          onPlace: (_, _, _) {},
          onRemove: (_) {},
          onShowForest: () {},
          onShowSpending: () {},
          onShowCalendar: () {},
          onShowReport: () {},
          onShowAchievements: () {},
          onShowShop: () {},
          onExportImage: (_) async {},
        ),
      ),
    );

    // Two days two weeks apart land in different weekly buckets.
    final chart = find.byKey(const Key('savings-chart-canvas'));
    await tester.tap(chart);
    await tester.pumpAndSettle();
    expect(find.textContaining(' saved'), findsOneWidget);

    await tester.tap(find.byKey(const Key('stats-period-month')));
    await tester.pumpAndSettle();

    // Same month, so both days now collapse into a single running total —
    // unambiguous regardless of where the chart is tapped.
    await tester.tap(chart);
    await tester.pumpAndSettle();
    expect(find.textContaining('Aug 2026 · 30 saved'), findsOneWidget);
  });
}
