import '../data/money_style_archetypes.dart';
import '../models/money_style.dart';

class MoneyStyleEngine {
  // Calculate raw dimension scores from selected answers
  DimensionScores calculateDimensionScores(
    AnswerSession session,
    List<MoneyStyleQuestion> questions,
  ) {
    final scores = DimensionScores();

    for (final entry in session.selectedAnswers.entries) {
      final questionId = entry.key;
      final answerIndex = entry.value;

      if (questionId < 1 || questionId > questions.length) {
        continue;
      }

      final question = questions.firstWhere(
        (q) => q.id == questionId,
        orElse: () => questions[questionId - 1],
      );

      if (answerIndex < 0 || answerIndex >= question.answers.length) {
        continue;
      }

      final answer = question.answers[answerIndex];

      // Increment the appropriate counter based on dimension and pole
      switch (answer.dimension) {
        case Dimension.moneyRhythm:
          if (answer.pole == MoneyRhythmPole.steady) {
            scores.incrementSteady();
          } else {
            scores.incrementResponsive();
          }
          break;
        case Dimension.decisionStyle:
          if (answer.pole == DecisionStylePole.pause) {
            scores.incrementPause();
          } else {
            scores.incrementMomentum();
          }
          break;
        case Dimension.supportStyle:
          if (answer.pole == SupportStylePole.selfDirected) {
            scores.incrementSelf();
          } else {
            scores.incrementCollaborative();
          }
          break;
      }
    }

    return scores;
  }

  // Apply tie-breaker logic for each dimension
  DimensionScores applyTieBreakers(
    DimensionScores scores,
    AnswerSession session,
    List<MoneyStyleQuestion> questions,
  ) {
    var updatedScores = scores;

    // Money Rhythm tie-breaker: Q2
    if (scores.steadyCount == scores.responsiveCount) {
      final breakerAnswer = _getTieBreakerAnswer(2, session, questions);
      if (breakerAnswer != null &&
          breakerAnswer.dimension == Dimension.moneyRhythm) {
        if (breakerAnswer.pole == MoneyRhythmPole.steady) {
          updatedScores = updatedScores.copyWith(steadyCount: scores.steadyCount + 1);
        } else {
          updatedScores = updatedScores.copyWith(responsiveCount: scores.responsiveCount + 1);
        }
      }
    }

    // Decision Style tie-breaker: Q8
    if (updatedScores.pauseCount == updatedScores.momentumCount) {
      final breakerAnswer = _getTieBreakerAnswer(8, session, questions);
      if (breakerAnswer != null &&
          breakerAnswer.dimension == Dimension.decisionStyle) {
        if (breakerAnswer.pole == DecisionStylePole.pause) {
          updatedScores = updatedScores.copyWith(pauseCount: updatedScores.pauseCount + 1);
        } else {
          updatedScores = updatedScores.copyWith(momentumCount: updatedScores.momentumCount + 1);
        }
      }
    }

    // Support Style tie-breaker: Q11
    if (updatedScores.selfCount == updatedScores.collaborativeCount) {
      final breakerAnswer = _getTieBreakerAnswer(11, session, questions);
      if (breakerAnswer != null &&
          breakerAnswer.dimension == Dimension.supportStyle) {
        if (breakerAnswer.pole == SupportStylePole.selfDirected) {
          updatedScores = updatedScores.copyWith(selfCount: updatedScores.selfCount + 1);
        } else {
          updatedScores = updatedScores.copyWith(collaborativeCount: updatedScores.collaborativeCount + 1);
        }
      }
    }

    return updatedScores;
  }

  // Helper to get the tie-breaker answer for a given question
  MoneyStyleAnswer? _getTieBreakerAnswer(
    int questionId,
    AnswerSession session,
    List<MoneyStyleQuestion> questions,
  ) {
    if (!session.selectedAnswers.containsKey(questionId)) {
      return null;
    }

    final answerIndex = session.selectedAnswers[questionId]!;
    final question = questions.firstWhere(
      (q) => q.id == questionId,
      orElse: () => questions[questionId - 1],
    );

    if (answerIndex < 0 || answerIndex >= question.answers.length) {
      return null;
    }

    return question.answers[answerIndex];
  }

  // Determine the winner for each dimension
  MoneyRhythmPole getMoneyRhythmWinner(DimensionScores scores) {
    if (scores.steadyCount > scores.responsiveCount) {
      return MoneyRhythmPole.steady;
    } else if (scores.responsiveCount > scores.steadyCount) {
      return MoneyRhythmPole.responsive;
    } else {
      // If still tied (rare), default to steady
      return MoneyRhythmPole.steady;
    }
  }

  DecisionStylePole getDecisionStyleWinner(DimensionScores scores) {
    if (scores.pauseCount > scores.momentumCount) {
      return DecisionStylePole.pause;
    } else if (scores.momentumCount > scores.pauseCount) {
      return DecisionStylePole.momentum;
    } else {
      // If still tied (rare), default to pause
      return DecisionStylePole.pause;
    }
  }

  SupportStylePole getSupportStyleWinner(DimensionScores scores) {
    if (scores.selfCount > scores.collaborativeCount) {
      return SupportStylePole.selfDirected;
    } else if (scores.collaborativeCount > scores.selfCount) {
      return SupportStylePole.collaborative;
    } else {
      // If still tied (rare), default to self-directed
      return SupportStylePole.selfDirected;
    }
  }

  // Map 3D pattern to archetype
  ArchetypeInfo mapScoresToArchetype(
    MoneyRhythmPole moneyRhythm,
    DecisionStylePole decisionStyle,
    SupportStylePole supportStyle,
  ) {
    final isMoneyRhythmSteady = moneyRhythm == MoneyRhythmPole.steady;
    final isDecisionStylePause = decisionStyle == DecisionStylePole.pause;
    final isSupportStyleSelf = supportStyle == SupportStylePole.selfDirected;

    return getArchetypeByPattern(isMoneyRhythmSteady, isDecisionStylePause, isSupportStyleSelf);
  }

  // Determine confidence tier based on number of answers
  ConfidenceTier getConfidenceTier(int answerCount) {
    if (answerCount <= 3) {
      return ConfidenceTier.earlySnapshot;
    } else if (answerCount <= 8) {
      return ConfidenceTier.standard;
    } else {
      return ConfidenceTier.fullClarity;
    }
  }

  // Generate final result from a session
  MoneyStyleResult generateResult(
    AnswerSession session,
    List<MoneyStyleQuestion> questions,
  ) {
    // Calculate raw scores
    var scores = calculateDimensionScores(session, questions);

    // Apply tie-breakers
    scores = applyTieBreakers(scores, session, questions);

    // Get winners for each dimension
    final moneyRhythmWinner = getMoneyRhythmWinner(scores);
    final decisionStyleWinner = getDecisionStyleWinner(scores);
    final supportStyleWinner = getSupportStyleWinner(scores);

    // Map to archetype
    final archetype = mapScoresToArchetype(
      moneyRhythmWinner,
      decisionStyleWinner,
      supportStyleWinner,
    );

    // Determine confidence tier
    final confidenceTier = getConfidenceTier(session.totalAnswered);

    return MoneyStyleResult(
      archetype: archetype,
      confidenceTier: confidenceTier,
      dimensionScores: scores,
      moneyRhythmWinner: moneyRhythmWinner,
      decisionStyleWinner: decisionStyleWinner,
      supportStyleWinner: supportStyleWinner,
      totalAnswered: session.totalAnswered,
    );
  }
}
