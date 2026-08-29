import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/forest_day.dart';
import 'package:moneymoneymoney/services/savings_stats_service.dart';

ForestDay _day({
  required DateTime date,
  required double spending,
  required double dailyBudget,
  TreeStatus status = TreeStatus.healthy,
}) {
  return ForestDay(
    date: date,
    status: status,
    treeLevel: 1,
    spending: spending,
    dailyBudget: dailyBudget,
    actionCompleted: true,
    message: '',
  );
}

void main() {
  group('computeSavingsSeries', () {
    test('returns an empty series when there are no days', () {
      final series = computeSavingsSeries(days: const [], period: StatsPeriod.week);

      expect(series, isEmpty);
    });

    test('accumulates saved amount (budget minus spending) within a week', () {
      final days = [
        _day(date: DateTime(2026, 8, 24), spending: 30, dailyBudget: 50), // +20
        _day(date: DateTime(2026, 8, 25), spending: 60, dailyBudget: 50), // -10
      ];

      final series = computeSavingsSeries(days: days, period: StatsPeriod.week);

      expect(series, hasLength(1));
      expect(series.single.cumulativeSaved, 10);
    });

    test('produces one running-total point per calendar month, in order', () {
      final days = [
        _day(date: DateTime(2026, 7, 15), spending: 30, dailyBudget: 50), // +20
        _day(date: DateTime(2026, 8, 5), spending: 40, dailyBudget: 50), // +10
        _day(date: DateTime(2026, 8, 20), spending: 60, dailyBudget: 50), // -10
      ];

      final series = computeSavingsSeries(days: days, period: StatsPeriod.month);

      expect(series, hasLength(2));
      expect(series[0].cumulativeSaved, 20);
      expect(series[1].cumulativeSaved, 20); // 20 + 10 - 10
    });

    test('produces one running-total point per calendar year, in order', () {
      final days = [
        _day(date: DateTime(2025, 12, 31), spending: 30, dailyBudget: 50), // +20
        _day(date: DateTime(2026, 1, 2), spending: 40, dailyBudget: 50), // +10
      ];

      final series = computeSavingsSeries(days: days, period: StatsPeriod.year);

      expect(series, hasLength(2));
      expect(series[0].cumulativeSaved, 20);
      expect(series[1].cumulativeSaved, 30);
    });

    test('ignores days that were never checked in (pending)', () {
      final days = [
        _day(
          date: DateTime(2026, 8, 24),
          spending: 0,
          dailyBudget: 50,
          status: TreeStatus.pending,
        ),
      ];

      final series = computeSavingsSeries(days: days, period: StatsPeriod.week);

      expect(series, isEmpty);
    });
  });
}
