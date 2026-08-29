import '../models/forest_day.dart';
import '../models/progression.dart';

class ProgressionEngine {
  static const int _maxLevel = 50;
  static const Map<int, int> _streakMilestoneCoins = {
    3: 15,
    7: 30,
    14: 60,
    30: 120,
  };

  ProgressionState compute({
    required List<ForestDay> days,
    required List<Achievement> achievements,
    required List<RewardEvent> spendEvents,
  }) {
    final orderedDays = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final earned = <RewardEvent>[];
    var runningXp = 0;
    var runningLevel = 1;
    var runningStreak = 0;

    void checkLevelUps(DateTime date) {
      while (runningLevel < _maxLevel &&
          runningXp >= totalXpForLevel(runningLevel + 1)) {
        runningLevel++;
        earned.add(
          RewardEvent(
            date: date,
            type: RewardEventType.levelUp,
            xp: 0,
            coins: 25 * runningLevel,
            description: 'Reached level $runningLevel',
          ),
        );
      }
    }

    for (final day in orderedDays) {
      final continuesStreak =
          day.status == TreeStatus.healthy || day.status == TreeStatus.restored;
      final streakBeforeToday = runningStreak;
      final streakAfterToday = continuesStreak ? runningStreak + 1 : 0;

      if (day.status == TreeStatus.healthy) {
        final streakBonus =
            (streakBeforeToday < 10 ? streakBeforeToday : 10) * 2;
        final dayXp = 10 + streakBonus;
        runningXp += dayXp;
        earned.add(
          RewardEvent(
            date: day.date,
            type: RewardEventType.healthyDay,
            xp: dayXp,
            coins: 5,
            description: 'Healthy day',
          ),
        );
        checkLevelUps(day.date);

        if (day.spending <= day.dailyBudget * 0.8) {
          runningXp += 5;
          earned.add(
            RewardEvent(
              date: day.date,
              type: RewardEventType.underBudget,
              xp: 5,
              coins: 3,
              description: 'Under budget bonus',
            ),
          );
          checkLevelUps(day.date);
        }

        final milestoneCoins = _streakMilestoneCoins[streakAfterToday];
        if (milestoneCoins != null) {
          earned.add(
            RewardEvent(
              date: day.date,
              type: RewardEventType.streakMilestone,
              xp: 0,
              coins: milestoneCoins,
              description: 'Streak milestone: $streakAfterToday days',
            ),
          );
        }
      }

      runningStreak = streakAfterToday;
    }

    final unlockDate = orderedDays.isNotEmpty
        ? orderedDays.last.date
        : DateTime(1970, 1, 1);
    for (final achievement in achievements) {
      if (!achievement.unlocked) {
        continue;
      }
      runningXp += 25;
      earned.add(
        RewardEvent(
          date: unlockDate,
          type: RewardEventType.achievementUnlock,
          xp: 25,
          coins: 20,
          description: 'Achievement unlocked: ${achievement.title}',
        ),
      );
      checkLevelUps(unlockDate);
    }

    final ledger = _stableSortByDate([...earned, ...spendEvents]);
    var lifetimeCoinsEarned = 0;
    var lifetimeCoinsSpent = 0;
    for (final event in ledger) {
      if (event.coins > 0) {
        lifetimeCoinsEarned += event.coins;
      } else if (event.coins < 0) {
        lifetimeCoinsSpent += -event.coins;
      }
    }

    return ProgressionState(
      totalXp: runningXp,
      level: levelForXp(runningXp),
      coinBalance: lifetimeCoinsEarned - lifetimeCoinsSpent,
      lifetimeCoinsEarned: lifetimeCoinsEarned,
      lifetimeCoinsSpent: lifetimeCoinsSpent,
      ledger: ledger,
    );
  }

  LevelProgress levelForXp(int totalXp) {
    var level = 1;
    while (level < _maxLevel && totalXp >= totalXpForLevel(level + 1)) {
      level++;
    }
    final xpIntoLevel = totalXp - totalXpForLevel(level);
    final xpForNextLevel = xpToAdvance(level);
    final fraction = xpForNextLevel > 0
        ? (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0)
        : 1.0;

    return LevelProgress(
      level: level,
      xpIntoLevel: xpIntoLevel,
      xpForNextLevel: xpForNextLevel,
      fraction: fraction,
    );
  }

  /// Cumulative XP required to have reached [level].
  ///
  /// Derived from `xpToAdvance` as the sum of the per-level requirements, so
  /// the two formulas always agree with each other by construction.
  int totalXpForLevel(int level) {
    return 100 * (level - 1) + 25 * (level - 1) * (level - 2);
  }

  /// XP required to advance from [level] to `level + 1`.
  int xpToAdvance(int level) {
    return 100 + 50 * (level - 1);
  }

  List<RewardEvent> _stableSortByDate(List<RewardEvent> events) {
    final indexed = events.asMap().entries.toList()
      ..sort((a, b) {
        final byDate = a.value.date.compareTo(b.value.date);
        if (byDate != 0) {
          return byDate;
        }
        return a.key.compareTo(b.key);
      });
    return [for (final entry in indexed) entry.value];
  }
}
