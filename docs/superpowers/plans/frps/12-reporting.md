# Task 12: Report Assembler

**Wave:** 3 (parallel). Pure Dart. Imports `models/report.dart` and
`models/tool_outputs.dart`. Does no arithmetic — only formats and arranges
values already in `ToolOutputs`.

**Files:**
- Create: `lib/frps/reporting/report_assembler.dart`
- Create: `test/frps/reporting/report_assembler_test.dart`

**Produces:**

```dart
class ReportAssembler {
  Report assemble({
    required ToolOutputs toolOutputs,
    required String narrative,
    required String userId,
    required DateTime date,
  });
}
```

**Section order and titles (spec §Report Assembly):**
1. `Executive Summary` — includes `narrative` plus the headline metrics
   (`budget.surplus`, `budget.savingsRate`, `netWorth.netWorth`).
2. `Expense Overview` — category percentages from
   `budget.categoryPercentages` and overspend flags from
   `benchmark.overspendFlags`.
3. `Opportunities & Options` — quantified opportunities (savings projection
   `futureValue`, debt `totalInterest`).
4. `Progress & Motivation` — gamified framing (savings `totalInterest` as
   "free money", `cashFlow.averageSurplus` momentum).

No new numbers may be computed inside `assemble` — format existing values only.

- [ ] **Step 1: Write the failing test**

Create `test/frps/reporting/report_assembler_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/benchmark_comparator.dart';
import 'package:moneymoneymoney/frps/financial_tools/budget_calculator.dart';
import 'package:moneymoneymoney/frps/financial_tools/cash_flow_analyzer.dart';
import 'package:moneymoneymoney/frps/financial_tools/debt_payoff_planner.dart';
import 'package:moneymoneymoney/frps/financial_tools/net_worth_tracker.dart';
import 'package:moneymoneymoney/frps/financial_tools/savings_projector.dart';
import 'package:moneymoneymoney/frps/models/tool_outputs.dart';
import 'package:moneymoneymoney/frps/reporting/report_assembler.dart';

void main() {
  test('produces the four required sections in order', () {
    final outputs = ToolOutputs(
      budget: budgetCalculator(6000, {'housing': 2600}),
      savings: savingsProjector(
        currentSavings: 0,
        monthlyContribution: 900,
        annualRate: 0.05,
        years: 10,
      ),
      debtPlan: debtPayoffPlanner(const []),
      netWorth: netWorthTracker({'cash': 10000}, {'card': 500}),
      cashFlow: cashFlowAnalyzer([6000], [2600]),
      benchmark: benchmarkComparator({'housing': 43.33}, nationalBenchmark),
    );

    final report = ReportAssembler().assemble(
      toolOutputs: outputs,
      narrative: 'You are on track.',
      userId: 'u1',
      date: DateTime(2026, 8, 29),
    );

    expect(
      report.sections.map((s) => s.title).toList(),
      ['Executive Summary', 'Expense Overview', 'Opportunities & Options', 'Progress & Motivation'],
    );
    expect(report.sections.first.content, contains('You are on track.'));
    expect(report.sections[1].content, contains('housing'));
  });
}
```

- [ ] **Step 2: Run and verify RED**

`flutter test test/frps/reporting/report_assembler_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

Implement `ReportAssembler` per the interface and section rules.

- [ ] **Step 4: Run and verify GREEN**

`flutter test test/frps/reporting/report_assembler_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/frps/reporting test/frps/reporting/report_assembler_test.dart
git commit -m "feat(frps): add report assembler"
```
