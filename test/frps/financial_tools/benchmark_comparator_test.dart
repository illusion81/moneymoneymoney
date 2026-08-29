import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/benchmark_comparator.dart';

void main() {
  group('benchmarkComparator', () {
    test('computes differences and flags overspending', () {
      final comparison = benchmarkComparator(
        {'housing': 40, 'food': 25},
        {'housing': 30, 'food': 20, 'transport': 10},
        flagTolerance: 5,
      );

      expect(comparison.differences['housing'], 10);
      expect(comparison.differences['food'], 5);
      expect(comparison.differences['transport'], -10);
      expect(comparison.overspendFlags, contains('housing'));
      expect(comparison.overspendFlags, isNot(contains('food')));
      expect(comparison.overspendFlags, isNot(contains('transport')));
    });

    test('exposes the national benchmark default', () {
      expect(nationalBenchmark['housing'], 30);
      expect(nationalBenchmark['savings'], 20);
    });
  });
}
