import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/money_style_questions.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/services/money_style_engine.dart';

void main() {
  group('MoneyStyleEngine', () {
    late MoneyStyleEngine engine;

    setUp(() {
      engine = MoneyStyleEngine();
    });

    group('calculateDimensionScores', () {
      test('should calculate scores from selected answers', () {
        final session = AnswerSession(
          userId: 'test-user',
          sessionId: 'session-1',
          selectedAnswers: {
            1: 0, // Q1: Steady
            3: 1, // Q3: Momentum
            4: 1, // Q4: Collaborative
          },
        );

        final scores = engine.calculateDimensionScores(
          session,
          moneyStyleQuestions,
        );

        expect(scores.steadyCount, 1);
        expect(scores.responsiveCount, 0);
        expect(scores.pauseCount, 0);
        expect(scores.momentumCount, 1);
        expect(scores.selfCount, 0);
        expect(scores.collaborativeCount, 1);
      });

      test('should handle empty session', () {
        final session = AnswerSession(
          userId: 'test-user',
          sessionId: 'session-1',
        );

        final scores = engine.calculateDimensionScores(
          session,
          moneyStyleQuestions,
        );

        expect(scores.steadyCount, 0);
        expect(scores.responsiveCount, 0);
        expect(scores.pauseCount, 0);
        expect(scores.momentumCount, 0);
        expect(scores.selfCount, 0);
        expect(scores.collaborativeCount, 0);
      });

      test('should count all answer types correctly', () {
        final session = AnswerSession(
          userId: 'test-user',
          sessionId: 'session-1',
          selectedAnswers: {
            1: 0, // Steady
            5: 0, // Steady
            10: 0, // Steady
            2: 1, // Responsive
            3: 0, // Pause
            6: 0, // Pause
            12: 0, // Pause
            8: 1, // Momentum
            4: 0, // Self
            7: 1, // Collaborative
            9: 2, // Collaborative
          },
        );

        final scores = engine.calculateDimensionScores(
          session,
          moneyStyleQuestions,
        );

        // Should have counted: Q1 Steady, Q5 Steady, Q10 Steady, Q2 Responsive
        // Q3 Pause, Q6 Pause, Q12 Pause, Q8 Momentum
        // Q4 Self, Q7 Collaborative, Q9 Collaborative
        expect(scores.steadyCount, 3);
        expect(scores.responsiveCount, 1);
        expect(scores.pauseCount, 3);
        expect(scores.momentumCount, 1);
        expect(scores.selfCount, 1);
        expect(scores.collaborativeCount, 2);
      });
    });

    group('applyTieBreakers', () {
      test('Q2 should break Money Rhythm ties', () {
        // Create a scenario where we have 2 Steady, 2 Responsive
        final session = AnswerSession(
          userId: 'test-user',
          sessionId: 'session-1',
          selectedAnswers: {
            1: 0, // Q1: Steady
            2: 1, // Q2: Responsive (tie-breaker, should break tie to Responsive)
            5: 1, // Q5: Responsive
            10: 0, // Q10: Steady
          },
        );

        var scores = engine.calculateDimensionScores(
          session,
          moneyStyleQuestions,
        );
        expect(scores.steadyCount, 2);
        expect(scores.responsiveCount, 2); // Tied

        final scoresAfter = engine.applyTieBreakers(
          scores,
          session,
          moneyStyleQuestions,
        );
        expect(
          scoresAfter.responsiveCount,
          3,
        ); // Tie-breaker from Q2 breaks it to Responsive
      });

      test('Q8 should break Decision Style ties', () {
        // Create exactly 2-2 tie
        final session = AnswerSession(
          userId: 'test-user',
          sessionId: 'session-1',
          selectedAnswers: {
            3: 0, // Q3: Pause
            6: 0, // Q6: Pause
            8: 1, // Q8: Momentum (will be tie-breaker)
            12: 1, // Q12: Momentum
            // Now we have 2 Pause, 2 Momentum before tie-breaker
          },
        );

        var scores = engine.calculateDimensionScores(
          session,
          moneyStyleQuestions,
        );
        expect(scores.pauseCount, 2);
        expect(scores.momentumCount, 2);

        final scoresAfter = engine.applyTieBreakers(
          scores,
          session,
          moneyStyleQuestions,
        );
        expect(scoresAfter.momentumCount, 3); // Q8 breaks tie to Momentum
      });

      test('Q11 should break Support Style ties', () {
        // Create exactly 1 Self, 1 Collaborative tie without Q11
        final sessionBeforeTieBreaker = AnswerSession(
          userId: 'test-user',
          sessionId: 'session-1',
          selectedAnswers: {
            4: 0, // Q4: Self (answer 0: "I work through it myself first")
            9: 1, // Q9: Collaborative (answer 1: "I ask a trusted friend")
            // Before tie-breaker: 1 Self, 1 Collaborative (tie!)
          },
        );

        var scores = engine.calculateDimensionScores(
          sessionBeforeTieBreaker,
          moneyStyleQuestions,
        );
        expect(scores.selfCount, 1);
        expect(scores.collaborativeCount, 1);

        // Now add Q11 to break the tie
        final sessionWithTieBreaker = AnswerSession(
          userId: 'test-user',
          sessionId: 'session-1',
          selectedAnswers: {
            4: 0, // Q4: Self
            9: 1, // Q9: Collaborative
            11: 1, // Q11: Collaborative (tie-breaker answer)
          },
        );

        final scoresAfter = engine.applyTieBreakers(
          scores,
          sessionWithTieBreaker,
          moneyStyleQuestions,
        );
        expect(scoresAfter.selfCount, 1);
        expect(
          scoresAfter.collaborativeCount,
          2,
        ); // Q11 breaks tie to Collaborative
      });

      test('tie-breaker should not apply if question not answered', () {
        final session = AnswerSession(
          userId: 'test-user',
          sessionId: 'session-1',
          selectedAnswers: {
            1: 0, // Q1: Steady
            5: 1, // Q5: Responsive
            10: 0, // Q10: Steady
            // Q2 (tie-breaker) is not answered, so we have 2 Steady, 1 Responsive
          },
        );

        var scores = engine.calculateDimensionScores(
          session,
          moneyStyleQuestions,
        );
        expect(scores.steadyCount, 2);
        expect(scores.responsiveCount, 1);

        scores = engine.applyTieBreakers(scores, session, moneyStyleQuestions);
        expect(scores.steadyCount, 2); // No change since not tied
        expect(scores.responsiveCount, 1);
      });
    });

    group('dimension winners', () {
      test('getMoneyRhythmWinner returns steady when higher', () {
        final scores = DimensionScores(steadyCount: 5, responsiveCount: 3);
        expect(engine.getMoneyRhythmWinner(scores), MoneyRhythmPole.steady);
      });

      test('getMoneyRhythmWinner returns responsive when higher', () {
        final scores = DimensionScores(steadyCount: 3, responsiveCount: 5);
        expect(engine.getMoneyRhythmWinner(scores), MoneyRhythmPole.responsive);
      });

      test('getDecisionStyleWinner returns pause when higher', () {
        final scores = DimensionScores(pauseCount: 5, momentumCount: 3);
        expect(engine.getDecisionStyleWinner(scores), DecisionStylePole.pause);
      });

      test('getDecisionStyleWinner returns momentum when higher', () {
        final scores = DimensionScores(pauseCount: 3, momentumCount: 5);
        expect(
          engine.getDecisionStyleWinner(scores),
          DecisionStylePole.momentum,
        );
      });

      test('getSupportStyleWinner returns selfDirected when higher', () {
        final scores = DimensionScores(selfCount: 5, collaborativeCount: 3);
        expect(
          engine.getSupportStyleWinner(scores),
          SupportStylePole.selfDirected,
        );
      });

      test('getSupportStyleWinner returns collaborative when higher', () {
        final scores = DimensionScores(selfCount: 3, collaborativeCount: 5);
        expect(
          engine.getSupportStyleWinner(scores),
          SupportStylePole.collaborative,
        );
      });
    });

    group('mapScoresToArchetype', () {
      test('Steady + Pause + Self maps to Calm Comparator', () {
        final archetype = engine.mapScoresToArchetype(
          MoneyRhythmPole.steady,
          DecisionStylePole.pause,
          SupportStylePole.selfDirected,
        );
        expect(archetype.name, 'The Calm Comparator');
      });

      test('Steady + Pause + Collaborative maps to Intentional Protector', () {
        final archetype = engine.mapScoresToArchetype(
          MoneyRhythmPole.steady,
          DecisionStylePole.pause,
          SupportStylePole.collaborative,
        );
        expect(archetype.name, 'The Intentional Protector');
      });

      test('Responsive + Momentum + Collaborative maps to Momentum Maker', () {
        final archetype = engine.mapScoresToArchetype(
          MoneyRhythmPole.responsive,
          DecisionStylePole.momentum,
          SupportStylePole.collaborative,
        );
        expect(archetype.name, 'The Momentum Maker');
      });

      test('all 8 archetypes map correctly', () {
        final patterns = [
          (
            'The Calm Comparator',
            MoneyRhythmPole.steady,
            DecisionStylePole.pause,
            SupportStylePole.selfDirected,
          ),
          (
            'The Intentional Protector',
            MoneyRhythmPole.steady,
            DecisionStylePole.pause,
            SupportStylePole.collaborative,
          ),
          (
            'The Quiet Builder',
            MoneyRhythmPole.steady,
            DecisionStylePole.momentum,
            SupportStylePole.selfDirected,
          ),
          (
            'The Steady Improviser',
            MoneyRhythmPole.steady,
            DecisionStylePole.momentum,
            SupportStylePole.collaborative,
          ),
          (
            'The Flexible Pathfinder',
            MoneyRhythmPole.responsive,
            DecisionStylePole.pause,
            SupportStylePole.selfDirected,
          ),
          (
            'The Community Navigator',
            MoneyRhythmPole.responsive,
            DecisionStylePole.pause,
            SupportStylePole.collaborative,
          ),
          (
            'The Resourceful Resetter',
            MoneyRhythmPole.responsive,
            DecisionStylePole.momentum,
            SupportStylePole.selfDirected,
          ),
          (
            'The Momentum Maker',
            MoneyRhythmPole.responsive,
            DecisionStylePole.momentum,
            SupportStylePole.collaborative,
          ),
        ];

        for (final (expectedName, rhythm, decision, support) in patterns) {
          final archetype = engine.mapScoresToArchetype(
            rhythm,
            decision,
            support,
          );
          expect(
            archetype.name,
            expectedName,
            reason: 'Failed for $expectedName',
          );
        }
      });
    });

    group('getConfidenceTier', () {
      test('0-3 answers returns earlySnapshot', () {
        expect(engine.getConfidenceTier(0), ConfidenceTier.earlySnapshot);
        expect(engine.getConfidenceTier(1), ConfidenceTier.earlySnapshot);
        expect(engine.getConfidenceTier(3), ConfidenceTier.earlySnapshot);
      });

      test('4-8 answers returns standard', () {
        expect(engine.getConfidenceTier(4), ConfidenceTier.standard);
        expect(engine.getConfidenceTier(6), ConfidenceTier.standard);
        expect(engine.getConfidenceTier(8), ConfidenceTier.standard);
      });

      test('9-12 answers returns fullClarity', () {
        expect(engine.getConfidenceTier(9), ConfidenceTier.fullClarity);
        expect(engine.getConfidenceTier(10), ConfidenceTier.fullClarity);
        expect(engine.getConfidenceTier(12), ConfidenceTier.fullClarity);
      });
    });

    group('generateResult', () {
      test('generates complete result with all fields populated', () {
        final session = AnswerSession(
          userId: 'test-user',
          sessionId: 'session-1',
          selectedAnswers: {
            1: 0, // Q1: Steady
            3: 1, // Q3: Momentum
            4: 1, // Q4: Collaborative
            5: 0, // Q5: Steady
            6: 1, // Q6: Momentum
            7: 1, // Q7: Collaborative
          },
        );

        final result = engine.generateResult(session, moneyStyleQuestions);

        expect(result.archetype, isNotNull);
        expect(result.archetype.name, isNotEmpty);
        expect(result.confidenceTier, ConfidenceTier.standard);
        expect(result.dimensionScores, isNotNull);
        expect(result.moneyRhythmWinner, isNotNull);
        expect(result.decisionStyleWinner, isNotNull);
        expect(result.supportStyleWinner, isNotNull);
        expect(result.totalAnswered, 6);
      });

      test('early snapshot result has correct confidence label', () {
        final session = AnswerSession(
          userId: 'test-user',
          sessionId: 'session-1',
          selectedAnswers: {1: 0},
        );

        final result = engine.generateResult(session, moneyStyleQuestions);

        expect(result.confidenceTier, ConfidenceTier.earlySnapshot);
        expect(result.confidenceLabel, 'Early Snapshot');
      });

      test('full clarity result has correct confidence label', () {
        final session = AnswerSession(
          userId: 'test-user',
          sessionId: 'session-1',
          selectedAnswers: {
            1: 0,
            2: 0,
            3: 0,
            4: 0,
            5: 0,
            6: 0,
            7: 0,
            8: 0,
            9: 0,
            10: 0,
            11: 0,
            12: 0,
          },
        );

        final result = engine.generateResult(session, moneyStyleQuestions);

        expect(result.confidenceTier, ConfidenceTier.fullClarity);
        expect(result.confidenceLabel, 'Full Clarity');
      });
    });
  });
}
