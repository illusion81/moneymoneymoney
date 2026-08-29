enum RiskPreference { conservative, balanced, growth }

enum FinancialGoal {
  emergencyFund,
  reduceSpending,
  saveForPurchase,
  invest,
  debtControl,
}

enum SpendingPressure { low, medium, high }

class FinanceProfile {
  const FinanceProfile({
    required this.monthlyIncome,
    required this.fixedMonthlyExpenses,
    required this.monthlySavingsGoal,
    required this.riskPreference,
    required this.financialGoal,
    required this.spendingPressure,
  });

  final double monthlyIncome;
  final double fixedMonthlyExpenses;
  final double monthlySavingsGoal;
  final RiskPreference riskPreference;
  final FinancialGoal financialGoal;
  final SpendingPressure spendingPressure;
}
