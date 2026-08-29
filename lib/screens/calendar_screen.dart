import 'package:flutter/material.dart';

import '../widgets/day_checklist.dart';

import '../models/forest_day.dart';
import '../models/shop_item.dart';
import '../services/item_visuals.dart';
import '../widgets/app_nav_bar.dart';

class CalendarScreen extends StatefulWidget {
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
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  /// Defaults to today so the checklist is useful the moment you arrive.
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final sel = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    ForestDay? selectedDay;
    for (final d in widget.summary.days) {
      if (d.date.year == sel.year &&
          d.date.month == sel.month &&
          d.date.day == sel.day) {
        selectedDay = d;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Shop',
            onPressed: widget.onShowShop,
            icon: const Icon(Icons.store_outlined),
          ),
          IconButton(
            tooltip: 'Report',
            onPressed: widget.onShowReport,
            icon: const Icon(Icons.description_outlined),
          ),
          IconButton(
            tooltip: 'Achievements',
            onPressed: widget.onShowAchievements,
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        selectedIndex: 2,
        onShowForest: widget.onShowForest,
        onShowSpending: widget.onShowSpending,
        onShowCalendar: () {},
        onShowHomestead: widget.onShowHomestead,
        onShowAchievements: widget.onShowAchievements,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ForestCalendar(
                  summary: widget.summary,
                  shopState: widget.shopState,
                  selectedDate: sel,
                  onSelectDate: (d) => setState(() => _selectedDate = d),
                ),
                DayChecklist(
                  date: sel,
                  day: selectedDay,
                  isToday: sel == today,
                  isFuture: sel.isAfter(today),
                  onCheckIn: sel == today ? widget.onShowForest : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ForestCalendar extends StatefulWidget {
  const ForestCalendar({
    this.selectedDate,
    this.onSelectDate,
    super.key,
    required this.summary,
    required this.shopState,
  });

  final ForestSummary summary;
  final ShopState shopState;

  /// Currently selected day, highlighted in the grid.
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onSelectDate;

  @override
  State<ForestCalendar> createState() => _ForestCalendarState();
}

class _ForestCalendarState extends State<ForestCalendar> {
  /// Which month the grid is showing. Starts on today's, but a streak worth
  /// showing off is usually longer than the current month — a calendar you
  /// cannot page back through hides most of the story.
  DateTime? _viewMonth;

  DateTime get _month =>
      _viewMonth ?? DateTime(DateTime.now().year, DateTime.now().month);

  /// Earliest month with any recorded day; you cannot page back past it.
  DateTime get _earliestMonth {
    final days = widget.summary.days;
    if (days.isEmpty) return _month;
    final first = days
        .map((d) => _normalize(d.date))
        .reduce((a, b) => b.isBefore(a) ? b : a);
    return DateTime(first.year, first.month);
  }

  bool get _canGoBack => _month.isAfter(_earliestMonth);

  bool get _canGoForward {
    final now = DateTime.now();
    return _month.isBefore(DateTime(now.year, now.month));
  }

  void _shiftMonth(int delta) =>
      setState(() => _viewMonth = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final shopState = widget.shopState;
    final selectedDate = widget.selectedDate;
    final onSelectDate = widget.onSelectDate;

    final today = _normalize(DateTime.now());
    final monthStart = _month;
    final nextMonth = DateTime(monthStart.year, monthStart.month + 1);
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
              Expanded(
                child: Text(
                  _monthLabel(monthStart),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xff173b2f),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Disabled rather than hidden at the ends of the range, so the
              // controls do not jump around as you page.
              IconButton(
                key: const Key('calendar-prev-month'),
                tooltip: 'Previous month',
                icon: const Icon(Icons.chevron_left),
                onPressed: _canGoBack ? () => _shiftMonth(-1) : null,
              ),
              IconButton(
                key: const Key('calendar-next-month'),
                tooltip: 'Next month',
                icon: const Icon(Icons.chevron_right),
                onPressed: _canGoForward ? () => _shiftMonth(1) : null,
              ),
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
              // At a real phone width each cell is ~40pt wide; 0.78 left it
              // 8pt short of the day number + tree + dot stack.
              childAspectRatio: 0.66,
            ),
            itemBuilder: (context, index) {
              if (index < leadingEmptyCells) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                monthStart.year,
                monthStart.month,
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
                isSelected:
                    selectedDate != null && _isSameDate(date, selectedDate),
                onTap: onSelectDate == null ? null : () => onSelectDate(date),
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
    this.onTap,
    this.isSelected = false,
  });

  final DateTime date;
  final TreeStatus status;
  final int treeLevel;
  final ShopState shopState;
  final bool isToday;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final dateKey = _dateKey(date);
    final color = _statusColor(status);

    return Tooltip(
      message: '${_dateKey(date)} ${_statusLabel(status)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        decoration: BoxDecoration(
          color: _cellColor(status),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xff173b2f)
                : isToday
                    ? const Color(0xff2f7d50)
                    : const Color(0xffe5decf),
            width: isSelected ? 2.5 : (isToday ? 2 : 1),
          ),
        ),
        // The day number, tree and dot are fixed sizes but the cell scales
        // with screen width, so on a narrow phone the stack no longer fit.
        // Scaling down is better than clipping a tree in half.
        child: FittedBox(
          fit: BoxFit.scaleDown,
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
              size: 20,
              color: color,
            ),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
        ),
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
      case TreeStatus.frozen:
        return Icons.ac_unit;
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
      case TreeStatus.frozen:
        return const Color(0xffe6eff7);
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
      case TreeStatus.frozen:
        return const Color(0xff4a7fa8);
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
    case TreeStatus.frozen:
      return 'frozen — streak held';
    case TreeStatus.pending:
      return 'pending';
  }
}

bool _isSameDate(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
