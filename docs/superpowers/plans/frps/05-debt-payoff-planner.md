# Task 5: debtPayoffPlanner

**Wave:** 1 (parallel). Pure Dart. No Flutter imports. Self-contained: defines
`Debt`, `DebtStrategy`, and all result types in this one file (no import of
`models/`).

**Files:**
- Create: `lib/frps/financial_tools/debt_payoff_planner.dart`
- Create: `test/frps/financial_tools/debt_payoff_planner_test.dart`

**Produces:**

```dart
enum DebtStrategy { avalanche, snowball }

class Debt {
  const Debt({
    required this.name,
    required this.balance,
    required this.annualRate,
    required this.minPayment,
  });
  final String name;
  final double balance;
  final double annualRate;   // e.g. 0.18 for 18%
  final double minPayment;
}

class DebtPayoffMonth {
  const DebtPayoffMonth({required this.date, required this.remainingBalances});
  final DateTime date;
  final Map<String, double> remainingBalances;
}

class DebtPayoffPlan {
  const DebtPayoffPlan({
    required this.schedule,
    required this.totalInterest,
    required this.totalPaid,
    required this.payoffDate,
    required this.monthsToPayoff,
  });
  final List<DebtPayoffMonth> schedule;
  final double totalInterest;
  final double totalPaid;
  final DateTime payoffDate;
  final int monthsToPayoff;
}

DebtPayoffPlan debtPayoffPlanner(
  List<Debt> debts, {
  DebtStrategy strategy = DebtStrategy.avalanche,
  double extraPayment = 0,
  DateTime? startDate,
});
```

**Rules (spec §debtPayoffPlanner):**
- Throw `ArgumentError` if any debt has `balance < 0` or `minPayment <= 0`.
- Target order: avalanche sorts by `annualRate` descending; snowball sorts by
  `balance` ascending; ties break by original list order.
- `startDate` defaults to `DateTime(2000, 1, 1)` (never `DateTime.now()`).
- Month loop (guard: at most 600 iterations):
  1. For each debt with `balance > 0`: add interest `balance * annualRate / 12`;
     accumulate into `totalInterest`.
  2. Determine `target` = first debt in strategy order with `balance > 0`.
  3. For each debt in strategy order: if it is the target, pay
     `min(balance, minPayment + extraPayment)`; else pay `min(balance, minPayment)`.
     Accumulate into `totalPaid`; reduce balance.
  4. Record a `DebtPayoffMonth(date, remainingBalances)` where remaining balances
     are rounded to 2 decimals and the date advances one month per iteration.
  5. Break when every balance `<= 0.005`.
- `payoffDate` = `startDate` advanced by `monthsToPayoff` months (calendar-safe:
  use `DateTime(year, month + i, day)` and let Dart normalize the month).
- `monthsToPayoff` = number of months simulated.

- [ ] **Step 1: Write the failing test**

Create `test/frps/financial_tools/debt_payoff_planner_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/debt_payoff_planner.dart';

void main() {
  group('debtPayoffPlanner', () {
    test('pays off a zero-interest single debt in full', () {
      final plan = debtPayoffPlanner(
        const [Debt(name: 'card', balance: 1000, annualRate: 0, minPayment: 250)],
        startDate: DateTime(2026, 1, 1),
      );

      expect(plan.totalInterest, 0);
      expect(plan.totalPaid, closeTo(1000, 0.01));
      expect(plan.monthsToPayoff, 4);
      expect(plan.payoffDate, DateTime(2026, 5, 1));
      expect(plan.schedule, hasLength(4));
      expect(plan.schedule.last.remainingBalances['card'], closeTo(0, 0.01));
    });

    test('avalanche targets the higher-rate debt; snowball the smaller balance', () {
      const debts = [
        Debt(name: 'A', balance: 300, annualRate: 0.20, minPayment: 10),
        Debt(name: 'B', balance: 100, annualRate: 0.10, minPayment: 10),
      ];

      final avalanche = debtPayoffPlanner(
        debts,
        strategy: DebtStrategy.avalanche,
        extraPayment: 50,
        startDate: DateTime(2026, 1, 1),
      );
      final snowball = debtPayoffPlanner(
        debts,
        strategy: DebtStrategy.snowball,
        extraPayment: 50,
        startDate: DateTime(2026, 1, 1),
      );

      // Avalanche targets A (20% > 10%): A shrinks by 60 in month 1.
      expect(avalanche.schedule.first.remainingBalances['A'], closeTo(245, 0.01));
      // Snowball targets B (100 < 300): B shrinks by 60 in month 1.
      expect(snowball.schedule.first.remainingBalances['B'], closeTo(40.83, 0.01));
    });

    test('rejects a debt with non-positive minimum payment', () {
      expect(
        () => debtPayoffPlanner(
          const [Debt(name: 'bad', balance: 100, annualRate: 0.1, minPayment: 0)],
        ),
        throwsArgumentError,
      );
    });
  });
}
```

Note: verify the month-1 numbers by hand before trusting them — avalanche month
1: A interest `300*0.20/12 = 5` → 305, pay `min(305, 10+50)=60` → 245; B interest
`100*0.10/12 ≈ 0.8333` → 100.8333, pay `min(100.8333, 10)=10` → 90.8333.
Snowball month 1: target B, pay `min(100.8333, 60)=60` → 40.8333; A pays `10` →
`300+5-10 = 295`.

- [ ] **Step 2: Run and verify RED**

`flutter test test/frps/financial_tools/debt_payoff_planner_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

Implement per the interface and rules. Use plain doubles; do not import Flutter.
Keep a strategy-ordered working copy of debts and mutate balances in place.

- [ ] **Step 4: Run and verify GREEN**

`flutter test test/frps/financial_tools/debt_payoff_planner_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/frps/financial_tools/debt_payoff_planner.dart test/frps/financial_tools/debt_payoff_planner_test.dart
git commit -m "feat(frps): add debt payoff planner tool"
```
