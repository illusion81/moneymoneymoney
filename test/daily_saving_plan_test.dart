import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/models.dart';
import 'package:moneymoneymoney/services/daily_saving_plan.dart';

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
  group('buildDailySavingPlan', () {
    test('returns null when there is no discretionary spending to trim', () {
      final plan = buildDailySavingPlan([
        _txn(amount: -900, category: 'housing'),
        _txn(amount: -100, category: 'utilities'),
      ], days: 30);

      expect(plan, isNull);
    });

    test('returns null for an empty feed', () {
      expect(buildDailySavingPlan(const [], days: 30), isNull);
    });

    test('picks the largest discretionary category', () {
      final plan = buildDailySavingPlan([
        _txn(amount: -400, category: 'eating-out'),
        _txn(amount: -150, category: 'subscriptions'),
        // Essentials must never be proposed as something to cut.
        _txn(amount: -2000, category: 'housing'),
      ], days: 30);

      expect(plan!.category, 'eating-out');
    });

    test('monthly saving is the trim fraction of that categorys spend', () {
      final plan = buildDailySavingPlan([
        _txn(amount: -300, category: 'eating-out'),
      ], days: 30, trimFraction: 0.30);

      expect(plan!.monthlySaving, closeTo(90, 0.01));
      expect(plan.dailySaving, closeTo(3, 0.01));
    });

    test('normalises a longer window to a monthly figure', () {
      final plan = buildDailySavingPlan([
        _txn(amount: -600, category: 'eating-out'),
      ], days: 60, trimFraction: 0.30);

      // 600 over 60 days is 300 a month; trimming 30% saves 90.
      expect(plan!.monthlySaving, closeTo(90, 0.01));
    });

    test('reports the current monthly spend for that category', () {
      final plan = buildDailySavingPlan([
        _txn(amount: -300, category: 'eating-out'),
      ], days: 30);

      expect(plan!.monthlyCategorySpend, closeTo(300, 0.01));
    });

    test('ignores income and transfers', () {
      final plan = buildDailySavingPlan([
        _txn(amount: 5000, category: 'income'),
        _txn(amount: -500, category: 'transfer-out'),
        _txn(amount: -200, category: 'eating-out'),
      ], days: 30);

      expect(plan!.category, 'eating-out');
      expect(plan.monthlyCategorySpend, closeTo(200, 0.01));
    });

    test('guards against a zero window', () {
      expect(
        buildDailySavingPlan([
          _txn(amount: -200, category: 'eating-out'),
        ], days: 0),
        isNull,
      );
    });
  });
}
