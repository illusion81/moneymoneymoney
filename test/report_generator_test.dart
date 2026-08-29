import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';
import 'package:moneymoneymoney/services/report_generator.dart';

void main() {
  group('ReportGenerator', () {
    test('calculates disposable income and daily budget from profile', () {
      final report = ReportGenerator().generate(
        const FinanceProfile(
          monthlyIncome: 6000,
          fixedMonthlyExpenses: 2500,
          monthlySavingsGoal: 900,
          riskPreference: RiskPreference.balanced,
          financialGoal: FinancialGoal.emergencyFund,
          spendingPressure: SpendingPressure.medium,
        ),
      );

      expect(report.disposableIncome, 3500);
      expect(report.dailyBudget, closeTo(86.67, 0.01));
      expect(report.warning, isNull);
      expect(report.dailyActions, hasLength(3));
      expect(report.profileSummary, contains('6000'));
    });

    test(
      'warns and sets daily budget to zero when savings target is unrealistic',
      () {
        final report = ReportGenerator().generate(
          const FinanceProfile(
            monthlyIncome: 3000,
            fixedMonthlyExpenses: 2600,
            monthlySavingsGoal: 800,
            riskPreference: RiskPreference.conservative,
            financialGoal: FinancialGoal.reduceSpending,
            spendingPressure: SpendingPressure.high,
          ),
        );

        expect(report.disposableIncome, 400);
        expect(report.dailyBudget, 0);
        expect(report.warning, isNotNull);
        expect(report.warning, contains('unrealistic'));
        expect(report.dailyActions.join(' '), contains('spending'));
      },
    );

    test('uses risk preference and goal to tailor advice', () {
      final report = ReportGenerator().generate(
        const FinanceProfile(
          monthlyIncome: 8000,
          fixedMonthlyExpenses: 3000,
          monthlySavingsGoal: 1200,
          riskPreference: RiskPreference.growth,
          financialGoal: FinancialGoal.invest,
          spendingPressure: SpendingPressure.low,
        ),
      );

      expect(report.riskAdvice, contains('long-term'));
      expect(report.savingsAdvice, contains('1200'));
      expect(report.dailyActions.join(' '), contains('investment'));
    });
  });
}
