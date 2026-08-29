import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/collect/models/wallet.dart';
import 'package:moneymoneymoney/screens/egg_screen.dart';
import 'package:moneymoneymoney/sprites/asset_paths.dart';

void main() {
  final upperIds = SpriteAssets.animalIds.map((id) => id.toUpperCase()).toSet();

  Widget host(Wallet wallet) => MaterialApp(home: EggScreen(wallet: wallet));

  testWidgets('lists all four egg tiers with prices', (tester) async {
    await tester.pumpWidget(host(const Wallet(coins: 20)));

    expect(find.text('Common Egg'), findsOneWidget);
    expect(find.text('Uncommon Egg'), findsOneWidget);
    expect(find.text('Rare Egg'), findsOneWidget);
    expect(find.text('Legendary Egg'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
  });

  testWidgets('an egg the balance cannot afford is disabled', (tester) async {
    await tester.pumpWidget(host(const Wallet(coins: 4)));

    final buy = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '5'),
    );
    expect(buy.onPressed, isNull);
  });

  testWidgets('buying an egg spends coins and reveals an animal', (
    tester,
  ) async {
    await tester.pumpWidget(host(const Wallet(coins: 20)));

    await tester.tap(find.widgetWithText(ElevatedButton, '5'));
    await tester.pump();

    expect(find.text('15'), findsOneWidget);

    // Run through the wait and the one-shot hatch.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(find.text('Hatch another'), findsOneWidget);
    final shown = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .where((d) => d != null && upperIds.contains(d));
    expect(shown, hasLength(1));
  });
}
