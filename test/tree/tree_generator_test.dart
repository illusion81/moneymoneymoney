import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/tree/finance_pillars.dart';
import 'package:moneymoneymoney/tree/tree_generator.dart';

void main() {
  const generator = TreeGenerator();

  List<dynamic> gen(FinancePillars pillars, {int seed = 7}) =>
      generator.generate(pillars: pillars, random: Random(seed));

  test('produces a tree for balanced pillars', () {
    expect(gen(const FinancePillars.balanced()), isNotEmpty);
  });

  test('is reproducible for a fixed seed', () {
    final a = gen(const FinancePillars.balanced());
    final b = gen(const FinancePillars.balanced());
    expect(a.length, b.length);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].a, b[i].a, reason: 'segment $i start');
      expect(a[i].b, b[i].b, reason: 'segment $i end');
      expect(a[i].growthAt, closeTo(b[i].growthAt, 1e-12));
    }
  });

  test('different seeds give different trees', () {
    final a = gen(const FinancePillars.balanced(), seed: 1);
    final b = gen(const FinancePillars.balanced(), seed: 2);
    final sameLength = a.length == b.length;
    final sameFirstBranchEnd = a[9].b == b[9].b;
    expect(sameLength && sameFirstBranchEnd, isFalse);
  });

  test('every growthAt is within 0..1 and spans the range', () {
    final segments = gen(const FinancePillars.balanced());
    var maxGrowth = 0.0;
    var minGrowth = 1.0;
    for (final s in segments) {
      expect(s.growthAt, inInclusiveRange(0.0, 1.0));
      maxGrowth = s.growthAt > maxGrowth ? s.growthAt : maxGrowth;
      minGrowth = s.growthAt < minGrowth ? s.growthAt : minGrowth;
    }
    expect(maxGrowth, closeTo(1.0, 1e-9));
    expect(minGrowth, lessThan(0.2));
  });

  test('revealed segment count never decreases as progress rises', () {
    final segments = gen(const FinancePillars.balanced());
    var previous = 0;
    for (var i = 0; i <= 20; i++) {
      final progress = i / 20;
      final visible =
          segments.where((s) => s.growthAt <= progress).length;
      expect(visible, greaterThanOrEqualTo(previous));
      previous = visible;
    }
    expect(previous, segments.length);
  });

  test('higher profitability grows a taller tree', () {
    double topOf(double profitability) {
      final segments = generator.generate(
        pillars: FinancePillars(
          profitability: profitability,
          liquidity: 0.5,
          solvency: 0.5,
          efficiency: 0.5,
        ),
        random: Random(3),
      );
      return segments.map((s) => s.b.dy).reduce(min);
    }

    // Smaller dy is higher on screen.
    expect(topOf(0.9), lessThan(topOf(0.1)));
  });

  test('higher solvency thickens the trunk', () {
    double trunkWeight(double solvency) => generator
        .generate(
          pillars: FinancePillars(
            profitability: 0.5,
            liquidity: 0.5,
            solvency: solvency,
            efficiency: 0.5,
          ),
          random: Random(3),
        )
        .first
        .weight;

    expect(trunkWeight(0.9), greaterThan(trunkWeight(0.1)));
  });

  test('higher liquidity grows more leaves', () {
    int leaves(double liquidity) => generator
        .generate(
          pillars: FinancePillars(
            profitability: 0.5,
            liquidity: liquidity,
            solvency: 0.5,
            efficiency: 0.8,
          ),
          random: Random(11),
        )
        .where((s) => s.isLeaf)
        .length;

    expect(leaves(0.95), greaterThan(leaves(0.05)));
  });

  test('a withered tree grows no leaves at all', () {
    final segments = generator.generate(
      pillars: const FinancePillars(
        profitability: 0.05,
        liquidity: 0.05,
        solvency: 0.05,
        efficiency: 0.05,
      ),
      random: Random(5),
    );
    expect(segments.where((s) => s.isLeaf), isEmpty);
  });

  test('recursion never exceeds the pillar-derived cap', () {
    final segments = generator.generate(
      pillars: const FinancePillars(
        profitability: 0.9,
        liquidity: 0.9,
        solvency: 0.9,
        efficiency: 0.9,
      ),
      random: Random(2),
    );
    expect(segments.map((s) => s.depth).reduce(max), lessThanOrEqualTo(4));
  });
}