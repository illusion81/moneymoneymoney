import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/models/financial_snapshot.dart';
import 'package:moneymoneymoney/frps/models/question_response.dart';
import 'package:moneymoneymoney/frps/models/report.dart';
import 'package:moneymoneymoney/frps/models/user.dart';
import 'package:moneymoneymoney/frps/models/user_profile.dart';
import 'package:moneymoneymoney/frps/storage/sqlite_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('round-trips user, response, snapshot, and report', () async {
    final store = SqliteStore(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );

    final user = User(
      id: 'u1',
      name: 'Ada',
      profile: const UserProfile(monthlyIncome: 6000, age: 34),
    );
    await store.saveUser(user);
    expect((await store.getUser('u1'))!.name, 'Ada');

    final response = QuestionResponse(
      userId: 'u1',
      questionId: 'income',
      answer: 6000.0,
      answeredAt: DateTime(2026, 8, 29),
    );
    await store.saveResponse(response);
    expect(await store.responsesFor('u1'), hasLength(1));

    final snapshot = FinancialSnapshot(
      userId: 'u1',
      date: DateTime(2026, 8, 29),
      income: 6000,
      expenses: {'housing': 1500},
      assets: {'cash': 5000},
      liabilities: {'card': 1200},
      monthlySavingsGoal: 900,
    );
    await store.saveSnapshot(snapshot);
    expect((await store.latestSnapshot('u1'))!.income, 6000);

    final report = Report(
      userId: 'u1',
      date: DateTime(2026, 8, 29),
      sections: const [ReportSection(title: 'Executive Summary', content: 'hi')],
    );
    await store.saveReport(report);
    expect((await store.latestReport('u1'))!.sections.first.title, 'Executive Summary');

    expect(await store.getUser('missing'), isNull);
    expect(await store.latestSnapshot('missing'), isNull);
  });
}
