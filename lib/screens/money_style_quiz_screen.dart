import 'dart:math';
import 'package:flutter/material.dart';

import '../data/money_style_questions.dart';
import '../demo_flags.dart';
import '../models/money_style.dart';
import '../services/money_style_engine.dart';
import '../widgets/dev_gate.dart';

/// The quiz, page-sequential.
///
/// The engine owns the whole 24-question pool on device; this screen renders
/// page 1 (fixed), then page 2 (fixed), then asks the engine for page 3's and
/// page 4's three question IDs at each page boundary, computed from the
/// running score. Scoring stays on device — the backend only ever sees the
/// finished session — so no new endpoint is involved (design §C.5 option b).
class MoneyStyleQuizScreen extends StatefulWidget {
  const MoneyStyleQuizScreen({
    super.key,
    required this.userId,
    required this.onComplete,
    this.answerOrderSeed,
    this.initialSession,
    this.onProgress,
    this.onSkipAll,
  });

  final String userId;
  final ValueChanged<MoneyStyleCompletion> onComplete;
  final int? answerOrderSeed;
  final AnswerSession? initialSession;
  final ValueChanged<AnswerSession>? onProgress;

  /// Leaves the questionnaire entirely. Reachable from every page so the flow
  /// never feels like a trap.
  final VoidCallback? onSkipAll;

  @override
  State<MoneyStyleQuizScreen> createState() => _MoneyStyleQuizScreenState();
}

class _MoneyStyleQuizScreenState extends State<MoneyStyleQuizScreen> {
  static const MoneyStyleEngine _engine = MoneyStyleEngine();

  late AnswerSession _session;
  late Random _random;

  /// Questions in the order this session shows them, three per page. Pages 1–2
  /// are fixed; pages 3–4 are appended when their boundary is reached.
  final List<List<MoneyStyleQuestion>> _pages = [];
  final Map<int, List<int>> _answerOrder = {};
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _session =
        widget.initialSession ??
        AnswerSession(
          userId: widget.userId,
          sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        );
    _random = Random(widget.answerOrderSeed ?? _session.sessionId.hashCode);
    _pages.addAll(_engine.fixedPages);
    _extendPages();
    final resumeIndex = _questions.indexWhere(
      (q) =>
          !_session.selectedAnswers.containsKey(q.id) &&
          !_session.skippedQuestions.contains(q.id),
    );
    _currentIndex = resumeIndex >= 0 ? resumeIndex : _questions.length - 1;
  }

  List<MoneyStyleQuestion> get _questions => [
    for (final page in _pages) ...page,
  ];

  MoneyStyleQuestion get _currentQuestion => _questions[_currentIndex];

  int get _currentPageIndex => _currentIndex ~/ kQuestionsPerPage;

  DimensionScores get _scores =>
      _engine.calculateDimensionScores(_session, moneyStyleQuestionPool);

  /// Whether every question on [pageIndex] has been answered or skipped.
  bool _pageResolved(int pageIndex) => _pages[pageIndex].every(
    (q) =>
        _session.selectedAnswers.containsKey(q.id) ||
        _session.skippedQuestions.contains(q.id),
  );

  /// Appends any adaptive page whose predecessor is now complete. Called at
  /// page boundaries and when restoring a session, so a resumed quiz rebuilds
  /// exactly the same pages a live one would have produced.
  void _extendPages() {
    while (_pages.length < kPagesPerSession &&
        _pageResolved(_pages.length - 1)) {
      final scores = _scores;
      final alreadyDeepened = <Dimension>{
        for (var page = 2; page < _pages.length; page++)
          ..._pages[page].map((q) => q.dimension),
      };
      _pages.add(
        _engine.selectFollowUpQuestions(scores, exclude: alreadyDeepened),
      );
    }
    _syncShownQuestions();
  }

  /// Keeps the session's shown-question record and the answer shuffle in step
  /// with the pages that currently exist.
  void _syncShownQuestions() {
    _session.setShownQuestions(_questions.map((q) => q.id));
    for (final question in _questions) {
      _answerOrder.putIfAbsent(
        question.id,
        () =>
            List<int>.generate(question.answers.length, (i) => i)
              ..shuffle(_random),
      );
    }
  }

  /// Changing an earlier page's answer invalidates every adaptive page routed
  /// from it, so those pages (and any answers collected on them) are dropped
  /// and recomputed rather than left stale.
  void _invalidatePagesAfter(int pageIndex) {
    final keep = max(pageIndex + 1, 2);
    if (_pages.length <= keep) return;
    final keptIds = {
      for (final page in _pages.take(keep)) ...page.map((q) => q.id),
    };
    for (final page in _pages.sublist(keep)) {
      for (final question in page) {
        if (keptIds.contains(question.id)) continue;
        _session.selectedAnswers.remove(question.id);
        _session.skippedQuestions.remove(question.id);
      }
    }
    _pages.removeRange(keep, _pages.length);
    _syncShownQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _currentQuestion;
    final progress = _currentIndex + 1;
    const total = kQuestionsPerSession;

    return Scaffold(
      appBar: AppBar(
        leading: _buildBackButton(),
        // "Discover your Money Style" does not fit a 390pt app bar next to a
        // back button — it truncated to "Discover your Money S…". The full
        // phrase already appears on the screen that launches the quiz.
        title: const Text('Money Style'),
        elevation: 0,
        actions: [
          // Both survive the merge and they do different things: "Skip for
          // now" abandons the quiz with no answers, the demo bolt answers it
          // so the result screen has a real archetype to show.
          if (widget.onSkipAll != null)
            TextButton(
              key: const Key('skip-questionnaire-button'),
              onPressed: widget.onSkipAll,
              child: const Text('Skip for now'),
            ),
          if (kDemoTools)
            IconButton(
              key: const Key('demo-skip-quiz'),
              tooltip: 'Demo: answer every question',
              icon: Icon(DevGate.isUnlocked ? Icons.bolt : Icons.lock_outline),
              onPressed: () async {
                if (await DevGate.ensureUnlocked(context)) _demoCompleteQuiz();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$progress of $total',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress / total,
                      minHeight: 8,
                    ),
                  ],
                ),
              ),

              // Question content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Scenario
                      if (currentQuestion.scenario.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              currentQuestion.scenario,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),

                      // Prompt
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          currentQuestion.prompt,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),

                      // Answer buttons
                      ..._answerOrder[currentQuestion.id]!.map(
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnswerButton(
                            answer: currentQuestion.answers[index],
                            onPressed: () => _selectAnswer(index),
                            isSelected:
                                _session.selectedAnswers[currentQuestion.id] ==
                                index,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        // Skip this one question
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _skipQuestion,
                            child: const Text('Skip'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Next button
                        Expanded(
                          child: FilledButton(
                            onPressed: _isAnswerSelected()
                                ? _nextQuestion
                                : null,
                            child: const Text('Next'),
                          ),
                        ),
                      ],
                    ),
                    // A second, always-visible way out, in the same place on
                    // every page — a user is never more than one tap from
                    // leaving the questionnaire.
                    if (widget.onSkipAll != null)
                      TextButton(
                        key: const Key('skip-questionnaire-footer-button'),
                        onPressed: widget.onSkipAll,
                        child: const Text('Skip the whole questionnaire'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return _currentIndex == 0
        ? const SizedBox.shrink()
        : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _previousQuestion,
          );
  }

  bool _isAnswerSelected() =>
      _session.selectedAnswers.containsKey(_currentQuestion.id);

  void _selectAnswer(int answerIndex) {
    setState(() {
      final questionId = _currentQuestion.id;
      _invalidatePagesAfter(_currentPageIndex);
      _session.selectedAnswers[questionId] = answerIndex;
      _session.skippedQuestions.remove(questionId);
      widget.onProgress?.call(_session.snapshot());
    });
  }

  /// Demo shortcut: answer the whole session and jump to the result.
  ///
  /// Rewritten for the adaptive quiz. The follow-up pages are chosen from the
  /// running score, so they do not exist until the page before them is
  /// answered — answering "all questions" once would only cover page one.
  /// Answer what exists, extend, repeat until no new page appears.
  ///
  /// It answers rather than skips so the result screen shows a real archetype
  /// instead of an empty session with no confidence.
  void _demoCompleteQuiz() {
    setState(() {
      var guard = 0;
      while (guard++ < kPagesPerSession + 2) {
        for (final q in _questions) {
          // putIfAbsent: a real answer already given stays.
          _session.selectedAnswers.putIfAbsent(q.id, () => 0);
          _session.skippedQuestions.remove(q.id);
        }
        final before = _questions.length;
        _extendPages();
        if (_questions.length == before) break;
      }
      _syncShownQuestions();
      _currentIndex = _questions.length - 1;
      widget.onProgress?.call(_session.snapshot());
    });

    final session = _session.snapshot();
    final result = _engine.generateResult(session, moneyStyleQuestionPool);
    widget.onComplete(MoneyStyleCompletion(session: session, result: result));
  }

  void _skipQuestion() {
    setState(() {
      final questionId = _currentQuestion.id;
      _invalidatePagesAfter(_currentPageIndex);
      _session.skippedQuestions.add(questionId);
      _session.selectedAnswers.remove(questionId);
      widget.onProgress?.call(_session.snapshot());
      _moveToNextQuestion();
    });
  }

  void _nextQuestion() {
    if (_isAnswerSelected()) {
      setState(_moveToNextQuestion);
    }
  }

  /// Must be called from inside a `setState`.
  void _moveToNextQuestion() {
    // At a page boundary, route the next page from the running score.
    if ((_currentIndex + 1) % kQuestionsPerPage == 0) {
      _extendPages();
    }

    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      return;
    }

    // Quiz complete. Navigation is owned by the app shell: onComplete
    // switches the view to AppView.moneyStyleResult.
    final session = _session.snapshot();
    final result = _engine.generateResult(session, moneyStyleQuestionPool);
    widget.onComplete(MoneyStyleCompletion(session: session, result: result));
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.answer,
    required this.onPressed,
    required this.isSelected,
  });

  final MoneyStyleAnswer answer;
  final VoidCallback onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.all(16),
      ),
      child: Text(
        answer.text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.black87,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
