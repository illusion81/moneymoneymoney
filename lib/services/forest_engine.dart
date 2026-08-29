import '../models/forest_day.dart';
import '../models/progression.dart';
import '../models/shop_item.dart';
import '../models/wealth_report.dart';

class ForestEngine {
  /// Records [spending] for [date]. A day is healthy purely when spending
  /// stayed within the daily budget — the report's daily money action is
  /// advisory guidance and deliberately does not gate the tree.
  CheckInResult checkIn({
    required List<ForestDay> existingDays,
    required WealthReport report,
    required DateTime date,
    required double spending,
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
    final healthy = !overBudget;
    final provisionalDays = [
      ...previousDays,
      ForestDay(
        date: normalizedDate,
        status: healthy ? TreeStatus.healthy : TreeStatus.withered,
        treeLevel: 0,
        spending: spending,
        dailyBudget: report.dailyBudget,
        actionCompleted: healthy,
        message: _message(overBudget: overBudget),
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
      restoredAt: day.restoredAt,
      recoveryNote: day.recoveryNote,
    );
    final updatedDays = provisionalDays
        .map((day) => _isSameDate(day.date, normalizedDate) ? updatedDay : day)
        .toList();

    return CheckInResult(day: updatedDay, summary: summarize(updatedDays));
  }

  List<ForestDay> _withMissedDays(
    List<ForestDay> existingDays,
    DateTime checkInDate,
    double dailyBudget,
  ) {
    if (existingDays.isEmpty) {
      return existingDays;
    }

    final orderedDays = [...existingDays]
      ..sort((a, b) => a.date.compareTo(b.date));
    final missedDays = <ForestDay>[];
    var missedDate = orderedDays.last.date.add(const Duration(days: 1));

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

  ForestSummary summarize(
    List<ForestDay> days, {
    ProgressionState? progression,
    ShopState? shopState,
  }) {
    final orderedDays = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final healthyTreeCount = orderedDays
        .where((day) => day.status == TreeStatus.healthy)
        .length;
    final witheredTreeCount = orderedDays
        .where((day) => day.status == TreeStatus.withered)
        .length;
    final restoredTreeCount = orderedDays
        .where((day) => day.status == TreeStatus.restored)
        .length;
    final currentStreak = _currentStreak(orderedDays);

    return ForestSummary(
      days: orderedDays,
      currentStreak: currentStreak,
      healthyTreeCount: healthyTreeCount,
      witheredTreeCount: witheredTreeCount,
      restoredTreeCount: restoredTreeCount,
      achievements: _achievements(
        days: orderedDays,
        currentStreak: currentStreak,
        healthyTreeCount: healthyTreeCount,
        progression: progression,
        shopState: shopState,
      ),
    );
  }

  RestorationQuote quoteRestoration({
    required List<ForestDay> days,
    required DateTime dayDate,
    required DateTime now,
  }) {
    final normalizedDayDate = _normalize(dayDate);
    final normalizedNow = _normalize(now);
    final matches = days.where(
      (day) => _isSameDate(day.date, normalizedDayDate),
    );
    if (matches.isEmpty) {
      return const RestorationQuote(
        eligible: false,
        cost: 0,
        blockedReason: 'There is no record for that day.',
      );
    }

    final target = matches.first;
    if (target.status == TreeStatus.restored) {
      return const RestorationQuote(
        eligible: false,
        cost: 0,
        blockedReason: 'This day has already been restored.',
      );
    }
    if (target.status != TreeStatus.withered) {
      return const RestorationQuote(
        eligible: false,
        cost: 0,
        blockedReason: 'Only withered days can be restored.',
      );
    }

    final ageInDays = normalizedNow.difference(normalizedDayDate).inDays;
    if (ageInDays < 0 || ageInDays > 6) {
      return const RestorationQuote(
        eligible: false,
        cost: 0,
        blockedReason: 'This day is too old to restore.',
      );
    }

    final priorRestorations = _restorationsInWindow(days, normalizedNow);
    if (priorRestorations >= 2) {
      return const RestorationQuote(
        eligible: false,
        cost: 0,
        blockedReason:
            'You have reached the restoration limit for the last 30 days.',
      );
    }

    return RestorationQuote(
      eligible: true,
      cost: _restorationCost(priorRestorations),
      blockedReason: null,
    );
  }

  RestorationResult restoreDay({
    required List<ForestDay> days,
    required DateTime dayDate,
    required DateTime now,
    required String recoveryNote,
    required int coinBalance,
  }) {
    final normalizedDayDate = _normalize(dayDate);
    final normalizedNow = _normalize(now);
    final trimmedNote = recoveryNote.trim();

    if (trimmedNote.isEmpty) {
      return RestorationResult(
        success: false,
        failureReason: 'Add a short recovery note to restore this day.',
        summary: summarize(days),
        spendEvent: null,
      );
    }

    final quote = quoteRestoration(
      days: days,
      dayDate: normalizedDayDate,
      now: normalizedNow,
    );
    if (!quote.eligible) {
      return RestorationResult(
        success: false,
        failureReason: quote.blockedReason,
        summary: summarize(days),
        spendEvent: null,
      );
    }
    if (coinBalance < quote.cost) {
      return RestorationResult(
        success: false,
        failureReason:
            'Not enough coins. Restoring this day costs ${quote.cost} coins.',
        summary: summarize(days),
        spendEvent: null,
      );
    }

    final target = days.firstWhere(
      (day) => _isSameDate(day.date, normalizedDayDate),
    );
    final restoredDay = ForestDay(
      date: target.date,
      status: TreeStatus.restored,
      treeLevel: 1,
      spending: target.spending,
      dailyBudget: target.dailyBudget,
      actionCompleted: target.actionCompleted,
      message: target.message,
      restoredAt: normalizedNow,
      recoveryNote: trimmedNote,
    );
    final updatedDays = [
      for (final day in days)
        if (_isSameDate(day.date, normalizedDayDate)) restoredDay else day,
    ]..sort((a, b) => a.date.compareTo(b.date));

    final spendEvent = RewardEvent(
      date: normalizedNow,
      type: RewardEventType.restorationSpend,
      xp: 0,
      coins: -quote.cost,
      description: 'Restored ${_formatDate(normalizedDayDate)}',
    );

    return RestorationResult(
      success: true,
      failureReason: null,
      summary: summarize(updatedDays),
      spendEvent: spendEvent,
    );
  }

  String _message({required bool overBudget}) {
    if (overBudget) {
      return 'Today withered because spending exceeded the daily budget.';
    }
    return 'Healthy growth: spending stayed within budget.';
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
      if (day.status == TreeStatus.healthy ||
          day.status == TreeStatus.restored) {
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
    ProgressionState? progression,
    ShopState? shopState,
  }) {
    final budgetGuardian = days.any(
      (day) =>
          day.status == TreeStatus.healthy &&
          day.spending <= day.dailyBudget * 0.8,
    );
    final recoveryDay = _hasRecoveryDay(days);
    final secondWind = days.any((day) => day.status == TreeStatus.restored);
    final curator =
        shopState != null &&
        shopState.ownedItemIds.any((id) => !_isDefaultShopItem(id));
    final seedlingScholar = progression != null && progression.level.level >= 5;

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
      Achievement(
        id: 'second-wind',
        title: 'Second Wind',
        description: 'Restore a withered day.',
        unlocked: secondWind,
      ),
      Achievement(
        id: 'curator',
        title: 'Curator',
        description: 'Own a non-default cosmetic item.',
        unlocked: curator,
      ),
      Achievement(
        id: 'seedling-scholar',
        title: 'Seedling Scholar',
        description: 'Reach level 5.',
        unlocked: seedlingScholar,
      ),
    ];
  }

  bool _isDefaultShopItem(String itemId) {
    for (final item in kShopCatalog) {
      if (item.id == itemId) {
        return item.isDefault;
      }
    }
    return true;
  }

  bool _hasRecoveryDay(List<ForestDay> days) {
    for (var index = 1; index < days.length; index++) {
      final previousQualifies =
          days[index - 1].status == TreeStatus.withered ||
          days[index - 1].status == TreeStatus.restored;
      if (previousQualifies && days[index].status == TreeStatus.healthy) {
        return true;
      }
    }
    return false;
  }

  int _restorationsInWindow(List<ForestDay> days, DateTime now) {
    final windowStart = now.subtract(const Duration(days: 30));
    return days
        .where(
          (day) =>
              day.status == TreeStatus.restored &&
              day.restoredAt != null &&
              !day.restoredAt!.isBefore(windowStart) &&
              !day.restoredAt!.isAfter(now),
        )
        .length;
  }

  int _restorationCost(int priorRestorationsInWindow) {
    const costs = [60, 150];
    return costs[priorRestorationsInWindow];
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
