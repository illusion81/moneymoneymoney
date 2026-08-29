import 'progression.dart';

enum TreeStatus { pending, healthy, withered, restored }

class ForestDay {
  const ForestDay({
    required this.date,
    required this.status,
    required this.treeLevel,
    required this.spending,
    required this.dailyBudget,
    required this.actionCompleted,
    required this.message,
    this.restoredAt,
    this.recoveryNote,
  });

  final DateTime date;
  final TreeStatus status;
  final int treeLevel;
  final double spending;
  final double dailyBudget;
  final bool actionCompleted;
  final String message;
  final DateTime? restoredAt;
  final String? recoveryNote;
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
    this.restoredTreeCount = 0,
  });

  final List<ForestDay> days;
  final int currentStreak;
  final int healthyTreeCount;
  final int witheredTreeCount;
  final int restoredTreeCount;
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

class RestorationQuote {
  const RestorationQuote({
    required this.eligible,
    required this.cost,
    this.blockedReason,
  });

  final bool eligible;
  final int cost;
  final String? blockedReason;
}

class RestorationResult {
  const RestorationResult({
    required this.success,
    required this.summary,
    this.failureReason,
    this.spendEvent,
  });

  final bool success;
  final String? failureReason;
  final ForestSummary summary;
  final RewardEvent? spendEvent;
}
