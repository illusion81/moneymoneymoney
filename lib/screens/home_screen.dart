import 'package:flutter/material.dart';

import '../models/forest_day.dart';
import '../models/progression.dart';
import '../models/shop_item.dart';
import '../models/wealth_report.dart';
import '../services/forest_engine.dart';
import '../data/api_client.dart';
import '../services/item_visuals.dart';
import '../widgets/app_nav_bar.dart';
import 'connect_bank_screen.dart';
import 'circle_screen.dart';
import 'goals_screen.dart';
import 'spending_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.report,
    required this.summary,
    required this.progression,
    required this.shopState,
    required this.onCheckIn,
    required this.onRestore,
    required this.onShowReport,
    required this.onShowAchievements,
    required this.onShowShop,
    required this.onShowSpending,
    required this.onShowPlus,
    required this.isPlusMember,
    required this.onShowCalendar,
    required this.onShowHomestead,
    required this.onFetchTodaySpending,
    this.lastEarnedSummary,
    this.api,
    this.onRetakeQuestionnaire,
  });

  final WealthReport report;
  final ForestSummary summary;
  final ProgressionState progression;
  final ShopState shopState;
  final String? lastEarnedSummary;

  /// When supplied, the screen can link a bank and pull real spending
  /// instead of asking the user to type it.
  final ApiClient? api;
  final void Function({required double spending}) onCheckIn;
  final void Function(String recoveryNote) onRestore;
  final VoidCallback onShowReport;
  final VoidCallback onShowAchievements;
  final VoidCallback onShowShop;
  final VoidCallback onShowSpending;
  final VoidCallback onShowPlus;
  final bool isPlusMember;
  final VoidCallback onShowCalendar;
  final VoidCallback onShowHomestead;
  final Future<double> Function() onFetchTodaySpending;
  final VoidCallback? onRetakeQuestionnaire;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _SpendingMode { manual, bank }

class _HomeScreenState extends State<HomeScreen> {
  final _spendingController = TextEditingController();
  final _recoveryNoteController = TextEditingController();
  String? _errorText;
  bool _bankConnected = false;
  // Bank is the default: the whole point is not making people type numbers
  // they have to remember. _selectBankMode falls back to manual on failure.
  _SpendingMode _spendingMode = _SpendingMode.bank;
  bool _bankLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBank();
    _selectBankMode();
  }

  /// Only a live bank connection counts as trusted — a CSV or PDF the user
  /// uploaded could have been edited before we saw it.
  Future<void> _checkBank() async {
    final api = widget.api;
    if (api == null) return;
    try {
      final trusted = await api.dataTrusted();
      if (mounted) setState(() => _bankConnected = trusted);
    } catch (_) {}
  }

  Future<void> _openConnectBank() async {
    final api = widget.api;
    if (api == null) return;
    final linked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ConnectBankScreen(api: api)),
    );
    if (linked == true) {
      await _checkBank();
      _selectBankMode();
    }
  }

  @override
  void dispose() {
    _spendingController.dispose();
    _recoveryNoteController.dispose();
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
        actions: [
          IconButton(
            key: const Key('get-plus-button'),
            icon: Icon(
              widget.isPlusMember
                  ? Icons.workspace_premium
                  : Icons.workspace_premium_outlined,
              color: const Color(0xffc79a33),
            ),
            tooltip: widget.isPlusMember ? 'Plus member' : 'Get Plus',
            onPressed: widget.onShowPlus,
          ),
          if (widget.api != null)
            IconButton(
              icon: const Icon(Icons.groups_outlined),
              tooltip: 'Your circle',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CircleScreen(api: widget.api!),
                ),
              ),
            ),
          if (widget.api != null)
            IconButton(
              icon: const Icon(Icons.savings_outlined),
              tooltip: 'Saving for something',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GoalsScreen(api: widget.api!),
                ),
              ),
            ),
          if (widget.api != null)
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'Where your money went',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SpendingScreen(api: widget.api!),
                ),
              ),
            ),
          if (widget.api != null)
            IconButton(
              icon: Icon(
                _bankConnected
                    ? Icons.account_balance
                    : Icons.account_balance_outlined,
              ),
              tooltip: _bankConnected ? 'Bank connected' : 'Connect your bank',
              onPressed: _openConnectBank,
            ),
          IconButton(
            tooltip: 'Shop',
            onPressed: widget.onShowShop,
            icon: const Icon(Icons.store_outlined),
          ),
          IconButton(
            tooltip: 'Report',
            onPressed: widget.onShowReport,
            icon: const Icon(Icons.description_outlined),
          ),
          if (widget.onRetakeQuestionnaire != null)
            IconButton(
              key: const Key('retake-questionnaire-button'),
              tooltip: 'Retake questionnaire',
              onPressed: widget.onRetakeQuestionnaire,
              icon: const Icon(Icons.fact_check_outlined),
            ),
          IconButton(
            tooltip: 'Achievements',
            onPressed: widget.onShowAchievements,
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        selectedIndex: 0,
        onShowForest: () {},
        onShowSpending: widget.onShowSpending,
        onShowCalendar: widget.onShowCalendar,
        onShowHomestead: widget.onShowHomestead,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ProgressionHeader(
                  progression: widget.progression,
                  onShowShop: widget.onShowShop,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: skyColor(widget.shopState),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: groundColor(widget.shopState),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _treeIcon(latestDay, widget.shopState),
                          size: 112,
                          color: statusColor,
                        ),
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
                            'Check in today and stay within budget to grow your tree.',
                        textAlign: TextAlign.center,
                      ),
                      if (latestDay?.status == TreeStatus.restored &&
                          latestDay?.recoveryNote != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Recovery note: ${latestDay!.recoveryNote}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.lastEarnedSummary != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    widget.lastEarnedSummary!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xffc79a33),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                _MetricRow(
                  streak: widget.summary.currentStreak,
                  healthy: widget.summary.healthyTreeCount,
                  withered: widget.summary.witheredTreeCount,
                ),
                if (latestDay?.status == TreeStatus.withered) ...[
                  const SizedBox(height: 18),
                  _RestorationPanel(
                    day: latestDay!,
                    days: widget.summary.days,
                    coinBalance: widget.progression.coinBalance,
                    noteController: _recoveryNoteController,
                    onRestore: () {
                      widget.onRestore(_recoveryNoteController.text);
                      _recoveryNoteController.clear();
                    },
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'Today\'s money action',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(widget.report.dailyActions.first),
                const SizedBox(height: 14),
                Text(
                  'Daily budget: \$${widget.report.dailyBudget.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    ChoiceChip(
                      key: const Key('spending-mode-bank'),
                      label: const Text('From bank'),
                      selected: _spendingMode == _SpendingMode.bank,
                      onSelected: (_) => _selectBankMode(),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      key: const Key('spending-mode-manual'),
                      label: const Text('Manual'),
                      selected: _spendingMode == _SpendingMode.manual,
                      onSelected: (_) => _selectManualMode(),
                    ),
                    if (_bankLoading) ...[
                      const SizedBox(width: 10),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('spending-field'),
                  controller: _spendingController,
                  readOnly: _spendingMode == _SpendingMode.bank,
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
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _checkIn,
                  icon: const Icon(Icons.check),
                  label: const Text('Check In'),
                ),
              ],
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
    widget.onCheckIn(spending: spending);
  }

  void _selectManualMode() {
    setState(() {
      _spendingMode = _SpendingMode.manual;
      _errorText = null;
    });
  }

  Future<void> _selectBankMode() async {
    setState(() {
      _spendingMode = _SpendingMode.bank;
      _bankLoading = true;
      _errorText = null;
    });

    try {
      final spending = await widget.onFetchTodaySpending();
      if (!mounted) {
        return;
      }
      setState(() {
        _spendingController.text = spending.toStringAsFixed(2);
        _bankLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _spendingMode = _SpendingMode.manual;
        _bankLoading = false;
        _errorText = 'Could not load bank data. Enter spending manually.';
      });
    }
  }

  String _statusText(ForestDay? day) {
    switch (day?.status) {
      case TreeStatus.healthy:
        return 'Healthy tree';
      case TreeStatus.withered:
        return 'Withered tree';
      case TreeStatus.restored:
        return 'Restored tree';
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
      case TreeStatus.restored:
        return const Color(0xff3f8f8a);
      case TreeStatus.pending:
      case null:
        return const Color(0xffc79a33);
    }
  }

  IconData _treeIcon(ForestDay? day, ShopState shopState) {
    if (day?.status == TreeStatus.withered) {
      return Icons.energy_savings_leaf_outlined;
    }
    if (day?.status == TreeStatus.restored) {
      return Icons.eco;
    }

    return treeSkinIcon(
      equippedId: shopState.equippedItemIds[ShopItemCategory.treeSkin],
      level: day?.treeLevel ?? 0,
    );
  }
}

class _ProgressionHeader extends StatelessWidget {
  const _ProgressionHeader({
    required this.progression,
    required this.onShowShop,
  });

  final ProgressionState progression;
  final VoidCallback onShowShop;

  @override
  Widget build(BuildContext context) {
    final level = progression.level;

    return Container(
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff2f7d50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Level ${level.level}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                key: const Key('coin-balance'),
                onTap: onShowShop,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xfffff4d7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xffc79a33),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${progression.coinBalance}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
          Text(
            '${level.xpIntoLevel} / ${level.xpForNextLevel} XP',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RestorationPanel extends StatelessWidget {
  const _RestorationPanel({
    required this.day,
    required this.days,
    required this.coinBalance,
    required this.noteController,
    required this.onRestore,
  });

  final ForestDay day;
  final List<ForestDay> days;
  final int coinBalance;
  final TextEditingController noteController;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final quote = ForestEngine().quoteRestoration(
      days: days,
      dayDate: day.date,
      now: DateTime.now(),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfffdf1e6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Restore this day',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (!quote.eligible) ...[
            Text(quote.blockedReason ?? 'Restoration is not available.'),
          ] else ...[
            Text('Cost: ${quote.cost} coins. Your balance: $coinBalance.'),
            const SizedBox(height: 10),
            TextField(
              key: const Key('recovery-note-field'),
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'What happened, and what will you do differently?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('restore-button'),
              onPressed: onRestore,
              icon: const Icon(Icons.healing),
              label: Text('Restore for ${quote.cost} coins'),
            ),
          ],
        ],
      ),
    );
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
        Expanded(
          child: _MetricTile(label: 'Streak', value: '$streak'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(label: 'Healthy', value: '$healthy'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(label: 'Withered', value: '$withered'),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label),
        ],
      ),
    );
  }
}
