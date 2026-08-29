import 'package:moneymoneymoney/frps/models/financial_snapshot.dart';
import 'package:moneymoneymoney/frps/models/question_response.dart';
import 'package:moneymoneymoney/frps/models/report.dart';
import 'package:moneymoneymoney/frps/models/user.dart';
import 'package:moneymoneymoney/frps/storage/repository.dart';

/// In-memory [FrpsRepository] for tests, so screens and controllers can be
/// exercised without a real database (or the sqflite FFI shim).
class FakeFrpsRepository implements FrpsRepository {
  final Map<String, User> users = {};
  final Map<String, List<FinancialSnapshot>> snapshots = {};
  final Map<String, List<Report>> reports = {};

  @override
  Future<void> saveUser(User user) async => users[user.id] = user;

  @override
  Future<User?> getUser(String id) async => users[id];

  @override
  Future<void> saveResponse(QuestionResponse response) async {}

  @override
  Future<List<QuestionResponse>> responsesFor(String userId) async => const [];

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
