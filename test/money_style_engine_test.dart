import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/money_style_questions.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/services/money_style_engine.dart';

void main() {
  final engine = MoneyStyleEngine();
  test(
    'returns null without all three dimensions',
    () => expect(
      engine.generateResult(
        AnswerSession(
          userId: 'u',
          sessionId: 's',
          selectedAnswers: {1: 0, 2: 0},
        ),
        moneyStyleQuestions,
      ),
      isNull,
    ),
  );
  test('returns early snapshot after coverage', () {
    final result = engine.generateResult(
      AnswerSession(
        userId: 'u',
        sessionId: 's',
        selectedAnswers: {1: 0, 2: 0, 4: 0},
      ),
      moneyStyleQuestions,
    );
    expect(result, isNotNull);
    expect(result!.confidenceTier, ConfidenceTier.earlySnapshot);
  });
  test('question bank is balanced with stable identities', () {
    for (final d in Dimension.values) {
      final questions = moneyStyleQuestions
          .where((q) => q.dimension == d)
          .toList();
      expect(questions, hasLength(4));
      final poles = questions
          .expand((q) => q.answers)
          .map((a) => a.pole)
          .toList();
      expect(poles.where((p) => p == poles.first).length, lessThan(7));
    }
    for (final q in moneyStyleQuestions) {
      expect(q.answers.map((a) => a.id).toSet(), hasLength(3));
    }
  });
  test(
    'bank has exactly twelve questions, unique answer ids, and six poles each',
    () {
      expect(moneyStyleQuestions, hasLength(12));
      final ids = moneyStyleQuestions
          .expand((q) => q.answers)
          .map((a) => a.id)
          .toList();
      expect(ids.toSet(), hasLength(ids.length));
      expect(
        moneyStyleQuestions
            .expand((q) => q.answers)
            .where((a) => a.pole == MoneyRhythmPole.steady),
        hasLength(6),
      );
      expect(
        moneyStyleQuestions
            .expand((q) => q.answers)
            .where((a) => a.pole == MoneyRhythmPole.responsive),
        hasLength(6),
      );
      expect(
        moneyStyleQuestions
            .expand((q) => q.answers)
            .where((a) => a.pole == DecisionStylePole.pause),
        hasLength(6),
      );
      expect(
        moneyStyleQuestions
            .expand((q) => q.answers)
            .where((a) => a.pole == DecisionStylePole.momentum),
        hasLength(6),
      );
      expect(
        moneyStyleQuestions
            .expand((q) => q.answers)
            .where((a) => a.pole == SupportStylePole.selfDirected),
        hasLength(6),
      );
      expect(
        moneyStyleQuestions
            .expand((q) => q.answers)
            .where((a) => a.pole == SupportStylePole.collaborative),
        hasLength(6),
      );
    },
  );
  test('declares exactly one complete tie-break item per dimension', () {
    for (final dimension in Dimension.values) {
      final breakers = moneyStyleQuestions
          .where(
            (question) =>
                question.dimension == dimension &&
                question.answers.any((answer) => answer.isBreaker),
          )
          .toList();
      expect(breakers, hasLength(1), reason: '$dimension tie-break items');
      expect(
        breakers.single.answers.every((answer) => answer.isBreaker),
        isTrue,
        reason: '$dimension tie-break answers',
      );
    }
  });
  test('confidence tiers use answer count boundaries', () {
    expect(engine.getConfidenceTier(3), ConfidenceTier.earlySnapshot);
    expect(engine.getConfidenceTier(4), ConfidenceTier.standard);
    expect(engine.getConfidenceTier(8), ConfidenceTier.standard);
    expect(engine.getConfidenceTier(9), ConfidenceTier.fullClarity);
  });
  test('maps all eight winner combinations to distinct archetypes', () {
    final names = <String>{};
    for (final rhythm in MoneyRhythmPole.values) {
      for (final decision in DecisionStylePole.values) {
        for (final support in SupportStylePole.values) {
          names.add(
            engine.mapScoresToArchetype(rhythm, decision, support).name,
          );
        }
      }
    }
    expect(names, hasLength(8));
  });
  test('scores both poles across all dimensions', () {
    final scores = engine.calculateDimensionScores(
      AnswerSession(
        userId: 'u',
        sessionId: 's',
        selectedAnswers: {1: 0, 3: 1, 2: 0, 6: 0, 4: 0, 7: 0},
      ),
      moneyStyleQuestions,
    );
    expect(scores.steadyCount, 1);
    expect(scores.responsiveCount, 1);
    expect(scores.pauseCount, 1);
    expect(scores.momentumCount, 1);
    expect(scores.selfCount, 1);
    expect(scores.collaborativeCount, 1);
  });
  test(
    'one answer from each dimension is eligible while a missing dimension is not',
    () {
      expect(
        engine.generateResult(
          AnswerSession(
            userId: 'u',
            sessionId: 's',
            selectedAnswers: {1: 0, 2: 0, 4: 0},
          ),
          moneyStyleQuestions,
        ),
        isNotNull,
      );
      expect(
        engine.generateResult(
          AnswerSession(
            userId: 'u',
            sessionId: 's',
            selectedAnswers: {1: 0, 3: 0},
          ),
          moneyStyleQuestions,
        ),
        isNull,
      );
    },
  );
  test(
    'money rhythm tie breaker only applies when its question is answered',
    () {
      final withBreaker = AnswerSession(
        userId: 'u',
        sessionId: 's',
        selectedAnswers: {1: 0, 3: 1},
      );
      final tied = engine.calculateDimensionScores(
        withBreaker,
        moneyStyleQuestions,
      );
      expect(
        engine
            .applyTieBreakers(tied, withBreaker, moneyStyleQuestions)
            .steadyCount,
        2,
      );
      final skippedBreaker = AnswerSession(
        userId: 'u',
        sessionId: 's',
        selectedAnswers: {3: 1},
      );
      final skipped = engine.calculateDimensionScores(
        skippedBreaker,
        moneyStyleQuestions,
      );
      expect(
        engine
            .applyTieBreakers(skipped, skippedBreaker, moneyStyleQuestions)
            .responsiveCount,
        1,
      );
    },
  );
}
