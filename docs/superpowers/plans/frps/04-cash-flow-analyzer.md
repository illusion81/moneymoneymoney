# Task 4: cashFlowAnalyzer

**Wave:** 1 (parallel). Pure Dart. Uses `dart:math` (`sqrt`). No Flutter imports.

**Files:**
- Create: `lib/frps/financial_tools/cash_flow_analyzer.dart`
- Create: `test/frps/financial_tools/cash_flow_analyzer_test.dart`

**Produces:**

```dart
class CashFlowAnalysis {
  const CashFlowAnalysis({
    required this.negativeMonths,
    required this.averageSurplus,
    required this.volatility,
  });
  final List<int> negativeMonths; // 0-based indices where expense > income
  final double averageSurplus;    // mean(income - expense)
  final double volatility;        // sample std dev of monthly surplus
}

CashFlowAnalysis cashFlowAnalyzer(
  List<double> incomeSchedule,
  List<double> expenseSchedule,
);
```

**Rules (spec §cashFlowAnalyzer):**
- Equalize lengths to `max(income.length, expense.length)`; missing months are `0`.
- `surplus[i] = income[i] - expense[i]`.
- `negativeMonths` = indices where `surplus[i] < 0`.
- `averageSurplus` = mean of surplus values.
- `volatility` = sample standard deviation of surplus values (`sqrt(sum((x - mean)^2) / (n - 1))`); `0` when `n < 2`.

- [ ] **Step 1: Write the failing test**

Create `test/frps/financial_tools/cash_flow_analyzer_test.dart`:

```dart
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
```

- [ ] **Step 2: Run and verify RED**

`flutter test test/frps/financial_tools/cash_flow_analyzer_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

Implement per the interface and rules. Import `dart:math` for `sqrt`.

- [ ] **Step 4: Run and verify GREEN**

`flutter test test/frps/financial_tools/cash_flow_analyzer_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/frps/financial_tools/cash_flow_analyzer.dart test/frps/financial_tools/cash_flow_analyzer_test.dart
git commit -m "feat(frps): add cash flow analyzer tool"
```
