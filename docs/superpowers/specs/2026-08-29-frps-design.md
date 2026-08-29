# Financial Report Planner System (FRPS) Design

## Goal

Add a Financial Report Planner System to the existing Flutter app. FRPS combines
a Small Language Model (SLM) — for parsing free-text input and writing
natural-language narrative only — with a suite of deterministic financial tools
that perform all arithmetic. The system asks adaptive questions, computes a
personal financial picture with pure functions, and assembles a four-section
report with accurate numbers and a coherent, motivating narrative.

## Scope

This is a Dart-native subsystem living inside the existing Flutter app, under
`lib/frps/`. It is NOT a separate package and it has NO HTTP server: the app
calls a plain Dart service directly, mirroring how the existing
`ReportGenerator` and `ForestEngine` services are consumed.

- In scope: six deterministic financial tools, data models, a mock SLM
  interface, an adaptive questionnaire engine, report assembly, and local
  SQLite persistence behind a repository interface.
- Out of scope: any external SLM/LLM API call, cloud storage, cross-user
  analytics, authentication, and selling or exporting user data. The mock SLM
  is the only SLM; a real model is a future plug-in behind the same interface.
- Existing `lib/models/`, `lib/services/`, `lib/screens/`, and `lib/main.dart`
  are untouched by this work.

## Core Invariants

These bind every phase and every future change:

1. **Deterministic tools do all arithmetic.** Every number in any report
   originates in `lib/frps/financial_tools/`. The tools are pure functions:
   no I/O, no randomness, no clock reads, no SLM calls.
2. **The SLM does zero arithmetic.** The SLM interface only parses text into
   structured data and formats already-computed numbers into prose. It never
   sums, projects, or derives a financial value.
3. **Tools and SLM are fully separated.** `financial_tools/` never imports
   `slm/`, and `slm/` never imports `financial_tools/`. They meet only in
   `reporting/`.
4. **SLM and storage are behind interfaces.** A real model (e.g. Hugging Face
   / local Llama) replaces the mock without touching callers; a different
   storage engine replaces SQLite without touching callers.
5. **Pure-Dart logic is tested independently** of Flutter widgets, via
   `flutter test`.

## Architecture

```text
lib/frps/
  financial_tools/          # pure, deterministic, no I/O, no SLM
    budget_calculator.dart
    savings_projector.dart
    debt_payoff_planner.dart
    net_worth_tracker.dart
    cash_flow_analyzer.dart
    benchmark_comparator.dart
  models/                   # plain data classes + JSON serialization
    user.dart
    user_profile.dart
    question.dart
    question_response.dart
    financial_snapshot.dart
    report.dart
    tool_outputs.dart
  slm/
    slm_interface.dart      # abstract contract + ExtractedData
    mock_slm.dart           # template/rule-based implementation
  questions/
    question_flow.dart      # adaptive questionnaire engine + branching
    question_catalog.dart   # static question definitions
  reporting/
    report_assembler.dart   # tools + narrative -> Report
  storage/
    repository.dart         # abstract repository interfaces
    sqlite_store.dart       # sqflite implementation
  report_planner.dart       # top-level service orchestrating the flow

test/frps/                  # mirrored test tree
```

### Data flow

```text
Questionnaire answers ──► ReportPlanner
                              │ 1. answers -> structured data
                              │    (free-text answers pass through MockSlm.parseFreeText)
                              │ 2. structured data -> financial_tools (all arithmetic)
                              │ 3. tool outputs -> MockSlm.generateReportNarrative
                              │ 4. tool outputs + narrative -> ReportAssembler -> Report
                              │ 5. Report persisted via storage repository
                              ▼
                          Report (4 sections)
```

---

## Deterministic Financial Tools

All functions are top-level pure functions (or static methods) in
`lib/frps/financial_tools/`. Inputs are plain Dart values; outputs are plain
data classes. No function touches `dart:io`, `dart:math` randomness, or
`DateTime.now()`. The only external input for `debtPayoffPlanner` is a starting
`DateTime` supplied by the caller.

### 1. `budgetCalculator`

```dart
class BudgetResult {
  final double totalIncome;
  final double totalExpenses;
  final double surplus;            // income - expenses (may be negative)
  final double savingsRate;        // surplus / income, 0..1; 0 when income <= 0
  final Map<String, double> categoryPercentages; // category / totalExpenses * 100
}

BudgetResult budgetCalculator(
  double income,
  Map<String, double> expensesByCategory,
)
```

Rules:
- `totalExpenses` = sum of `expensesByCategory` values.
- `surplus` = `income - totalExpenses`.
- `savingsRate` = `surplus / income` when `income > 0`, else `0`.
- `categoryPercentages` maps each category to `amount / totalExpenses * 100`
  when `totalExpenses > 0`, else `0`.

### 2. `savingsProjector`

```dart
class SavingsProjection {
  final double futureValue;
  final double totalContributions;
  final double totalInterest;
}

SavingsProjection savingsProjector({
  required double currentSavings,
  required double monthlyContribution,
  required double annualRate,   // e.g. 0.05 for 5%
  required int years,
})
```

Rules:
- `n = years * 12`, `r = annualRate / 12`.
- `futureValue = currentSavings * pow(1 + r, n) + monthlyContribution * ((pow(1 + r, n) - 1) / r)` when `r > 0`; when `r == 0`, `futureValue = currentSavings + monthlyContribution * n`.
- `totalContributions = currentSavings + monthlyContribution * n`.
- `totalInterest = futureValue - totalContributions`.

### 3. `debtPayoffPlanner`

`Debt` and `DebtStrategy` are defined in this same file, so the tool is
self-contained and has no dependency on `models/`.

```dart
enum DebtStrategy { avalanche, snowball }

class Debt {
  final String name;
  final double balance;
  final double annualRate;   // e.g. 0.18 for 18%
  final double minPayment;
}

class DebtPayoffPlan {
  final List<DebtPayoffMonth> schedule; // month-by-month
  final double totalInterest;
  final double totalPaid;
  final DateTime payoffDate;
  final int monthsToPayoff;
}

class DebtPayoffMonth {
  final DateTime date;
  final Map<String, double> remainingBalances;
}

DebtPayoffPlan debtPayoffPlanner(
  List<Debt> debts, {
  DebtStrategy strategy = DebtStrategy.avalanche,
  double extraPayment = 0,
  DateTime? startDate,
})
```

Rules:
- Avalanche targets extra payment at the highest `annualRate` first; snowball
  at the lowest `balance` first. Ties break by earliest list order.
- Each month, every debt accrues `balance * annualRate / 12` interest first,
  then receives at least its `minPayment`; the strategy's target debt receives
  `minPayment + extraPayment` until paid off, after which freed-up payments roll
  into the next target.
- The schedule records remaining balances per debt at each month until all
  balances reach zero. `totalInterest` accumulates all interest paid;
  `totalPaid` accumulates all principal + interest paid.
- `payoffDate` = `startDate` (default supplied by caller; never `now()`) advanced
  by `monthsToPayoff` months.
- Assumptions documented in the plan: payments are monthly, interest compounds
  monthly, no fees, no prepayment penalties.

### 4. `netWorthTracker`

```dart
class NetWorth {
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;          // assets - liabilities
}

NetWorth netWorthTracker(
  Map<String, double> assets,
  Map<String, double> liabilities,
)
```

### 5. `cashFlowAnalyzer`

```dart
class CashFlowAnalysis {
  final List<int> negativeMonths;  // 0-based indices where expense > income
  final double averageSurplus;     // mean(income - expense) across months
  final double volatility;         // sample standard deviation of monthly surplus
}

CashFlowAnalysis cashFlowAnalyzer(
  List<double> incomeSchedule,
  List<double> expenseSchedule,
)
```

Rules:
- Schedules must be equal length; a shorter list is treated as `0` for the
  missing months (lengths equalized to `max`).
- `averageSurplus` = mean of `income[i] - expense[i]`.
- `volatility` = sample standard deviation of monthly surplus values;
  `0` when fewer than 2 months.

### 6. `benchmarkComparator`

```dart
class BenchmarkComparison {
  final Map<String, double> differences; // user - benchmark, per category
  final List<String> overspendFlags;     // categories where user > benchmark * threshold
}

BenchmarkComparison benchmarkComparator(
  Map<String, double> userExpenseRatios,   // category -> percentage
  Map<String, double> benchmarkRatios,     // category -> percentage
  { double flagTolerance = 5.0 }
)
```

A `const Map<String, double> nationalBenchmark` (category → typical percentage)
lives in this file as the default benchmark source.

Rules:
- `differences[c] = userExpenseRatios[c] - benchmarkRatios[c]` for every
  category present in either map (missing side treated as `0`).
- `overspendFlags` lists categories where
  `userExpenseRatios[c] > benchmarkRatios[c] + flagTolerance`.

---

## Data Models (`lib/frps/models/`)

Plain immutable Dart classes with `toJson()` / `fromJson()` (no Flutter
imports). Used by storage and reporting.

```dart
class User {
  final String id;
  final String name;
  final String? email;
  final UserProfile profile;
}

class UserProfile {
  final double monthlyIncome;
  final int age;
  // extended in later phases with expenses, debts, assets, liabilities
}

class Question {
  final String id;
  final String text;
  final QuestionType type; // multipleChoice | numeric | freeText
  final List<String>? options;
}

class QuestionResponse {
  final String userId;
  final String questionId;
  final dynamic answer;         // String, double, or structured map
  final DateTime answeredAt;
}

class FinancialSnapshot {
  final String userId;
  final DateTime date;
  final double income;
  final Map<String, double> expenses;
  final Map<String, double> assets;
  final Map<String, double> liabilities;
  final double monthlySavingsGoal;
}

class Report {
  final String userId;
  final DateTime date;
  final List<ReportSection> sections;
}

class ReportSection {
  final String title;   // Executive Summary | Expense Overview |
                        // Opportunities & Options | Progress & Motivation
  final String content;
}
```

`tool_outputs.dart` is a typed container for the six tool results fed into the
SLM and assembler. `Debt`/`DebtStrategy` are co-located in
`debt_payoff_planner.dart` and the `nationalBenchmark` constant in
`benchmark_comparator.dart`, so each tool file is fully self-contained.

---

## SLM Interface (`lib/frps/slm/`)

```dart
class ExtractedData {
  final String category;    // e.g. 'dining'
  final double amount;      // e.g. 200
  final String? raw;        // original free-text
}

abstract class SlmInterface {
  String generateReportNarrative({
    required ToolOutputs toolOutputs,
    required UserProfile userProfile,
  });

  ExtractedData parseFreeText(String answer);
}

class MockSlm implements SlmInterface { ... }
```

Rules:
- `generateReportNarrative` composes prose from `toolOutputs` using string
  templates. It contains NO arithmetic and no number that is not already in
  `toolOutputs` (formatting and rounding for display is allowed).
- `parseFreeText` uses rule-based patterns (regex for currency + frequency +
  keyword → category). Example: `"I spend $200/month on coffee"` →
  `ExtractedData(category: 'dining', amount: 200)`.
- `MockSlm` is the only concrete implementation in this version. A real model
  implements `SlmInterface` in a future phase.

---

## Adaptive Question Flow (`lib/frps/questions/`)

`question_catalog.dart` defines the ordered question list with types and
branching metadata. `question_flow.dart` owns the engine:

```dart
class QuestionFlow {
  Question? nextQuestion(List<QuestionResponse> previous);
  bool isComplete(List<QuestionResponse> previous);
}
```

Rules:
- Questions ask income, fixed expenses, savings goal, risk preference, primary
  financial goal, spending pressure, and — conditionally — debt details and
  asset/liability details.
- Branching: if the user reports debt, ask for each debt's balance, rate, and
  minimum payment; otherwise skip. If the user reports assets/liabilities, ask
  for their values.
- Free-text answers are passed to `SlmInterface.parseFreeText` and stored as
  structured `ExtractedData`; the resulting category/amount feeds the tools.

---

## Report Assembly (`lib/frps/reporting/`)

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

Produces four sections in order:
1. **Executive Summary** — key metrics (surplus, savings rate, net worth) +
   a headline benefit.
2. **Expense Overview** — category table data (from `budgetCalculator` +
   `benchmarkComparator`).
3. **Opportunities & Options** — actionable steps, each with quantified impact
   from the tools (e.g. "an extra $100/mo toward debt saves $X in interest").
4. **Progress & Motivation** — gamified elements (streak-style framing, savings
   projection milestone) from the tool outputs.

The assembler does not compute any new numbers; it selects and arranges values
already produced by the tools.

---

## Storage (`lib/frps/storage/`)

```dart
abstract class FrpsRepository {
  Future<void> saveUser(User user);
  Future<User?> getUser(String id);
  Future<void> saveResponse(QuestionResponse response);
  Future<List<QuestionResponse>> responsesFor(String userId);
  Future<void> saveSnapshot(FinancialSnapshot snapshot);
  Future<FinancialSnapshot?> latestSnapshot(String userId);
  Future<void> saveReport(Report report);
  Future<Report?> latestReport(String userId);
}
```

`SqliteStore` implements `FrpsRepository` with `sqflite`. All storage access is
async and behind this interface so a future backend can replace SQLite.

---

## Orchestrator (`lib/frps/report_planner.dart`)

```dart
class ReportPlanner {
  ReportPlanner({
    required FrpsRepository repository,
    required SlmInterface slm,
  });

  Future<Report> generateReport(String userId);
}
```

`generateReport` loads the user's profile and snapshots from the repository,
runs the six tools, calls `slm.generateReportNarrative`, assembles the report,
persists it, and returns it. This is the single entry point the app calls.

---

## Error Handling

- `budgetCalculator` and `cashFlowAnalyzer` handle zero/empty input gracefully
  (rates of `0`, no negative months) rather than throwing.
- `savingsProjector` handles `annualRate == 0` (no division by zero).
- `debtPayoffPlanner` throws `ArgumentError` on a debt with negative balance or
  non-positive minimum payment.
- `parseFreeText` returns `ExtractedData` with a sentinel `category` of
  `'unknown'` and `amount` of `0` when no rule matches, so the flow can re-ask
  rather than crash.

---

## Testing Requirements

Unit tests (via `flutter test`, pure-Dart, no widget tree):
- Each of the six tools has correct outputs on a happy path and at least one
  edge case (empty input, zero rate, overspend flag threshold, debt payoff
  order for both strategies).
- `MockSlm.generateReportNarrative` contains the numbers passed in and contains
  no computed value beyond formatting.
- `MockSlm.parseFreeText` extracts category + amount for the documented example
  and returns the `unknown` sentinel for unmatched text.
- `QuestionFlow` returns the debt questions only after a debt-confirming answer
  and reports completion correctly.
- `ReportAssembler` emits exactly four sections in the required order with
  correct titles.
- `SqliteStore` (or an in-memory fake of `FrpsRepository`) persists and returns
  users, responses, snapshots, and reports round-trip.

Widget/flow tests are out of scope for FRPS (the existing app's `widget_test.dart`
already covers app-level flow); FRPS is service-level and tested at that level.

---

## Build Order (Phases)

1. **Deterministic tools** — six pure functions + unit tests. No dependencies.
2. **Models + storage + orchestrator** — data classes, `FrpsRepository`,
   SQLite store, and `ReportPlanner` skeleton.
3. **Mock SLM** — `SlmInterface`, `MockSlm`, `parseFreeText`, narrative.
4. **Question flow** — catalog + adaptive engine + branching.
5. **Report assembly** — `ReportAssembler` producing the four sections, wiring
   the full flow end to end in `ReportPlanner`.

Phases 2–5 are planned in full but implemented after Phase 1, which is the
first deliverable.

---

## Future Extension Points

- Replace `MockSlm` with a real model behind `SlmInterface` (HF/local model).
- Replace `SqliteStore` with a remote backend behind `FrpsRepository`.
- Add cross-user analytics or cloud sync as a separate sub-project (requires
  consent flow, anonymization, and a hosted service — explicitly not part of
  this core).
- Wire `ReportPlanner` into the existing Flutter screens, replacing or
  augmenting the current `ReportGenerator`.
