import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/tree/finance_pillars.dart';
import 'package:moneymoneymoney/tree/pixel_tree_painter.dart';
import 'package:moneymoneymoney/tree/tree_generator.dart';

void main() {
  final segments = const TreeGenerator().generate(
    pillars: const FinancePillars.balanced(),
    random: Random(7),
  );

  test('quantizes segments onto a grid with no duplicate cells', () {
    final cells = quantizeSegments(segments, progress: 1.0, cell: 4);
    expect(cells, isNotEmpty);
    // A Set cannot hold duplicates; assert the contract explicitly.
    expect(cells.length, cells.toSet().length);
  });

  test('reveals more cells as progress rises', () {
    final early = quantizeSegments(segments, progress: 0.2, cell: 4).length;
    final late = quantizeSegments(segments, progress: 1.0, cell: 4).length;
    expect(late, greaterThan(early));
  });

  test('draws nothing at zero progress', () {
    expect(quantizeSegments(segments, progress: 0.0, cell: 4), isEmpty);
  });

  test('a coarser grid yields fewer cells', () {
    final fine = quantizeSegments(segments, progress: 1.0, cell: 2).length;
    final coarse = quantizeSegments(segments, progress: 1.0, cell: 8).length;
    expect(coarse, lessThan(fine));
  });

  test('cells snap to the grid', () {
    for (final cell in quantizeSegments(segments, progress: 1.0, cell: 4)) {
      expect(cell.x, isA<int>());
      expect(cell.y, isA<int>());
    }
  });

  test('the withered palette differs from the healthy one', () {
    expect(
      const TreePalette.withered().leaf,
      isNot(const TreePalette.healthy().leaf),
    );
  });
}