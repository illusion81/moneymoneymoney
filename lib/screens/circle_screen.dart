// The social layer.
//
// The one thing to understand before changing anything here: this leaderboard
// shows NO dollar figures. Ranking students by how much they save ranks whose
// parents earn more. We rank on adherence to each person's own plan — a target
// the app calculated from their own income — so someone on $400 a month can
// beat someone on $4,000. That is the whole fairness argument, and it lives in
// the data model, not in a disclaimer.

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  Circle? _circle;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _circle = await widget.api.leaderboard();
      _error = null;
    } on ApiException catch (e) {
      _error = e.needsSurvey
          ? 'Finish the questionnaire first — your rank is based on your own plan.'
          : e.message;
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cheer(LeaderboardEntry e) async {
    await widget.api.cheer(e.displayName);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sent ${e.displayName} some encouragement')),
    );
  }

  IconData _trendIcon(String t) => switch (t) {
        'up' => Icons.trending_up,
        'down' => Icons.trending_down,
        _ => Icons.trending_flat,
      };

  Color _trendColour(String t) => switch (t) {
        'up' => const Color(0xff2f7d50),
        'down' => const Color(0xffb4553f),
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = _circle;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your circle'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      Text(c!.name, style: t.titleLarge),
                      Text('${c.memberCount} people · code ${c.code}',
                          style: t.bodySmall),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(c.headline, style: t.bodyMedium),
                      ),
                      const SizedBox(height: 20),
                      for (final e in c.entries) _row(e),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.balance, size: 18),
                              const SizedBox(width: 8),
                              Text('Why there are no dollar amounts here',
                                  style: t.titleSmall),
                            ]),
                            const SizedBox(height: 8),
                            Text(
                              'Ranking people by how much they save just ranks who '
                              'earns more. Everyone here is measured against their own '
                              'plan, built from their own income and fixed costs — so '
                              'someone on a small budget can top this table. Nobody in '
                              'your circle can see what you earn, hold or spend.',
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _row(LeaderboardEntry e) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: e.isYou
            ? scheme.primaryContainer.withValues(alpha: 0.55)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: e.isYou ? Border.all(color: scheme.primary, width: 1.5) : null,
      ),
      child: Row(children: [
        SizedBox(
          width: 26,
          child: Text('${e.rank}',
              style: t.titleMedium?.copyWith(
                  fontWeight: e.isYou ? FontWeight.w700 : FontWeight.w400)),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(e.displayName,
                  style: t.titleSmall?.copyWith(
                      fontWeight: e.isYou ? FontWeight.w700 : FontWeight.w500)),
              if (e.isYou) ...[
                const SizedBox(width: 6),
                Text('you', style: t.bodySmall),
              ],
            ]),
            const SizedBox(height: 2),
            Text('Level ${e.level} · tower stage ${e.towerStage} · '
                '${e.streakDays}d streak',
                style: t.bodySmall),
            if (e.badge != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(e.badge!,
                    style: t.bodySmall?.copyWith(color: scheme.primary)),
              ),
          ]),
        ),
        Column(children: [
          Text('${(e.adherence * 100).round()}%',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text('plan kept', style: t.bodySmall),
        ]),
        const SizedBox(width: 8),
        Icon(_trendIcon(e.trend), size: 18, color: _trendColour(e.trend)),
        if (!e.isYou)
          IconButton(
            tooltip: 'Send encouragement',
            icon: const Icon(Icons.favorite_border, size: 18),
            onPressed: () => _cheer(e),
          ),
      ]),
    );
  }
}
