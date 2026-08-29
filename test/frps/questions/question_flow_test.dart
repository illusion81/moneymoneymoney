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
  while (true) {
    final q = flow.nextQuestion(responses);
    if (q == null) break;
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
    final real = [
      answer('u', 'income', 6000.0),
    ];
    expect(flow.isComplete(real), isFalse);
    expect(flow.nextQuestion(real)!.id, 'fixed-expenses');
  });
}
