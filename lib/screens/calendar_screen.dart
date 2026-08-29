import 'package:flutter/material.dart';

import '../models/forest_day.dart';
import '../models/shop_item.dart';
import '../services/item_visuals.dart';
import '../widgets/app_nav_bar.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    required this.summary,
    required this.shopState,
    required this.onShowForest,
    required this.onShowSpending,
    required this.onShowHomestead,
    required this.onShowReport,
    required this.onShowAchievements,
    required this.onShowShop,
  });

  final ForestSummary summary;
  final ShopState shopState;
  final VoidCallback onShowForest;
  final VoidCallback onShowSpending;
  final VoidCallback onShowHomestead;
  final VoidCallback onShowReport;
  final VoidCallback onShowAchievements;
  final VoidCallback onShowShop;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Shop',
            onPressed: onShowShop,
            icon: const Icon(Icons.store_outlined),
          ),
          IconButton(
            tooltip: 'Report',
            onPressed: onShowReport,
            icon: const Icon(Icons.description_outlined),
          ),
          IconButton(
            tooltip: 'Achievements',
            onPressed: onShowAchievements,
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        selectedIndex: 2,
        onShowForest: onShowForest,
        onShowSpending: onShowSpending,
        onShowCalendar: () {},
        onShowHomestead: onShowHomestead,
        onShowAchievements: onShowAchievements,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ForestCalendar(summary: summary, shopState: shopState),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForestCalendar extends StatelessWidget {
  const ForestCalendar({
    super.key,
    required this.summary,
    required this.shopState,
  });

  final ForestSummary summary;
  final ShopState shopState;

  @override
  Widget build(BuildContext context) {
    final today = _normalize(DateTime.now());
    final monthStart = DateTime(today.year, today.month);
    final nextMonth = DateTime(today.year, today.month + 1);
    final daysInMonth = nextMonth.difference(monthStart).inDays;
    final leadingEmptyCells = monthStart.weekday - DateTime.monday;
    final recordedDays = {
      for (final day in summary.days) _dateKey(_normalize(day.date)): day,
    };
    final firstTrackedDate = summary.days.isEmpty
        ? today
        : summary.days
              .map((day) => _normalize(day.date))
              .reduce((first, day) => day.isBefore(first) ? day : first);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _monthLabel(monthStart),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xff173b2f),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.calendar_month, color: Color(0xff2f7d50)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              _WeekdayLabel('Mon'),
              _WeekdayLabel('Tue'),
              _WeekdayLabel('Wed'),
              _WeekdayLabel('Thu'),
              _WeekdayLabel('Fri'),
              _WeekdayLabel('Sat'),
              _WeekdayLabel('Sun'),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            key: const Key('forest-calendar-grid'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingEmptyCells + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyCells) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                today.year,
                today.month,
                index - leadingEmptyCells + 1,
              );
              final dateKey = _dateKey(date);
              final recordedDay = recordedDays[dateKey];
              final status = _calendarStatus(
                date: date,
                today: today,
                firstTrackedDate: firstTrackedDate,
                recordedDay: recordedDay,
              );

              return _ForestDayCell(
                key: Key('forest-day-$dateKey'),
                date: date,
                status: status,
                treeLevel: recordedDay?.treeLevel ?? 0,
                shopState: shopState,
                isToday: _isSameDate(date, today),
              );
            },
          ),
        ],
      ),
    );
  }

  TreeStatus _calendarStatus({
    required DateTime date,
    required DateTime today,
    required DateTime firstTrackedDate,
    required ForestDay? recordedDay,
  }) {
    if (recordedDay != null) {
      return recordedDay.status;
    }
    if (date.isBefore(today) && !date.isBefore(firstTrackedDate)) {
      return TreeStatus.withered;
    }
    return TreeStatus.pending;
  }

  DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _monthLabel(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }
}

class _ForestDayCell extends StatelessWidget {
  const _ForestDayCell({
    super.key,
    required this.date,
    required this.status,
    required this.treeLevel,
    required this.shopState,
    required this.isToday,
  });

  final DateTime date;
  final TreeStatus status;
  final int treeLevel;
  final ShopState shopState;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final dateKey = _dateKey(date);
    final color = _statusColor(status);

    return Tooltip(
      message: '${_dateKey(date)} ${_statusLabel(status)}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: _cellColor(status),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday ? const Color(0xff2f7d50) : const Color(0xffe5decf),
            width: isToday ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${date.day}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xff173b2f),
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            Icon(
              _treeIcon(status, treeLevel, shopState),
              key: Key('forest-tree-${status.name}-$dateKey'),
              size: 24,
              color: color,
            ),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  IconData _treeIcon(TreeStatus status, int level, ShopState shopState) {
    switch (status) {
      case TreeStatus.withered:
        return Icons.energy_savings_leaf_outlined;
      case TreeStatus.restored:
        return Icons.eco;
      case TreeStatus.pending:
        return Icons.grass;
      case TreeStatus.healthy:
        return treeSkinIcon(
          equippedId: shopState.equippedItemIds[ShopItemCategory.treeSkin],
          level: level,
        );
    }
  }

  Color _cellColor(TreeStatus status) {
    switch (status) {
      case TreeStatus.healthy:
        return const Color(0xffedf8ed);
      case TreeStatus.withered:
        return const Color(0xfff3eadf);
      case TreeStatus.restored:
        return const Color(0xffe8f5f3);
      case TreeStatus.pending:
        return const Color(0xfffaf8f1);
    }
  }

  Color _statusColor(TreeStatus status) {
    switch (status) {
      case TreeStatus.healthy:
        return const Color(0xff2f7d50);
      case TreeStatus.withered:
        return const Color(0xff8a6a4f);
      case TreeStatus.restored:
        return const Color(0xff3f8f8a);
      case TreeStatus.pending:
        return const Color(0xffc79a33);
    }
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xff5f6f68),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _statusLabel(TreeStatus status) {
  switch (status) {
    case TreeStatus.healthy:
      return 'healthy tree';
    case TreeStatus.withered:
      return 'withered tree';
    case TreeStatus.restored:
      return 'restored tree';
    case TreeStatus.pending:
      return 'pending';
  }
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
