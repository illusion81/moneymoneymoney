import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/benchmark_comparator.dart';
import 'package:moneymoneymoney/frps/financial_tools/budget_calculator.dart';
import 'package:moneymoneymoney/frps/financial_tools/cash_flow_analyzer.dart';
import 'package:moneymoneymoney/frps/financial_tools/debt_payoff_planner.dart';
import 'package:moneymoneymoney/frps/financial_tools/net_worth_tracker.dart';
import 'package:moneymoneymoney/frps/financial_tools/savings_projector.dart';
import 'package:moneymoneymoney/frps/models/tool_outputs.dart';
import 'package:moneymoneymoney/frps/models/user_profile.dart';
import 'package:moneymoneymoney/frps/slm/slot_slm.dart';

ToolOutputs _outputs({
  double surplus = 1864.19,
  double savingsRate = 0.2663,
  double futureValue = 50000,
  double totalInterest = 10000,
  double netWorth = 80000,
  List<String> overspendFlags = const ['housing', 'food'],
}) {
  return ToolOutputs(
    budget: BudgetResult(
      totalIncome: 5000,
      totalExpenses: 5000 - surplus,
      surplus: surplus,
      savingsRate: savingsRate,
      categoryPercentages: const {},
    ),
    savings: SavingsProjection(
      futureValue: futureValue,
      totalContributions: 40000,
      totalInterest: totalInterest,
    ),
    debtPlan: DebtPayoffPlan(
      schedule: const [],
      totalInterest: 0,
      totalPaid: 0,
      payoffDate: DateTime(2000),
      monthsToPayoff: 0,
    ),
    netWorth: NetWorth(
      totalAssets: 100000,
      totalLiabilities: 20000,
      netWorth: netWorth,
    ),
    cashFlow: CashFlowAnalysis(
      negativeMonths: const [],
      averageSurplus: 1000,
      volatility: 100,
    ),
    benchmark: BenchmarkComparison(
      differences: const {},
      overspendFlags: overspendFlags,
    ),
  );
}

void main() {
  group('fillNarrative', () {
    test('substitutes exact money and percent values', () {
      final prose = fillNarrative(
        'Surplus {SURPLUS}, rate {SAVINGS_RATE}.',
        _outputs(),
      );

      expect(prose, contains(r'$1,864.19'));
      expect(prose, contains('26.6%'));
    });

    test('formats a negative surplus with a leading minus sign', () {
      final prose = fillNarrative('{SURPLUS}', _outputs(surplus: -200.00));

      expect(prose, r'-$200.00');
    });

    test('joins overspend flags and emits "none" when empty', () {
      final joined = fillNarrative(
        '{OVERSPEND}',
        _outputs(overspendFlags: const ['housing', 'food']),
      );
      final none = fillNarrative('{OVERSPEND}', _outputs(overspendFlags: const []));

      expect(joined, 'housing, food');
      expect(none, 'none');
    });

    test('leaves unknown tokens unchanged', () {
      final prose = fillNarrative('{FOO} {SURPLUS}', _outputs());

      expect(prose, contains('{FOO}'));
      expect(prose, contains(r'$1,864.19'));
    });
  });

  group('TemplateSlotModel.generateSlotProse', () {
    test('emits no digits and at least one slot token', () {
      final prose = TemplateSlotModel().generateSlotProse(
        toolOutputs: _outputs(),
        userProfile: const UserProfile(monthlyIncome: 5000, age: 30),
      );

      expect(RegExp(r'\d').hasMatch(prose), isFalse);
      expect(RegExp(r'\{[A-Z_]+\}').hasMatch(prose), isTrue);
    });
  });

  group('SlotSlm.generateReportNarrative', () {
    test('fills all slots with exact numbers and leaves no braces', () {
      final text = SlotSlm().generateReportNarrative(
        toolOutputs: _outputs(),
        userProfile: const UserProfile(monthlyIncome: 5000, age: 30),
      );

      expect(text.contains('{'), isFalse);
      expect(text, contains(r'$1,864.19'));
    });

    test('delegates parseFreeText to the deterministic parser', () {
      final data = SlotSlm().parseFreeText('I spend \$200/month on coffee');

      expect(data.category, 'dining');
      expect(data.amount, 200);
    });
  });
}
