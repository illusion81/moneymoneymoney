import 'package:flutter/material.dart';

import '../models/money_style.dart';

class MoneyStyleIdeasScreen extends StatelessWidget {
  const MoneyStyleIdeasScreen({
    super.key,
    required this.result,
    required this.onBack,
  });

  final MoneyStyleResult result;
  final VoidCallback onBack;

  String get rhythm => result.moneyRhythmWinner == MoneyRhythmPole.steady
      ? 'a small repeatable reminder'
      : 'a flexible weekly reset';
  String get decision => result.decisionStyleWinner == DecisionStylePole.pause
      ? 'a compare-before-deciding note'
      : 'a next-step note for quick decisions';
  String get support =>
      result.supportStyleWinner == SupportStylePole.selfDirected
      ? 'a private check-in you control'
      : 'a short check-in with someone you trust';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ideas for your style')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.archetype.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          const Text('You could try:'),
          Text('• $rhythm for your money rhythm.'),
          Text('• $decision for your decision style.'),
          Text('• $support for your support style.'),
          const SizedBox(height: 12),
          const Text('These are optional prompts, not financial advice.'),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onBack,
              child: const Text('Back to Money Style'),
            ),
          ),
        ],
      ),
    ),
  );
}
