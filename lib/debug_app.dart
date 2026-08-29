// Lane A's throwaway harness. NOT the product, NOT Lane C's screen.
// Proves the Flutter app can actually reach the backend and render live data.
//
//   flutter run -t lib/debug_app.dart -d chrome
//
// Backend must be running:
//   cd "backend,dataAPI" && .venv/bin/uvicorn main:app --port 8000
//
// Delete this file before the final build if you like — nothing imports it.

import 'package:flutter/material.dart';

import 'data/api_client.dart';
import 'data/models.dart';
import 'data/tower_controller.dart';

void main() => runApp(const DebugApp());

class DebugApp extends StatelessWidget {
  const DebugApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Wealth Tower — data harness',
    theme: ThemeData.dark(useMaterial3: true),
    home: const _Home(),
  );
}

class _Home extends StatefulWidget {
  const _Home();
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  late final TowerController c = TowerController(api: ApiClient());

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  Future<void> _survey() => c.submitSurvey(
    const SurveyAnswers(
      monthlyIncome: 2700,
      fixedCosts: 1500,
      riskAppetite: 4,
      horizonMonths: 24,
      hasEmergencyFund: false,
      topWorry: 'subscriptions',
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: c,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text('Wealth Tower — ${c.provider}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(c.syncLabel)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: c.refresh,
        child: const Icon(Icons.refresh),
      ),
      body: RefreshIndicator(
        onRefresh: c.refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!c.dataTrusted)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Demo data — not a live bank connection. '
                  'No mission here is bank-verified.',
                ),
              ),
            if (c.error != null)
              Text(
                'Error: ${c.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            if (c.needsSurvey)
              FilledButton(
                onPressed: _survey,
                child: const Text('Run the survey'),
              ),
            if (c.profile != null) ...[
              Text(
                c.profile!.archetype,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(c.profile!.archetypeBlurb),
              const SizedBox(height: 20),
            ],
            if (c.plan != null) ...[
              Text(
                'Adherence ${c.plan!.adherence.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(c.plan!.headline),
              const SizedBox(height: 8),
              for (final b in c.plan!.buckets)
                Text(
                  '${b.bucket.padRight(9)} '
                  '\$${b.actualAmount.toStringAsFixed(0)} / '
                  '\$${b.targetAmount.toStringAsFixed(0)}'
                  '${b.onTrack ? "  ok" : "  off plan"}',
                ),
              const SizedBox(height: 20),
            ],
            if (c.tower != null) ...[
              Text(
                'Tower — stage ${c.tower!.stage}, '
                '${c.tower!.weather}, health '
                '${(c.tower!.health * 100).round()}%'
                '${c.tower!.stale ? "  (FROZEN — feed down)" : ""}',
              ),
              Text(c.tower!.caption),
              const SizedBox(height: 20),
            ],
            if (c.progression != null)
              Text(
                'Level ${c.progression!.level} · '
                '${c.progression!.coins} coins · '
                '${c.progression!.xpIntoLevel}/'
                '${c.progression!.xpForNextLevel} XP',
              ),
            const SizedBox(height: 20),
            for (final m in c.missions)
              Card(
                child: ListTile(
                  title: Text(m.title),
                  subtitle: Text(
                    '${m.detail}\n'
                    '${m.verified ? "bank-verified" : "self-reported"}'
                    ' · ${m.xp} XP',
                  ),
                  isThreeLine: true,
                  trailing: m.claimed
                      ? const Text('claimed')
                      : m.complete
                      ? FilledButton(
                          onPressed: () => c.claim(m.id),
                          child: const Text('Claim'),
                        )
                      : !m.verified
                      ? OutlinedButton(
                          onPressed: () => c.markDone(m.id),
                          child: const Text('Mark done'),
                        )
                      : const Text('locked'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
