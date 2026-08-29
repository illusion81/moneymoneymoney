import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/collect/models/wallet.dart';

void main() {
  test('a beta wallet starts with the 20 coin grant', () {
    expect(const Wallet.beta().coins, 20);
    expect(Wallet.betaGrantCoins, 20);
  });

  test('formats the balance as currency for the beta credit line', () {
    expect(const Wallet.beta().creditLabel, r'$20.00');
    expect(const Wallet(coins: 7).creditLabel, r'$7.00');
  });

  test('earning adds coins', () {
    expect(const Wallet(coins: 5).earn(3).coins, 8);
  });

  test('spending subtracts coins', () {
    expect(const Wallet(coins: 20).spend(12).coins, 8);
  });

  test('canAfford is inclusive of the exact balance', () {
    expect(const Wallet(coins: 5).canAfford(5), isTrue);
    expect(const Wallet(coins: 5).canAfford(6), isFalse);
  });

  test('overspending throws instead of going negative', () {
    expect(() => const Wallet(coins: 5).spend(6), throwsStateError);
  });

  test('earning or spending a negative amount throws', () {
    expect(() => const Wallet(coins: 5).earn(-1), throwsArgumentError);
    expect(() => const Wallet(coins: 5).spend(-1), throwsArgumentError);
  });
}