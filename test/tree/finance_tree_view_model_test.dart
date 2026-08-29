import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';
import 'package:moneymoneymoney/models/forest_day.dart';
import 'package:moneymoneymoney/tree/finance_tree_view_model.dart';

void main() {
  const healthyProfile = FinanceProfile(
    monthlyIncome: 6000,
    fixedMonthlyExpenses: 2500,
    monthlySavingsGoal: 900,
    riskPreference: RiskPreference.balanced,
    financialGoal: FinancialGoal.emergencyFund,
    spendingPressure: SpendingPressure.medium,
  );

  // A profile whose income is swallowed by fixed expenses, so every pillar
  // collapses below the withered gate.
  const brokeProfile = FinanceProfile(
    monthlyIncome: 2000,
    fixedMonthlyExpenses: 2600,
    monthlySavingsGoal: 1000,
    riskPreference: RiskPreference.balanced,
    financialGoal: FinancialGoal.emergencyFund,
    spendingPressure: SpendingPressure.high,
  );

  ForestDay day(TreeStatus status) => ForestDay(
    date: DateTime(2026, 1, 1),
    status: status,
    treeLevel: status == TreeStatus.healthy ? 1 : 0,
    spending: status == TreeStatus.healthy ? 30 : 500,
    dailyBudget: 50,
    actionCompleted: true,
    message: 'message',
  );

  ForestSummary summary(TreeStatus status) => ForestSummary(
    days: [day(status)],
    currentStreak: status == TreeStatus.healthy ? 1 : 0,
    healthyTreeCount: status == TreeStatus.healthy ? 1 : 0,
    witheredTreeCount: status == TreeStatus.withered ? 1 : 0,
    achievements: const [],
  );

  FinanceTreeState state(FinanceProfile profile, ForestSummary summary) =>
      FinanceTreeViewModel(profile: profile, summary: summary).state;

  test('healthy profile plus healthy check-in stays healthy', () {
    final s = state(healthyProfile, summary(TreeStatus.healthy));
    expect(s.withered, isFalse);
    expect(s.checkInStatus, TreeStatus.healthy);
    expect(s.streak, 1);
    expect(s.pillars.isWithered, isFalse);
  });

  test('a withered check-in withers a healthy finance tree', () {
    final s = state(healthyProfile, summary(TreeStatus.withered));
    expect(s.pillars.isWithered, isFalse, reason: 'shape signal is untouched');
    expect(s.withered, isTrue, reason: 'check-in withers the render');
    expect(s.checkInStatus, TreeStatus.withered);
  });

  test('unhealthy finances wither even with a healthy check-in', () {
    final s = state(brokeProfile, summary(TreeStatus.healthy));
    expect(s.pillars.isWithered, isTrue);
    expect(s.withered, isTrue);
    expect(s.checkInStatus, TreeStatus.healthy);
  });

  test('both signals withering still just withers', () {
    final s = state(brokeProfile, summary(TreeStatus.withered));
    expect(s.withered, isTrue);
  });

  test('a restored check-in does not count as withered', () {
    final s = state(healthyProfile, summary(TreeStatus.restored));
    expect(s.withered, isFalse);
    expect(s.checkInStatus, TreeStatus.restored);
  });

  test('no check-in yet leaves withering up to the pillars alone', () {
    const empty = ForestSummary(
      days: [],
      currentStreak: 0,
      healthyTreeCount: 0,
      witheredTreeCount: 0,
      achievements: [],
    );

    expect(state(healthyProfile, empty).withered, isFalse);
    expect(state(healthyProfile, empty).checkInStatus, isNull);

    expect(state(brokeProfile, empty).withered, isTrue);
  });

  test('check-in health never alters the shape pillars', () {
    final healthy = state(healthyProfile, summary(TreeStatus.healthy));
    final withered = state(healthyProfile, summary(TreeStatus.withered));

    expect(withered.pillars.profitability, healthy.pillars.profitability);
    expect(withered.pillars.liquidity, healthy.pillars.liquidity);
    expect(withered.pillars.solvency, healthy.pillars.solvency);
    expect(withered.pillars.efficiency, healthy.pillars.efficiency);
  });

  test('streak is passed through unchanged', () {
    final summary = ForestSummary(
      days: [
        day(TreeStatus.healthy),
        day(TreeStatus.healthy),
      ],
      currentStreak: 2,
      healthyTreeCount: 2,
      witheredTreeCount: 0,
      achievements: const [],
    );
    expect(state(healthyProfile, summary).streak, 2);
  });
}
