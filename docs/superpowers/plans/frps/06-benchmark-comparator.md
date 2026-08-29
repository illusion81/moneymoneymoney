# Task 6: benchmarkComparator

**Wave:** 1 (parallel). Pure Dart. No Flutter imports. Self-contained: defines
the `nationalBenchmark` constant in this file.

**Files:**
- Create: `lib/frps/financial_tools/benchmark_comparator.dart`
- Create: `test/frps/financial_tools/benchmark_comparator_test.dart`

**Produces:**

```dart
class BenchmarkComparison {
  const BenchmarkComparison({
    required this.differences,
    required this.overspendFlags,
  });
  final Map<String, double> differences; // user - benchmark, per category
  final List<String> overspendFlags;     // categories flagged as overspending
}

BenchmarkComparison benchmarkComparator(
  Map<String, double> userExpenseRatios,   // category -> percentage
  Map<String, double> benchmarkRatios,     // category -> percentage
  {double flagTolerance = 5.0},
);

const Map<String, double> nationalBenchmark = {
  'housing': 30,
  'food': 15,
  'transport': 15,
  'entertainment': 5,
  'savings': 20,
  'other': 15,
};
```

**Rules (spec §benchmarkComparator):**
- `differences[c] = userExpenseRatios[c] - benchmarkRatios[c]` for every category
  present in either map (missing side treated as `0`).
- `overspendFlags` = categories where `userExpenseRatios[c] > benchmarkRatios[c] + flagTolerance`.

- [ ] **Step 1: Write the failing test**

Create `test/frps/financial_tools/benchmark_comparator_test.dart`:

```dart
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
```

- [ ] **Step 2: Run and verify RED**

`flutter test test/frps/financial_tools/benchmark_comparator_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

Implement per the interface and rules. Build the differences map over the union
of keys.

- [ ] **Step 4: Run and verify GREEN**

`flutter test test/frps/financial_tools/benchmark_comparator_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/frps/financial_tools/benchmark_comparator.dart test/frps/financial_tools/benchmark_comparator_test.dart
git commit -m "feat(frps): add benchmark comparator tool"
```
