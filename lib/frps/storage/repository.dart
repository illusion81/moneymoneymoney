import 'package:moneymoneymoney/frps/models/financial_snapshot.dart';
import 'package:moneymoneymoney/frps/models/question_response.dart';
import 'package:moneymoneymoney/frps/models/report.dart';
import 'package:moneymoneymoney/frps/models/user.dart';

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
