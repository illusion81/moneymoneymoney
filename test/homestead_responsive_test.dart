import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/home_layout.dart';
import 'package:moneymoneymoney/screens/homestead_screen.dart';
import 'package:moneymoneymoney/services/shop_service.dart';

Widget _harness() {
  return MaterialApp(
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
  );
}

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  final view = tester.view;
  view.physicalSize = size;
  view.devicePixelRatio = 1.0;
  addTearDown(view.resetPhysicalSize);
  addTearDown(view.resetDevicePixelRatio);
  await tester.pumpWidget(_harness());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the grid fits inside a narrow phone width', (tester) async {
    // A small phone: 360 logical pixels wide.
    await _pumpAt(tester, const Size(360, 900));

    final grid = tester.getSize(find.byKey(const Key('homestead-grid')));
    expect(grid.width, lessThanOrEqualTo(360));
  });

  testWidgets('the grid never overflows its parent on a very narrow screen', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(320, 900));

    expect(tester.takeException(), isNull);
    final grid = tester.getSize(find.byKey(const Key('homestead-grid')));
    expect(grid.width, lessThanOrEqualTo(320));
  });

  testWidgets('the grid keeps its 2:1 isometric proportions when scaled', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(360, 900));
    final narrow = tester.getSize(find.byKey(const Key('homestead-grid')));

    // Width-to-height ratio should hold regardless of the scale applied.
    final expected = kHomeGridCanvasWidth / kHomeGridCanvasHeight;
    expect(narrow.width / narrow.height, closeTo(expected, 0.01));
  });

  testWidgets('a wide screen does not blow the grid up past its design size', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1400, 1400));

    final grid = tester.getSize(find.byKey(const Key('homestead-grid')));
    expect(grid.width, lessThanOrEqualTo(kHomeGridCanvasWidth));
  });
}
