import 'package:flutter/material.dart';

import '../models/money_style.dart';
import 'money_style_quiz_screen.dart';

class MoneyStyleFlow extends StatefulWidget {
  const MoneyStyleFlow({
    super.key,
    required this.userId,
    required this.onComplete,
  });

  final String userId;
  final ValueChanged<MoneyStyleCompletion> onComplete;

  @override
  State<MoneyStyleFlow> createState() => _MoneyStyleFlowState();
}

class _MoneyStyleFlowState extends State<MoneyStyleFlow> {
  bool _quizStarted = false;

  @override
  Widget build(BuildContext context) {
    if (_quizStarted) {
      return MoneyStyleQuizScreen(
        userId: widget.userId,
        onComplete: widget.onComplete,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    'Discover Your Money Style',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff173b2f),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Twelve everyday choices. No dollar amounts. No judgement.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text('About 2–3 minutes', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  const Text('A light reflection on your current habits — not financial, mental-health, or clinical advice.', textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Text(
                    'Notice the patterns that feel closest today. Your result can change as life changes.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  FilledButton.icon(
                    onPressed: _startQuiz,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Find My Style'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startQuiz() {
    setState(() {
      _quizStarted = true;
    });
  }
}
