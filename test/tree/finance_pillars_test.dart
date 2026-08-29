import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';
import 'package:moneymoneymoney/services/risk_assessment.dart';
import 'package:moneymoneymoney/tree/finance_pillars.dart';

void main() {
  FinanceProfile profile({
    double income = 6000,
    double expenses = 2500,
    double savings = 900,
  }) => FinanceProfile(
    monthlyIncome: income,
    fixedMonthlyExpenses: expenses,
    monthlySavingsGoal: savings,
    riskLevel: RiskLevel.balanced,
    financialGoal: FinancialGoal.emergencyFund,
    spendingPressure: SpendingPressure.medium,
  );

  test('a healthy profile scores mid-to-high on every pillar', () {
    final p = FinancePillars.fromProfile(profile());
    for (final value in [
      p.profitability,
      p.liquidity,
      p.solvency,
      p.efficiency,
    ]) {
      expect(value, inInclusiveRange(0.0, 1.0));
      expect(value, greaterThan(0.3));
    }
  });

  test('profitability tracks the operating margin', () {
    final lean = FinancePillars.fromProfile(
      profile(income: 6000, expenses: 5000),
    ).profitability;
    final fat = FinancePillars.fromProfile(
      profile(income: 6000, expenses: 1000),
    ).profitability;
    expect(fat, greaterThan(lean));
  });

  test('solvency falls as fixed expenses take more of the income', () {
    final light = FinancePillars.fromProfile(
      profile(income: 6000, expenses: 600),
    ).solvency;
    final heavy = FinancePillars.fromProfile(
      profile(income: 6000, expenses: 5400),
    ).solvency;
    expect(light, greaterThan(heavy));
  });

  test('efficiency tracks the savings rate on disposable income', () {
    final low = FinancePillars.fromProfile(
      profile(income: 6000, expenses: 2000, savings: 200),
    ).efficiency;
    final high = FinancePillars.fromProfile(
      profile(income: 6000, expenses: 2000, savings: 3200),
    ).efficiency;
    expect(high, greaterThan(low));
  });

  test('every pillar stays within 0..1 even for absurd inputs', () {
    final broke = FinancePillars.fromProfile(
      profile(income: 1000, expenses: 9000, savings: 5000),
    );
    for (final value in [
      broke.profitability,
      broke.liquidity,
      broke.solvency,
      broke.efficiency,
    ]) {
      expect(value, inInclusiveRange(0.0, 1.0));
    }
  });

  test('zero income yields zeros rather than dividing by zero', () {
    final p = FinancePillars.fromProfile(
      profile(income: 0, expenses: 0, savings: 0),
    );
    expect(p.profitability, 0);
    expect(p.liquidity, 0);
    expect(p.solvency, 0);
    expect(p.efficiency, 0);
    expect(p.health, 0);
  });

  test('health is the mean of the four pillars', () {
    const p = FinancePillars(
      profitability: 0.2,
      liquidity: 0.4,
      solvency: 0.6,
      efficiency: 0.8,
    );
    expect(p.health, closeTo(0.5, 1e-9));
  });

  test('the withered gate fires below the threshold', () {
    const sick = FinancePillars(
      profitability: 0.1,
      liquidity: 0.1,
      solvency: 0.1,
      efficiency: 0.1,
    );
    expect(sick.isWithered, isTrue);
    expect(const FinancePillars.balanced().isWithered, isFalse);
  });
}