import 'package:flutter/material.dart';

import '../models/forest_day.dart';
import '../models/progression.dart';
import '../models/shop_item.dart';
import '../models/wealth_report.dart';
import '../services/forest_engine.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.report,
    required this.summary,
    required this.progression,
    required this.shopState,
    required this.onCheckIn,
    required this.onRestore,
    required this.onShowReport,
    required this.onShowAchievements,
    required this.onShowShop,
    this.lastEarnedSummary,
    this.onRetakeQuestionnaire,
  });

  final WealthReport report;
  final ForestSummary summary;
  final ProgressionState progression;
  final ShopState shopState;
  final String? lastEarnedSummary;
  final void Function({required double spending, required bool actionCompleted})
  onCheckIn;
  final void Function(String recoveryNote) onRestore;
  final VoidCallback onShowReport;
  final VoidCallback onShowAchievements;
  final VoidCallback onShowShop;
  final VoidCallback? onRetakeQuestionnaire;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _spendingController = TextEditingController();
  final _recoveryNoteController = TextEditingController();
  bool _actionCompleted = false;
  String? _errorText;

  @override
  void dispose() {
    _spendingController.dispose();
    _recoveryNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latestDay = widget.summary.days.isEmpty
        ? null
        : widget.summary.days.last;
    final statusText = _statusText(latestDay);
    final statusColor = _statusColor(latestDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wealth Forest'),
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
          if (widget.onRetakeQuestionnaire != null)
            IconButton(
              key: const Key('retake-questionnaire-button'),
              tooltip: 'Retake questionnaire',
              onPressed: widget.onRetakeQuestionnaire,
              icon: const Icon(Icons.fact_check_outlined),
            ),
          IconButton(
            tooltip: 'Achievements',
            onPressed: widget.onShowAchievements,
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            widget.onShowReport();
          } else if (index == 2) {
            widget.onShowAchievements();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.park_outlined),
            selectedIcon: Icon(Icons.park),
            label: 'Forest',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Awards',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ProgressionHeader(
                  progression: widget.progression,
                  onShowShop: widget.onShowShop,
                ),
                const SizedBox(height: 14),
                _ForestCalendar(
                  summary: widget.summary,
                  shopState: widget.shopState,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _skyColor(widget.shopState),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _groundColor(widget.shopState),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _treeIcon(latestDay, widget.shopState),
                          size: 112,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        latestDay?.message ??
                            'Complete today\'s money action to grow your tree.',
                        textAlign: TextAlign.center,
                      ),
                      if (latestDay?.status == TreeStatus.restored &&
                          latestDay?.recoveryNote != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Recovery note: ${latestDay!.recoveryNote}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.lastEarnedSummary != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.lastEarnedSummary!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xffc79a33),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _MetricRow(
                  streak: widget.summary.currentStreak,
                  healthy: widget.summary.healthyTreeCount,
                  withered: widget.summary.witheredTreeCount,
                ),
                if (latestDay?.status == TreeStatus.withered) ...[
                  const SizedBox(height: 18),
                  _RestorationPanel(
                    day: latestDay!,
                    days: widget.summary.days,
                    coinBalance: widget.progression.coinBalance,
                    noteController: _recoveryNoteController,
                    onRestore: () {
                      widget.onRestore(_recoveryNoteController.text);
                      _recoveryNoteController.clear();
                    },
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'Today\'s money action',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(widget.report.dailyActions.first),
                const SizedBox(height: 14),
                Text(
                  'Daily budget: \$${widget.report.dailyBudget.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('spending-field'),
                  controller: _spendingController,
                  decoration: InputDecoration(
                    labelText: 'Today\'s spending',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: const OutlineInputBorder(),
                    errorText: _errorText,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  key: const Key('action-complete-checkbox'),
                  value: _actionCompleted,
                  onChanged: (value) =>
                      setState(() => _actionCompleted = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Money action completed'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _checkIn,
                  icon: const Icon(Icons.check),
                  label: const Text('Check In'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: widget.onShowAchievements,
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('Achievements'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _checkIn() {
    final spending = double.tryParse(_spendingController.text);
    if (spending == null || spending < 0) {
      setState(() => _errorText = 'Enter a valid spending amount');
      return;
    }

    setState(() => _errorText = null);
    widget.onCheckIn(spending: spending, actionCompleted: _actionCompleted);
  }

  String _statusText(ForestDay? day) {
    switch (day?.status) {
      case TreeStatus.healthy:
        return 'Healthy tree';
      case TreeStatus.withered:
        return 'Withered tree';
      case TreeStatus.restored:
        return 'Restored tree';
      case TreeStatus.pending:
      case null:
        return 'Ready to grow';
    }
  }

  Color _statusColor(ForestDay? day) {
    switch (day?.status) {
      case TreeStatus.healthy:
        return const Color(0xff2f7d50);
      case TreeStatus.withered:
        return const Color(0xff8a6a4f);
      case TreeStatus.restored:
        return const Color(0xff3f8f8a);
      case TreeStatus.pending:
      case null:
        return const Color(0xffc79a33);
    }
  }

  IconData _treeIcon(ForestDay? day, ShopState shopState) {
    if (day?.status == TreeStatus.withered) {
      return Icons.energy_savings_leaf_outlined;
    }
    if (day?.status == TreeStatus.restored) {
      return Icons.eco;
    }

    final equippedSkin = shopState.equippedItemIds[ShopItemCategory.treeSkin];
    final level = day?.treeLevel ?? 0;
    switch (equippedSkin) {
      case 'tree-crystal-pine':
        return Icons.ac_unit;
      case 'tree-bonsai':
        return Icons.spa;
      case 'tree-cherry-blossom':
        return Icons.local_florist;
      case 'tree-golden-ginkgo':
        return level >= 2 ? Icons.park : Icons.eco;
      default:
        if (level >= 3) {
          return Icons.forest;
        }
        if (level >= 2) {
          return Icons.park;
        }
        return Icons.eco;
    }
  }

  Color _groundColor(ShopState shopState) {
    switch (shopState.equippedItemIds[ShopItemCategory.ground]) {
      case 'ground-riverbank':
        return const Color(0xffcfe8ea);
      case 'ground-autumn':
        return const Color(0xffe9d1a3);
      default:
        return const Color(0xffdcefd9);
    }
  }

  Color _skyColor(ShopState shopState) {
    switch (shopState.equippedItemIds[ShopItemCategory.sky]) {
      case 'sky-sunset':
        return const Color(0xfffbe3d0);
      case 'sky-aurora':
        return const Color(0xffe3ecfb);
      default:
        return Colors.white;
    }
  }
}

class _ForestCalendar extends StatelessWidget {
  const _ForestCalendar({required this.summary, required this.shopState});

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
        final equippedSkin =
            shopState.equippedItemIds[ShopItemCategory.treeSkin];
        switch (equippedSkin) {
          case 'tree-crystal-pine':
            return Icons.ac_unit;
          case 'tree-bonsai':
            return Icons.spa;
          case 'tree-cherry-blossom':
            return Icons.local_florist;
          case 'tree-golden-ginkgo':
            return level >= 2 ? Icons.park : Icons.eco;
          default:
            if (level >= 3) {
              return Icons.forest;
            }
            if (level >= 2) {
              return Icons.park;
            }
            return Icons.eco;
        }
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

class _ProgressionHeader extends StatelessWidget {
  const _ProgressionHeader({
    required this.progression,
    required this.onShowShop,
  });

  final ProgressionState progression;
  final VoidCallback onShowShop;

  @override
  Widget build(BuildContext context) {
    final level = progression.level;

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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff2f7d50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Level ${level.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                key: const Key('coin-balance'),
                onTap: onShowShop,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xfffff4d7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xffc79a33),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${progression.coinBalance}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: level.fraction,
              minHeight: 8,
              backgroundColor: const Color(0xffeee6d3),
              color: const Color(0xff2f7d50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${level.xpIntoLevel} / ${level.xpForNextLevel} XP',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RestorationPanel extends StatelessWidget {
  const _RestorationPanel({
    required this.day,
    required this.days,
    required this.coinBalance,
    required this.noteController,
    required this.onRestore,
  });

  final ForestDay day;
  final List<ForestDay> days;
  final int coinBalance;
  final TextEditingController noteController;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final quote = ForestEngine().quoteRestoration(
      days: days,
      dayDate: day.date,
      now: DateTime.now(),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfffdf1e6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restore this day',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (!quote.eligible) ...[
            Text(quote.blockedReason ?? 'Restoration is not available.'),
          ] else ...[
            Text('Cost: ${quote.cost} coins. Your balance: $coinBalance.'),
            const SizedBox(height: 10),
            TextField(
              key: const Key('recovery-note-field'),
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'What happened, and what will you do differently?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('restore-button'),
              onPressed: onRestore,
              icon: const Icon(Icons.healing),
              label: Text('Restore for ${quote.cost} coins'),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.streak,
    required this.healthy,
    required this.withered,
  });

  final int streak;
  final int healthy;
  final int withered;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(label: 'Streak', value: '$streak'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(label: 'Healthy', value: '$healthy'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(label: 'Withered', value: '$withered'),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label),
        ],
      ),
    );
  }
}
