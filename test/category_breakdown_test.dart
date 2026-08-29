import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/services/category_breakdown.dart';

void main() {
  group('topCategorySlices', () {
    test('returns an empty list when there is no spending', () {
      expect(topCategorySlices(const {}), isEmpty);
    });

    test('orders slices from largest to smallest', () {
      final slices = topCategorySlices(const {
        'groceries': 50.0,
        'eating-out': 120.0,
        'transport': 80.0,
      });

      expect(slices.map((s) => s.label), [
        'eating-out',
        'transport',
        'groceries',
      ]);
      expect(slices.first.amount, 120.0);
    });

    test('computes each slice share of the total', () {
      final slices = topCategorySlices(const {'a': 75.0, 'b': 25.0});

      expect(slices[0].share, 0.75);
      expect(slices[1].share, 0.25);
    });

    test('folds everything past maxSlices into a single Other slice', () {
      final slices = topCategorySlices(const {
        'a': 100.0,
        'b': 90.0,
        'c': 80.0,
        'd': 5.0,
        'e': 4.0,
        'f': 1.0,
      }, maxSlices: 4);

      expect(slices, hasLength(4));
      expect(slices.last.label, 'Other');
      expect(slices.last.amount, 10.0); // 5 + 4 + 1
      expect(slices.last.isOther, isTrue);
    });

    test('does not create an Other slice when categories fit exactly', () {
      final slices = topCategorySlices(const {
        'a': 10.0,
        'b': 5.0,
      }, maxSlices: 4);

      expect(slices, hasLength(2));
      expect(slices.any((s) => s.isOther), isFalse);
    });

    test('ignores non-positive amounts', () {
      final slices = topCategorySlices(const {'a': 10.0, 'b': 0.0, 'c': -5.0});

      expect(slices.map((s) => s.label), ['a']);
    });

    test('shares always sum to 1 for a non-empty breakdown', () {
      final slices = topCategorySlices(const {
        'a': 33.0,
        'b': 33.0,
        'c': 34.0,
        'd': 10.0,
      }, maxSlices: 3);

      final total = slices.fold<double>(0, (sum, s) => sum + s.share);
      expect(total, closeTo(1.0, 1e-9));
    });
  });
}
