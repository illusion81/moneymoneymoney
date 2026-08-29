import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/models.dart';
import 'package:moneymoneymoney/services/profile_suggestions.dart';

Txn _txn({
  required double amount,
  required String category,
  String id = 'tx',
}) {
  return Txn(
    id: id,
    accountId: 'acc',
    postDate: '2026-08-01',
    description: 'x',
    amount: amount,
    category: category,
    bucket: 'living',
  );
}

void main() {
  group('suggestProfileFromTransactions', () {
    test('returns null when there are no transactions to learn from', () {
      expect(suggestProfileFromTransactions(const [], days: 30), isNull);
    });

    test('sums income transactions over the window', () {
      final s = suggestProfileFromTransactions([
        _txn(amount: 2000, category: 'income'),
        _txn(amount: 1000, category: 'income'),
      ], days: 30);

      expect(s!.monthlyIncome, 3000);
    });

    test('normalises a 60-day window to a monthly figure', () {
      final s = suggestProfileFromTransactions([
        _txn(amount: 6000, category: 'income'),
      ], days: 60);

      expect(s!.monthlyIncome, 3000);
    });

    test('counts only recurring commitments as fixed expenses', () {
      final s = suggestProfileFromTransactions([
        _txn(amount: 1500, category: 'income'),
        _txn(amount: -900, category: 'housing'),
        _txn(amount: -100, category: 'utilities'),
        _txn(amount: -50, category: 'subscriptions'),
        // Variable spending must not inflate the "fixed" figure.
        _txn(amount: -300, category: 'groceries'),
        _txn(amount: -200, category: 'eating-out'),
      ], days: 30);

      expect(s!.fixedMonthlyExpenses, 1050);
    });

    test('ignores transfers between the users own accounts', () {
      final s = suggestProfileFromTransactions([
        _txn(amount: 2000, category: 'income'),
        _txn(amount: -500, category: 'transfer-out'),
        _txn(amount: 500, category: 'transfer-in'),
      ], days: 30);

      expect(s!.monthlyIncome, 2000);
      expect(s.fixedMonthlyExpenses, 0);
    });

    test('a feed with spending but no income still suggests expenses', () {
      final s = suggestProfileFromTransactions([
        _txn(amount: -900, category: 'housing'),
      ], days: 30);

      expect(s!.monthlyIncome, 0);
      expect(s.fixedMonthlyExpenses, 900);
    });

    test('guards against a zero or negative window', () {
      expect(
        suggestProfileFromTransactions([
          _txn(amount: 100, category: 'income'),
        ], days: 0),
        isNull,
      );
    });

    test('rounds to whole currency units so the form reads cleanly', () {
      final s = suggestProfileFromTransactions([
        _txn(amount: 1000.4, category: 'income'),
      ], days: 30);

      expect(s!.monthlyIncome, 1000);
    });
  });
}
