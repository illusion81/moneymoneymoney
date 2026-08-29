import '../services/risk_assessment.dart';

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
    required this.riskLevel,
    required this.financialGoal,
    required this.spendingPressure,
  });

  final double monthlyIncome;
  final double fixedMonthlyExpenses;
  final double monthlySavingsGoal;
  final RiskLevel riskLevel;
  final FinancialGoal financialGoal;
  final SpendingPressure spendingPressure;
}
