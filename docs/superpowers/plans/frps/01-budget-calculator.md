# Task 1: budgetCalculator

**Wave:** 1 (parallel). Pure Dart. No Flutter imports. No dependencies on other tasks.

**Files:**
- Create: `lib/frps/financial_tools/budget_calculator.dart`
- Create: `test/frps/financial_tools/budget_calculator_test.dart`

**Produces (exact interface later tasks rely on):**

```dart
class BudgetResult {
  const BudgetResult({
    required this.totalIncome,
    required this.totalExpenses,
    required this.surplus,
    required this.savingsRate,
    required this.categoryPercentages,
  });
  final double totalIncome;
  final double totalExpenses;
  final double surplus;
  final double savingsRate;               // 0..1
  final Map<String, double> categoryPercentages; // category -> % of totalExpenses
}

BudgetResult budgetCalculator(double income, Map<String, double> expensesByCategory);
```

**Rules (spec §budgetCalculator):**
- `totalExpenses` = sum of `expensesByCategory` values.
- `surplus` = `income - totalExpenses`.
- `savingsRate` = `income > 0 ? (surplus / income).clamp(0.0, 1.0) : 0.0`.
- `categoryPercentages[c]` = `totalExpenses > 0 ? amount / totalExpenses * 100 : 0.0`.

- [ ] **Step 1: Write the failing test**

Create `test/frps/financial_tools/budget_calculator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/budget_calculator.dart';

void main() {
  group('budgetCalculator', () {
    test('totals expenses, surplus, savings rate, and category percentages', () {
      final result = budgetCalculator(6000, {
        'housing': 1500,
        'food': 800,
        'transport': 300,
      });

      expect(result.totalIncome, 6000);
      expect(result.totalExpenses, 2600);
      expect(result.surplus, 3400);
      expect(result.savingsRate, closeTo(3400 / 6000, 1e-9));
      expect(result.categoryPercentages['housing'], closeTo(1500 / 2600 * 100, 1e-9));
      expect(result.categoryPercentages['food'], closeTo(800 / 2600 * 100, 1e-9));
    });

    test('negative surplus is a deficit and savings rate floors at zero', () {
      final result = budgetCalculator(2000, {'rent': 2500});
      expect(result.surplus, -500);
      expect(result.savingsRate, 0);
    });

    test('empty expenses and zero income are safe', () {
      final result = budgetCalculator(0, {});
      expect(result.totalExpenses, 0);
      expect(result.surplus, 0);
      expect(result.savingsRate, 0);
      expect(result.categoryPercentages, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run and verify RED**

`flutter test test/frps/financial_tools/budget_calculator_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

`lib/frps/financial_tools/budget_calculator.dart` — implement the class and
function exactly per the interface and rules above. No `import` beyond `dart:`
(no Flutter).

- [ ] **Step 4: Run and verify GREEN**

`flutter test test/frps/financial_tools/budget_calculator_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/frps/financial_tools/budget_calculator.dart test/frps/financial_tools/budget_calculator_test.dart
git commit -m "feat(frps): add budget calculator tool"
```
