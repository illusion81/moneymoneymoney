import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../models/forest_day.dart';
import '../models/progression.dart';
import '../models/shop_item.dart';
import '../models/wealth_report.dart';
import '../services/forest_engine.dart';
import '../data/api_client.dart';
import '../services/item_visuals.dart';
import '../widgets/dev_gate.dart';
import '../widgets/farm_scene.dart';
import '../widgets/tree_view.dart';
import '../widgets/app_nav_bar.dart';
import 'connect_bank_screen.dart';
import 'circle_screen.dart';
import 'goals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.report,
    required this.summary,
    required this.progression,
    required this.shopState,
    required this.onCheckIn,
    required this.onRestore,
    required this.freezes,
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
    this.onDebugSimulate,
    this.onDebugFillFarm,
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

  /// Debug: add another week of on-budget days. Wired to a FAB so the demo
  /// can be driven from this screen instead of via the shop.
  final VoidCallback? onDebugSimulate;
  /// Debug: own and place everything, for the demo.
  final VoidCallback? onDebugFillFarm;
  final void Function({required double spending}) onCheckIn;
  final void Function(String recoveryNote) onRestore;

  /// Freezes held, and the cap. Shown so a missed day is never a surprise:
  /// people should know they have a safety net *before* they need it.
  final FreezeState freezes;
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
  double? _adherence;
  _SpendingMode _spendingMode = _SpendingMode.manual;
  bool _bankLoading = false;

  @override
  void initState() {
    super.initState();
    _checkBank();
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
    try {
      final plan = await api.plan();
      if (mounted) setState(() => _adherence = plan.adherence);
    } catch (_) {
      // No profile yet, or backend down — fall back to streak-only growth.
    }
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

  /// A labelled block of menu entries. Returns nothing at all when every
  /// entry in the group is unavailable, so an empty heading never appears.
  List<PopupMenuEntry<VoidCallback>> _menuGroup(
    BuildContext context,
    String heading,
    List<(IconData, String, VoidCallback)> entries,
  ) {
    if (entries.isEmpty) return const [];
    return [
      PopupMenuItem<VoidCallback>(
        enabled: false,
        height: 32,
        child: Text(
          heading.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      for (final (icon, label, action) in entries)
        PopupMenuItem<VoidCallback>(
          value: action,
          // PopupMenuItem hands its child a bounded width, so a long label
          // like "Retake questionnaire" overflows unless it can shrink.
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ]),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final latestDay = widget.summary.days.isEmpty
        ? null
        : widget.summary.days.last;
    final statusText = _statusText(latestDay);
    final statusColor = _statusColor(latestDay);

    return Scaffold(
      floatingActionButton: !kDebugMode
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.onDebugFillFarm != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FloatingActionButton.extended(
                      heroTag: 'fill',
                      onPressed: () async {
                        if (await DevGate.ensureUnlocked(context)) {
                          widget.onDebugFillFarm!();
                        }
                      },
                      icon: Icon(DevGate.isUnlocked
                          ? Icons.auto_awesome
                          : Icons.lock_outline),
                      label: const Text('Demo'),
                    ),
                  ),
                if (widget.onDebugSimulate != null)
                  FloatingActionButton.extended(
                    heroTag: 'sim',
                    onPressed: () async {
                      // Gated so nobody fast-forwards the farm mid-pitch.
                      if (await DevGate.ensureUnlocked(context)) {
                        widget.onDebugSimulate!();
                      }
                    },
                    icon: Icon(DevGate.isUnlocked
                        ? Icons.fast_forward
                        : Icons.lock_outline),
                    label: const Text('+1 week'),
                  ),
              ],
            ),
      appBar: AppBar(
        title: const Text('Wealth Forest'),
        actions: [
          // Only two things stay as their own icon: the membership badge
          // (it doubles as status — gold when you are a member) and the shop,
          // which is where the currency you earn actually goes. Everything
          // else was eight icons of undifferentiated grey; it now lives in one
          // grouped menu.
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
          IconButton(
            tooltip: 'Shop',
            onPressed: widget.onShowShop,
            icon: const Icon(Icons.store_outlined),
          ),
          PopupMenuButton<VoidCallback>(
            key: const Key('home-more-menu'),
            tooltip: 'More',
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              ..._menuGroup(context, 'Your money', [
                if (widget.api != null)
                  (
                    _bankConnected
                        ? Icons.account_balance
                        : Icons.account_balance_outlined,
                    _bankConnected ? 'Bank connected' : 'Connect your bank',
                    _openConnectBank,
                  ),
                if (widget.api != null)
                  (
                    Icons.savings_outlined,
                    'Saving for something',
                    () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => GoalsScreen(api: widget.api!),
                        )),
                  ),
                (Icons.description_outlined, 'Your report', widget.onShowReport),
                if (widget.onRetakeQuestionnaire != null)
                  (
                    Icons.fact_check_outlined,
                    'Retake questionnaire',
                    widget.onRetakeQuestionnaire!,
                  ),
              ]),
              if (widget.api != null) const PopupMenuDivider(),
              ..._menuGroup(context, 'People', [
                if (widget.api != null)
                  (
                    Icons.groups_outlined,
                    'Your circle',
                    () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CircleScreen(
                            api: widget.api!,
                            streak: widget.summary.currentStreak,
                            level: widget.progression.level.level,
                            adherence: localAdherence,
                          ),
                        )),
                  ),
              ]),
            ],
          ),
        ],
      ),
      bottomNavigationBar: AppNavBar(
        selectedIndex: 0,
        onShowForest: () {},
        onShowSpending: widget.onShowSpending,
        onShowCalendar: widget.onShowCalendar,
        onShowHomestead: widget.onShowHomestead,
        onShowAchievements: widget.onShowAchievements,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              // Extra bottom room so the debug FABs never sit on top of
              // something the user needs to read or tap.
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
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
                      FarmScene(
                        // Growth is half streak, half plan adherence — the
                        // tree must answer to the budget, not just to logins.
                        growth: _farmGrowth(latestDay),
                        health: _treeHealth(latestDay),
                        skinId: widget.shopState
                            .equippedItemIds[ShopItemCategory.treeSkin],
                        skyColor: skyColor(widget.shopState),
                        groundColor: groundColor(widget.shopState),
                        // Animals are bought in the shop with coins you earn
                        // by holding your plan — they do not appear for free.
                        animals: widget.shopState.ownedItemIds
                            .map((id) => kShopCatalog
                                .where((i) => i.id == id)
                                .firstOrNull)
                            .whereType<ShopItem>()
                            .where((i) => i.category == ShopItemCategory.animal)
                            .map((i) => i.asset!)
                            .toList(),
                        // One tree, then another every three levels — the
                        // forest grows as you do.
                        treeCount: 1 + (widget.progression.level.level ~/ 3),
                        seed: widget.summary.days.length + 7,
                        height: 280,
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
                const SizedBox(height: 12),
                _FreezeBar(
                  freezes: widget.freezes,
                  isPlusMember: widget.isPlusMember,
                  onShowPlus: widget.onShowPlus,
                ),
                if (latestDay?.status == TreeStatus.frozen) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xffe6eff7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      const Icon(Icons.ac_unit, color: Color(0xff4a7fa8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You missed a day and a freeze covered it. Your '
                          '${widget.summary.currentStreak}-day streak is still '
                          'standing — check in today and it keeps growing.',
                        ),
                      ),
                    ]),
                  ),
                ],
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
                      key: const Key('spending-mode-manual'),
                      label: const Text('Manual'),
                      selected: _spendingMode == _SpendingMode.manual,
                      onSelected: (_) => _selectManualMode(),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      key: const Key('spending-mode-bank'),
                      label: const Text('From bank'),
                      selected: _spendingMode == _SpendingMode.bank,
                      onSelected: (_) => _selectBankMode(),
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
      case TreeStatus.frozen:
        return 'Streak frozen';
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
      case TreeStatus.frozen:
        return const Color(0xff4a7fa8);
      case TreeStatus.pending:
      case null:
        return const Color(0xffc79a33);
    }
  }

  /// 0..1. Half of it is the check-in streak, half is how closely they are
  /// holding their actual budget. Streak alone would mean the tree rewards
  /// opening the app, which is not the product's claim.
  /// Share of recorded days that stayed within budget.
  ///
  /// The backend's adherence comes from bank transactions, which never change
  /// while you play — so it sat at 45% no matter what you did, and your rank
  /// could never move. This is the number the app actually knows.
  double? get localAdherence {
    final days = widget.summary.days;
    if (days.isEmpty) return null;
    final kept = days
        .where((d) =>
            d.status == TreeStatus.healthy || d.status == TreeStatus.restored)
        .length;
    return kept / days.length;
  }

  double _farmGrowth(ForestDay? day) {
    // Three inputs so the farm keeps visibly growing well past the first week:
    //   streak    — caps at 7 days, gets you started
    //   adherence — how closely the real budget is being held
    //   level     — long-run progress, keeps climbing after the streak maxes
    final streakPart = (widget.summary.currentStreak / 7).clamp(0.0, 1.0);
    final adherencePart = _adherence ?? streakPart;
    final levelPart = (widget.progression.level.level / 10).clamp(0.0, 1.0);
    return (streakPart * 0.35 + adherencePart * 0.3 + levelPart * 0.35)
        .clamp(0.0, 1.0);
  }

  TreeHealth _treeHealth(ForestDay? day) => switch (day?.status) {
        TreeStatus.withered => TreeHealth.withered,
        TreeStatus.restored => TreeHealth.restored,
        TreeStatus.healthy => TreeHealth.healthy,
        // A frozen day means the tree was held, not harmed — it should look
        // alive, because that is the whole promise of the freeze.
        TreeStatus.frozen => TreeHealth.healthy,
        _ => TreeHealth.pending,
      };

  // Kept for the shop preview, which still shows icons.
  // ignore: unused_element
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

/// The safety net, shown before it is needed. A habit app's worst moment is
/// the day after you miss one — knowing a freeze is sitting there is what
/// stops people deleting the app instead of opening it.
class _FreezeBar extends StatelessWidget {
  const _FreezeBar({
    required this.freezes,
    required this.isPlusMember,
    required this.onShowPlus,
  });

  final FreezeState freezes;
  final bool isPlusMember;
  final VoidCallback onShowPlus;

  @override
  Widget build(BuildContext context) {
    final has = freezes.available > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: has ? const Color(0xffeef4fa) : const Color(0xfff5f3ee),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(
          has ? Icons.ac_unit : Icons.ac_unit_outlined,
          size: 20,
          color: has ? const Color(0xff4a7fa8) : const Color(0xff9a968c),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            has
                ? 'Streak freezes: ${freezes.available} of ${freezes.capacity}. '
                    'Miss a day and one covers you automatically.'
                : 'No streak freezes left. Earn one back by checking in.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        if (!isPlusMember) ...[
          const SizedBox(width: 8),
          TextButton(
            key: const Key('freeze-upgrade'),
            onPressed: onShowPlus,
            child: const Text('Hold 3'),
          ),
        ],
      ]),
    );
  }
}
