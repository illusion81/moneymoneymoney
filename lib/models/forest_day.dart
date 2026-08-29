import 'progression.dart';

/// [frozen] is a day you missed that a streak freeze covered. It is not a
/// healthy day — it earns nothing — but it does not break the chain either.
/// Missing a day is the moment people delete a habit app; the freeze is the
/// product saying "you are still in this" instead of resetting you to zero.
enum TreeStatus { pending, healthy, withered, restored, frozen }

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

/// How many freezes the player holds, and how many they may hold at once.
/// Plus members carry more — this is the one subscription perk that changes
/// what happens on your worst day rather than what your farm looks like.
class FreezeState {
  const FreezeState({required this.available, required this.capacity});

  final int available;
  final int capacity;

  bool get isFull => available >= capacity;

  FreezeState copyWith({int? available, int? capacity}) => FreezeState(
        available: available ?? this.available,
        capacity: capacity ?? this.capacity,
      );
}

class CheckInResult {
  const CheckInResult({
    required this.day,
    required this.summary,
    this.freezesUsed = 0,
  });

  final ForestDay day;
  final ForestSummary summary;

  /// Freezes spent covering days missed since the last check-in, so the
  /// caller can deduct them and tell the user what happened.
  final int freezesUsed;
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
