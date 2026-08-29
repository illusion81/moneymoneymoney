import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/savings_projector.dart';

void main() {
  group('savingsProjector', () {
    test('computes future value, contributions, and interest', () {
      final projection = savingsProjector(
        currentSavings: 10000,
        monthlyContribution: 500,
        annualRate: 0.05,
        years: 10,
      );

      final r = 0.05 / 12;
      final n = 120;
      final expectedFv =
          10000 * pow(1 + r, n) + 500 * ((pow(1 + r, n) - 1) / r);

      expect(projection.futureValue, closeTo(expectedFv, 0.01));
      expect(projection.totalContributions, 10000 + 500 * 120);
      expect(projection.totalInterest, closeTo(expectedFv - (10000 + 500 * 120), 0.01));
    });

    test('zero annual rate uses linear growth with no interest', () {
      final projection = savingsProjector(
        currentSavings: 0,
        monthlyContribution: 100,
        annualRate: 0,
        years: 2,
      );

      expect(projection.futureValue, closeTo(2400, 1e-9));
      expect(projection.totalContributions, 2400);
      expect(projection.totalInterest, 0);
    });
  });
}
