import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/benchmark_comparator.dart';
import 'package:moneymoneymoney/frps/financial_tools/budget_calculator.dart';
import 'package:moneymoneymoney/frps/financial_tools/cash_flow_analyzer.dart';
import 'package:moneymoneymoney/frps/financial_tools/debt_payoff_planner.dart';
import 'package:moneymoneymoney/frps/financial_tools/net_worth_tracker.dart';
import 'package:moneymoneymoney/frps/financial_tools/savings_projector.dart';
import 'package:moneymoneymoney/frps/models/tool_outputs.dart';

void main() {
  test('ToolOutputs holds all six tool results', () {
    final outputs = ToolOutputs(
      budget: budgetCalculator(6000, {'housing': 1500}),
      savings: savingsProjector(
        currentSavings: 0,
        monthlyContribution: 100,
        annualRate: 0,
        years: 1,
      ),
      debtPlan: debtPayoffPlanner(const []),
      netWorth: netWorthTracker({'cash': 100}, {}),
      cashFlow: cashFlowAnalyzer([100], [50]),
      benchmark: benchmarkComparator({}, {}),
    );

    expect(outputs.budget.surplus, 4500);
    expect(outputs.savings.totalContributions, 1200);
    expect(outputs.debtPlan.monthsToPayoff, 0);
    expect(outputs.netWorth.netWorth, 100);
    expect(outputs.cashFlow.negativeMonths, isEmpty);
    expect(outputs.benchmark.overspendFlags, isEmpty);
  });
}
