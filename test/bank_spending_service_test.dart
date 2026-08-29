import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/models.dart';
import 'package:moneymoneymoney/services/bank_spending_service.dart';

Txn _txn({
  required String postDate,
  required double amount,
  String id = 'tx-1',
}) {
  return Txn(
    id: id,
    accountId: 'acc-txn',
    postDate: postDate,
    description: 'Test',
    amount: amount,
    category: 'other',
    bucket: 'living',
  );
}

void main() {
  group('sumTodaySpending', () {
    test('sums the absolute value of today\'s debit transactions', () {
      final today = DateTime(2026, 8, 29);
      final result = sumTodaySpending([
        _txn(id: 'tx-1', postDate: '2026-08-29', amount: -12.5),
        _txn(id: 'tx-2', postDate: '2026-08-29', amount: -7.25),
      ], today: today);

      expect(result, 19.75);
    });

    test('ignores transactions from other days', () {
      final today = DateTime(2026, 8, 29);
      final result = sumTodaySpending([
        _txn(id: 'tx-1', postDate: '2026-08-28', amount: -12.5),
      ], today: today);

      expect(result, 0.0);
    });

    test('ignores credits (deposits) even when dated today', () {
      final today = DateTime(2026, 8, 29);
      final result = sumTodaySpending([
        _txn(id: 'tx-1', postDate: '2026-08-29', amount: 1350.0),
      ], today: today);

      expect(result, 0.0);
    });

    test('returns 0 when there are no transactions', () {
      final result = sumTodaySpending(const [], today: DateTime(2026, 8, 29));

      expect(result, 0.0);
    });
  });
}
