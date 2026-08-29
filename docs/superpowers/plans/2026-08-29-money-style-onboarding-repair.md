# Money Style Onboarding Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the 12-question Money Style experience the honest, resilient first-run onboarding, preserve behavioural answers separately from financial facts, and provide real opt-in next steps.

**Architecture:** `MoneyStyleFlow` becomes the initial app view. The quiz produces a `MoneyStyleCompletion` containing the raw answer session and an optional result; an archetype is only generated after every dimension has at least one answered item. A dedicated `/api/money-style` contract stores raw behavioural answers independently from the existing `/api/survey` financial-planning contract. Result actions route to real style ideas and range-first planning screens; exact-number planning remains explicitly optional.

**Tech Stack:** Flutter/Dart, Material 3, `http`, `shared_preferences`, FastAPI/Pydantic, Python `unittest`, Flutter widget/unit tests.

---

## Scope and non-negotiable boundaries

- Money Style answers must never be converted into income, debt, hardship, risk appetite, emergency-fund status, or investment allocation.
- `/api/survey` remains the exact-financial-input contract. `/api/money-style` is a separate behavioural-reflection contract.
- Zero answers, or answers that leave any dimension unobserved, must not produce an archetype.
- The 12 questions remain draft product content. Do not claim psychometric, clinical, or financial validity.
- Do not modify or commit `.claude/settings.json`.
- Do not perform unrelated visual redesigns or refactors.

## File responsibility map

- `lib/models/money_style.dart`: typed question, session, completion, result, serialization models.
- `lib/services/money_style_engine.dart`: deterministic scoring and insufficient-evidence gate only.
- `lib/services/money_style_repository.dart`: local JSON persistence for the in-progress/completed session.
- `lib/data/money_style_questions.dart`: draft content and stable answer IDs/pole mappings.
- `lib/data/models.dart`: Dart mirrors for the new backend Money Style contract.
- `lib/data/api_client.dart`: `/api/money-style` transport.
- `lib/screens/money_style_flow.dart`: disclosure/entry and resume behavior.
- `lib/screens/money_style_quiz_screen.dart`: question presentation, deterministic answer-order randomization, answer/skip/back behavior.
- `lib/screens/money_style_result_screen.dart`: qualified result or insufficient-evidence state plus real callbacks.
- `lib/screens/money_style_ideas_screen.dart`: strengths-led, non-prescriptive style ideas.
- `lib/screens/plan_range_screen.dart`: range-first optional planning intake and explicit exact-number handoff.
- `lib/screens/onboarding_screen.dart`: legacy exact-number form, relabelled as an optional calculation step.
- `lib/main.dart`: app-view orchestration and dependency injection.
- `backend,dataAPI/models.py`: Pydantic request/response contract.
- `backend,dataAPI/main.py`: store/retrieve Money Style submission without changing financial profile.
- `backend,dataAPI/store.py`: add `money_style` state slot.
- `backend,dataAPI/docs/API.md`: document the new endpoints and separation boundary.

### Task 1: Add the insufficient-evidence scoring contract

**Files:**
- Modify: `lib/models/money_style.dart`
- Modify: `lib/services/money_style_engine.dart`
- Test: `test/money_style_engine_test.dart`

- [ ] **Step 1: Write failing tests for dimension coverage and completion**

Add tests with these exact expectations:

```dart
test('returns null when no answers are present', () {
  final session = AnswerSession(userId: 'u', sessionId: 's');
  expect(engine.generateResult(session, moneyStyleQuestions), isNull);
});

test('returns null when any dimension has no answered item', () {
  final session = AnswerSession(
    userId: 'u',
    sessionId: 's',
    selectedAnswers: {1: 0, 2: 1, 3: 0},
  );
  expect(engine.generateResult(session, moneyStyleQuestions), isNull);
});

test('returns early snapshot after all dimensions are observed', () {
  final session = AnswerSession(
    userId: 'u',
    sessionId: 's',
    selectedAnswers: {1: 0, 3: 1, 4: 1},
  );
  final result = engine.generateResult(session, moneyStyleQuestions);
  expect(result, isNotNull);
  expect(result!.confidenceTier, ConfidenceTier.earlySnapshot);
});
```

- [ ] **Step 2: Run the focused test and verify failure**

Run: `flutter test test/money_style_engine_test.dart`

Expected: compile/assertion failure because `generateResult` still returns a non-null `MoneyStyleResult` for insufficient evidence.

- [ ] **Step 3: Introduce `MoneyStyleCompletion` and nullable result generation**

Add to `lib/models/money_style.dart`:

```dart
class MoneyStyleCompletion {
  const MoneyStyleCompletion({required this.session, required this.result});

  final AnswerSession session;
  final MoneyStyleResult? result;

  bool get hasEnoughEvidence => result != null;
}
```

In `MoneyStyleEngine`, add a dimension-coverage helper and change the return type:

```dart
bool hasMinimumDimensionCoverage(
  AnswerSession session,
  List<MoneyStyleQuestion> questions,
) {
  final observed = <Dimension>{};
  for (final entry in session.selectedAnswers.entries) {
    final question = questions.where((q) => q.id == entry.key).firstOrNull;
    if (question == null || entry.value < 0 || entry.value >= question.answers.length) {
      continue;
    }
    observed.add(question.answers[entry.value].dimension);
  }
  return observed.length == Dimension.values.length;
}

MoneyStyleResult? generateResult(
  AnswerSession session,
  List<MoneyStyleQuestion> questions,
) {
  if (!hasMinimumDimensionCoverage(session, questions)) return null;
  // Existing scoring, tie-breaking, mapping, and confidence logic follows.
}
```

Do not add a collection package solely for `firstOrNull`; implement a small loop or local lookup so the project remains dependency-light.

- [ ] **Step 4: Update existing result tests for the nullable return type**

Use `result!` only after an explicit `expect(result, isNotNull)`. Remove any test that treats an empty session returning an archetype as acceptable.

- [ ] **Step 5: Run focused tests**

Run: `flutter test test/money_style_engine_test.dart`

Expected: all Money Style engine tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/models/money_style.dart lib/services/money_style_engine.dart test/money_style_engine_test.dart
git commit -m "fix: prevent unsupported money style results"
```

### Task 2: Balance draft mappings and randomize presentation safely

**Files:**
- Modify: `lib/models/money_style.dart`
- Modify: `lib/data/money_style_questions.dart`
- Modify: `lib/screens/money_style_quiz_screen.dart`
- Test: `test/money_style_questions_test.dart`
- Test: `test/money_style_quiz_screen_test.dart`

- [ ] **Step 1: Add failing structural tests for the question bank**

Create `test/money_style_questions_test.dart` with checks that:

```dart
test('contains four items per dimension', () {
  for (final dimension in Dimension.values) {
    expect(
      moneyStyleQuestions.where((q) => q.dimension == dimension),
      hasLength(4),
    );
  }
});

test('balances pole opportunities within each dimension', () {
  expect(countPole(MoneyRhythmPole.steady), countPole(MoneyRhythmPole.responsive));
  expect(countPole(DecisionStylePole.pause), countPole(DecisionStylePole.momentum));
  expect(countPole(SupportStylePole.selfDirected), countPole(SupportStylePole.collaborative));
});

test('uses stable answer ids', () {
  for (final question in moneyStyleQuestions) {
    expect(question.answers.map((a) => a.id).toSet(), hasLength(3));
  }
});
```

Add `dimension` directly to `MoneyStyleQuestion`; all answers in one question must share it. Add a stable string `id` to every `MoneyStyleAnswer`, such as `q01_plan`, `q01_adjust`, and `q01_enjoy`.

- [ ] **Step 2: Run the question tests and verify failure**

Run: `flutter test test/money_style_questions_test.dart`

Expected: compile failure because question dimension and answer IDs do not exist, followed by balance failures after the types are added.

- [ ] **Step 3: Rewrite the draft question bank to the approved scenario briefs**

Use the 12 scenes in `docs/superpowers/specs/2026-08-29-money-style-questionnaire-handoff.md` section 6. Every prompt must be `What feels closest to your first move?` or an equally non-evaluative `What feels closest?`. Remove assumptions that the user has increasing income, a car, a home purchase, savings, a partner, family help, a coach, or disposable travel money.

Across each four-question dimension, use this pole-count pattern so the total answer opportunities are 6/6:

```text
Item A: pole 1, pole 1, pole 2
Item B: pole 1, pole 2, pole 2
Item C: pole 1, pole 1, pole 2
Item D: pole 1, pole 2, pole 2
```

Rotate which textual position carries each pole; do not make the most socially approved answer consistently first. Keep Q2, Q8, and Q11 as declared tie-break items only if their rewritten dimension matches the tie-breaker they serve; otherwise move the tie-break marker to one item within the correct dimension and update engine tests.

- [ ] **Step 4: Add deterministic display-order randomization without changing stored answer identity**

Change the quiz constructor to accept an optional test seed:

```dart
const MoneyStyleQuizScreen({
  super.key,
  required this.userId,
  required this.onComplete,
  this.answerOrderSeed,
});

final int? answerOrderSeed;
final ValueChanged<MoneyStyleCompletion> onComplete;
```

Build a `Map<int, List<int>>` once in `initState`, shuffling original answer indices with `Random(answerOrderSeed ?? sessionId.hashCode)`. Render by original index and keep `selectedAnswers[questionId]` as the original index.

- [ ] **Step 5: Add widget tests for stable scoring under shuffled presentation**

Pump two quizzes with different seeds. Assert that the first visible answer differs for at least one question, then select the answer with stable ID `q01_plan` in both and assert the stored original answer identity produces the same pole/result.

- [ ] **Step 6: Run question and quiz tests**

Run: `flutter test test/money_style_questions_test.dart test/money_style_quiz_screen_test.dart`

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/models/money_style.dart lib/data/money_style_questions.dart lib/screens/money_style_quiz_screen.dart test/money_style_questions_test.dart test/money_style_quiz_screen_test.dart
git commit -m "fix: balance and randomize money style questions"
```

### Task 3: Add a separate backend Money Style contract

**Files:**
- Modify: `backend,dataAPI/models.py`
- Modify: `backend,dataAPI/store.py`
- Modify: `backend,dataAPI/main.py`
- Modify: `backend,dataAPI/docs/API.md`
- Create: `backend,dataAPI/test_money_style_api.py`

- [ ] **Step 1: Write failing API tests**

Create a `unittest.TestCase` using `fastapi.testclient.TestClient`:

```python
VALID = {
    "session_id": "session-1",
    "question_version": "money-style-v1",
    "selected_answers": {"1": "q01_plan", "3": "q03_pause", "4": "q04_talk"},
    "skipped_question_ids": [2, 5, 6, 7, 8, 9, 10, 11, 12],
    "answered_count": 3,
    "confidence_tier": "early_snapshot",
    "archetype_id": "steady_pause_collaborative",
}

class MoneyStyleApiTest(unittest.TestCase):
    def setUp(self):
        store.reset()
        self.client = TestClient(app)

    def test_submission_does_not_create_financial_profile(self):
        response = self.client.post("/api/money-style", json=VALID)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(self.client.get("/api/profile").status_code, 409)

    def test_round_trip(self):
        saved = self.client.post("/api/money-style", json=VALID).json()
        loaded = self.client.get("/api/money-style").json()
        self.assertEqual(loaded, saved)

    def test_answer_count_must_match(self):
        invalid = {**VALID, "answered_count": 12}
        self.assertEqual(self.client.post("/api/money-style", json=invalid).status_code, 422)
```

- [ ] **Step 2: Run the backend test and verify failure**

Run from `backend,dataAPI` after installing its declared requirements in an isolated environment:

```bash
python3 -m unittest test_money_style_api.py -v
```

Expected: FAIL because the models and routes do not exist.

- [ ] **Step 3: Add Pydantic models and validation**

Add these shapes to `models.py`:

```python
ConfidenceTierName = Literal["early_snapshot", "standard", "full_clarity"]

class MoneyStyleSubmission(BaseModel):
    session_id: str = Field(..., min_length=1)
    question_version: str = Field(..., min_length=1)
    selected_answers: dict[int, str]
    skipped_question_ids: list[int]
    answered_count: int = Field(..., ge=0, le=12)
    confidence_tier: Optional[ConfidenceTierName] = None
    archetype_id: Optional[str] = None

    @model_validator(mode="after")
    def validate_counts(self) -> "MoneyStyleSubmission":
        if self.answered_count != len(self.selected_answers):
            raise ValueError("answered_count must match selected_answers")
        if set(self.selected_answers).intersection(self.skipped_question_ids):
            raise ValueError("a question cannot be answered and skipped")
        if any(question_id < 1 or question_id > 12 for question_id in self.selected_answers):
            raise ValueError("question ids must be between 1 and 12")
        return self
```

- [ ] **Step 4: Store Money Style independently and add routes**

Add `"money_style": None` to `store.user`. Add:

```python
@app.post("/api/money-style", response_model=MoneyStyleSubmission)
def submit_money_style(submission: MoneyStyleSubmission) -> MoneyStyleSubmission:
    store.user(UID)["money_style"] = submission
    return submission

@app.get("/api/money-style", response_model=MoneyStyleSubmission)
def get_money_style() -> MoneyStyleSubmission:
    submission = store.user(UID)["money_style"]
    if submission is None:
        raise HTTPException(404, "No Money Style submission yet.")
    return submission
```

Do not call `build_profile` and do not mutate `store.user(UID)["profile"]` in these routes.

- [ ] **Step 5: Document the contract boundary**

Add both endpoints to `docs/API.md` and explicitly state: Money Style is behavioural reflection only; financial allocations, plans, and missions require separate, user-provided financial facts through `/api/survey` or bank data.

- [ ] **Step 6: Run backend tests**

Run: `python3 -m unittest test_money_style_api.py -v`

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add 'backend,dataAPI/models.py' 'backend,dataAPI/store.py' 'backend,dataAPI/main.py' 'backend,dataAPI/docs/API.md' 'backend,dataAPI/test_money_style_api.py'
git commit -m "feat: add separate money style API contract"
```

### Task 4: Add Dart transport and local persistence

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/data/models.dart`
- Modify: `lib/data/api_client.dart`
- Create: `lib/services/money_style_repository.dart`
- Test: `test/money_style_repository_test.dart`
- Test: `test/api_client_money_style_test.dart`

- [ ] **Step 1: Add `shared_preferences`**

Run: `flutter pub add shared_preferences`

Expected: `pubspec.yaml` and `pubspec.lock` update without unrelated dependency upgrades.

- [ ] **Step 2: Write failing serialization and HTTP tests**

Test that a completion round-trips through `MoneyStyleRepository`, preserving stable answer IDs, skips, and result metadata. With a mock `http.Client`, assert `submitMoneyStyle` posts to `/api/money-style`, uses `application/json`, and never includes `monthly_income`, `fixed_costs`, `risk_appetite`, or `top_worry`.

The expected JSON shape is:

```json
{
  "session_id": "session-1",
  "question_version": "money-style-v1",
  "selected_answers": {"1": "q01_plan"},
  "skipped_question_ids": [2],
  "answered_count": 1,
  "confidence_tier": null,
  "archetype_id": null
}
```

- [ ] **Step 3: Run tests and verify failure**

Run: `flutter test test/money_style_repository_test.dart test/api_client_money_style_test.dart`

Expected: compile failure because repository/model/API methods do not exist.

- [ ] **Step 4: Implement the Dart backend mirror**

Add `MoneyStyleSubmission` to `lib/data/models.dart` with `toJson` and `fromJson`. Build it from `MoneyStyleCompletion` using stable answer IDs from the question bank. Use snake-case confidence names matching Python.

Add to `ApiClient`:

```dart
Future<MoneyStyleSubmission> submitMoneyStyle(MoneyStyleSubmission value) async =>
    MoneyStyleSubmission.fromJson(
      await _getObjFromPost('/api/money-style', value.toJson()),
    );
```

If no `_getObjFromPost` helper exists, call `_send('POST', ...)` directly and cast once, following `submitSurvey`.

- [ ] **Step 5: Implement local persistence**

Use one key, `money_style_completion_v1`. Repository methods:

```dart
abstract interface class MoneyStyleStore {
  Future<void> save(MoneyStyleCompletion completion);
  Future<MoneyStyleCompletion?> load();
  Future<void> clear();
}
```

`SharedPreferencesMoneyStyleRepository` must encode/decode JSON and return `null`, not throw, for malformed or unsupported stored data. Include a `schemaVersion: 1` field.

- [ ] **Step 6: Run focused tests**

Run: `flutter test test/money_style_repository_test.dart test/api_client_money_style_test.dart`

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/data/models.dart lib/data/api_client.dart lib/services/money_style_repository.dart test/money_style_repository_test.dart test/api_client_money_style_test.dart
git commit -m "feat: persist and sync money style answers"
```

### Task 5: Make Money Style the first-run experience

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/screens/money_style_flow.dart`
- Modify: `lib/screens/money_style_quiz_screen.dart`
- Modify: `lib/screens/onboarding_screen.dart`
- Test: `test/widget_test.dart`
- Test: `test/money_style_flow_test.dart`

- [ ] **Step 1: Write failing first-run and disclosure tests**

Replace the old first-screen assertion with:

```dart
testWidgets('first app screen earns trust before asking for numbers', (tester) async {
  await tester.pumpWidget(const MyApp());
  expect(find.text('Discover Your Money Style'), findsOneWidget);
  expect(find.textContaining('2–3 minutes'), findsOneWidget);
  expect(find.textContaining('not financial, mental-health, or clinical advice'), findsOneWidget);
  expect(find.text('Monthly income'), findsNothing);
  expect(find.text('Find My Style'), findsOneWidget);
});
```

Add a flow test proving an existing local session offers `Resume` and `Start over`, while a new session offers `Find My Style`.

- [ ] **Step 2: Run tests and verify failure**

Run: `flutter test test/widget_test.dart test/money_style_flow_test.dart`

Expected: first-run test finds the legacy `Money Profile` screen and fails.

- [ ] **Step 3: Change app orchestration**

Set `_view = AppView.moneyStyleFlow`. Inject `ApiClient` and `MoneyStyleStore` through optional `MyApp` constructor parameters so tests can use fakes. Change completion callbacks to `ValueChanged<MoneyStyleCompletion>`.

On completion:

```dart
Future<void> _handleMoneyStyleComplete(MoneyStyleCompletion completion) async {
  await _moneyStyleStore.save(completion);
  if (mounted) {
    setState(() {
      _moneyStyleCompletion = completion;
      _view = AppView.moneyStyleResult;
    });
  }
  unawaited(_syncMoneyStyle(completion));
}
```

Backend sync failure must not block the result. Record it with `debugPrint`; do not tell the user that a server save succeeded when it did not.

- [ ] **Step 4: Correct entry copy and resume behavior**

The entry screen must show exactly these trust elements:

```text
Discover Your Money Style
Twelve everyday choices. No dollar amounts. No judgement.
About 2–3 minutes
A light reflection on your current habits — not financial, mental-health, or clinical advice.
```

Replace “reveal how you approach money in your own unique way” with “Notice the patterns that feel closest today. Your result can change as life changes.”

- [ ] **Step 5: Relabel the legacy form as optional exact-number planning**

Change its heading to `Build an exact-number plan` and add: `Optional: these amounts are used to calculate a daily budget. You can go back and keep using your Money Style result without sharing them.` Remove `Money Profile`, `risk preference`, and `recent spending pressure` from the first-run path; they may remain inside this explicit optional form until later product validation.

- [ ] **Step 6: Run focused tests**

Run: `flutter test test/widget_test.dart test/money_style_flow_test.dart test/money_style_quiz_screen_test.dart`

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/main.dart lib/screens/money_style_flow.dart lib/screens/money_style_quiz_screen.dart lib/screens/onboarding_screen.dart test/widget_test.dart test/money_style_flow_test.dart test/money_style_quiz_screen_test.dart
git commit -m "feat: make money style the primary onboarding"
```

### Task 6: Replace fabricated and dead-end results with real next steps

**Files:**
- Modify: `lib/screens/money_style_result_screen.dart`
- Create: `lib/screens/money_style_ideas_screen.dart`
- Create: `lib/screens/plan_range_screen.dart`
- Modify: `lib/main.dart`
- Test: `test/money_style_result_screen_test.dart`
- Test: `test/plan_range_screen_test.dart`

- [ ] **Step 1: Write failing result-state tests**

Test two states:

```dart
testWidgets('insufficient evidence invites more answers without archetype claims', (tester) async {
  await pumpResult(tester, completionWithNoResult);
  expect(find.text('Not enough to name a style yet'), findsOneWidget);
  expect(find.text('The Calm Comparator'), findsNothing);
  expect(find.text('Answer a few more'), findsOneWidget);
});

testWidgets('early snapshot qualifies the result', (tester) async {
  await pumpResult(tester, earlyCompletion);
  expect(find.textContaining('Based on what you shared today'), findsOneWidget);
});
```

Also assert both result actions invoke callbacks rather than showing “coming soon”.

- [ ] **Step 2: Run tests and verify failure**

Run: `flutter test test/money_style_result_screen_test.dart test/plan_range_screen_test.dart`

Expected: compile/assertion failure because callbacks and screens do not exist.

- [ ] **Step 3: Implement the two result states**

Change the screen contract:

```dart
const MoneyStyleResultScreen({
  super.key,
  required this.completion,
  required this.onAnswerMore,
  required this.onExploreIdeas,
  required this.onBuildRangePlan,
});
```

For `completion.result == null`, render no archetype, strengths, pattern, or dimension claims. Show the answered count, explain that each area needs at least one answer, and provide `Answer a few more` plus `Start over`/back behavior.

For early/standard results, add the qualifiers required by the specification. Do not show “Full Clarity” language.

- [ ] **Step 4: Implement strengths-led ideas**

`MoneyStyleIdeasScreen` accepts an `ArchetypeInfo` and displays three reversible, non-financial-product ideas keyed to the three dimensions, for example: a reminder cadence, a compare-before-deciding note, and a preferred check-in style. Use language such as `You could try`, never `You should`, and include `These are optional prompts, not financial advice.`

- [ ] **Step 5: Implement range-first planning**

`PlanRangeScreen` collects only:

```dart
enum IncomeRange { under2500, from2500To5000, from5000To8000, over8000, preferNotToSay }
enum FixedCostShareRange { underHalf, aboutHalf, overHalf, unsure, preferNotToSay }
enum PlanningPriority { breathingRoom, upcomingCost, reduceSpending, debtOrganisation, explore }
```

Show a factual summary of the selected ranges without calculating exact dollar targets. Provide two exits:

- `Keep this range-based snapshot` returns to the Money Style result.
- `Use exact numbers for a daily calculation` opens the legacy optional form.

Never convert ranges to hidden midpoint amounts and never submit them to `/api/survey`.

- [ ] **Step 6: Wire real navigation in `main.dart`**

Add app views for ideas and range planning. Pass callbacks into the result screen. The exact-number form remains reachable only through the range screen’s explicit action.

- [ ] **Step 7: Run focused tests**

Run: `flutter test test/money_style_result_screen_test.dart test/plan_range_screen_test.dart test/widget_test.dart`

Expected: all tests pass and no `coming soon` result actions remain.

- [ ] **Step 8: Commit**

```bash
git add lib/main.dart lib/screens/money_style_result_screen.dart lib/screens/money_style_ideas_screen.dart lib/screens/plan_range_screen.dart test/money_style_result_screen_test.dart test/plan_range_screen_test.dart test/widget_test.dart
git commit -m "feat: add honest money style next steps"
```

### Task 7: Add end-to-end coverage and verify the product boundary

**Files:**
- Modify: `test/widget_test.dart`
- Modify: `test/api_client_money_style_test.dart`
- Modify: `backend,dataAPI/test_money_style_api.py`

- [ ] **Step 1: Add the critical integration tests**

Cover these paths:

1. First run shows Money Style, never exact financial inputs.
2. Skipping all questions produces no archetype and offers more answers.
3. Answering at least one question from each dimension produces an early snapshot.
4. Completion persists locally before backend sync is attempted.
5. The Money Style request contains answer IDs and skips but no financial facts.
6. Money Style API submission leaves `/api/profile` absent.
7. Range planning never submits `/api/survey`.
8. Choosing exact-number calculation explicitly opens the legacy form.

- [ ] **Step 2: Run formatting and static analysis**

Run:

```bash
dart format lib test
flutter analyze
```

Expected: formatting completes and analysis reports `No issues found!`.

- [ ] **Step 3: Run all Flutter tests**

Run: `flutter test`

Expected: all tests pass with no uncaught async backend errors.

- [ ] **Step 4: Run all backend tests**

Run from `backend,dataAPI`:

```bash
python3 -m unittest discover -p 'test_*.py' -v
```

Expected: all backend tests pass.

- [ ] **Step 5: Build and visually inspect the web app**

Run:

```bash
flutter build web
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8127
```

Verify at desktop and narrow mobile viewport:

- Entry disclosure is visible without scrolling on a typical phone.
- All answer buttons and Skip/Next controls remain reachable.
- All-skip result makes no archetype claim.
- A valid early result is qualified.
- Ideas and range planning navigate successfully.
- Exact numbers appear only after explicit opt-in.
- No console errors occur across the flow.

- [ ] **Step 6: Confirm the worktree contains only intended changes**

Run:

```bash
git status --short
git diff --check
```

Expected: `.claude/settings.json` remains untouched by this work; no whitespace errors or unrelated files are included.

- [ ] **Step 7: Commit final integration coverage**

```bash
git add test/widget_test.dart test/api_client_money_style_test.dart 'backend,dataAPI/test_money_style_api.py'
git commit -m "test: cover money style onboarding end to end"
```

## Definition of done

- The app opens on the Money Style trust/disclosure screen.
- A user can skip freely without receiving a fabricated result.
- Answer display order is randomized while scoring remains stable.
- Draft item mappings are structurally balanced and do not rely on privileged financial circumstances.
- Raw Money Style answers persist locally and sync through their own API contract.
- Behavioural answers do not create or mutate a financial profile.
- Both result actions lead somewhere useful.
- Range planning does not invent exact amounts.
- Exact-number planning requires explicit opt-in.
- Flutter analysis, full Flutter tests, backend tests, web build, and rendered desktop/mobile checks pass.

