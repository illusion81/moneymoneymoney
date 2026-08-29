import 'package:flutter/material.dart';

import '../models/forest_day.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({
    super.key,
    required this.summary,
    required this.onBack,
  });

  final ForestSummary summary;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final achievements = summary.achievements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          tooltip: 'Back to Forest',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ProgressCard(
                        label: 'Current streak',
                        value: '${summary.currentStreak}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProgressCard(
                        label: 'Healthy trees',
                        value: '${summary.healthyTreeCount}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProgressCard(
                        label: 'Withered trees',
                        value: '${summary.witheredTreeCount}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (final achievement in achievements)
                  Card(
                    elevation: 0,
                    color: achievement.unlocked
                        ? const Color(0xfffff4d7)
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(
                        achievement.unlocked
                            ? Icons.emoji_events
                            : Icons.lock_outline,
                        color: achievement.unlocked
                            ? const Color(0xffc79a33)
                            : Colors.grey,
                      ),
                      title: Text(achievement.title),
                      subtitle: Text(achievement.description),
                      trailing: Text(
                        achievement.unlocked ? 'Unlocked' : 'Locked',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.park),
                  label: const Text('Back to Forest'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
