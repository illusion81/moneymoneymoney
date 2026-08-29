import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/services/report_generator.dart';
import 'package:moneymoneymoney/services/risk_assessment.dart';

const _profile = FinanceProfile(
  monthlyIncome: 6000,
  fixedMonthlyExpenses: 2500,
  monthlySavingsGoal: 900,
  riskLevel: RiskLevel.balanced,
  financialGoal: FinancialGoal.emergencyFund,
  spendingPressure: SpendingPressure.medium,
);

void main() {
  group('Money Style shapes the daily action', () {
    test('without a quiz result the actions are unchanged', () {
      final without = ReportGenerator().generate(_profile);
      final explicitNull = ReportGenerator().generate(_profile, style: null);

      expect(without.dailyActions, explicitNull.dailyActions);
    });

    test('a pause-style result adds a deliberation prompt', () {
      final report = ReportGenerator().generate(
        _profile,
        style: styleActionFor(
          decision: DecisionStylePole.pause,
          support: SupportStylePole.selfDirected,
        ),
      );

      expect(report.dailyActions.join(' ').toLowerCase(), contains('before'));
    });

    test('a momentum-style result reads differently from a pause one', () {
      final pause = ReportGenerator().generate(
        _profile,
        style: styleActionFor(
          decision: DecisionStylePole.pause,
          support: SupportStylePole.selfDirected,
        ),
      );
      final momentum = ReportGenerator().generate(
        _profile,
        style: styleActionFor(
          decision: DecisionStylePole.momentum,
          support: SupportStylePole.selfDirected,
        ),
      );

      expect(pause.dailyActions, isNot(equals(momentum.dailyActions)));
    });

    test('a collaborative result reads differently from a self-directed one', () {
      final solo = ReportGenerator().generate(
        _profile,
        style: styleActionFor(
          decision: DecisionStylePole.pause,
          support: SupportStylePole.selfDirected,
        ),
      );
      final shared = ReportGenerator().generate(
        _profile,
        style: styleActionFor(
          decision: DecisionStylePole.pause,
          support: SupportStylePole.collaborative,
        ),
      );

      expect(solo.dailyActions, isNot(equals(shared.dailyActions)));
    });

    test('the style action is added, not substituted for the goal actions', () {
      final without = ReportGenerator().generate(_profile);
      final with_ = ReportGenerator().generate(
        _profile,
        style: styleActionFor(
          decision: DecisionStylePole.momentum,
          support: SupportStylePole.collaborative,
        ),
      );

      expect(with_.dailyActions.length, without.dailyActions.length + 1);
      for (final action in without.dailyActions) {
        expect(with_.dailyActions, contains(action));
      }
    });
  });
}
