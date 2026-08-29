# Task 11: Repository + SQLite Store

**Wave:** 3 (parallel). This is the ONLY task that adds dependencies and edits
`pubspec.yaml`.

**Files:**
- Create: `lib/frps/storage/repository.dart`
- Create: `lib/frps/storage/sqlite_store.dart`
- Create: `test/frps/storage/sqlite_store_test.dart`
- Modify: `pubspec.yaml` (add `sqflite` + `sqflite_common_ffi`)

**Produces:**

```dart
// repository.dart
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

```dart
// sqlite_store.dart
class SqliteStore implements FrpsRepository {
  SqliteStore({DatabaseFactory? factory, String? path});
}
```

`SqliteStore` uses `package:sqflite`. Constructor takes an optional
`DatabaseFactory` and database `path` (default `'frps.db'`) so tests can inject
`databaseFactoryFfi` and `inMemoryDatabasePath`.

**Schema** (one table per entity; serialize the object to a JSON string in a
`data` column, plus columns needed for lookup/ordering):

```sql
users      (id TEXT PRIMARY KEY, data TEXT)
responses  (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT, data TEXT)
snapshots  (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT, date TEXT, data TEXT)
reports    (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT, date TEXT, data TEXT)
```

- `saveUser` upserts by `id`.
- `responsesFor` returns rows for the user ordered by `id`.
- `latestSnapshot` / `latestReport` return the row with the max `date` for the
  user.

- [ ] **Step 1: Add dependencies**

```bash
flutter pub add sqflite
flutter pub add --dev sqflite_common_ffi
```

- [ ] **Step 2: Write the failing test**

Create `test/frps/storage/sqlite_store_test.dart`:

```dart
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
```

- [ ] **Step 3: Run and verify RED**

`flutter test test/frps/storage/sqlite_store_test.dart`
Expected: FAIL — files do not exist.

- [ ] **Step 4: Implement**

Implement `repository.dart` and `sqlite_store.dart` per the interface and schema.
Use `jsonEncode`/`jsonDecode` and the model classes' `toJson`/`fromJson`.

- [ ] **Step 5: Run and verify GREEN**

`flutter test test/frps/storage/sqlite_store_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/frps/storage test/frps/storage/sqlite_store_test.dart
git commit -m "feat(frps): add SQLite repository"
```
