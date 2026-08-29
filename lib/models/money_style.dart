// Enums for Money Style dimensions and poles
enum Dimension { moneyRhythm, decisionStyle, supportStyle }

enum MoneyRhythmPole { steady, responsive }

enum DecisionStylePole { pause, momentum }

enum SupportStylePole { selfDirected, collaborative }

enum ConfidenceTier { earlySnapshot, standard, fullClarity }

// MoneyStyleAnswer represents one of the 3 answer options for a question
class MoneyStyleAnswer {
  const MoneyStyleAnswer({
    required this.text,
    required this.dimension,
    required this.pole,
    this.isBreaker = false,
  });

  final String text;
  final Dimension dimension;
  final dynamic pole; // MoneyRhythmPole | DecisionStylePole | SupportStylePole
  final bool isBreaker; // True if this answer is a tie-breaker

  @override
  String toString() => text;
}

// MoneyStyleQuestion represents a single question with its 3 answers
class MoneyStyleQuestion {
  const MoneyStyleQuestion({
    required this.id,
    required this.scenario,
    required this.prompt,
    required this.answers,
  });

  final int id;
  final String scenario;
  final String prompt;
  final List<MoneyStyleAnswer> answers; // Always exactly 3

  @override
  String toString() => 'Q$id: $prompt';
}

// DimensionScores tracks the count for each pole in each dimension
class DimensionScores {
  DimensionScores({
    int steadyCount = 0,
    int responsiveCount = 0,
    int pauseCount = 0,
    int momentumCount = 0,
    int selfCount = 0,
    int collaborativeCount = 0,
  })  : _steadyCount = steadyCount,
        _responsiveCount = responsiveCount,
        _pauseCount = pauseCount,
        _momentumCount = momentumCount,
        _selfCount = selfCount,
        _collaborativeCount = collaborativeCount;

  int _steadyCount;
  int _responsiveCount;
  int _pauseCount;
  int _momentumCount;
  int _selfCount;
  int _collaborativeCount;

  // Getters
  int get steadyCount => _steadyCount;
  int get responsiveCount => _responsiveCount;
  int get pauseCount => _pauseCount;
  int get momentumCount => _momentumCount;
  int get selfCount => _selfCount;
  int get collaborativeCount => _collaborativeCount;

  // Increment helpers
  void incrementSteady() => _steadyCount++;
  void incrementResponsive() => _responsiveCount++;
  void incrementPause() => _pauseCount++;
  void incrementMomentum() => _momentumCount++;
  void incrementSelf() => _selfCount++;
  void incrementCollaborative() => _collaborativeCount++;

  // Copy with new values
  DimensionScores copyWith({
    int? steadyCount,
    int? responsiveCount,
    int? pauseCount,
    int? momentumCount,
    int? selfCount,
    int? collaborativeCount,
  }) {
    return DimensionScores(
      steadyCount: steadyCount ?? _steadyCount,
      responsiveCount: responsiveCount ?? _responsiveCount,
      pauseCount: pauseCount ?? _pauseCount,
      momentumCount: momentumCount ?? _momentumCount,
      selfCount: selfCount ?? _selfCount,
      collaborativeCount: collaborativeCount ?? _collaborativeCount,
    );
  }

  @override
  String toString() =>
      'Rhythm: $steadyCount Steady, $responsiveCount Responsive | '
      'Decision: $pauseCount Pause, $momentumCount Momentum | '
      'Support: $selfCount Self, $collaborativeCount Collaborative';
}

// AnswerSession tracks a user's quiz session
class AnswerSession {
  AnswerSession({
    required this.userId,
    required this.sessionId,
    Map<int, int>? selectedAnswers,
    Set<int>? skippedQuestions,
    DateTime? timestamp,
  })  : selectedAnswers = selectedAnswers ?? {},
        skippedQuestions = skippedQuestions ?? {},
        timestamp = timestamp ?? DateTime.now();

  final String userId;
  final String sessionId;
  final Map<int, int> selectedAnswers; // question_id -> answer_index
  final Set<int> skippedQuestions;
  final DateTime timestamp;

  int get totalAnswered => selectedAnswers.length;
  int get totalSkipped => skippedQuestions.length;
}

// ArchetypeInfo contains all metadata for an archetype
class ArchetypeInfo {
  const ArchetypeInfo({
    required this.name,
    required this.playfulDescriptor,
    required this.strengths,
    required this.interpretation,
    required this.pattern, // "Steady Pause Self" etc
  });

  final String name; // e.g., "The Calm Comparator"
  final String playfulDescriptor; // e.g., "The thoughtful steward"
  final List<String> strengths; // 3 bullet points
  final String interpretation; // Paragraph explaining the archetype
  final String pattern; // "Steady Pause Self" / "Steady Pause Collaborative" / etc

  @override
  String toString() => name;
}

// MoneyStyleResult is the final output of the quiz
class MoneyStyleResult {
  const MoneyStyleResult({
    required this.archetype,
    required this.confidenceTier,
    required this.dimensionScores,
    required this.moneyRhythmWinner,
    required this.decisionStyleWinner,
    required this.supportStyleWinner,
    required this.totalAnswered,
  });

  final ArchetypeInfo archetype;
  final ConfidenceTier confidenceTier;
  final DimensionScores dimensionScores;
  final MoneyRhythmPole moneyRhythmWinner;
  final DecisionStylePole decisionStyleWinner;
  final SupportStylePole supportStyleWinner;
  final int totalAnswered;

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
