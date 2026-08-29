import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/money_style_questions.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/services/money_style_engine.dart';

void main() {
  final engine = MoneyStyleEngine();
  test('returns null without all three dimensions', () => expect(engine.generateResult(AnswerSession(userId: 'u', sessionId: 's', selectedAnswers: {1: 0, 2: 0}), moneyStyleQuestions), isNull));
  test('returns early snapshot after coverage', () { final result = engine.generateResult(AnswerSession(userId: 'u', sessionId: 's', selectedAnswers: {1: 0, 2: 0, 4: 0}), moneyStyleQuestions); expect(result, isNotNull); expect(result!.confidenceTier, ConfidenceTier.earlySnapshot); });
  test('question bank is balanced with stable identities', () { for (final d in Dimension.values) { final questions = moneyStyleQuestions.where((q) => q.dimension == d).toList(); expect(questions, hasLength(4)); final poles = questions.expand((q) => q.answers).map((a) => a.pole).toList(); expect(poles.where((p) => p == poles.first).length, lessThan(7)); } for (final q in moneyStyleQuestions) { expect(q.answers.map((a) => a.id).toSet(), hasLength(3)); } });
  test('bank has exactly twelve questions, unique answer ids, and six poles each', () { expect(moneyStyleQuestions, hasLength(12)); final ids = moneyStyleQuestions.expand((q) => q.answers).map((a) => a.id).toList(); expect(ids.toSet(), hasLength(ids.length)); expect(moneyStyleQuestions.expand((q)=>q.answers).where((a)=>a.pole==MoneyRhythmPole.steady),hasLength(6)); expect(moneyStyleQuestions.expand((q)=>q.answers).where((a)=>a.pole==MoneyRhythmPole.responsive),hasLength(6)); expect(moneyStyleQuestions.expand((q)=>q.answers).where((a)=>a.pole==DecisionStylePole.pause),hasLength(6)); expect(moneyStyleQuestions.expand((q)=>q.answers).where((a)=>a.pole==DecisionStylePole.momentum),hasLength(6)); expect(moneyStyleQuestions.expand((q)=>q.answers).where((a)=>a.pole==SupportStylePole.selfDirected),hasLength(6)); expect(moneyStyleQuestions.expand((q)=>q.answers).where((a)=>a.pole==SupportStylePole.collaborative),hasLength(6)); });
  test('confidence tiers use answer count boundaries', () { expect(engine.getConfidenceTier(3),ConfidenceTier.earlySnapshot); expect(engine.getConfidenceTier(4),ConfidenceTier.standard); expect(engine.getConfidenceTier(8),ConfidenceTier.standard); expect(engine.getConfidenceTier(9),ConfidenceTier.fullClarity); });
}
