# Task 7: Domain Models

**Wave:** 1 (parallel). Pure Dart. No Flutter imports. No dependencies on other
tasks (does NOT import `financial_tools/`; `ToolOutputs` is Task 8).

**Files:**
- Create: `lib/frps/models/user.dart`
- Create: `lib/frps/models/user_profile.dart`
- Create: `lib/frps/models/question.dart`
- Create: `lib/frps/models/question_response.dart`
- Create: `lib/frps/models/financial_snapshot.dart`
- Create: `lib/frps/models/report.dart`
- Create: `test/frps/models/models_test.dart`

**Produces (exact interfaces later tasks rely on):**

```dart
// user_profile.dart
class UserProfile {
  const UserProfile({required this.monthlyIncome, required this.age});
  final double monthlyIncome;
  final int age;
  Map<String, dynamic> toJson();
  static UserProfile fromJson(Map<String, dynamic> json);
}

// user.dart
class User {
  const User({required this.id, required this.name, this.email, required this.profile});
  final String id;
  final String name;
  final String? email;
  final UserProfile profile;
  Map<String, dynamic> toJson();
  static User fromJson(Map<String, dynamic> json);
}

// question.dart
enum QuestionType { multipleChoice, numeric, freeText }

class Question {
  const Question({required this.id, required this.text, required this.type, this.options});
  final String id;
  final String text;
  final QuestionType type;
  final List<String>? options; // only for multipleChoice
}

// question_response.dart
class QuestionResponse {
  const QuestionResponse({
    required this.userId,
    required this.questionId,
    required this.answer,
    required this.answeredAt,
  });
  final String userId;
  final String questionId;
  final dynamic answer; // String, double, or bool
  final DateTime answeredAt;
  Map<String, dynamic> toJson();
  static QuestionResponse fromJson(Map<String, dynamic> json);
}

// financial_snapshot.dart
class FinancialSnapshot {
  const FinancialSnapshot({
    required this.userId,
    required this.date,
    required this.income,
    required this.expenses,
    required this.assets,
    required this.liabilities,
    required this.monthlySavingsGoal,
  });
  final String userId;
  final DateTime date;
  final double income;
  final Map<String, double> expenses;
  final Map<String, double> assets;
  final Map<String, double> liabilities;
  final double monthlySavingsGoal;
  Map<String, dynamic> toJson();
  static FinancialSnapshot fromJson(Map<String, dynamic> json);
}

// report.dart
class ReportSection {
  const ReportSection({required this.title, required this.content});
  final String title;
  final String content;
  Map<String, dynamic> toJson();
  static ReportSection fromJson(Map<String, dynamic> json);
}

class Report {
  const Report({required this.userId, required this.date, required this.sections});
  final String userId;
  final DateTime date;
  final List<ReportSection> sections;
  Map<String, dynamic> toJson();
  static Report fromJson(Map<String, dynamic> json);
}
```

**Serialization conventions:**
- `DateTime` → ISO-8601 string via `toIso8601String()`, and back via
  `DateTime.parse(...)`.
- `Map<String, double>` → keep as JSON object (Dart's `jsonEncode` handles it),
  but cast back with `(json[k] as num).toDouble()` on `fromJson`.
- `QuestionResponse.answer` → store as-is in JSON; on `fromJson`, read the raw
  value (numbers come back as `int`/`double`; leave as `dynamic`).

- [ ] **Step 1: Write the failing test**

Create `test/frps/models/models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/models/financial_snapshot.dart';
import 'package:moneymoneymoney/frps/models/question.dart';
import 'package:moneymoneymoney/frps/models/question_response.dart';
import 'package:moneymoneymoney/frps/models/report.dart';
import 'package:moneymoneymoney/frps/models/user.dart';
import 'package:moneymoneymoney/frps/models/user_profile.dart';

void main() {
  test('User round-trips through JSON', () {
    final user = User(
      id: 'u1',
      name: 'Ada',
      email: 'ada@example.com',
      profile: const UserProfile(monthlyIncome: 6000, age: 34),
    );
    expect(User.fromJson(user.toJson()).name, 'Ada');
    expect(User.fromJson(user.toJson()).profile.monthlyIncome, 6000);
  });

  test('FinancialSnapshot round-trips through JSON', () {
    final snapshot = FinancialSnapshot(
      userId: 'u1',
      date: DateTime(2026, 8, 29),
      income: 6000,
      expenses: {'housing': 1500, 'food': 800},
      assets: {'cash': 5000},
      liabilities: {'card': 1200},
      monthlySavingsGoal: 900,
    );
    final restored = FinancialSnapshot.fromJson(snapshot.toJson());
    expect(restored.income, 6000);
    expect(restored.expenses['food'], 800);
    expect(restored.assets['cash'], 5000);
    expect(restored.date, DateTime(2026, 8, 29));
  });

  test('Report round-trips through JSON', () {
    final report = Report(
      userId: 'u1',
      date: DateTime(2026, 8, 29),
      sections: const [
        ReportSection(title: 'Executive Summary', content: 'hi'),
        ReportSection(title: 'Expense Overview', content: 'data'),
      ],
    );
    final restored = Report.fromJson(report.toJson());
    expect(restored.sections, hasLength(2));
    expect(restored.sections.first.title, 'Executive Summary');
  });

  test('Question and QuestionResponse expose expected fields', () {
    const q = Question(id: 'risk', text: 'Risk?', type: QuestionType.multipleChoice, options: ['low', 'high']);
    expect(q.options, ['low', 'high']);

    final r = QuestionResponse(
      userId: 'u1',
      questionId: 'risk',
      answer: 'low',
      answeredAt: DateTime(2026, 8, 29),
    );
    expect(QuestionResponse.fromJson(r.toJson()).answer, 'low');
  });
}
```

- [ ] **Step 2: Run and verify RED**

`flutter test test/frps/models/models_test.dart`
Expected: FAIL — files do not exist.

- [ ] **Step 3: Implement**

Implement all six model files per the interfaces and serialization conventions.
Match the repo's existing immutable-class style (`const` constructors, `final`
fields, no Flutter imports).

- [ ] **Step 4: Run and verify GREEN**

`flutter test test/frps/models/models_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/frps/models test/frps/models/models_test.dart
git commit -m "feat(frps): add domain models"
```
