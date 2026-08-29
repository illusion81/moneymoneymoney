import 'dart:math';
import 'package:flutter/material.dart';

import '../data/money_style_questions.dart';
import '../models/money_style.dart';
import '../services/money_style_engine.dart';

class MoneyStyleQuizScreen extends StatefulWidget {
  const MoneyStyleQuizScreen({
    super.key,
    required this.userId,
    required this.onComplete,
    this.answerOrderSeed,
  });

  final String userId;
  final ValueChanged<MoneyStyleCompletion> onComplete;
  final int? answerOrderSeed;

  @override
  State<MoneyStyleQuizScreen> createState() => _MoneyStyleQuizScreenState();
}

class _MoneyStyleQuizScreenState extends State<MoneyStyleQuizScreen> {
  late AnswerSession _session;
  late Map<int, List<int>> _answerOrder;
  int _currentQuestionIndex = 0;
  final MoneyStyleEngine _engine = MoneyStyleEngine();

  @override
  void initState() {
    super.initState();
    _session = AnswerSession(
      userId: widget.userId,
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    final random = Random(widget.answerOrderSeed ?? _session.sessionId.hashCode);
    _answerOrder = {
      for (final question in moneyStyleQuestions)
        question.id: (List<int>.generate(question.answers.length, (i) => i)..shuffle(random)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = moneyStyleQuestions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1);
    final total = moneyStyleQuestions.length;

    return Scaffold(
      appBar: AppBar(
        leading: _buildBackButton(),
        title: Text('Discover your Money Style'),
        elevation: 0,
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                        ),

                      // Prompt
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          currentQuestion.prompt,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),

                      // Answer buttons
                      ..._answerOrder[currentQuestion.id]!.map(
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnswerButton(
                            answer: currentQuestion.answers[index],
                            onPressed: () => _selectAnswer(index),
                            isSelected: _session.selectedAnswers[currentQuestion.id] == index,
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
                child: Row(
                  children: [
                    // Skip button
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
                        onPressed: _isAnswerSelected() ? _nextQuestion : null,
                        child: const Text('Next'),
                      ),
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
    return _currentQuestionIndex == 0
        ? const SizedBox.shrink()
        : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _previousQuestion,
          );
  }

  bool _isAnswerSelected() {
    return _session.selectedAnswers.containsKey(moneyStyleQuestions[_currentQuestionIndex].id);
  }

  void _selectAnswer(int answerIndex) {
    setState(() {
      final questionId = moneyStyleQuestions[_currentQuestionIndex].id;
      _session.selectedAnswers[questionId] = answerIndex;
      _session.skippedQuestions.remove(questionId);
    });
  }

  void _skipQuestion() {
    setState(() {
      final questionId = moneyStyleQuestions[_currentQuestionIndex].id;
      _session.skippedQuestions.add(questionId);
      _session.selectedAnswers.remove(questionId);
      _moveToNextQuestion();
    });
  }

  void _nextQuestion() {
    if (_isAnswerSelected()) {
      _moveToNextQuestion();
    }
  }

  void _moveToNextQuestion() {
    if (_currentQuestionIndex < moneyStyleQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Quiz complete
      final result = _engine.generateResult(_session, moneyStyleQuestions);
      widget.onComplete(MoneyStyleCompletion(session: _session, result: result));
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
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
