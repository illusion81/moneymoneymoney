# Task 9: SLM Interface + Mock

**Wave:** 3 (parallel). Pure Dart (no Flutter imports). Imports `models` and
`models/tool_outputs.dart`. Does NOT import `financial_tools/` (invariant #3).

**Files:**
- Create: `lib/frps/slm/slm_interface.dart`
- Create: `lib/frps/slm/mock_slm.dart`
- Create: `test/frps/slm/mock_slm_test.dart`

**Produces:**

```dart
// slm_interface.dart
class ExtractedData {
  const ExtractedData({required this.category, required this.amount, this.raw});
  final String category;
  final double amount;
  final String? raw;
}

abstract class SlmInterface {
  String generateReportNarrative({
    required ToolOutputs toolOutputs,
    required UserProfile userProfile,
  });
  ExtractedData parseFreeText(String answer);
}
```

```dart
// mock_slm.dart
class MockSlm implements SlmInterface {
  @override
  String generateReportNarrative({required ToolOutputs toolOutputs, required UserProfile userProfile});
  @override
  ExtractedData parseFreeText(String answer);
}
```

**Mock rules (spec §SLM Interface):**
- `parseFreeText`: extract amount via `RegExp(r'\$?\s*(\d+(?:\.\d+)?)')`; detect
  frequency with `RegExp(r'/month|per month|monthly|a month')` (frequency is not
  needed to produce the amount — the amount is returned as-is). Map keywords to a
  category: coffee/dining/restaurant/food/grocery/eat → `dining`;
  rent/mortgage/housing → `housing`; transport/car/fuel/gas/commute →
  `transport`; gym/fitness/health → `health`; shopping/clothes → `shopping`;
  otherwise `unknown`. If no amount matches, return
  `ExtractedData(category: 'unknown', amount: 0, raw: answer)`.
- `generateReportNarrative`: compose prose from `toolOutputs` using string
  templates ONLY. No arithmetic — only string interpolation of numbers that
  already exist in `toolOutputs`/`userProfile`, formatted with
  `toStringAsFixed`. It MUST mention `budget.surplus`, `budget.savingsRate`,
  `netWorth.netWorth`, and `userProfile.monthlyIncome`.

- [ ] **Step 1: Write the failing test**

Create `test/frps/slm/mock_slm_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/financial_tools/benchmark_comparator.dart';
import 'package:moneymoneymoney/frps/financial_tools/budget_calculator.dart';
import 'package:moneymoneymoney/frps/financial_tools/cash_flow_analyzer.dart';
import 'package:moneymoneymoney/frps/financial_tools/debt_payoff_planner.dart';
import 'package:moneymoneymoney/frps/financial_tools/net_worth_tracker.dart';
import 'package:moneymoneymoney/frps/financial_tools/savings_projector.dart';
import 'package:moneymoneymoney/frps/models/tool_outputs.dart';
import 'package:moneymoneymoney/frps/models/user_profile.dart';
import 'package:moneymoneymoney/frps/slm/mock_slm.dart';

void main() {
  group('MockSlm.parseFreeText', () {
    test('extracts category and amount from a spending sentence', () {
      final data = MockSlm().parseFreeText('I spend \$200/month on coffee');
      expect(data.category, 'dining');
      expect(data.amount, 200);
    });

    test('returns the unknown sentinel for unmatched text', () {
      final data = MockSlm().parseFreeText('hello there friend');
      expect(data.category, 'unknown');
      expect(data.amount, 0);
    });
  });

  group('MockSlm.generateReportNarrative', () {
    test('embeds computed numbers without doing arithmetic', () {
      final outputs = ToolOutputs(
        budget: budgetCalculator(6000, {'housing': 2600}),
        savings: savingsProjector(
          currentSavings: 0,
          monthlyContribution: 900,
          annualRate: 0,
          years: 1,
        ),
        debtPlan: debtPayoffPlanner(const []),
        netWorth: netWorthTracker({'cash': 10000}, {'card': 500}),
        cashFlow: cashFlowAnalyzer([6000], [2600]),
        benchmark: benchmarkComparator({}, {}),
      );
      final text = MockSlm().generateReportNarrative(
        toolOutputs: outputs,
        userProfile: const UserProfile(monthlyIncome: 6000, age: 30),
      );

      expect(text, contains('3400.00')); // surplus
      expect(text, contains('9500.00')); // net worth
      expect(text, contains('6000.00')); // income
    });
  });
}
```

- [ ] **Step 2: Run and verify RED**

`flutter test test/frps/slm/mock_slm_test.dart`
Expected: FAIL — files do not exist.

- [ ] **Step 3: Implement**

Implement `slm_interface.dart` then `mock_slm.dart` per the interfaces and rules.
Ensure `MockSlm` imports only `models/` and `models/tool_outputs.dart` — never
`financial_tools/`.

- [ ] **Step 4: Run and verify GREEN**

`flutter test test/frps/slm/mock_slm_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/frps/slm test/frps/slm/mock_slm_test.dart
git commit -m "feat(frps): add mock SLM interface"
```
