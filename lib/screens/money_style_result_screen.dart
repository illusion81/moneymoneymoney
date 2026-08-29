import 'package:flutter/material.dart';

import '../models/money_style.dart';

class MoneyStyleResultScreen extends StatelessWidget {
  const MoneyStyleResultScreen({
    super.key,
    required this.result,
    this.onExplore,
    this.onBuildPlan,
  });

  final MoneyStyleResult result;

  /// Where the two buttons go. Left null they fall back to a snackbar, so the
  /// screen still works standalone (e.g. in a widget test).
  final VoidCallback? onExplore;
  final VoidCallback? onBuildPlan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Money Style'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Confidence tier badge (if not full clarity)
              if (result.confidenceTier != ConfidenceTier.fullClarity)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Chip(
                    label: Text(result.confidenceLabel),
                    backgroundColor: Colors.amber[100],
                  ),
                ),

              // Archetype name (large)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  result.archetype.name,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff173b2f),
                  ),
                ),
              ),

              // Playful descriptor
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  result.archetype.playfulDescriptor,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

              // Divider
              Divider(color: Colors.grey[300]),

              // Strengths section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Strengths',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...result.archetype.strengths.map(
                      (strength) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 12, top: 4),
                              child: Text(
                                '•',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                strength,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Divider(color: Colors.grey[300]),

              // Interpretation section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What This Means',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.archetype.interpretation,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                  ],
                ),
              ),

              // Dimension breakdown (optional, for transparency)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Pattern',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.archetype.pattern,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${result.totalAnswered} of 12 questions answered',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons (stubs for now)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: onExplore ??
                          () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Nothing wired here yet')),
                              ),
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('Explore ideas that fit my style'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onBuildPlan ??
                          () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Nothing wired here yet')),
                              ),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Build a practical plan with ranges'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
