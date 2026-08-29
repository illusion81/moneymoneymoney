import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/progression.dart';
import 'package:moneymoneymoney/screens/shop_screen.dart';
import 'package:moneymoneymoney/services/shop_service.dart';

const _progression = ProgressionState(
  totalXp: 0,
  level: LevelProgress(
    level: 1,
    xpIntoLevel: 0,
    xpForNextLevel: 100,
    fraction: 0,
  ),
  coinBalance: 0,
  lifetimeCoinsEarned: 0,
  lifetimeCoinsSpent: 0,
  ledger: [],
);

Widget _shop({VoidCallback? onDebugMaxCoins, VoidCallback? onDebugUnlockAll}) {
  return MaterialApp(
    home: ShopScreen(
      progression: _progression,
      shopState: ShopService().initialState(),
      onPurchase: (_) {},
      onEquip: (_) {},
      onBack: () {},
      isPlusMember: false,
      onShowPlus: () {},
      onDebugMaxCoins: onDebugMaxCoins,
      onDebugUnlockAll: onDebugUnlockAll,
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

  testWidgets('debug actions are hidden until debug mode is switched on', (
    tester,
  ) async {
    await tester.pumpWidget(
      _shop(onDebugMaxCoins: () {}, onDebugUnlockAll: () {}),
    );

    expect(find.byKey(const Key('debug-mode-toggle')), findsOneWidget);
    expect(find.byKey(const Key('debug-max-coins-button')), findsNothing);
    expect(find.byKey(const Key('debug-unlock-all-button')), findsNothing);
  });

  testWidgets('switching debug mode on reveals the debug actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _shop(onDebugMaxCoins: () {}, onDebugUnlockAll: () {}),
    );

    await tester.tap(find.byKey(const Key('debug-mode-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('debug-max-coins-button')), findsOneWidget);
    expect(find.byKey(const Key('debug-unlock-all-button')), findsOneWidget);
  });

  testWidgets('switching debug mode back off hides the debug actions again', (
    tester,
  ) async {
    await tester.pumpWidget(
      _shop(onDebugMaxCoins: () {}, onDebugUnlockAll: () {}),
    );

    await tester.tap(find.byKey(const Key('debug-mode-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('debug-mode-toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('debug-max-coins-button')), findsNothing);
    expect(find.byKey(const Key('debug-unlock-all-button')), findsNothing);
  });

  testWidgets('tapping the debug Max Coins button calls onDebugMaxCoins', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(_shop(onDebugMaxCoins: () => tapped = true));

    await tester.tap(find.byKey(const Key('debug-mode-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('debug-max-coins-button')));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('tapping the debug Unlock All button calls onDebugUnlockAll', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(_shop(onDebugUnlockAll: () => tapped = true));

    await tester.tap(find.byKey(const Key('debug-mode-toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('debug-unlock-all-button')));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
