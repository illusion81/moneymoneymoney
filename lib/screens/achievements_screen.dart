import 'package:flutter/material.dart';

import '../models/forest_day.dart';
import '../models/progression.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({
    super.key,
    required this.summary,
    required this.progression,
    required this.onBack,
  });

  final ForestSummary summary;
  final ProgressionState progression;
  final VoidCallback onBack;

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _showActivity = false;

  @override
  Widget build(BuildContext context) {
    final achievements = widget.summary.achievements;
    final level = widget.progression.level;
    final recentEvents = widget.progression.ledger.reversed.take(10).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          tooltip: 'Back to Forest',
          onPressed: widget.onBack,
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Level ${level.level}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: Color(0xffc79a33),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.progression.coinBalance}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: level.fraction,
                          minHeight: 8,
                          backgroundColor: const Color(0xffeee6d3),
                          color: const Color(0xff2f7d50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${level.xpIntoLevel} / ${level.xpForNextLevel} XP'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ProgressCard(
                        label: 'Current streak',
                        value: '${widget.summary.currentStreak}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProgressCard(
                        label: 'Healthy trees',
                        value: '${widget.summary.healthyTreeCount}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProgressCard(
                        label: 'Restored trees',
                        value: '${widget.summary.restoredTreeCount}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ProgressCard(
                        label: 'Withered trees',
                        value: '${widget.summary.witheredTreeCount}',
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
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Recent activity'),
                        trailing: Icon(
                          _showActivity
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                        onTap: () =>
                            setState(() => _showActivity = !_showActivity),
                      ),
                      if (_showActivity)
                        for (final event in recentEvents)
                          ListTile(
                            dense: true,
                            title: Text(event.description),
                            subtitle: Text(_formatDate(event.date)),
                            trailing: Text(
                              '${_signed(event.xp)} XP, ${_signed(event.coins)} coins',
                            ),
                          ),
                      if (_showActivity && recentEvents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No activity yet.'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: widget.onBack,
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

  String _signed(int value) => value >= 0 ? '+$value' : '$value';

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
