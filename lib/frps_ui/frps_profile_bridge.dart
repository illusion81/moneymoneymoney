import 'package:moneymoneymoney/frps/models/financial_snapshot.dart';
import 'package:moneymoneymoney/frps/models/user.dart';
import 'package:moneymoneymoney/frps/models/user_profile.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';

/// Bridges the app's on-device [FinanceProfile] into the [User] and
/// [FinancialSnapshot] pair that the FRPS [ReportPlanner] reads from storage.
///
/// The on-device profile only tracks income, fixed expenses and a savings
/// goal, so the snapshot it produces is deliberately minimal: one expense
/// category, and no assets or liabilities. Richer detail (categorised
/// expenses, real asset/liability values, debt) comes from the FRPS question
/// flow and bank data, which write to the same repository from other lanes.
class FrpsProfileBridge {
  const FrpsProfileBridge._();

  /// The id the app uses for its single local user, matching `main.dart`.
  static const String defaultUserId = 'user-1';

  static User userFrom(
    FinanceProfile profile, {
    String id = defaultUserId,
    int age = 30,
  }) {
    return User(
      id: id,
      name: 'You',
      profile: UserProfile(monthlyIncome: profile.monthlyIncome, age: age),
    );
  }

  static FinancialSnapshot snapshotFrom(
    FinanceProfile profile, {
    required String userId,
    DateTime? date,
  }) {
    return FinancialSnapshot(
      userId: userId,
      date: date ?? DateTime.now(),
      income: profile.monthlyIncome,
      expenses: {'fixed expenses': profile.fixedMonthlyExpenses},
      assets: const {},
      liabilities: const {},
      monthlySavingsGoal: profile.monthlySavingsGoal,
    );
  }
}
