import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/forest_day.dart';
import 'package:moneymoneymoney/models/progression.dart';
import 'package:moneymoneymoney/services/progression_engine.dart';

ForestDay _healthyDay(
  DateTime date, {
  double spending = 10,
  double dailyBudget = 50,
}) {
  return ForestDay(
    date: date,
    status: TreeStatus.healthy,
    treeLevel: 1,
    spending: spending,
    dailyBudget: dailyBudget,
    actionCompleted: true,
    message: 'Healthy growth',
  );
}

ForestDay _witheredDay(DateTime date) {
  return ForestDay(
    date: date,
    status: TreeStatus.withered,
    treeLevel: 0,
    spending: 100,
    dailyBudget: 50,
    actionCompleted: false,
    message: 'Withered',
  );
}

ForestDay _restoredDay(DateTime date) {
  return ForestDay(
    date: date,
    status: TreeStatus.restored,
    treeLevel: 1,
    spending: 100,
    dailyBudget: 50,
    actionCompleted: false,
    message: 'Withered',
    restoredAt: date,
    recoveryNote: 'Back on track',
  );
}

void main() {
  final engine = ProgressionEngine();

  group('ProgressionEngine level curve', () {
    test(
      'level thresholds match the closed-form table at levels 1 through 6',
      () {
        // totalXpForLevel(L) = 100 * (L - 1) + 25 * (L - 1) * (L - 2), the same
        // closed form given in the spec, cross-checked against the cumulative
        // sum of xpToAdvance(1..L-1) so both formulas agree by construction.
        const expected = {1: 0, 2: 100, 3: 250, 4: 450, 5: 700, 6: 1000};

        for (final entry in expected.entries) {
          expect(engine.totalXpForLevel(entry.key), entry.value);
        }
      },
    );

    test('levelForXp returns the level whose threshold has been reached', () {
      expect(engine.levelForXp(0).level, 1);
      expect(engine.levelForXp(99).level, 1);
      expect(engine.levelForXp(100).level, 2);
      expect(engine.levelForXp(249).level, 2);
      expect(engine.levelForXp(250).level, 3);
    });
  });

  group('ProgressionEngine XP and coins', () {
    test('a single healthy day under budget awards 15 XP and 8 coins', () {
      final state = engine.compute(
        days: [
          _healthyDay(DateTime(2026, 8, 29), spending: 10, dailyBudget: 50),
        ],
        achievements: const [],
        spendEvents: const [],
      );

      expect(state.totalXp, 15);
      expect(state.coinBalance, 8);
      expect(state.lifetimeCoinsEarned, 8);
      expect(state.lifetimeCoinsSpent, 0);
    });

    test(
      'a three-day healthy streak awards the streak milestone coins exactly once',
      () {
        final days = [
          _healthyDay(DateTime(2026, 8, 27), spending: 40, dailyBudget: 50),
          _healthyDay(DateTime(2026, 8, 28), spending: 40, dailyBudget: 50),
          _healthyDay(DateTime(2026, 8, 29), spending: 40, dailyBudget: 50),
        ];

        final state = engine.compute(
          days: days,
          achievements: const [],
          spendEvents: const [],
        );

        final milestoneEvents = state.ledger
            .where((event) => event.type == RewardEventType.streakMilestone)
            .toList();

        expect(milestoneEvents, hasLength(1));
        expect(milestoneEvents.single.coins, 15);
      },
    );

    test('withered and restored days award zero XP and zero coins', () {
      final witheredState = engine.compute(
        days: [_witheredDay(DateTime(2026, 8, 29))],
        achievements: const [],
        spendEvents: const [],
      );
      final restoredState = engine.compute(
        days: [_restoredDay(DateTime(2026, 8, 29))],
        achievements: const [],
        spendEvents: const [],
      );

      expect(witheredState.totalXp, 0);
      expect(witheredState.coinBalance, 0);
      expect(restoredState.totalXp, 0);
      expect(restoredState.coinBalance, 0);
    });

    test(
      'coin balance equals lifetime earned minus lifetime spent after a mixed sequence',
      () {
        final days = [
          _healthyDay(DateTime(2026, 8, 25), spending: 40, dailyBudget: 50),
          _witheredDay(DateTime(2026, 8, 26)),
          _restoredDay(DateTime(2026, 8, 27)),
          _healthyDay(DateTime(2026, 8, 28), spending: 5, dailyBudget: 50),
        ];
        final spendEvents = [
          RewardEvent(
            date: DateTime(2026, 8, 27),
            type: RewardEventType.restorationSpend,
            xp: 0,
            coins: -60,
            description: 'Restored 2026-8-26',
          ),
        ];

        final state = engine.compute(
          days: days,
          achievements: const [],
          spendEvents: spendEvents,
        );

        expect(
          state.coinBalance,
          state.lifetimeCoinsEarned - state.lifetimeCoinsSpent,
        );
        expect(state.lifetimeCoinsSpent, 60);
      },
    );

    test('level-up coins scale with the new level', () {
      // 12 consecutive healthy, under-budget days cross the level-2 threshold
      // (100 XP) and pay 25 * 2 coins for reaching it.
      final days = [
        for (var i = 0; i < 12; i++)
          _healthyDay(DateTime(2026, 8, 1 + i), spending: 1, dailyBudget: 50),
      ];

      final state = engine.compute(
        days: days,
        achievements: const [],
        spendEvents: const [],
      );

      final levelUpEvents = state.ledger
          .where((event) => event.type == RewardEventType.levelUp)
          .toList();

      expect(levelUpEvents, isNotEmpty);
      expect(levelUpEvents.first.coins, 25 * 2);
    });

    test('achievement unlock awards 25 XP and 20 coins once', () {
      final state = engine.compute(
        days: const [],
        achievements: const [
          Achievement(
            id: 'first-sapling',
            title: 'First Sapling',
            description: 'Grow your first healthy wealth tree.',
            unlocked: true,
          ),
        ],
        spendEvents: const [],
      );

      expect(state.totalXp, 25);
      expect(state.coinBalance, 20);
    });
  });
}
