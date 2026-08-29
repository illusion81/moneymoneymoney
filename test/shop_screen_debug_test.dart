import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/progression.dart';
import 'package:moneymoneymoney/screens/shop_screen.dart';
import 'package:moneymoneymoney/services/shop_service.dart';

void main() {
  testWidgets('tapping the debug Max Coins button calls onDebugMaxCoins', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ShopScreen(
          progression: const ProgressionState(
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
          ),
          shopState: ShopService().initialState(),
          onPurchase: (_) {},
          onEquip: (_) {},
          onBack: () {},
          onDebugMaxCoins: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('debug-max-coins-button')));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('tapping the debug Unlock All button calls onDebugUnlockAll', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ShopScreen(
          progression: const ProgressionState(
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
          ),
          shopState: ShopService().initialState(),
          onPurchase: (_) {},
          onEquip: (_) {},
          onBack: () {},
          onDebugUnlockAll: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('debug-unlock-all-button')));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
