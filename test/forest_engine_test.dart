import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/forest_day.dart';
import 'package:moneymoneymoney/models/wealth_report.dart';
import 'package:moneymoneymoney/services/forest_engine.dart';

void main() {
  const report = WealthReport(
    profileSummary: 'summary',
    disposableIncome: 3000,
    dailyBudget: 50,
    savingsAdvice: 'save',
    riskAdvice: 'risk',
    warning: null,
    dailyActions: ['Record every expense today.'],
  );

  group('ForestEngine', () {
    test('marks today healthy when action is complete and spending is within budget', () {
      final result = ForestEngine().checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 40,
        actionCompleted: true,
      );

      expect(result.day.status, TreeStatus.healthy);
      expect(result.day.treeLevel, 1);
      expect(result.summary.currentStreak, 1);
      expect(result.summary.healthyTreeCount, 1);
    });

    test('marks today withered when action is incomplete', () {
      final result = ForestEngine().checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 20,
        actionCompleted: false,
      );

      expect(result.day.status, TreeStatus.withered);
      expect(result.day.treeLevel, 0);
      expect(result.day.message, contains('action'));
      expect(result.summary.currentStreak, 0);
    });

    test('marks today withered when spending exceeds daily budget', () {
      final result = ForestEngine().checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 75,
        actionCompleted: true,
      );

      expect(result.day.status, TreeStatus.withered);
      expect(result.day.message, contains('budget'));
      expect(result.summary.witheredTreeCount, 1);
    });

    test('unlocks streak and budget achievements', () {
      final engine = ForestEngine();
      final first = engine.checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 27),
        spending: 30,
        actionCompleted: true,
      );
      final second = engine.checkIn(
        existingDays: first.summary.days,
        report: report,
        date: DateTime(2026, 8, 28),
        spending: 35,
        actionCompleted: true,
      );
      final third = engine.checkIn(
        existingDays: second.summary.days,
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 39,
        actionCompleted: true,
      );

      final unlocked = third.summary.achievements
          .where((achievement) => achievement.unlocked)
          .map((achievement) => achievement.title);

      expect(third.day.treeLevel, 2);
      expect(third.summary.currentStreak, 3);
      expect(unlocked, contains('First Sapling'));
      expect(unlocked, contains('Three Day Streak'));
      expect(unlocked, contains('Budget Guardian'));
    });

    test('inserts withered missed days and resets streak across calendar gaps', () {
      final engine = ForestEngine();
      final first = engine.checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 27),
        spending: 30,
        actionCompleted: true,
      );
      final third = engine.checkIn(
        existingDays: first.summary.days,
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 30,
        actionCompleted: true,
      );

      expect(third.summary.days, hasLength(3));
      expect(third.summary.days[1].date, DateTime(2026, 8, 28));
      expect(third.summary.days[1].status, TreeStatus.withered);
      expect(third.summary.currentStreak, 1);
      expect(third.summary.healthyTreeCount, 2);
      expect(third.summary.witheredTreeCount, 1);
    });

    test('returns the checked-in day when updating an earlier date', () {
      final engine = ForestEngine();
      final first = engine.checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 30,
        actionCompleted: true,
      );
      final earlier = engine.checkIn(
        existingDays: first.summary.days,
        report: report,
        date: DateTime(2026, 8, 28),
        spending: 10,
        actionCompleted: true,
      );

      expect(earlier.day.date, DateTime(2026, 8, 28));
      expect(earlier.day.status, TreeStatus.healthy);
      expect(earlier.summary.days.map((day) => day.date), [
        DateTime(2026, 8, 28),
        DateTime(2026, 8, 29),
      ]);
    });
  });
}
