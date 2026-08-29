# Task 10: Question Catalog + Flow

**Wave:** 3 (parallel). Pure Dart. Imports `models/question.dart` and
`models/question_response.dart` only. Does NOT call the SLM (free-text parsing
happens in the orchestrator).

**Files:**
- Create: `lib/frps/questions/question_catalog.dart`
- Create: `lib/frps/questions/question_flow.dart`
- Create: `test/frps/questions/question_flow_test.dart`

**Produces:**

```dart
// question_catalog.dart
const List<Question> questionCatalog = [
  Question(id: 'income', text: 'What is your monthly income?', type: QuestionType.numeric),
  Question(id: 'fixed-expenses', text: 'What are your fixed monthly expenses?', type: QuestionType.numeric),
  Question(id: 'savings-goal', text: 'What is your monthly savings goal?', type: QuestionType.numeric),
  Question(id: 'risk-preference', text: 'How do you feel about investment risk?', type: QuestionType.multipleChoice, options: ['conservative', 'balanced', 'growth']),
  Question(id: 'financial-goal', text: 'What is your primary financial goal?', type: QuestionType.multipleChoice, options: ['emergency fund', 'reduce spending', 'save for purchase', 'invest', 'debt control']),
  Question(id: 'spending-pressure', text: 'How much spending pressure do you feel?', type: QuestionType.multipleChoice, options: ['low', 'medium', 'high']),
  Question(id: 'has-debt', text: 'Do you currently have debt?', type: QuestionType.multipleChoice, options: ['yes', 'no']),
  Question(id: 'debt-details', text: 'Describe your debts (name, balance, interest rate, minimum payment).', type: QuestionType.freeText),
  Question(id: 'assets', text: 'Describe your assets and their values.', type: QuestionType.freeText),
  Question(id: 'liabilities', text: 'Describe your liabilities and their values.', type: QuestionType.freeText),
];
```

```dart
// question_flow.dart
class QuestionFlow {
  const QuestionFlow({List<Question> questions = questionCatalog}) : questions = questions;
  final List<Question> questions;

  Question? nextQuestion(List<QuestionResponse> previous);
  bool isComplete(List<QuestionResponse> previous);
}
```

**Rules (spec §Adaptive Question Flow):**
- Questions are asked in catalog order.
- `debt-details` is skipped unless the `has-debt` response answer is `'yes'`.
- `nextQuestion` returns the first not-yet-answered question (respecting the
  skip); `null` when all applicable questions are answered.
- `isComplete` is `true` iff `nextQuestion` returns `null`.

- [ ] **Step 1: Write the failing test**

Create `test/frps/questions/question_flow_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/models/question.dart';
import 'package:moneymoneymoney/frps/models/question_response.dart';
import 'package:moneymoneymoney/frps/questions/question_flow.dart';

QuestionResponse answer(String userId, String questionId, dynamic value) =>
    QuestionResponse(
      userId: userId,
      questionId: questionId,
      answer: value,
      answeredAt: DateTime(2026, 1, 1),
    );

List<QuestionResponse> answerFlow(QuestionFlow flow, String hasDebt) {
  final responses = <QuestionResponse>[];
  Question? q;
  while ((q = flow.nextQuestion(responses)) != null) {
    dynamic value;
    if (q.id == 'has-debt') {
      value = hasDebt;
    } else if (q.type == QuestionType.multipleChoice) {
      value = q.options!.first;
    } else if (q.type == QuestionType.numeric) {
      value = 100.0;
    } else {
      value = 'free text';
    }
    responses.add(answer('u', q.id, value));
  }
  return responses;
}

void main() {
  test('starts with the income question', () {
    final flow = QuestionFlow();
    expect(flow.nextQuestion(const [])!.id, 'income');
  });

  test('no-debt path skips debt details and completes', () {
    final flow = QuestionFlow();
    final responses = answerFlow(flow, 'no');
    expect(responses.map((r) => r.questionId), isNot(contains('debt-details')));
    expect(flow.isComplete(responses), isTrue);
    expect(flow.nextQuestion(responses), isNull);
  });

  test('debt path asks debt details', () {
    final flow = QuestionFlow();
    final responses = answerFlow(flow, 'yes');
    expect(responses.map((r) => r.questionId), contains('debt-details'));
    expect(flow.isComplete(responses), isTrue);
  });

  test('partial answers are not complete', () {
    final flow = QuestionFlow();
    const responses = [
      QuestionResponse(userId: 'u', questionId: 'income', answer: 6000.0, answeredAt: null),
    ];
    // QuestionResponse requires a DateTime; use a real one instead.
    final real = [
      answer('u', 'income', 6000.0),
    ];
    expect(flow.isComplete(real), isFalse);
    expect(flow.nextQuestion(real)!.id, 'fixed-expenses');
  });
}
```

- [ ] **Step 2: Run and verify RED**

`flutter test test/frps/questions/question_flow_test.dart`
Expected: FAIL — files do not exist.

- [ ] **Step 3: Implement**

Implement both files. Note the last test in the block has a
`const`-with-`null`-DateTime mistake by design; replace it with the `real`
list (using `answer(...)`) so it compiles — `QuestionResponse.answeredAt` is
non-nullable `DateTime`.

- [ ] **Step 4: Run and verify GREEN**

`flutter test test/frps/questions/question_flow_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/frps/questions test/frps/questions/question_flow_test.dart
git commit -m "feat(frps): add adaptive question flow"
```
