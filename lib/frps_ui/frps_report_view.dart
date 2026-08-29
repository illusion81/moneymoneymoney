import 'package:flutter/material.dart';

import 'package:moneymoneymoney/frps/financial_tools/benchmark_comparator.dart';
import 'package:moneymoneymoney/frps/financial_tools/budget_calculator.dart';
import 'package:moneymoneymoney/frps/financial_tools/cash_flow_analyzer.dart';
import 'package:moneymoneymoney/frps/financial_tools/debt_payoff_planner.dart';
import 'package:moneymoneymoney/frps/financial_tools/net_worth_tracker.dart';
import 'package:moneymoneymoney/frps/financial_tools/savings_projector.dart';
import 'package:moneymoneymoney/frps/models/report.dart';
import 'package:moneymoneymoney/ui/market_icon.dart';

import 'frps_report_controller.dart';

/// The readable, on-demand deep financial report.
///
/// Pure presentation: takes an already-built [FrpsReportData] and lays out the
/// SLM narrative, the structured tool outputs, and the assembled report
/// sections. No storage access happens here, so it can be tested against an
/// in-memory [FrpsReportData] without a database.
class FrpsReportView extends StatelessWidget {
  const FrpsReportView({super.key, required this.data});

  final FrpsReportData data;

  @override
  Widget build(BuildContext context) {
    final outputs = data.toolOutputs;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _Header(date: data.report.date),
        const SizedBox(height: 16),
        _NarrativeCard(narrative: data.narrative),
        const SizedBox(height: 20),
        const _SectionHeading('The numbers'),
        const SizedBox(height: 8),
        _BudgetCard(budget: outputs.budget),
        _NetWorthCard(netWorth: outputs.netWorth),
        _CashFlowCard(cashFlow: outputs.cashFlow),
        _SavingsCard(savings: outputs.savings),
        _BenchmarkCard(benchmark: outputs.benchmark),
        _DebtCard(debtPlan: outputs.debtPlan),
        const SizedBox(height: 20),
        const _SectionHeading('Full report'),
        const SizedBox(height: 8),
        for (final section in data.report.sections)
          _ReportSectionCard(section: section),
      ],
    );
  }
}

String _money(double value) => '\$${value.toStringAsFixed(2)}';

String _percentOfRatio(double ratio) => '${(ratio * 100).toStringAsFixed(1)}%';

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class _Header extends StatelessWidget {
  const _Header({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xff2f7d50),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const MarketIconImage(
            icon: MarketIcon.receipt,
            size: 28,
            tint: Colors.white,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deep Financial Report',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff173b2f),
                ),
              ),
              Text(
                'Generated ${_formatDate(date)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NarrativeCard extends StatelessWidget {
  const _NarrativeCard({required this.narrative});

  final String narrative;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffeee6d3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your money story',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xff173b2f),
            ),
          ),
          const SizedBox(height: 8),
          Text(narrative, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xff173b2f),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    required this.children,
  });

  final MarketIcon icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                MarketIconImage(icon: icon, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff173b2f),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value, this.emphasis = false});

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: emphasis
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget});

  final BudgetResult budget;

  @override
  Widget build(BuildContext context) {
    final categories = budget.categoryPercentages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _Card(
      icon: MarketIcon.coin,
      title: 'Budget',
      children: [
        _KeyValueRow(label: 'Monthly income', value: _money(budget.totalIncome)),
        _KeyValueRow(label: 'Monthly expenses', value: _money(budget.totalExpenses)),
        _KeyValueRow(
          label: 'Surplus',
          value: _money(budget.surplus),
          emphasis: true,
        ),
        _KeyValueRow(
          label: 'Savings rate',
          value: _percentOfRatio(budget.savingsRate),
        ),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Where it goes',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          for (final entry in categories)
            _KeyValueRow(
              label: entry.key,
              value: '${entry.value.toStringAsFixed(1)}%',
            ),
        ],
      ],
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.netWorth});

  final NetWorth netWorth;

  @override
  Widget build(BuildContext context) {
    return _Card(
      icon: MarketIcon.vault,
      title: 'Net worth',
      children: [
        _KeyValueRow(label: 'Total assets', value: _money(netWorth.totalAssets)),
        _KeyValueRow(
          label: 'Total liabilities',
          value: _money(netWorth.totalLiabilities),
        ),
        _KeyValueRow(
          label: 'Net worth',
          value: _money(netWorth.netWorth),
          emphasis: true,
        ),
      ],
    );
  }
}

class _CashFlowCard extends StatelessWidget {
  const _CashFlowCard({required this.cashFlow});

  final CashFlowAnalysis cashFlow;

  @override
  Widget build(BuildContext context) {
    final negatives = cashFlow.negativeMonths.length;
    return _Card(
      icon: MarketIcon.wallet,
      title: 'Cash flow',
      children: [
        _KeyValueRow(
          label: 'Average monthly surplus',
          value: _money(cashFlow.averageSurplus),
          emphasis: true,
        ),
        _KeyValueRow(
          label: 'Volatility',
          value: _money(cashFlow.volatility),
        ),
        _KeyValueRow(
          label: 'Negative months',
          value: negatives == 0 ? 'None' : '$negatives',
        ),
      ],
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.savings});

  final SavingsProjection savings;

  @override
  Widget build(BuildContext context) {
    return _Card(
      icon: MarketIcon.lootbox,
      title: 'Savings projection',
      children: [
        _KeyValueRow(
          label: 'Future value (10 yr)',
          value: _money(savings.futureValue),
          emphasis: true,
        ),
        _KeyValueRow(
          label: 'Total contributions',
          value: _money(savings.totalContributions),
        ),
        _KeyValueRow(
          label: 'Interest earned',
          value: _money(savings.totalInterest),
        ),
      ],
    );
  }
}

class _BenchmarkCard extends StatelessWidget {
  const _BenchmarkCard({required this.benchmark});

  final BenchmarkComparison benchmark;

  @override
  Widget build(BuildContext context) {
    final flags = benchmark.overspendFlags;
    final differences = benchmark.differences.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return _Card(
      icon: MarketIcon.achievement,
      title: 'Benchmark',
      children: [
        if (flags.isEmpty)
          const Text('No categories flagged for overspending.')
        else
          Text(
            'Overspending: ${flags.join(', ')}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        if (differences.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'vs national benchmark',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          for (final entry in differences)
            _KeyValueRow(
              label: entry.key,
              value: '${entry.value >= 0 ? '+' : ''}'
                  '${entry.value.toStringAsFixed(1)} pts',
            ),
        ],
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debtPlan});

  final DebtPayoffPlan debtPlan;

  @override
  Widget build(BuildContext context) {
    return _Card(
      icon: MarketIcon.receipt,
      title: 'Debt plan',
      children: [
        if (debtPlan.schedule.isEmpty)
          const Text('No debts on file.')
        else ...[
          _KeyValueRow(label: 'Total interest', value: _money(debtPlan.totalInterest)),
          _KeyValueRow(label: 'Total paid', value: _money(debtPlan.totalPaid)),
          _KeyValueRow(
            label: 'Months to payoff',
            value: '${debtPlan.monthsToPayoff}',
          ),
        ],
      ],
    );
  }
}

class _ReportSectionCard extends StatelessWidget {
  const _ReportSectionCard({required this.section});

  final ReportSection section;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xff173b2f),
              ),
            ),
            const SizedBox(height: 8),
            ..._contentLines(section.content),
          ],
        ),
      ),
    );
  }

  /// Turns the assembler's plain-text prose into a readable layout: blank
  /// lines become spacing, `- item` lines become bullets, and `label: value`
  /// lines become aligned rows. Anything else stays a paragraph.
  List<Widget> _contentLines(String content) {
    final widgets = <Widget>[];
    for (final raw in content.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }
      if (line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(color: Color(0xff2f7d50)),
                ),
                Expanded(child: Text(line.substring(2))),
              ],
            ),
          ),
        );
      } else if (line.contains(':')) {
        final index = line.indexOf(':');
        widgets.add(
          _KeyValueRow(
            label: line.substring(0, index).trim(),
            value: line.substring(index + 1).trim(),
          ),
        );
      } else {
        widgets.add(Text(line));
      }
    }
    return widgets;
  }
}
