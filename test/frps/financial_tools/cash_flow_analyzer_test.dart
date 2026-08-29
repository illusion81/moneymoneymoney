import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/cash_flow_analyzer.dart';

void main() {
  group('cashFlowAnalyzer', () {
    test('finds negative months and computes surplus statistics', () {
      final analysis = cashFlowAnalyzer([3000, 3000, 3000], [2500, 3200, 2400]);

      expect(analysis.negativeMonths, [1]);
      expect(analysis.averageSurplus, closeTo(900 / 3, 1e-9));

      final mean = 900 / 3;
      final variance = (pow(500 - mean, 2) + pow(-200 - mean, 2) + pow(600 - mean, 2)) / 2;
      expect(analysis.volatility, closeTo(sqrt(variance), 1e-9));
    });

    test('equalizes unequal-length schedules with zero padding', () {
      final analysis = cashFlowAnalyzer([3000], [4000, 1000]);
      // padded: income [3000, 0], expense [4000, 1000] -> surplus [-1000, -1000]
      expect(analysis.negativeMonths, [0, 1]);
      expect(analysis.averageSurplus, -1000);
    });

    test('single month has zero volatility', () {
      final analysis = cashFlowAnalyzer([3000], [2000]);
      expect(analysis.volatility, 0);
      expect(analysis.negativeMonths, isEmpty);
    });
  });
}
