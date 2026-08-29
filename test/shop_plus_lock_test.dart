import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/progression.dart';
import 'package:moneymoneymoney/screens/shop_screen.dart';
import 'package:moneymoneymoney/services/shop_service.dart';

const _richProgression = ProgressionState(
  totalXp: 0,
  level: LevelProgress(
    level: 50,
    xpIntoLevel: 0,
    xpForNextLevel: 100,
    fraction: 0,
  ),
  coinBalance: 99999,
  lifetimeCoinsEarned: 99999,
  lifetimeCoinsSpent: 0,
  ledger: [],
);

Widget _shop({
  required bool isPlusMember,
  VoidCallback? onShowPlus,
  void Function(String)? onPurchase,
}) {
  return MaterialApp(
    home: ShopScreen(
      progression: _richProgression,
      shopState: ShopService().initialState(),
      isPlusMember: isPlusMember,
      onPurchase: onPurchase ?? (_) {},
      onEquip: (_) {},
      onBack: () {},
      onShowPlus: onShowPlus ?? () {},
    ),
  );
}

void main() {
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1200,
      3600,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('a non-member sees a Plus lock instead of a buy button', (
    tester,
  ) async {
    await tester.pumpWidget(_shop(isPlusMember: false));

    expect(
      find.byKey(const Key('plus-lock-tree-crystal-pine')),
      findsOneWidget,
    );
  });

  testWidgets('tapping the lock opens the Plus screen', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      _shop(isPlusMember: false, onShowPlus: () => opened = true),
    );

    await tester.tap(find.byKey(const Key('plus-lock-tree-crystal-pine')));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('a Plus member sees a normal buy button on the same item', (
    tester,
  ) async {
    await tester.pumpWidget(_shop(isPlusMember: true));

    expect(find.byKey(const Key('plus-lock-tree-crystal-pine')), findsNothing);
    expect(find.text('Buy for 600'), findsOneWidget);
  });

  testWidgets('a non-member tapping the lock does not attempt a purchase', (
    tester,
  ) async {
    var purchased = false;
    await tester.pumpWidget(
      _shop(isPlusMember: false, onPurchase: (_) => purchased = true),
    );

    await tester.tap(find.byKey(const Key('plus-lock-tree-crystal-pine')));
    await tester.pumpAndSettle();

    expect(purchased, isFalse);
  });
}
