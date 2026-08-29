# Task 8: ToolOutputs container

**Wave:** 2 (runs after all Wave 1 tools exist). Pure Dart. Imports the six tool
files from `financial_tools/`.

**Files:**
- Create: `lib/frps/models/tool_outputs.dart`
- Create: `test/frps/models/tool_outputs_test.dart`

**Produces:**

```dart
class ToolOutputs {
  const ToolOutputs({
    required this.budget,
    required this.savings,
    required this.debtPlan,
    required this.netWorth,
    required this.cashFlow,
    required this.benchmark,
  });
  final BudgetResult budget;
  final SavingsProjection savings;
  final DebtPayoffPlan debtPlan;
  final NetWorth netWorth;
  final CashFlowAnalysis cashFlow;
  final BenchmarkComparison benchmark;
}
```

Field types are the result classes from Tasks 1–6. Import paths (package name
`moneymoneymoney`):

```dart
import '../financial_tools/budget_calculator.dart';
import '../financial_tools/savings_projector.dart';
import '../financial_tools/debt_payoff_planner.dart';
import '../financial_tools/net_worth_tracker.dart';
import '../financial_tools/cash_flow_analyzer.dart';
import '../financial_tools/benchmark_comparator.dart';
```

- [ ] **Step 1: Write the failing test**

Create `test/frps/models/tool_outputs_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/benchmark_comparator.dart';
import 'package:moneymoneymoney/frps/financial_tools/budget_calculator.dart';
import 'package:moneymoneymoney/frps/financial_tools/cash_flow_analyzer.dart';
import 'package:moneymoneymoney/frps/financial_tools/debt_payoff_planner.dart';
import 'package:moneymoneymoney/frps/financial_tools/net_worth_tracker.dart';
import 'package:moneymoneymoney/frps/financial_tools/savings_projector.dart';
import 'package:moneymoneymoney/frps/models/tool_outputs.dart';

void main() {
  test('ToolOutputs holds all six tool results', () {
    final outputs = ToolOutputs(
      budget: budgetCalculator(6000, {'housing': 1500}),
      savings: savingsProjector(
        currentSavings: 0,
        monthlyContribution: 100,
        annualRate: 0,
        years: 1,
      ),
      debtPlan: debtPayoffPlanner(const []),
      netWorth: netWorthTracker({'cash': 100}, {}),
      cashFlow: cashFlowAnalyzer([100], [50]),
      benchmark: benchmarkComparator({}, {}),
    );

    expect(outputs.budget.surplus, 4500);
    expect(outputs.savings.totalContributions, 1200);
    expect(outputs.debtPlan.monthsToPayoff, 0);
    expect(outputs.netWorth.netWorth, 100);
    expect(outputs.cashFlow.negativeMonths, isEmpty);
    expect(outputs.benchmark.overspendFlags, isEmpty);
  });
}
```

- [ ] **Step 2: Run and verify RED**

`flutter test test/frps/models/tool_outputs_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

Implement `ToolOutputs` per the interface above.

- [ ] **Step 4: Run and verify GREEN**

`flutter test test/frps/models/tool_outputs_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/frps/models/tool_outputs.dart test/frps/models/tool_outputs_test.dart
git commit -m "feat(frps): add tool outputs container"
```
