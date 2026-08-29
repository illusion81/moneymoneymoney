import 'dart:math';

class CashFlowAnalysis {
  const CashFlowAnalysis({
    required this.negativeMonths,
    required this.averageSurplus,
    required this.volatility,
  });
  final List<int> negativeMonths;
  final double averageSurplus;
  final double volatility;
}

CashFlowAnalysis cashFlowAnalyzer(
  List<double> incomeSchedule,
  List<double> expenseSchedule,
) {
  final n = max(incomeSchedule.length, expenseSchedule.length);

  final income = List<double>.filled(n, 0);
  final expense = List<double>.filled(n, 0);
  for (var i = 0; i < n; i++) {
    if (i < incomeSchedule.length) income[i] = incomeSchedule[i];
    if (i < expenseSchedule.length) expense[i] = expenseSchedule[i];
  }

  final surplus = <double>[];
  final negativeMonths = <int>[];
  for (var i = 0; i < n; i++) {
    final s = income[i] - expense[i];
    surplus.add(s);
    if (s < 0) negativeMonths.add(i);
  }

  final averageSurplus =
      surplus.fold<double>(0, (sum, x) => sum + x) / n;

  double volatility = 0;
  if (n >= 2) {
    final sumSq = surplus.fold<double>(
      0,
      (sum, x) => sum + pow(x - averageSurplus, 2),
    );
    volatility = sqrt(sumSq / (n - 1));
  }

  return CashFlowAnalysis(
    negativeMonths: negativeMonths,
    averageSurplus: averageSurplus,
    volatility: volatility,
  );
}
