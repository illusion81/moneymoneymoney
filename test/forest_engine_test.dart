import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/forest_day.dart';
import 'package:moneymoneymoney/models/wealth_report.dart';
import 'package:moneymoneymoney/services/forest_engine.dart';
import 'package:moneymoneymoney/services/progression_engine.dart';

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
    test('marks today healthy when spending is within budget', () {
      final result = ForestEngine().checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 40,
      );

      expect(result.day.status, TreeStatus.healthy);
      expect(result.day.treeLevel, 1);
      expect(result.summary.currentStreak, 1);
      expect(result.summary.healthyTreeCount, 1);
    });

    test('spending exactly at the daily budget still counts as healthy', () {
      final result = ForestEngine().checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 50,
      );

      expect(result.day.status, TreeStatus.healthy);
    });

    test('marks today withered when spending exceeds daily budget', () {
      final result = ForestEngine().checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 75,
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
      );
      final second = engine.checkIn(
        existingDays: first.summary.days,
        report: report,
        date: DateTime(2026, 8, 28),
        spending: 35,
      );
      final third = engine.checkIn(
        existingDays: second.summary.days,
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 39,
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

    test(
      'inserts withered missed days and resets streak across calendar gaps',
      () {
        final engine = ForestEngine();
        final first = engine.checkIn(
          existingDays: const [],
          report: report,
          date: DateTime(2026, 8, 27),
          spending: 30,
        );
        final third = engine.checkIn(
          existingDays: first.summary.days,
          report: report,
          date: DateTime(2026, 8, 29),
          spending: 30,
        );

        expect(third.summary.days, hasLength(3));
        expect(third.summary.days[1].date, DateTime(2026, 8, 28));
        expect(third.summary.days[1].status, TreeStatus.withered);
        expect(third.summary.currentStreak, 1);
        expect(third.summary.healthyTreeCount, 2);
        expect(third.summary.witheredTreeCount, 1);
      },
    );

    test('returns the checked-in day when updating an earlier date', () {
      final engine = ForestEngine();
      final first = engine.checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 30,
      );
      final earlier = engine.checkIn(
        existingDays: first.summary.days,
        report: report,
        date: DateTime(2026, 8, 28),
        spending: 10,
      );

      expect(earlier.day.date, DateTime(2026, 8, 28));
      expect(earlier.day.status, TreeStatus.healthy);
      expect(earlier.summary.days.map((day) => day.date), [
        DateTime(2026, 8, 28),
        DateTime(2026, 8, 29),
      ]);
    });
  });

  group('ForestEngine restoration', () {
    List<ForestDay> witheredDayList(DateTime date) {
      return [
        ForestDay(
          date: date,
          status: TreeStatus.withered,
          treeLevel: 0,
          spending: 100,
          dailyBudget: 50,
          actionCompleted: false,
          message: 'Today withered because spending exceeded the daily budget.',
        ),
      ];
    }

    test(
      'a withered day within 7 days quotes a cost of 60 on the first restoration',
      () {
        final engine = ForestEngine();
        final witheredDate = DateTime(2026, 8, 25);
        final now = DateTime(2026, 8, 29);

        final quote = engine.quoteRestoration(
          days: witheredDayList(witheredDate),
          dayDate: witheredDate,
          now: now,
        );

        expect(quote.eligible, isTrue);
        expect(quote.cost, 60);
      },
    );

    test('the second restoration in the window quotes 150', () {
      final engine = ForestEngine();
      final firstWitheredDate = DateTime(2026, 8, 1);
      final secondWitheredDate = DateTime(2026, 8, 25);
      final now = DateTime(2026, 8, 29);

      final days = [
        ForestDay(
          date: firstWitheredDate,
          status: TreeStatus.restored,
          treeLevel: 1,
          spending: 100,
          dailyBudget: 50,
          actionCompleted: false,
          message: 'withered',
          restoredAt: DateTime(2026, 8, 5),
          recoveryNote: 'back on track',
        ),
        ForestDay(
          date: secondWitheredDate,
          status: TreeStatus.withered,
          treeLevel: 0,
          spending: 100,
          dailyBudget: 50,
          actionCompleted: false,
          message: 'withered',
        ),
      ];

      final quote = engine.quoteRestoration(
        days: days,
        dayDate: secondWitheredDate,
        now: now,
      );

      expect(quote.eligible, isTrue);
      expect(quote.cost, 150);
    });

    test('a third restoration in the window is refused', () {
      final engine = ForestEngine();
      final thirdWitheredDate = DateTime(2026, 8, 26);
      final now = DateTime(2026, 8, 29);

      final days = [
        ForestDay(
          date: DateTime(2026, 8, 5),
          status: TreeStatus.restored,
          treeLevel: 1,
          spending: 100,
          dailyBudget: 50,
          actionCompleted: false,
          message: 'withered',
          restoredAt: DateTime(2026, 8, 6),
          recoveryNote: 'back on track',
        ),
        ForestDay(
          date: DateTime(2026, 8, 15),
          status: TreeStatus.restored,
          treeLevel: 1,
          spending: 100,
          dailyBudget: 50,
          actionCompleted: false,
          message: 'withered',
          restoredAt: DateTime(2026, 8, 16),
          recoveryNote: 'back on track',
        ),
        ForestDay(
          date: thirdWitheredDate,
          status: TreeStatus.withered,
          treeLevel: 0,
          spending: 100,
          dailyBudget: 50,
          actionCompleted: false,
          message: 'withered',
        ),
      ];

      final quote = engine.quoteRestoration(
        days: days,
        dayDate: thirdWitheredDate,
        now: now,
      );

      expect(quote.eligible, isFalse);
      expect(quote.blockedReason, isNotNull);
    });

    test('a withered day exactly 6 days old is eligible (boundary)', () {
      final engine = ForestEngine();
      final witheredDate = DateTime(2026, 8, 23);
      final now = DateTime(2026, 8, 29);

      final quote = engine.quoteRestoration(
        days: witheredDayList(witheredDate),
        dayDate: witheredDate,
        now: now,
      );

      expect(quote.eligible, isTrue);
      expect(quote.cost, 60);
    });

    test('a withered day exactly 7 days old is ineligible (boundary)', () {
      final engine = ForestEngine();
      final witheredDate = DateTime(2026, 8, 22);
      final now = DateTime(2026, 8, 29);

      final quote = engine.quoteRestoration(
        days: witheredDayList(witheredDate),
        dayDate: witheredDate,
        now: now,
      );

      expect(quote.eligible, isFalse);
      expect(quote.blockedReason, isNotNull);
    });

    test('a withered day older than 7 days is refused', () {
      final engine = ForestEngine();
      final witheredDate = DateTime(2026, 8, 10);
      final now = DateTime(2026, 8, 29);

      final quote = engine.quoteRestoration(
        days: witheredDayList(witheredDate),
        dayDate: witheredDate,
        now: now,
      );

      expect(quote.eligible, isFalse);
      expect(quote.blockedReason, isNotNull);
    });

    test(
      'restoration sets status to restored, repairs the streak, decrements the withered count, and does not increment the healthy count',
      () {
        final engine = ForestEngine();
        final witheredDate = DateTime(2026, 8, 29);
        final days = witheredDayList(witheredDate);

        final result = engine.restoreDay(
          days: days,
          dayDate: witheredDate,
          now: witheredDate,
          recoveryNote: 'Spent within budget the next day',
          coinBalance: 200,
        );

        expect(result.success, isTrue);
        expect(result.summary.days.single.status, TreeStatus.restored);
        expect(result.summary.days.single.treeLevel, 1);
        expect(result.summary.currentStreak, 1);
        expect(result.summary.witheredTreeCount, 0);
        expect(result.summary.healthyTreeCount, 0);
        expect(result.summary.restoredTreeCount, 1);
        expect(result.spendEvent, isNotNull);
        expect(result.spendEvent!.coins, -60);
      },
    );

    test(
      'restoration with an empty note is refused and leaves state unchanged',
      () {
        final engine = ForestEngine();
        final witheredDate = DateTime(2026, 8, 29);
        final days = witheredDayList(witheredDate);

        final result = engine.restoreDay(
          days: days,
          dayDate: witheredDate,
          now: witheredDate,
          recoveryNote: '   ',
          coinBalance: 200,
        );

        expect(result.success, isFalse);
        expect(result.failureReason, isNotNull);
        expect(result.spendEvent, isNull);
        expect(result.summary.days.single.status, TreeStatus.withered);
      },
    );

    test(
      'Recovery Day still unlocks for a healthy day following a restored day',
      () {
        final engine = ForestEngine();
        final witheredDate = DateTime(2026, 8, 28);
        final days = witheredDayList(witheredDate);

        final restoreResult = engine.restoreDay(
          days: days,
          dayDate: witheredDate,
          now: witheredDate,
          recoveryNote: 'Getting back on track',
          coinBalance: 200,
        );

        final checkInResult = engine.checkIn(
          existingDays: restoreResult.summary.days,
          report: report,
          date: DateTime(2026, 8, 29),
          spending: 20,
        );

        final recoveryDay = checkInResult.summary.achievements.firstWhere(
          (achievement) => achievement.id == 'recovery-day',
        );

        expect(recoveryDay.unlocked, isTrue);
      },
    );
  });

  group('Progression/achievement convergence', () {
    test(
      'achievement unlock → level up → Seedling Scholar unlock → more XP converges within 6 passes',
      () {
        final engine = ForestEngine();
        final progressionEngine = ProgressionEngine();

        var days = <ForestDay>[];
        var achievements = <Achievement>[];
        var progression = progressionEngine.compute(
          days: days,
          achievements: achievements,
          spendEvents: const [],
        );

        var stable = false;
        var passCount = 0;
        for (passCount = 0; passCount < 6; passCount++) {
          final newProgression = progressionEngine.compute(
            days: days,
            achievements: achievements,
            spendEvents: const [],
          );
          final newSummary = engine.summarize(
            days,
            progression: newProgression,
            shopState: null,
          );
          stable =
              newProgression.totalXp == progression.totalXp &&
              _sameUnlockState(newSummary.achievements, achievements);

          progression = newProgression;
          achievements = newSummary.achievements;

          if (stable) {
            break;
          }
        }

        expect(
          stable,
          isTrue,
          reason: 'Should converge within 6 passes, took $passCount',
        );
        expect(
          passCount,
          lessThan(6),
          reason: 'Should converge before reaching pass budget',
        );
      },
    );
  });
}

bool _sameUnlockState(List<Achievement> a, List<Achievement> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i].unlocked != b[i].unlocked) {
      return false;
    }
  }
  return true;
}
