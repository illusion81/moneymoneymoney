enum RewardEventType {
  healthyDay,
  underBudget,
  streakMilestone,
  achievementUnlock,
  levelUp,
  restorationSpend,
  purchaseSpend,
  debugGrant,
}

class RewardEvent {
  const RewardEvent({
    required this.date,
    required this.type,
    required this.xp,
    required this.coins,
    required this.description,
  });

  final DateTime date;
  final RewardEventType type;
  final int xp;
  final int coins;
  final String description;
}

class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.fraction,
  });

  final int level;
  final int xpIntoLevel;
  final int xpForNextLevel;
  final double fraction;
}

class ProgressionState {
  const ProgressionState({
    required this.totalXp,
    required this.level,
    required this.coinBalance,
    required this.lifetimeCoinsEarned,
    required this.lifetimeCoinsSpent,
    required this.ledger,
  });

  final int totalXp;
  final LevelProgress level;
  final int coinBalance;
  final int lifetimeCoinsEarned;
  final int lifetimeCoinsSpent;
  final List<RewardEvent> ledger;
}
