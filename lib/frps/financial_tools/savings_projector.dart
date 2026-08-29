import 'dart:math';

class SavingsProjection {
  const SavingsProjection({
    required this.futureValue,
    required this.totalContributions,
    required this.totalInterest,
  });
  final double futureValue;
  final double totalContributions;
  final double totalInterest;
}

SavingsProjection savingsProjector({
  required double currentSavings,
  required double monthlyContribution,
  required double annualRate,
  required int years,
}) {
  final n = years * 12;
  final r = annualRate / 12;

  final double futureValue;
  if (r > 0) {
    futureValue = currentSavings * pow(1 + r, n) +
        monthlyContribution * ((pow(1 + r, n) - 1) / r);
  } else {
    futureValue = currentSavings + monthlyContribution * n;
  }

  final totalContributions = currentSavings + monthlyContribution * n;
  final totalInterest = futureValue - totalContributions;

  return SavingsProjection(
    futureValue: futureValue,
    totalContributions: totalContributions,
    totalInterest: totalInterest,
  );
}
