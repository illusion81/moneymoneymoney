import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/money_style_questions.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/services/money_style_engine.dart';

void main() {
  final engine = MoneyStyleEngine();
  test('returns null without all three dimensions', () => expect(engine.generateResult(AnswerSession(userId: 'u', sessionId: 's', selectedAnswers: {1: 0, 2: 0}), moneyStyleQuestions), isNull));
  test('returns early snapshot after coverage', () { final result = engine.generateResult(AnswerSession(userId: 'u', sessionId: 's', selectedAnswers: {1: 0, 2: 0, 4: 0}), moneyStyleQuestions); expect(result, isNotNull); expect(result!.confidenceTier, ConfidenceTier.earlySnapshot); });
  test('question bank is balanced with stable identities', () { for (final d in Dimension.values) { final questions = moneyStyleQuestions.where((q) => q.dimension == d).toList(); expect(questions, hasLength(4)); final poles = questions.expand((q) => q.answers).map((a) => a.pole).toList(); expect(poles.where((p) => p == poles.first).length, lessThan(7)); } for (final q in moneyStyleQuestions) { expect(q.answers.map((a) => a.id).toSet(), hasLength(3)); } });
}
