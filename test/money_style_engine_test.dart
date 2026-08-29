import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/money_style_questions.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/services/money_style_engine.dart';

/// Index of the answer with the given band, for a question id.
int _answerIndex(int questionId, PoleBand band) =>
    moneyStyleQuestionsById[questionId]!.answers.indexWhere(
      (a) => a.band == band,
    );

/// Builds a session from `{questionId: band}` pairs.
AnswerSession _session(Map<int, PoleBand> answers, {Set<int>? skipped}) =>
    AnswerSession(
      userId: 'u',
      sessionId: 's',
      selectedAnswers: {
        for (final entry in answers.entries)
          entry.key: _answerIndex(entry.key, entry.value),
      },
      skippedQuestions: skipped ?? {},
      shownQuestionIds: [...answers.keys, ...?skipped],
    );

DimensionScores _scores(Map<int, PoleBand> answers) => const MoneyStyleEngine()
    .calculateDimensionScores(_session(answers), moneyStyleQuestionPool);

void main() {
  const engine = MoneyStyleEngine();

  group('question pool', () {
    test('holds 24 questions: 4 per dimension, one per branch', () {
      expect(moneyStyleQuestionPool, hasLength(24));
      for (final dimension in Dimension.values) {
        final questions = moneyStyleQuestionPool
            .where((q) => q.dimension == dimension)
            .toList();
        expect(questions, hasLength(4), reason: '$dimension question count');
        expect(
          questions.map((q) => q.branch).toSet(),
          QuestionBranch.values.toSet(),
          reason: '$dimension branches',
        );
      }
    });

    test('every question offers one bad, one mixed and one good option', () {
      for (final question in moneyStyleQuestionPool) {
        expect(question.answers, hasLength(3), reason: 'Q${question.id}');
        expect(
          question.answers.map((a) => a.band).toSet(),
          PoleBand.values.toSet(),
          reason: 'Q${question.id} bands',
        );
        expect(
          question.answers.map((a) => a.dimension).toSet(),
          {question.dimension},
          reason: 'Q${question.id} scores exactly one dimension',
        );
      }
    });

    test('weights are -1 / 0 / +1 and match their band', () {
      for (final answer in moneyStyleQuestionPool.expand((q) => q.answers)) {
        expect(answer.weight, inInclusiveRange(-1, 1));
        expect(answer.weight, answer.band.weight);
      }
    });

    test('question and answer ids are unique and stable', () {
      final questionIds = moneyStyleQuestionPool.map((q) => q.id).toList();
      expect(questionIds.toSet(), hasLength(questionIds.length));
      expect(questionIds.toSet(), List.generate(24, (i) => i + 1).toSet());
      final answerIds = moneyStyleQuestionPool
          .expand((q) => q.answers)
          .map((a) => a.id)
          .toList();
      expect(answerIds.toSet(), hasLength(answerIds.length));
    });

    test('the six openers are ids 1-6 in fixed page order', () {
      expect(moneyStyleOpeners.map((q) => q.id), [1, 2, 3, 4, 5, 6]);
      expect(
        moneyStyleOpeners.take(3).map((q) => q.dimension),
        kPageOneDimensions,
      );
      expect(
        moneyStyleOpeners.skip(3).map((q) => q.dimension),
        kPageTwoDimensions,
      );
      expect(moneyStyleOpeners.every((q) => q.isOpener), isTrue);
    });

    test('pages 1 and 2 are fixed and unconditional', () {
      expect(engine.fixedPages.map((p) => p.map((q) => q.id).toList()), [
        [1, 2, 3],
        [4, 5, 6],
      ]);
    });
  });

  group('scoring', () {
    test('running total is the sum of answer weights per dimension', () {
      final scores = _scores({1: PoleBand.bad, 7: PoleBand.bad});
      expect(scores.scoreFor(Dimension.revolvingDebtNeglect), -2);
      expect(scores.dataPointsFor(Dimension.revolvingDebtNeglect), 2);
    });

    test('an unanswered dimension is null, not zero', () {
      final scores = _scores({1: PoleBand.mixed});
      expect(scores.scoreFor(Dimension.revolvingDebtNeglect), 0);
      expect(scores.isUnscored(Dimension.revolvingDebtNeglect), isFalse);
      expect(scores.scoreFor(Dimension.savingsAvoidance), isNull);
      expect(scores.isUnscored(Dimension.savingsAvoidance), isTrue);
    });

    test('categorical pole counts are kept alongside the numeric total', () {
      final scores = _scores({1: PoleBand.bad, 7: PoleBand.bad});
      expect(
        scores.poleCount(
          Dimension.revolvingDebtNeglect,
          RevolvingDebtNeglectPole.balanceCarrier,
        ),
        2,
      );
    });
  });

  group('follow-up routing', () {
    test(
      'ranks by magnitude, then negative before positive, then priority',
      () {
        // RD -1, CI +1, PA 0, SB 0, SA -1, FA +1 — the design's §E snapshot.
        final scores = _scores({
          1: PoleBand.bad,
          2: PoleBand.good,
          3: PoleBand.mixed,
          4: PoleBand.mixed,
          5: PoleBand.bad,
          6: PoleBand.good,
        });
        expect(engine.rankDimensions(scores), [
          Dimension.revolvingDebtNeglect, // -1, negative, highest priority
          Dimension.savingsAvoidance, // -1, negative
          Dimension.convenienceImpulse, // +1, priority over FA
          Dimension.financialAvoidance, // +1
          Dimension.subscriptionBlindness, // 0
          Dimension.priceAnchoring, // 0
        ]);
      },
    );

    test('a larger magnitude outranks a negative sign', () {
      final scores = _scores({
        1: PoleBand.bad, // RD -1
        2: PoleBand.good, // CI +1
        11: PoleBand.good, // CI +2
      });
      expect(
        engine.rankDimensions(
          scores,
          candidates: [
            Dimension.revolvingDebtNeglect,
            Dimension.convenienceImpulse,
          ],
        ),
        [Dimension.convenienceImpulse, Dimension.revolvingDebtNeglect],
      );
    });

    test('an unscored dimension outranks every scored one', () {
      final scores = _scores({1: PoleBand.bad, 7: PoleBand.bad}); // RD -2
      expect(
        engine.rankDimensions(scores).first,
        isNot(Dimension.revolvingDebtNeglect),
      );
      expect(
        engine.rankDimensions(scores).first,
        Dimension.convenienceImpulse, // unscored, highest by priority
      );
    });

    test('branch follows the sign of the current score', () {
      expect(engine.branchFor(-2), QuestionBranch.badDrill);
      expect(engine.branchFor(2), QuestionBranch.goodDrill);
      expect(engine.branchFor(0), QuestionBranch.mixedClarify);
      expect(engine.branchFor(null), QuestionBranch.opening);
    });

    test('all-mixed sessions fall back to the fixed priority order', () {
      final scores = _scores({
        for (var id = 1; id <= 6; id++) id: PoleBand.mixed,
      });
      final page3 = engine.selectFollowUpQuestions(scores);
      expect(page3.map((q) => q.dimension), [
        Dimension.revolvingDebtNeglect,
        Dimension.convenienceImpulse,
        Dimension.subscriptionBlindness,
      ]);
      expect(
        page3.every((q) => q.branch == QuestionBranch.mixedClarify),
        isTrue,
      );
      final page4 = engine.selectFollowUpQuestions(
        scores,
        exclude: page3.map((q) => q.dimension).toSet(),
      );
      expect(page4.map((q) => q.dimension), [
        Dimension.savingsAvoidance,
        Dimension.priceAnchoring,
        Dimension.financialAvoidance,
      ]);
    });

    test('page 3 and page 4 exactly partition the six dimensions', () {
      final scores = _scores({
        1: PoleBand.bad,
        2: PoleBand.good,
        3: PoleBand.mixed,
        4: PoleBand.mixed,
        5: PoleBand.bad,
        6: PoleBand.good,
      });
      final page3 = engine.selectFollowUpQuestions(scores);
      final page4 = engine.selectFollowUpQuestions(
        scores,
        exclude: page3.map((q) => q.dimension).toSet(),
      );
      expect(page3, hasLength(3));
      expect(page4, hasLength(3));
      expect({
        ...page3.map((q) => q.dimension),
        ...page4.map((q) => q.dimension),
      }, Dimension.values.toSet());
    });

    test('a skipped opener earns a page-3 slot and re-shows the opener', () {
      // Every dimension answered except Savings Avoidance, whose opener was
      // skipped — and Revolving Debt is decisively negative at -2.
      final scores = _scores({
        1: PoleBand.bad,
        7: PoleBand.bad,
        2: PoleBand.good,
        3: PoleBand.mixed,
        4: PoleBand.mixed,
        6: PoleBand.good,
      });
      final page3 = engine.selectFollowUpQuestions(scores);
      final savings = page3.firstWhere(
        (q) => q.dimension == Dimension.savingsAvoidance,
      );
      expect(page3.first.dimension, Dimension.savingsAvoidance);
      expect(savings.branch, QuestionBranch.opening);
      expect(savings.id, 5);
    });
  });

  group('the design doc §E worked example (Alex)', () {
    test('routes and scores exactly as the doc walks through', () {
      final answers = <int, PoleBand>{};

      void answer(int id, PoleBand band) => answers[id] = band;

      // Page 1 (fixed: RD, CI, PA)
      answer(1, PoleBand.bad); // RD = -1
      answer(2, PoleBand.good); // CI = +1
      answer(3, PoleBand.mixed); // PA = 0

      // Page 2 (fixed: SB, SA, FA)
      answer(4, PoleBand.mixed); // SB = 0
      answer(5, PoleBand.bad); // SA = -1
      answer(6, PoleBand.good); // FA = +1

      var scores = _scores(answers);
      expect(scores.totals, {
        Dimension.revolvingDebtNeglect: -1,
        Dimension.convenienceImpulse: 1,
        Dimension.subscriptionBlindness: 0,
        Dimension.savingsAvoidance: -1,
        Dimension.priceAnchoring: 0,
        Dimension.financialAvoidance: 1,
      });

      // Page 3 = RD bad-drill, SA bad-drill, CI good-drill.
      final page3 = engine.selectFollowUpQuestions(scores);
      expect(page3.map((q) => q.dimension), [
        Dimension.revolvingDebtNeglect,
        Dimension.savingsAvoidance,
        Dimension.convenienceImpulse,
      ]);
      expect(page3.map((q) => q.branch), [
        QuestionBranch.badDrill,
        QuestionBranch.badDrill,
        QuestionBranch.goodDrill,
      ]);
      expect(page3.map((q) => q.id), [7, 16, 11]);

      answer(7, PoleBand.bad); // RD = -2
      answer(16, PoleBand.mixed); // SA = -1
      answer(11, PoleBand.good); // CI = +2

      scores = _scores(answers);
      expect(scores.scoreFor(Dimension.revolvingDebtNeglect), -2);
      expect(scores.scoreFor(Dimension.convenienceImpulse), 2);
      expect(scores.scoreFor(Dimension.savingsAvoidance), -1);

      // Page 4 = the complement: PA mixed-clarify, SB mixed-clarify, FA good-drill.
      final page4 = engine.selectFollowUpQuestions(
        scores,
        exclude: page3.map((q) => q.dimension).toSet(),
      );
      expect(page4.map((q) => q.dimension).toSet(), {
        Dimension.priceAnchoring,
        Dimension.subscriptionBlindness,
        Dimension.financialAvoidance,
      });
      expect(
        {for (final q in page4) q.dimension: q.branch},
        {
          Dimension.financialAvoidance: QuestionBranch.goodDrill,
          Dimension.subscriptionBlindness: QuestionBranch.mixedClarify,
          Dimension.priceAnchoring: QuestionBranch.mixedClarify,
        },
      );
      expect(page4.map((q) => q.id).toSet(), {23, 15, 21});

      answer(21, PoleBand.good); // PA = +1
      answer(15, PoleBand.bad); // SB = -1
      answer(23, PoleBand.good); // FA = +2

      scores = _scores(answers);
      expect(scores.totals, {
        Dimension.revolvingDebtNeglect: -2,
        Dimension.convenienceImpulse: 2,
        Dimension.subscriptionBlindness: -1,
        Dimension.savingsAvoidance: -1,
        Dimension.priceAnchoring: 1,
        Dimension.financialAvoidance: 2,
      });
      expect(scores.mostCritical, Dimension.revolvingDebtNeglect);
      // Convenience-Impulse and Financial Avoidance tie at +2; the fixed
      // priority order picks Convenience-Impulse.
      expect(scores.strongest, Dimension.convenienceImpulse);

      final result = engine.generateResult(
        _session(answers),
        moneyStyleQuestionPool,
      );
      expect(result, isNotNull);
      expect(result!.totalAnswered, 12);
      expect(result.confidenceTier, ConfidenceTier.fullClarity);
      // RD negative, CI positive, PA positive.
      expect(result.archetype.id, 'watch_hold_hold');
    });
  });

  group('result', () {
    test('needs every dimension before naming a style', () {
      expect(
        engine.generateResult(
          _session({1: PoleBand.bad, 2: PoleBand.bad}),
          moneyStyleQuestionPool,
        ),
        isNull,
      );
      final covered = _session({
        for (var id = 1; id <= 6; id++) id: PoleBand.mixed,
      });
      expect(engine.generateResult(covered, moneyStyleQuestionPool), isNotNull);
    });

    test('confidence tiers follow the 3/6/12 page boundaries', () {
      expect(engine.getConfidenceTier(3), ConfidenceTier.earlySnapshot);
      expect(engine.getConfidenceTier(5), ConfidenceTier.earlySnapshot);
      expect(engine.getConfidenceTier(6), ConfidenceTier.standard);
      expect(engine.getConfidenceTier(11), ConfidenceTier.standard);
      expect(engine.getConfidenceTier(12), ConfidenceTier.fullClarity);
    });

    test(
      'a dimension with no data holds a full session out of full clarity',
      () {
        // 12 answers, but Financial Avoidance never heard from.
        final scores = _scores({
          1: PoleBand.bad,
          7: PoleBand.bad,
          8: PoleBand.bad,
          9: PoleBand.bad,
          2: PoleBand.good,
          10: PoleBand.good,
          3: PoleBand.mixed,
          4: PoleBand.mixed,
          5: PoleBand.bad,
          16: PoleBand.bad,
          17: PoleBand.bad,
          18: PoleBand.bad,
        });
        expect(scores.isUnscored(Dimension.financialAvoidance), isTrue);
        expect(
          engine.getConfidenceTier(12, scores: scores),
          ConfidenceTier.standard,
        );
      },
    );

    test('maps the page-1 trio signs to eight distinct archetypes', () {
      final ids = <String>{};
      for (final rd in [PoleBand.bad, PoleBand.good]) {
        for (final ci in [PoleBand.bad, PoleBand.good]) {
          for (final pa in [PoleBand.bad, PoleBand.good]) {
            ids.add(
              engine.mapScoresToArchetype(_scores({1: rd, 2: ci, 3: pa})).id,
            );
          }
        }
      }
      expect(ids, hasLength(8));
    });

    test('an exact-zero dimension is treated as "watch", not a strength', () {
      final archetype = engine.mapScoresToArchetype(
        _scores({1: PoleBand.mixed, 2: PoleBand.mixed, 3: PoleBand.mixed}),
      );
      expect(archetype.id, 'watch_watch_watch');
    });
  });
}
