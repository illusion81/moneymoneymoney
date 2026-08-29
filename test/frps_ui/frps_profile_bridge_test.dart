import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps_ui/frps_profile_bridge.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';

const _profile = FinanceProfile(
  monthlyIncome: 6000,
  fixedMonthlyExpenses: 2600,
  monthlySavingsGoal: 900,
  riskPreference: RiskPreference.balanced,
  financialGoal: FinancialGoal.invest,
  spendingPressure: SpendingPressure.medium,
);

void main() {
  test('userFrom maps income and accepts an id and age', () {
    final user = FrpsProfileBridge.userFrom(_profile, id: 'u1', age: 42);

    expect(user.id, 'u1');
    expect(user.name, 'You');
    expect(user.profile.monthlyIncome, 6000);
    expect(user.profile.age, 42);
  });

  test('snapshotFrom maps a minimal snapshot with no assets or liabilities', () {
    final snapshot = FrpsProfileBridge.snapshotFrom(
      _profile,
      userId: 'u1',
      date: DateTime(2026, 1, 2),
    );

    expect(snapshot.userId, 'u1');
    expect(snapshot.date, DateTime(2026, 1, 2));
    expect(snapshot.income, 6000);
    expect(snapshot.expenses, {'fixed expenses': 2600});
    expect(snapshot.assets, isEmpty);
    expect(snapshot.liabilities, isEmpty);
    expect(snapshot.monthlySavingsGoal, 900);
  });
}
