# Task 2: savingsProjector

**Wave:** 1 (parallel). Pure Dart. Uses `dart:math` (`pow`). No Flutter imports.

**Files:**
- Create: `lib/frps/financial_tools/savings_projector.dart`
- Create: `test/frps/financial_tools/savings_projector_test.dart`

**Produces:**

```dart
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
  required double annualRate,   // e.g. 0.05 for 5%
  required int years,
});
```

**Rules (spec §savingsProjector):**
- `n = years * 12`, `r = annualRate / 12`.
- `futureValue = currentSavings * pow(1 + r, n) + monthlyContribution * ((pow(1 + r, n) - 1) / r)` when `r > 0`.
- `futureValue = currentSavings + monthlyContribution * n` when `r == 0`.
- `totalContributions = currentSavings + monthlyContribution * n`.
- `totalInterest = futureValue - totalContributions`.

- [ ] **Step 1: Write the failing test**

Create `test/frps/financial_tools/savings_projector_test.dart`:

```dart
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
```

- [ ] **Step 2: Run and verify RED**

`flutter test test/frps/financial_tools/savings_projector_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

Implement per the interface and rules. Import `dart:math` (for `pow`) only.

- [ ] **Step 4: Run and verify GREEN**

`flutter test test/frps/financial_tools/savings_projector_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/frps/financial_tools/savings_projector.dart test/frps/financial_tools/savings_projector_test.dart
git commit -m "feat(frps): add savings projector tool"
```
