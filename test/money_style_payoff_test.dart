import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/money_style_questions.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/services/money_style_engine.dart';
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

/// Builds a real result from opener answers, so the payoff is exercised
/// through the same path the app uses.
MoneyStyleResult resultFrom(Map<int, PoleBand> bands) {
  final session = AnswerSession(
    userId: 'u',
    sessionId: 's',
    selectedAnswers: {
      for (final entry in bands.entries)
        entry.key: moneyStyleQuestionsById[entry.key]!.answers.indexWhere(
          (a) => a.band == entry.value,
        ),
    },
    shownQuestionIds: List<int>.from(bands.keys),
  );
  return const MoneyStyleEngine().generateResult(
    session,
    moneyStyleQuestionPool,
  )!;
}

void main() {
  group('Money Style shapes the daily action', () {
    test('without a quiz result the actions are unchanged', () {
      final without = ReportGenerator().generate(_profile);
      final explicitNull = ReportGenerator().generate(_profile, style: null);

      expect(without.dailyActions, explicitNull.dailyActions);
    });

    test('the action names the habit the quiz found most critical', () {
      final report = ReportGenerator().generate(
        _profile,
        style: styleActionForResult(
          resultFrom({
            1: PoleBand.bad, // revolving debt is the worst score
            2: PoleBand.mixed,
            3: PoleBand.mixed,
            4: PoleBand.mixed,
            5: PoleBand.mixed,
            6: PoleBand.mixed,
          }),
        ),
      );

      expect(
        report.dailyActions.join(' ').toLowerCase(),
        contains('credit card'),
      );
    });

    test('a different critical habit produces a different action', () {
      final debt = ReportGenerator().generate(
        _profile,
        style: styleActionForResult(
          resultFrom({
            1: PoleBand.bad,
            2: PoleBand.mixed,
            3: PoleBand.mixed,
            4: PoleBand.mixed,
            5: PoleBand.mixed,
            6: PoleBand.mixed,
          }),
        ),
      );
      final savings = ReportGenerator().generate(
        _profile,
        style: styleActionForResult(
          resultFrom({
            1: PoleBand.mixed,
            2: PoleBand.mixed,
            3: PoleBand.mixed,
            4: PoleBand.mixed,
            5: PoleBand.bad,
            6: PoleBand.mixed,
          }),
        ),
      );

      expect(debt.dailyActions, isNot(equals(savings.dailyActions)));
    });

    test('an all-positive result confirms the strongest habit instead', () {
      final action = styleActionForResult(
        resultFrom({
          1: PoleBand.good,
          2: PoleBand.mixed,
          3: PoleBand.mixed,
          4: PoleBand.mixed,
          5: PoleBand.mixed,
          6: PoleBand.mixed,
        }),
      );

      expect(action, isNotNull);
      expect(action!.toLowerCase(), contains('already automated'));
    });

    test('the style action is added, not substituted for the goal actions', () {
      final without = ReportGenerator().generate(_profile);
      final with_ = ReportGenerator().generate(
        _profile,
        style: styleActionFor(
          dimension: Dimension.subscriptionBlindness,
          positive: false,
        ),
      );

      expect(with_.dailyActions.length, without.dailyActions.length + 1);
      for (final action in without.dailyActions) {
        expect(with_.dailyActions, contains(action));
      }
    });
  });
}
