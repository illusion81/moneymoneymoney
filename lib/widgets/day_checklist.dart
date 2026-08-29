// What happened on one day, as a checklist.
//
// The calendar shows colour per day; this says why. For today it reads as
// things still to do; for a past day it is a record of what did or did not
// happen. Nothing here scolds — a missed day says what to do next, not that you
// failed, because the whole product falls apart if opening it feels bad.

import 'package:flutter/material.dart';

import '../models/forest_day.dart';

class DayChecklist extends StatelessWidget {
  const DayChecklist({
    super.key,
    required this.date,
    required this.day,
    required this.isToday,
    required this.isFuture,
    this.onCheckIn,
  });

  final DateTime date;

  /// Null when nothing was recorded for this date.
  final ForestDay? day;
  final bool isToday;
  final bool isFuture;
  final VoidCallback? onCheckIn;

  String get _dateLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final checkedIn = day != null;
    final underBudget = day != null && day!.spending <= day!.dailyBudget;
    final actionDone = day?.actionCompleted ?? false;
    final restored = day?.status == TreeStatus.restored;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(isToday ? 'Today · $_dateLabel' : _dateLabel,
                style: t.titleMedium),
          ),
          if (day != null)
            Text(
              '\$${day!.spending.toStringAsFixed(0)} of '
              '\$${day!.dailyBudget.toStringAsFixed(0)}',
              style: t.bodySmall?.copyWith(
                color: underBudget ? const Color(0xff2f7d50) : const Color(0xffb4553f),
                fontWeight: FontWeight.w600,
              ),
            ),
        ]),
        const SizedBox(height: 14),

        if (isFuture)
          Text('Nothing to do yet — this day has not happened.',
              style: t.bodySmall)
        else ...[
          _item(context,
              done: checkedIn,
              label: 'Checked in',
              detail: checkedIn
                  ? 'Spending recorded for this day.'
                  : isToday
                      ? 'Log or sync today\'s spending.'
                      : 'No spending was recorded.'),
          _item(context,
              done: underBudget,
              label: 'Stayed within budget',
              detail: day == null
                  ? 'Needs a check-in first.'
                  : underBudget
                      ? 'Under by \$${(day!.dailyBudget - day!.spending).toStringAsFixed(0)}.'
                      : 'Over by \$${(day!.spending - day!.dailyBudget).toStringAsFixed(0)}.'),
          _item(context,
              done: actionDone,
              label: 'Money action done',
              detail: actionDone
                  ? 'One deliberate money decision.'
                  : 'Cancel something, move money across, or check a bill.'),
          if (restored)
            _item(context,
                done: true,
                label: 'Day restored',
                detail: day?.recoveryNote?.isNotEmpty == true
                    ? day!.recoveryNote!
                    : 'You brought this day back.'),
        ],

        if (day?.message.isNotEmpty == true) ...[
          const SizedBox(height: 12),
          Text(day!.message, style: t.bodySmall),
        ],

        if (isToday && onCheckIn != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCheckIn,
              icon: const Icon(Icons.check),
              label: Text(checkedIn ? 'Update today' : 'Check in for today'),
            ),
          ),
        ],

        if (!isToday && !isFuture && day == null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Missed days do not erase your progress — the tree just did not '
              'grow that day. Pick it back up whenever.',
              style: t.bodySmall,
            ),
          ),
        ],
      ]),
    );
  }

  Widget _item(BuildContext context,
      {required bool done, required String label, required String detail}) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 20,
          color: done ? const Color(0xff2f7d50) : Theme.of(context).disabledColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: t.bodyMedium?.copyWith(
                    fontWeight: done ? FontWeight.w600 : FontWeight.w400)),
            Text(detail, style: t.bodySmall),
          ]),
        ),
      ]),
    );
  }
}
