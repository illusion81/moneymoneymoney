enum TreeStatus { pending, healthy, withered }

class ForestDay {
  const ForestDay({
    required this.date,
    required this.status,
    required this.treeLevel,
    required this.spending,
    required this.dailyBudget,
    required this.actionCompleted,
    required this.message,
  });

  final DateTime date;
  final TreeStatus status;
  final int treeLevel;
  final double spending;
  final double dailyBudget;
  final bool actionCompleted;
  final String message;
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;
}

class ForestSummary {
  const ForestSummary({
    required this.days,
    required this.currentStreak,
    required this.healthyTreeCount,
    required this.witheredTreeCount,
    required this.achievements,
  });

  final List<ForestDay> days;
  final int currentStreak;
  final int healthyTreeCount;
  final int witheredTreeCount;
  final List<Achievement> achievements;
}

class CheckInResult {
  const CheckInResult({
    required this.day,
    required this.summary,
  });

  final ForestDay day;
  final ForestSummary summary;
}
