import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/benchmark_comparator.dart';
import 'package:moneymoneymoney/frps/financial_tools/budget_calculator.dart';
import 'package:moneymoneymoney/frps/financial_tools/cash_flow_analyzer.dart';
import 'package:moneymoneymoney/frps/financial_tools/debt_payoff_planner.dart';
import 'package:moneymoneymoney/frps/financial_tools/net_worth_tracker.dart';
import 'package:moneymoneymoney/frps/financial_tools/savings_projector.dart';
import 'package:moneymoneymoney/frps/models/tool_outputs.dart';
import 'package:moneymoneymoney/frps/models/user_profile.dart';
import 'package:moneymoneymoney/frps/slm/mock_slm.dart';

void main() {
  group('MockSlm.parseFreeText', () {
    test('extracts category and amount from a spending sentence', () {
      final data = MockSlm().parseFreeText('I spend \$200/month on coffee');
      expect(data.category, 'dining');
      expect(data.amount, 200);
    });

    test('returns the unknown sentinel for unmatched text', () {
      final data = MockSlm().parseFreeText('hello there friend');
      expect(data.category, 'unknown');
      expect(data.amount, 0);
    });
  });

  group('MockSlm.generateReportNarrative', () {
    test('embeds computed numbers without doing arithmetic', () {
      final outputs = ToolOutputs(
        budget: budgetCalculator(6000, {'housing': 2600}),
        savings: savingsProjector(
          currentSavings: 0,
          monthlyContribution: 900,
          annualRate: 0,
          years: 1,
        ),
        debtPlan: debtPayoffPlanner(const []),
        netWorth: netWorthTracker({'cash': 10000}, {'card': 500}),
        cashFlow: cashFlowAnalyzer([6000], [2600]),
        benchmark: benchmarkComparator({}, {}),
      );
      final text = MockSlm().generateReportNarrative(
        toolOutputs: outputs,
        userProfile: const UserProfile(monthlyIncome: 6000, age: 30),
      );

      expect(text, contains('3400.00')); // surplus
      expect(text, contains('9500.00')); // net worth
      expect(text, contains('6000.00')); // income
    });
  });
}
