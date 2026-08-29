class BudgetResult {
  const BudgetResult({
    required this.totalIncome,
    required this.totalExpenses,
    required this.surplus,
    required this.savingsRate,
    required this.categoryPercentages,
  });
  final double totalIncome;
  final double totalExpenses;
  final double surplus;
  final double savingsRate;               // 0..1
  final Map<String, double> categoryPercentages; // category -> % of totalExpenses
}

BudgetResult budgetCalculator(double income, Map<String, double> expensesByCategory) {
  final totalExpenses = expensesByCategory.values.fold(0.0, (sum, value) => sum + value);
  final surplus = income - totalExpenses;
  final savingsRate = income > 0 ? (surplus / income).clamp(0.0, 1.0) : 0.0;
  final categoryPercentages = <String, double>{};
  if (totalExpenses > 0) {
    for (final entry in expensesByCategory.entries) {
      categoryPercentages[entry.key] = entry.value / totalExpenses * 100;
    }
  }
  return BudgetResult(
    totalIncome: income,
    totalExpenses: totalExpenses,
    surplus: surplus,
    savingsRate: savingsRate,
    categoryPercentages: categoryPercentages,
  );
}
