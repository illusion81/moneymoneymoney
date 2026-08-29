// "Plan with ranges" — for people who will not type their exact income.
//
// Rewritten from a one-line minified version that showed raw enum names
// (`under2500`, `preferNotToSay`) in bare dropdowns. Nobody should ever see an
// identifier from the codebase in a form they are filling in.

import 'package:flutter/material.dart';

enum IncomeRange { under2500, from2500To5000, from5000To8000, over8000, preferNotToSay }

enum FixedCostShareRange { underHalf, aboutHalf, overHalf, unsure, preferNotToSay }

enum PlanningPriority { breathingRoom, upcomingCost, reduceSpending, debtOrganisation, explore }

String incomeLabel(IncomeRange v) => switch (v) {
      IncomeRange.under2500 => 'Under \$2,500 a month',
      IncomeRange.from2500To5000 => '\$2,500 – \$5,000 a month',
      IncomeRange.from5000To8000 => '\$5,000 – \$8,000 a month',
      IncomeRange.over8000 => 'Over \$8,000 a month',
      IncomeRange.preferNotToSay => 'Rather not say',
    };

String costLabel(FixedCostShareRange v) => switch (v) {
      FixedCostShareRange.underHalf => 'Less than half my income',
      FixedCostShareRange.aboutHalf => 'About half',
      FixedCostShareRange.overHalf => 'More than half',
      FixedCostShareRange.unsure => 'Not sure',
      FixedCostShareRange.preferNotToSay => 'Rather not say',
    };

String priorityLabel(PlanningPriority v) => switch (v) {
      PlanningPriority.breathingRoom => 'Get some breathing room',
      PlanningPriority.upcomingCost => 'Save for something coming up',
      PlanningPriority.reduceSpending => 'Spend less overall',
      PlanningPriority.debtOrganisation => 'Get on top of debt',
      PlanningPriority.explore => 'Just looking around',
    };

/// What the three dropdowns add up to. The screen hands this back rather than
/// a bare callback, so the caller can turn it into a real profile and open the
/// app — "keep this snapshot" has to go somewhere, or the button looks broken.
class RangeSnapshot {
  const RangeSnapshot({
    required this.income,
    required this.costs,
    required this.priority,
  });

  final IncomeRange income;
  final FixedCostShareRange costs;
  final PlanningPriority priority;
}

class PlanRangeScreen extends StatefulWidget {
  const PlanRangeScreen({super.key, required this.onKeep, required this.onExact});

  final ValueChanged<RangeSnapshot> onKeep;
  final VoidCallback onExact;

  @override
  State<PlanRangeScreen> createState() => _PlanRangeScreenState();
}

class _PlanRangeScreenState extends State<PlanRangeScreen> {
  IncomeRange? income;
  FixedCostShareRange? costs;
  PlanningPriority? priority;

  bool get _complete => income != null && costs != null && priority != null;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Plan with ranges')),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              children: [
                Text('Rough answers are fine', style: t.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'We can build a plan from ranges. It will not calculate exact '
                  'daily targets, but nothing here asks for a number you would '
                  'rather not give.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 26),

                _field<IncomeRange>(
                  label: 'Monthly income after tax',
                  value: income,
                  values: IncomeRange.values,
                  labelOf: incomeLabel,
                  onChanged: (v) => setState(() => income = v),
                ),
                _field<FixedCostShareRange>(
                  label: 'Rent, bills and transport take up',
                  value: costs,
                  values: FixedCostShareRange.values,
                  labelOf: costLabel,
                  onChanged: (v) => setState(() => costs = v),
                ),
                _field<PlanningPriority>(
                  label: 'Right now you mostly want to',
                  value: priority,
                  values: PlanningPriority.values,
                  labelOf: priorityLabel,
                  onChanged: (v) => setState(() => priority = v),
                ),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your snapshot', style: t.titleSmall),
                      const SizedBox(height: 8),
                      _summaryLine('Income',
                          income == null ? null : incomeLabel(income!)),
                      _summaryLine('Fixed costs',
                          costs == null ? null : costLabel(costs!)),
                      _summaryLine('Priority',
                          priority == null ? null : priorityLabel(priority!)),
                      const SizedBox(height: 10),
                      Text(
                        _complete
                            ? 'Good enough to start. Exact numbers unlock daily '
                                'targets and a tree that tracks them.'
                            : 'Pick all three to see your snapshot.',
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _complete
                      ? () => widget.onKeep(RangeSnapshot(
                            income: income!,
                            costs: costs!,
                            priority: priority!,
                          ))
                      : null,
                  child: const Text('Keep this range-based snapshot'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onExact,
                  child: const Text('Use exact numbers for a daily calculation'),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _summaryLine(String label, String? value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          SizedBox(
              width: 96,
              child: Text(label,
                  style: Theme.of(context).textTheme.bodySmall)),
          Expanded(
            child: Text(value ?? 'Not chosen yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight:
                        value == null ? FontWeight.w400 : FontWeight.w600)),
          ),
        ]),
      );

  Widget _field<T>({
    required String label,
    required T? value,
    required List<T> values,
    required String Function(T) labelOf,
    required ValueChanged<T?> onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
          ),
          items: values
              .map((v) => DropdownMenuItem(value: v, child: Text(labelOf(v))))
              .toList(),
          onChanged: onChanged,
        ),
      );
}
