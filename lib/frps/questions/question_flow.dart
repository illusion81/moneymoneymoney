import 'package:moneymoneymoney/frps/models/question.dart';
import 'package:moneymoneymoney/frps/models/question_response.dart';
import 'package:moneymoneymoney/frps/questions/question_catalog.dart';

class QuestionFlow {
  const QuestionFlow({this.questions = questionCatalog});

  final List<Question> questions;

  Question? nextQuestion(List<QuestionResponse> previous) {
    final answeredIds = previous.map((r) => r.questionId).toSet();
    final hasDebt = previous.any(
      (r) => r.questionId == 'has-debt' && r.answer == 'yes',
    );

    for (final question in questions) {
      if (answeredIds.contains(question.id)) {
        continue;
      }
      if (question.id == 'debt-details' && !hasDebt) {
        continue;
      }
      return question;
    }

    return null;
  }

  bool isComplete(List<QuestionResponse> previous) =>
      nextQuestion(previous) == null;
}
