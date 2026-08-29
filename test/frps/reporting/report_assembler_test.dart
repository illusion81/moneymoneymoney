import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/benchmark_comparator.dart';
import 'package:moneymoneymoney/frps/financial_tools/budget_calculator.dart';
import 'package:moneymoneymoney/frps/financial_tools/cash_flow_analyzer.dart';
import 'package:moneymoneymoney/frps/financial_tools/debt_payoff_planner.dart';
import 'package:moneymoneymoney/frps/financial_tools/net_worth_tracker.dart';
import 'package:moneymoneymoney/frps/financial_tools/savings_projector.dart';
import 'package:moneymoneymoney/frps/models/tool_outputs.dart';
import 'package:moneymoneymoney/frps/reporting/report_assembler.dart';

void main() {
  test('produces the four required sections in order', () {
    final outputs = ToolOutputs(
      budget: budgetCalculator(6000, {'housing': 2600}),
      savings: savingsProjector(
        currentSavings: 0,
        monthlyContribution: 900,
        annualRate: 0.05,
        years: 10,
      ),
      debtPlan: debtPayoffPlanner(const []),
      netWorth: netWorthTracker({'cash': 10000}, {'card': 500}),
      cashFlow: cashFlowAnalyzer([6000], [2600]),
      benchmark: benchmarkComparator({'housing': 43.33}, nationalBenchmark),
    );

    final report = ReportAssembler().assemble(
      toolOutputs: outputs,
      narrative: 'You are on track.',
      userId: 'u1',
      date: DateTime(2026, 8, 29),
    );

    expect(
      report.sections.map((s) => s.title).toList(),
      ['Executive Summary', 'Expense Overview', 'Opportunities & Options', 'Progress & Motivation'],
    );
    expect(report.sections.first.content, contains('You are on track.'));
    expect(report.sections[1].content, contains('housing'));
  });
}
