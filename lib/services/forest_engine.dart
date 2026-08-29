import '../models/forest_day.dart';
import '../models/wealth_report.dart';

class ForestEngine {
  CheckInResult checkIn({
    required List<ForestDay> existingDays,
    required WealthReport report,
    required DateTime date,
    required double spending,
    required bool actionCompleted,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final previousDays = _withMissedDays(
      existingDays
          .where((day) => !_isSameDate(day.date, normalizedDate))
          .toList(),
      normalizedDate,
      report.dailyBudget,
    );
    final overBudget = spending > report.dailyBudget;
    final healthy = actionCompleted && !overBudget;
    final provisionalDays = [
      ...previousDays,
      ForestDay(
        date: normalizedDate,
        status: healthy ? TreeStatus.healthy : TreeStatus.withered,
        treeLevel: 0,
        spending: spending,
        dailyBudget: report.dailyBudget,
        actionCompleted: actionCompleted,
        message: _message(
          actionCompleted: actionCompleted,
          overBudget: overBudget,
        ),
      ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    final streak = _currentStreak(provisionalDays);
    final day = provisionalDays.firstWhere(
      (day) => _isSameDate(day.date, normalizedDate),
    );
    final updatedDay = ForestDay(
      date: day.date,
      status: day.status,
      treeLevel: day.status == TreeStatus.healthy ? _treeLevel(streak) : 0,
      spending: day.spending,
      dailyBudget: day.dailyBudget,
      actionCompleted: day.actionCompleted,
      message: day.message,
    );
    final updatedDays = provisionalDays
        .map((day) => _isSameDate(day.date, normalizedDate) ? updatedDay : day)
        .toList();

    return CheckInResult(
      day: updatedDay,
      summary: summarize(updatedDays),
    );
  }

  List<ForestDay> _withMissedDays(
    List<ForestDay> existingDays,
    DateTime checkInDate,
    double dailyBudget,
  ) {
    if (existingDays.isEmpty) {
      return existingDays;
    }

    final orderedDays = [...existingDays]..sort((a, b) => a.date.compareTo(b.date));
    final lastRecordedDate = orderedDays.last.date;
    final missedDays = <ForestDay>[];
    var missedDate = lastRecordedDate.add(const Duration(days: 1));

    while (missedDate.isBefore(checkInDate)) {
      missedDays.add(
        ForestDay(
          date: missedDate,
          status: TreeStatus.withered,
          treeLevel: 0,
          spending: 0,
          dailyBudget: dailyBudget,
          actionCompleted: false,
          message: 'Today withered because no check-in was completed.',
        ),
      );
      missedDate = missedDate.add(const Duration(days: 1));
    }

    return [...orderedDays, ...missedDays];
  }

  ForestSummary summarize(List<ForestDay> days) {
    final orderedDays = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final healthyTreeCount =
        orderedDays.where((day) => day.status == TreeStatus.healthy).length;
    final witheredTreeCount =
        orderedDays.where((day) => day.status == TreeStatus.withered).length;
    final currentStreak = _currentStreak(orderedDays);

    return ForestSummary(
      days: orderedDays,
      currentStreak: currentStreak,
      healthyTreeCount: healthyTreeCount,
      witheredTreeCount: witheredTreeCount,
      achievements: _achievements(
        days: orderedDays,
        currentStreak: currentStreak,
        healthyTreeCount: healthyTreeCount,
      ),
    );
  }

  String _message({required bool actionCompleted, required bool overBudget}) {
    if (!actionCompleted && overBudget) {
      return 'Today withered because the action was incomplete and spending exceeded the budget.';
    }
    if (!actionCompleted) {
      return 'Today withered because the money action was not completed.';
    }
    if (overBudget) {
      return 'Today withered because spending exceeded the daily budget.';
    }
    return 'Healthy growth: action complete and spending stayed within budget.';
  }

  int _treeLevel(int streak) {
    if (streak >= 7) {
      return 3;
    }
    if (streak >= 3) {
      return 2;
    }
    return 1;
  }

  int _currentStreak(List<ForestDay> days) {
    var streak = 0;
    for (final day in days.reversed) {
      if (day.status == TreeStatus.healthy) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  List<Achievement> _achievements({
    required List<ForestDay> days,
    required int currentStreak,
    required int healthyTreeCount,
  }) {
    final budgetGuardian = days.any(
      (day) =>
          day.status == TreeStatus.healthy &&
          day.spending <= day.dailyBudget * 0.8,
    );
    final recoveryDay = _hasRecoveryDay(days);

    return [
      Achievement(
        id: 'first-sapling',
        title: 'First Sapling',
        description: 'Grow your first healthy wealth tree.',
        unlocked: healthyTreeCount >= 1,
      ),
      Achievement(
        id: 'three-day-streak',
        title: 'Three Day Streak',
        description: 'Keep your plan alive for three days.',
        unlocked: currentStreak >= 3,
      ),
      Achievement(
        id: 'budget-guardian',
        title: 'Budget Guardian',
        description: 'Finish a day below 80 percent of budget.',
        unlocked: budgetGuardian,
      ),
      Achievement(
        id: 'recovery-day',
        title: 'Recovery Day',
        description: 'Grow again after a withered day.',
        unlocked: recoveryDay,
      ),
      Achievement(
        id: 'forest-builder',
        title: 'Forest Builder',
        description: 'Grow seven healthy trees.',
        unlocked: healthyTreeCount >= 7,
      ),
    ];
  }

  bool _hasRecoveryDay(List<ForestDay> days) {
    for (var index = 1; index < days.length; index++) {
      if (days[index - 1].status == TreeStatus.withered &&
          days[index].status == TreeStatus.healthy) {
        return true;
      }
    }
    return false;
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
