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

  testWidgets('offers Facebook and Instagram share buttons', (tester) async {
    await tester.pumpWidget(_harness());

    expect(find.byKey(const Key('share-facebook-button')), findsOneWidget);
    expect(find.byKey(const Key('share-instagram-button')), findsOneWidget);
  });

  testWidgets('sharing says plainly that it is a demo, not a real post', (
    tester,
  ) async {
    await tester.pumpWidget(_harness());

    final fb = find.byKey(const Key('share-facebook-button'));
    await tester.ensureVisible(fb);
    await tester.pump();
    await tester.tap(fb);
    await tester.pumpAndSettle();

    // It must never imply a post actually went out.
    expect(find.byKey(const Key('share-demo-dialog')), findsOneWidget);
    expect(find.textContaining('Demo'), findsWidgets);
    expect(find.textContaining('nothing was posted'), findsWidgets);
  });

  testWidgets('the demo share dialog can be dismissed', (tester) async {
    await tester.pumpWidget(_harness());

    final ig = find.byKey(const Key('share-instagram-button'));
    await tester.ensureVisible(ig);
    await tester.pump();
    await tester.tap(ig);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('share-demo-dialog')), findsOneWidget);

    await tester.tap(find.byKey(const Key('share-demo-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('share-demo-dialog')), findsNothing);
  });
}
