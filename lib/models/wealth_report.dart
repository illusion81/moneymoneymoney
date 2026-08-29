class WealthReport {
  const WealthReport({
    required this.profileSummary,
    required this.disposableIncome,
    required this.dailyBudget,
    required this.savingsAdvice,
    required this.riskAdvice,
    required this.warning,
    required this.dailyActions,
  });

  final String profileSummary;
  final double disposableIncome;
  final double dailyBudget;
  final String savingsAdvice;
  final String riskAdvice;
  final String? warning;
  final List<String> dailyActions;
}
