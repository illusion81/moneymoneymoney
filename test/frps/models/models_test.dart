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
