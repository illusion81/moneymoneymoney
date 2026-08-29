import '../data/money_style_archetypes.dart';
import '../data/money_style_questions.dart';
import '../models/money_style.dart';

/// Scoring + adaptive routing for the Money Style quiz.
///
/// Pages 1–2 are fixed (the six openers). Pages 3–4 are computed from the
/// running per-dimension score by [selectFollowUpQuestions], which is the
/// single place routing logic lives — it replaces v1's per-dimension
/// hardcoded tie-breaker blocks entirely.
class MoneyStyleEngine {
  const MoneyStyleEngine();

  /// True once every dimension has at least one answer.
  bool hasMinimumDimensionCoverage(
    AnswerSession session,
    List<MoneyStyleQuestion> questions,
  ) {
    final scores = calculateDimensionScores(session, questions);
    return scores.observedDimensions.length == Dimension.values.length;
  }

  /// Replays a session's answers through the same per-answer update the live
  /// quiz uses, so a restored session scores identically to a live one.
  DimensionScores calculateDimensionScores(
    AnswerSession session,
    List<MoneyStyleQuestion> questions,
  ) {
    final scores = DimensionScores();
    for (final entry in session.selectedAnswers.entries) {
      final answer = _answerFor(entry.key, entry.value, questions);
      if (answer != null) {
        scores.record(answer);
      }
    }
    return scores;
  }

  MoneyStyleAnswer? _answerFor(
    int questionId,
    int answerIndex,
    List<MoneyStyleQuestion> questions,
  ) {
    for (final question in questions) {
      if (question.id != questionId) continue;
      if (answerIndex < 0 || answerIndex >= question.answers.length) {
        return null;
      }
      return question.answers[answerIndex];
    }
    return null;
  }

  // ------------------------------------------------------- adaptive routing

  /// Ranks dimensions by decisiveness, per design §C.4 steps 1–2:
  ///
  ///  1. `|score|` descending;
  ///  2a. an unscored (`null`) dimension outranks every scored one;
  ///  2b. at equal magnitude, a negative score outranks a positive one;
  ///  2c. remaining ties break on the fixed dimension priority order.
  List<Dimension> rankDimensions(
    DimensionScores scores, {
    Iterable<Dimension>? candidates,
  }) {
    final ranked = (candidates ?? kDimensionPriority).toList()
      ..sort((a, b) => _compare(a, b, scores));
    return ranked;
  }

  int _compare(Dimension a, Dimension b, DimensionScores scores) {
    final scoreA = scores.scoreFor(a);
    final scoreB = scores.scoreFor(b);

    // 2a — unscored outranks everything, regardless of magnitude.
    if ((scoreA == null) != (scoreB == null)) {
      return scoreA == null ? -1 : 1;
    }

    if (scoreA != null && scoreB != null) {
      // 1 — larger magnitude first.
      final magnitude = scoreB.abs().compareTo(scoreA.abs());
      if (magnitude != 0) return magnitude;

      // 2b — at equal magnitude, negative (a risk) before positive (a win).
      final sign = _signRank(scoreA).compareTo(_signRank(scoreB));
      if (sign != 0) return sign;
    }

    // 2c — fixed priority order.
    return kDimensionPriority
        .indexOf(a)
        .compareTo(kDimensionPriority.indexOf(b));
  }

  /// Negative first, then positive. Zero only ever ties with zero.
  int _signRank(int score) => score < 0 ? 0 : (score > 0 ? 1 : 2);

  /// Which follow-up branch a dimension gets, from its score *at the moment
  /// the page is generated* (design §C.4 step 4).
  QuestionBranch branchFor(int? score) {
    if (score == null) return QuestionBranch.opening; // catch-up re-show
    if (score < 0) return QuestionBranch.badDrill;
    if (score > 0) return QuestionBranch.goodDrill;
    return QuestionBranch.mixedClarify;
  }

  /// Picks the 3 questions for the next adaptive page.
  ///
  /// Page 3 passes no [exclude] and gets the top 3 ranked dimensions. Page 4
  /// passes page 3's dimensions as [exclude] and therefore gets the
  /// deterministic complement — the two pages exactly partition the 6
  /// dimensions, so every dimension gets exactly one deepening question.
  ///
  /// The variant is chosen from the *current* score, so page 4's pick reflects
  /// page 3's answers rather than the page-2 snapshot.
  List<MoneyStyleQuestion> selectFollowUpQuestions(
    DimensionScores scores, {
    Set<Dimension> exclude = const {},
    int slots = kQuestionsPerPage,
  }) {
    final candidates = kDimensionPriority.where((d) => !exclude.contains(d));
    final ranked = rankDimensions(scores, candidates: candidates);
    return [
      for (final dimension in ranked.take(slots))
        questionFor(dimension, branchFor(scores.scoreFor(dimension))),
    ];
  }

  // -------------------------------------------------------------- result

  /// Confidence is about *coverage*, not raw answer count (design §F.7).
  ///
  /// The answer-count boundaries follow the page structure (3 / 6 / 12), but a
  /// session with skips can hit 6 answers while still leaving a dimension with
  /// no data at all — so a dimension with zero data points holds the session
  /// down to the lower tier rather than letting the count alone speak.
  ConfidenceTier getConfidenceTier(int answerCount, {DimensionScores? scores}) {
    final everyDimensionHeard =
        scores == null ||
        scores.observedDimensions.length == Dimension.values.length;

    // Fewer answers than the two fixed pages hold: at best a partial picture.
    if (answerCount < kQuestionsPerPage * 2) {
      return ConfidenceTier.earlySnapshot;
    }
    // Full clarity needs both the full 12 *and* something heard on every
    // dimension — with adaptive routing plus skips, 12 answers no longer
    // implies full breadth on its own.
    if (answerCount < kQuestionsPerSession || !everyDimensionHeard) {
      return ConfidenceTier.standard;
    }
    return ConfidenceTier.fullClarity;
  }

  /// Collapses the page-1 trio's scores into the 3-bit archetype key.
  /// See the note in `money_style_archetypes.dart` for why an exact 0 is
  /// treated as "watch" rather than a fourth balanced state.
  ArchetypeInfo mapScoresToArchetype(DimensionScores scores) {
    bool holding(Dimension dimension) => (scores.scoreFor(dimension) ?? 0) > 0;
    return getArchetypeByPattern(
      holding(Dimension.revolvingDebtNeglect),
      holding(Dimension.convenienceImpulse),
      holding(Dimension.priceAnchoring),
    );
  }

  /// Generates the final result, or null when the session cannot honestly
  /// support one (a dimension with no answer at all).
  MoneyStyleResult? generateResult(
    AnswerSession session,
    List<MoneyStyleQuestion> questions,
  ) {
    final scores = calculateDimensionScores(session, questions);
    if (scores.observedDimensions.length != Dimension.values.length) {
      return null;
    }
    return MoneyStyleResult(
      archetype: mapScoresToArchetype(scores),
      confidenceTier: getConfidenceTier(session.totalAnswered, scores: scores),
      dimensionScores: scores,
      totalAnswered: session.totalAnswered,
    );
  }

  /// The fixed first two pages, identical for every user (design §C.3).
  List<List<MoneyStyleQuestion>> get fixedPages => [
    moneyStyleOpeners.sublist(0, kQuestionsPerPage),
    moneyStyleOpeners.sublist(kQuestionsPerPage, kQuestionsPerPage * 2),
  ];
}
