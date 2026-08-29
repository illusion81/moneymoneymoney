# Task 13: ReportPlanner Orchestrator

**Wave:** 4 (runs after everything else). Imports the six tools, `models`,
`slm`, `storage`, and `reporting`. This is where tools and SLM meet.

**Files:**
- Create: `lib/frps/report_planner.dart`
- Create: `test/frps/report_planner_test.dart`

**Produces:**

```dart
class ReportPlanner {
  ReportPlanner({required FrpsRepository repository, required SlmInterface slm});
  Future<Report> generateReport(String userId);
}
```

**`generateReport` pipeline (spec §Orchestrator):**
1. `user = await repository.getUser(userId)`; throw `StateError` if null.
2. `snapshot = await repository.latestSnapshot(userId)`; throw `StateError` if null.
3. `budget = budgetCalculator(snapshot.income, snapshot.expenses)`.
4. `netWorth = netWorthTracker(snapshot.assets, snapshot.liabilities)`.
5. `cashFlow = cashFlowAnalyzer([snapshot.income], [sum of snapshot.expenses values])`.
6. `savings = savingsProjector(currentSavings: snapshot.assets['savings'] ?? 0.0, monthlyContribution: snapshot.monthlySavingsGoal, annualRate: 0.05, years: 10)`.
7. `benchmark = benchmarkComparator(budget.categoryPercentages, nationalBenchmark)`.
8. `debtPlan = debtPayoffPlanner(const [], startDate: snapshot.date)` (debt list is
   empty for the MVP; the debt planner is already fully tested in isolation).
9. Build `ToolOutputs` from steps 3–8.
10. `narrative = slm.generateReportNarrative(toolOutputs: ..., userProfile: user.profile)`.
11. `report = ReportAssembler().assemble(toolOutputs, narrative, userId, snapshot.date)`.
12. `await repository.saveReport(report)` and return `report`.

- [ ] **Step 1: Write the failing test**

Create `test/frps/report_planner_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/models/financial_snapshot.dart';
import 'package:moneymoneymoney/frps/models/question_response.dart';
import 'package:moneymoneymoney/frps/models/report.dart';
import 'package:moneymoneymoney/frps/models/user.dart';
import 'package:moneymoneymoney/frps/models/user_profile.dart';
import 'package:moneymoneymoney/frps/report_planner.dart';
import 'package:moneymoneymoney/frps/slm/mock_slm.dart';
import 'package:moneymoneymoney/frps/storage/repository.dart';

class FakeRepository implements FrpsRepository {
  final Map<String, User> users = {};
  final Map<String, List<QuestionResponse>> responses = {};
  final Map<String, List<FinancialSnapshot>> snapshots = {};
  final Map<String, List<Report>> reports = {};

  @override
  Future<void> saveUser(User user) async => users[user.id] = user;
  @override
  Future<User?> getUser(String id) async => users[id];
  @override
  Future<void> saveResponse(QuestionResponse response) async =>
      responses.putIfAbsent(response.userId, () => []).add(response);
  @override
  Future<List<QuestionResponse>> responsesFor(String userId) async =>
      responses[userId] ?? const [];
  @override
  Future<void> saveSnapshot(FinancialSnapshot snapshot) async =>
      snapshots.putIfAbsent(snapshot.userId, () => []).add(snapshot);
  @override
  Future<FinancialSnapshot?> latestSnapshot(String userId) async {
    final list = snapshots[userId] ?? const [];
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  @override
  Future<void> saveReport(Report report) async =>
      reports.putIfAbsent(report.userId, () => []).add(report);
  @override
  Future<Report?> latestReport(String userId) async {
    final list = reports[userId] ?? const [];
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }
}

void main() {
  test('generates and persists a four-section report', () async {
    final repo = FakeRepository();
    await repo.saveUser(const User(
      id: 'u1',
      name: 'Ada',
      profile: UserProfile(monthlyIncome: 6000, age: 34),
    ));
    await repo.saveSnapshot(FinancialSnapshot(
      userId: 'u1',
      date: DateTime(2026, 8, 29),
      income: 6000,
      expenses: {'housing': 1500, 'food': 800},
      assets: {'savings': 5000},
      liabilities: {'card': 1200},
      monthlySavingsGoal: 900,
    ));

    final planner = ReportPlanner(repository: repo, slm: MockSlm());
    final report = await planner.generateReport('u1');

    expect(
      report.sections.map((s) => s.title).toList(),
      ['Executive Summary', 'Expense Overview', 'Opportunities & Options', 'Progress & Motivation'],
    );
    expect((await repo.latestReport('u1'))!.sections, hasLength(4));
  });

  test('throws when the user or snapshot is missing', () async {
    final planner = ReportPlanner(repository: FakeRepository(), slm: MockSlm());
    await expectLater(planner.generateReport('nope'), throwsStateError);
  });
}
```

- [ ] **Step 2: Run and verify RED**

`flutter test test/frps/report_planner_test.dart`
Expected: FAIL — file does not exist.

- [ ] **Step 3: Implement**

Implement `ReportPlanner` per the interface and pipeline. Import the six tools
from `financial_tools/`, `nationalBenchmark` from `benchmark_comparator.dart`,
`ReportAssembler` from `reporting/`, and the models/SLM/storage interfaces.

- [ ] **Step 4: Run and verify GREEN**

`flutter test test/frps/report_planner_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/frps/report_planner.dart test/frps/report_planner_test.dart
git commit -m "feat(frps): add report planner orchestrator"
```
