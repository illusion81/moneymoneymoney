import 'package:flutter/material.dart';

import '../models/forest_day.dart';
import '../models/wealth_report.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.report,
    required this.summary,
    required this.onCheckIn,
    required this.onShowReport,
    required this.onShowAchievements,
  });

  final WealthReport report;
  final ForestSummary summary;
  final void Function({
    required double spending,
    required bool actionCompleted,
  }) onCheckIn;
  final VoidCallback onShowReport;
  final VoidCallback onShowAchievements;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _spendingController = TextEditingController();
  bool _actionCompleted = false;
  String? _errorText;

  @override
  void dispose() {
    _spendingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final latestDay = widget.summary.days.isEmpty
        ? null
        : widget.summary.days.last;
    final statusText = _statusText(latestDay);
    final statusColor = _statusColor(latestDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wealth Forest'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            widget.onShowReport();
          } else if (index == 2) {
            widget.onShowAchievements();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.park_outlined),
            selectedIcon: Icon(Icons.park),
            label: 'Forest',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Report',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Awards',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _treeIcon(latestDay),
                          size: 112,
                          color: statusColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          statusText,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          latestDay?.message ??
                              'Complete today\'s money action to grow your tree.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _MetricRow(
                    streak: widget.summary.currentStreak,
                    healthy: widget.summary.healthyTreeCount,
                    withered: widget.summary.witheredTreeCount,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Today\'s money action',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.report.dailyActions.first),
                  const SizedBox(height: 14),
                  Text(
                    'Daily budget: \$${widget.report.dailyBudget.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    key: const Key('spending-field'),
                    controller: _spendingController,
                    decoration: InputDecoration(
                      labelText: 'Today\'s spending',
                      prefixIcon: const Icon(Icons.payments_outlined),
                      border: const OutlineInputBorder(),
                      errorText: _errorText,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    key: const Key('action-complete-checkbox'),
                    value: _actionCompleted,
                    onChanged: (value) =>
                        setState(() => _actionCompleted = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Money action completed'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _checkIn,
                    icon: const Icon(Icons.check),
                    label: const Text('Check In'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: widget.onShowAchievements,
                    icon: const Icon(Icons.emoji_events_outlined),
                    label: const Text('Achievements'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _checkIn() {
    final spending = double.tryParse(_spendingController.text);
    if (spending == null || spending < 0) {
      setState(() => _errorText = 'Enter a valid spending amount');
      return;
    }

    setState(() => _errorText = null);
    widget.onCheckIn(
      spending: spending,
      actionCompleted: _actionCompleted,
    );
  }

  String _statusText(ForestDay? day) {
    switch (day?.status) {
      case TreeStatus.healthy:
        return 'Healthy tree';
      case TreeStatus.withered:
        return 'Withered tree';
      case TreeStatus.pending:
      case null:
        return 'Ready to grow';
    }
  }

  Color _statusColor(ForestDay? day) {
    switch (day?.status) {
      case TreeStatus.healthy:
        return const Color(0xff2f7d50);
      case TreeStatus.withered:
        return const Color(0xff8a6a4f);
      case TreeStatus.pending:
      case null:
        return const Color(0xffc79a33);
    }
  }

  IconData _treeIcon(ForestDay? day) {
    if (day?.status == TreeStatus.withered) {
      return Icons.energy_savings_leaf_outlined;
    }
    if ((day?.treeLevel ?? 0) >= 3) {
      return Icons.forest;
    }
    if ((day?.treeLevel ?? 0) >= 2) {
      return Icons.park;
    }
    return Icons.eco;
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.streak,
    required this.healthy,
    required this.withered,
  });

  final int streak;
  final int healthy;
  final int withered;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MetricTile(label: 'Streak', value: '$streak')),
        const SizedBox(width: 8),
        Expanded(child: _MetricTile(label: 'Healthy', value: '$healthy')),
        const SizedBox(width: 8),
        Expanded(child: _MetricTile(label: 'Withered', value: '$withered')),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
          Text(label),
        ],
      ),
    );
  }
}
