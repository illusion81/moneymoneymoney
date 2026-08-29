/// Money Style question bank v2 — six bipolar habit dimensions.
///
/// Every dimension has three poles (bad / mixed / good) and every answer
/// option carries both a categorical pole tag (drives archetype naming and
/// the result-screen "reveals" copy) and a numeric weight of -1/0/+1 (drives
/// page scoring and the adaptive page-3/4 routing). The two coexist on the
/// same record — see the design doc, §C.1.
library;

/// The six habit dimensions, declared in evidence-strength priority order.
/// That order is load-bearing: it is the final tie-break when two dimensions
/// look equally decisive during follow-up routing (design §C.4, step 2c).
enum Dimension {
  revolvingDebtNeglect,
  convenienceImpulse,
  subscriptionBlindness,
  savingsAvoidance,
  priceAnchoring,
  financialAvoidance,
}

/// Fixed dimension priority order (design §B). `Dimension.values` already
/// declares them in this order; this alias exists so the intent is explicit
/// wherever ranking code depends on it.
const List<Dimension> kDimensionPriority = Dimension.values;

/// The three dimensions whose signs form the archetype key (design §F.8).
/// These are also page 1's dimensions.
const List<Dimension> kArchetypeDimensions = [
  Dimension.revolvingDebtNeglect,
  Dimension.convenienceImpulse,
  Dimension.priceAnchoring,
];

/// Page 1 and page 2 are fixed and unconditional (design §C.3).
const List<Dimension> kPageOneDimensions = kArchetypeDimensions;
const List<Dimension> kPageTwoDimensions = [
  Dimension.subscriptionBlindness,
  Dimension.savingsAvoidance,
  Dimension.financialAvoidance,
];

/// Which slot of a dimension's 4-question set a question fills.
/// The branch describes the *scenario framing* — every question still offers
/// a full bad/mixed/good triad.
enum QuestionBranch { opening, badDrill, goodDrill, mixedClarify }

/// The bad/mixed/good band an answer sits in. Kept alongside [MoneyStyleAnswer.weight]
/// so code can read intent without re-deriving it from the integer.
enum PoleBand { bad, mixed, good }

extension PoleBandWeight on PoleBand {
  int get weight => switch (this) {
    PoleBand.bad => -1,
    PoleBand.mixed => 0,
    PoleBand.good => 1,
  };
}

// --- Per-dimension categorical pole tags (design §B) -----------------------
// Retained from v1 in spirit: descriptive, no numeric behaviour, used for
// archetype/result copy. Each now has a third, genuinely-good pole.

enum RevolvingDebtNeglectPole {
  balanceCarrier,
  dueDateBlind,
  autopayFullBalance,
}

enum ConvenienceImpulsePole {
  rideOrDeliveryReflex,
  looseUnmonitored,
  preDecidedRule,
}

enum SubscriptionBlindnessPole { forgottenCharge, neverAudits, recentAudit }

enum SavingsAvoidancePole { noBuffer, thinBuffer, automatedTransfer }

enum PriceAnchoringPole { priciestDefault, upsellAccepter, priceAnchorSet }

enum FinancialAvoidancePole { routineAvoidance, acuteAvoidance, regularCheckIn }

/// The pole values of a dimension, ordered bad → mixed → good.
List<Object> poleValuesFor(Dimension dimension) => switch (dimension) {
  Dimension.revolvingDebtNeglect => RevolvingDebtNeglectPole.values,
  Dimension.convenienceImpulse => ConvenienceImpulsePole.values,
  Dimension.subscriptionBlindness => SubscriptionBlindnessPole.values,
  Dimension.savingsAvoidance => SavingsAvoidancePole.values,
  Dimension.priceAnchoring => PriceAnchoringPole.values,
  Dimension.financialAvoidance => FinancialAvoidancePole.values,
};

/// Short, human-readable dimension names for result copy.
String dimensionLabel(Dimension dimension) => switch (dimension) {
  Dimension.revolvingDebtNeglect => 'Credit card balances',
  Dimension.convenienceImpulse => 'Convenience spending',
  Dimension.subscriptionBlindness => 'Subscriptions',
  Dimension.savingsAvoidance => 'Saving a buffer',
  Dimension.priceAnchoring => 'Price anchoring',
  Dimension.financialAvoidance => 'Checking in on money',
};

enum ConfidenceTier { earlySnapshot, standard, fullClarity }

/// One of the 3 answer options for a question.
class MoneyStyleAnswer {
  const MoneyStyleAnswer({
    required this.id,
    required this.text,
    required this.dimension,
    required this.pole,
    required this.band,
    required this.reveals,
  });

  /// Stable storage identity, independent of randomised display order.
  final String id;
  final String text;
  final Dimension dimension;

  /// Categorical pole tag — one of the dimension's own pole enum values.
  final Object pole;

  /// bad / mixed / good.
  final PoleBand band;

  /// Human-readable "this reveals…" note used by result copy and analytics.
  final String reveals;

  /// Numeric weight: -1 (bad), 0 (mixed), +1 (good). Scoped to [dimension].
  int get weight => band.weight;

  @override
  String toString() => text;
}

/// A single question with its 3 answers.
class MoneyStyleQuestion {
  const MoneyStyleQuestion({
    required this.id,
    required this.dimension,
    required this.branch,
    required this.scenario,
    required this.prompt,
    required this.answers,
  });

  final int id;
  final Dimension dimension;
  final QuestionBranch branch;
  final String scenario;
  final String prompt;
  final List<MoneyStyleAnswer> answers; // Always exactly 3

  bool get isOpener => branch == QuestionBranch.opening;

  @override
  String toString() => 'Q$id: $prompt';
}

/// The running score structure for a session (design §C.2 / §F.4).
///
/// One class, two views of the same answers:
///  * a numeric running total per dimension (`null` = unscored), which drives
///    routing and the final read; and
///  * categorical pole counts, kept for archetype / "reveals" copy.
///
/// Both are updated by the same [record] call so they can never drift apart.
class DimensionScores {
  DimensionScores();

  /// Rebuilds a score set from an explicit map — handy in tests and when
  /// restoring a persisted session.
  factory DimensionScores.fromTotals(Map<Dimension, int?> totals) {
    final scores = DimensionScores();
    for (final entry in totals.entries) {
      final value = entry.value;
      if (value != null) {
        scores._totals[entry.key] = value;
        scores._dataPoints[entry.key] = 1;
      }
    }
    return scores;
  }

  final Map<Dimension, int> _totals = {};
  final Map<Dimension, int> _dataPoints = {};
  final Map<Dimension, Map<Object, int>> _poleCounts = {};

  /// Applies one answer. Live, per-answer — never batched at page end.
  void record(MoneyStyleAnswer answer) {
    final dimension = answer.dimension;
    _totals[dimension] = (_totals[dimension] ?? 0) + answer.weight;
    _dataPoints[dimension] = (_dataPoints[dimension] ?? 0) + 1;
    final poles = _poleCounts.putIfAbsent(dimension, () => <Object, int>{});
    poles[answer.pole] = (poles[answer.pole] ?? 0) + 1;
  }

  /// Running total for [dimension], or null when it has no data point at all.
  /// Unscored (`null`) and "answered mixed" (`0`) are deliberately distinct.
  int? scoreFor(Dimension dimension) => _totals[dimension];

  bool isUnscored(Dimension dimension) => !_totals.containsKey(dimension);

  /// How many answers have landed on [dimension].
  int dataPointsFor(Dimension dimension) => _dataPoints[dimension] ?? 0;

  int poleCount(Dimension dimension, Object pole) =>
      _poleCounts[dimension]?[pole] ?? 0;

  Map<Object, int> polesFor(Dimension dimension) =>
      Map.unmodifiable(_poleCounts[dimension] ?? const <Object, int>{});

  /// Every dimension, including the unscored ones (as `null`).
  Map<Dimension, int?> get totals => {
    for (final dimension in Dimension.values) dimension: _totals[dimension],
  };

  /// Dimensions with at least one answer.
  Set<Dimension> get observedDimensions => _totals.keys.toSet();

  /// Dimensions that have no answer at all.
  Set<Dimension> get unscoredDimensions =>
      Dimension.values.where(isUnscored).toSet();

  /// Most negative dimension (the "most critical habit"), null when nothing
  /// scored negative. Ties break on the fixed dimension priority order.
  Dimension? get mostCritical => _extreme(negative: true);

  /// Most positive dimension (the "strongest habit"), null when nothing
  /// scored positive.
  Dimension? get strongest => _extreme(negative: false);

  Dimension? _extreme({required bool negative}) {
    Dimension? best;
    int? bestScore;
    for (final dimension in kDimensionPriority) {
      final score = _totals[dimension];
      if (score == null) continue;
      if (negative ? score >= 0 : score <= 0) continue;
      if (bestScore == null ||
          (negative ? score < bestScore : score > bestScore)) {
        best = dimension;
        bestScore = score;
      }
    }
    return best;
  }

  DimensionScores copy() {
    final clone = DimensionScores();
    clone._totals.addAll(_totals);
    clone._dataPoints.addAll(_dataPoints);
    for (final entry in _poleCounts.entries) {
      clone._poleCounts[entry.key] = Map<Object, int>.from(entry.value);
    }
    return clone;
  }

  @override
  String toString() => Dimension.values
      .map((d) => '${d.name}: ${_totals[d] ?? '–'}')
      .join(' | ');
}

/// Tracks a user's quiz session.
class AnswerSession {
  AnswerSession({
    required this.userId,
    required this.sessionId,
    Map<int, int>? selectedAnswers,
    Set<int>? skippedQuestions,
    List<int>? shownQuestionIds,
    DateTime? timestamp,
  }) : selectedAnswers = selectedAnswers ?? {},
       skippedQuestions = skippedQuestions ?? {},
       shownQuestionIds = shownQuestionIds ?? [],
       timestamp = timestamp ?? DateTime.now();

  final String userId;
  final String sessionId;
  final Map<int, int> selectedAnswers; // question_id -> answer_index
  final Set<int> skippedQuestions;

  /// Which of the 24 pool questions this session actually put in front of the
  /// user, in the order they were shown — one entry per slot, so a re-shown
  /// opener (the skipped-opener catch-up case) legitimately appears twice.
  /// Two users see different follow-up sets, so this can't be inferred from a
  /// fixed list (design §F.6).
  final List<int> shownQuestionIds;

  final DateTime timestamp;

  int get totalAnswered => selectedAnswers.length;
  int get totalSkipped => skippedQuestions.length;

  /// Replaces the shown-question record with [ids]. The quiz screen owns the
  /// page list, so it rewrites this wholesale rather than appending, which
  /// keeps the record exact when adaptive pages are recomputed.
  void setShownQuestions(Iterable<int> ids) {
    shownQuestionIds
      ..clear()
      ..addAll(ids);
  }

  AnswerSession snapshot() => AnswerSession(
    userId: userId,
    sessionId: sessionId,
    selectedAnswers: Map<int, int>.from(selectedAnswers),
    skippedQuestions: Set<int>.from(skippedQuestions),
    shownQuestionIds: List<int>.from(shownQuestionIds),
    timestamp: timestamp,
  );

  /// A session is complete once every question it was actually shown has been
  /// answered or skipped, and it reached the full 12-question length.
  bool isCompleteFor(List<MoneyStyleQuestion> questions) {
    if (selectedAnswers.keys.any(skippedQuestions.contains)) {
      return false;
    }
    if (shownQuestionIds.isEmpty) {
      return false;
    }
    final resolved = shownQuestionIds.every(
      (id) => selectedAnswers.containsKey(id) || skippedQuestions.contains(id),
    );
    return resolved && shownQuestionIds.length >= kQuestionsPerSession;
  }

  Map<String, String> answerIdsFor(List<MoneyStyleQuestion> questions) {
    final values = <String, String>{};
    for (final entry in selectedAnswers.entries) {
      MoneyStyleQuestion? question;
      for (final candidate in questions) {
        if (candidate.id == entry.key) {
          question = candidate;
          break;
        }
      }
      if (question != null &&
          entry.value >= 0 &&
          entry.value < question.answers.length) {
        values['${entry.key}'] = question.answers[entry.value].id;
      }
    }
    return values;
  }
}

/// 4 pages × 3 questions.
const int kQuestionsPerPage = 3;
const int kPagesPerSession = 4;
const int kQuestionsPerSession = kQuestionsPerPage * kPagesPerSession;

/// All metadata for an archetype.
class ArchetypeInfo {
  const ArchetypeInfo({
    required this.id,
    required this.name,
    required this.playfulDescriptor,
    required this.strengths,
    required this.interpretation,
    required this.pattern,
  });

  /// Stable analytics identity, sent to the backend as `archetype_id`.
  final String id;
  final String name; // e.g., "The Quiet Compounder"
  final String playfulDescriptor;
  final List<String> strengths; // 3 bullet points
  final String interpretation;
  final String pattern; // human-readable 3-dimension pattern

  @override
  String toString() => name;
}

/// The final output of the quiz.
class MoneyStyleResult {
  const MoneyStyleResult({
    required this.archetype,
    required this.confidenceTier,
    required this.dimensionScores,
    required this.totalAnswered,
  });

  final ArchetypeInfo archetype;
  final ConfidenceTier confidenceTier;
  final DimensionScores dimensionScores;
  final int totalAnswered;

  /// Running totals per dimension (null = never answered).
  Map<Dimension, int?> get dimensionTotals => dimensionScores.totals;

  /// The habit worth working on first, if any answer leaned negative.
  Dimension? get mostCriticalDimension => dimensionScores.mostCritical;

  /// The habit already working, if any answer leaned positive.
  Dimension? get strongestDimension => dimensionScores.strongest;

  String get confidenceLabel {
    switch (confidenceTier) {
      case ConfidenceTier.earlySnapshot:
        return 'Early Snapshot';
      case ConfidenceTier.standard:
        return 'Standard';
      case ConfidenceTier.fullClarity:
        return 'Full Clarity';
    }
  }
}

/// Keeps the raw session even when it cannot honestly support an archetype.
class MoneyStyleCompletion {
  const MoneyStyleCompletion({required this.session, required this.result});

  final AnswerSession session;
  final MoneyStyleResult? result;

  bool get hasEnoughEvidence => result != null;
}
