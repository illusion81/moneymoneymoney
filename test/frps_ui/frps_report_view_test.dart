import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/benchmark_comparator.dart';
import 'package:moneymoneymoney/frps/financial_tools/budget_calculator.dart';
import 'package:moneymoneymoney/frps/financial_tools/cash_flow_analyzer.dart';
import 'package:moneymoneymoney/frps/financial_tools/debt_payoff_planner.dart';
import 'package:moneymoneymoney/frps/financial_tools/net_worth_tracker.dart';
import 'package:moneymoneymoney/frps/financial_tools/savings_projector.dart';
import 'package:moneymoneymoney/frps/models/tool_outputs.dart';
import 'package:moneymoneymoney/frps/models/user_profile.dart';
import 'package:moneymoneymoney/frps/reporting/report_assembler.dart';
import 'package:moneymoneymoney/frps/slm/mock_slm.dart';
import 'package:moneymoneymoney/frps_ui/frps_report_controller.dart';
import 'package:moneymoneymoney/frps_ui/frps_report_view.dart';

FrpsReportData _data({
  double income = 6000,
  Map<String, double> expenses = const {'housing': 2600, 'food': 800},
  double savingsGoal = 900,
  Map<String, double> assets = const {'savings': 5000},
  Map<String, double> liabilities = const {'card': 1200},
}) {
  final budget = budgetCalculator(income, expenses);
  final outputs = ToolOutputs(
    budget: budget,
    savings: savingsProjector(
      currentSavings: assets['savings'] ?? 0.0,
      monthlyContribution: savingsGoal,
      annualRate: 0.05,
      years: 10,
    ),
    debtPlan: debtPayoffPlanner(const []),
    netWorth: netWorthTracker(assets, liabilities),
    cashFlow: cashFlowAnalyzer(
      [income],
      [expenses.values.fold(0.0, (sum, value) => sum + value)],
    ),
    benchmark: benchmarkComparator(
      budget.categoryPercentages,
      nationalBenchmark,
    ),
  );
  final narrative = MockSlm().generateReportNarrative(
    toolOutputs: outputs,
    userProfile: UserProfile(monthlyIncome: income, age: 30),
  );
  final report = ReportAssembler().assemble(
    toolOutputs: outputs,
    narrative: narrative,
    userId: 'u1',
    date: DateTime(2026, 8, 29),
  );
  return FrpsReportData(report: report, toolOutputs: outputs, narrative: narrative);
}

void main() {
  testWidgets('renders narrative, tool numbers, and assembled sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: FrpsReportView(data: _data()))),
    );
    await tester.pump();

    expect(find.text('Deep Financial Report'), findsOneWidget);
    expect(find.text('Your money story'), findsOneWidget);
    expect(find.text('The numbers'), findsOneWidget);
    expect(find.text('Full report'), findsOneWidget);

    for (final title in [
      'Executive Summary',
      'Expense Overview',
      'Opportunities & Options',
      'Progress & Motivation',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }

    for (final title in [
      'Budget',
      'Cash flow',
      'Savings projection',
      'Benchmark',
      'Debt plan',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Total assets'), findsOneWidget);
  });

  testWidgets('renders empty/partial data without throwing', (tester) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FrpsReportView(
            data: _data(
              income: 0,
              expenses: const {},
              savingsGoal: 0,
              assets: const {},
              liabilities: const {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Deep Financial Report'), findsOneWidget);
    // Appears once in the structured Benchmark card and once in the assembled
    // "Expense Overview" prose.
    expect(find.text('No categories flagged for overspending.'), findsWidgets);
    expect(find.text('No debts on file.'), findsOneWidget);
  });
}
