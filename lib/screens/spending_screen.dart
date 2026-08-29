// "Where my money actually went" — the screen that makes real bank data legible.
//
// Everything here comes from the backend feed: accounts and balances, the four
// buckets with target vs actual, spend by category, and the transactions
// themselves with the category we assigned each one. Point it at a real bank
// (or a CSV export) and this is your own spending.

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../services/category_breakdown.dart';
import '../services/money_format.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/category_pie_chart.dart';
import 'connect_bank_screen.dart';

class SpendingScreen extends StatefulWidget {
  const SpendingScreen({
    super.key,
    required this.api,
    this.days = 30,
    this.onShowForest,
    this.onShowCalendar,
    this.onShowHomestead,
    this.onShowAchievements,
  });

  final ApiClient api;
  final int days;

  /// Supplied when the screen is a bottom-nav tab. When absent the screen
  /// was pushed as a route and keeps a plain back button instead.
  final VoidCallback? onShowForest;
  final VoidCallback? onShowCalendar;
  final VoidCallback? onShowHomestead;
  final VoidCallback? onShowAchievements;

  @override
  State<SpendingScreen> createState() => _SpendingScreenState();
}

class _SpendingScreenState extends State<SpendingScreen> {
  List<Account> _accounts = const [];
  List<Txn> _txns = const [];
  Plan? _plan;
  String _provider = 'mock';
  bool _trusted = false;
  bool _loading = true;
  String? _error;
  late int _days = widget.days;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.providerName(),
        widget.api.dataTrusted(),
        widget.api.accounts(),
        widget.api.transactions(days: _days),
      ]);
      _provider = results[0] as String;
      _trusted = results[1] as bool;
      _accounts = results[2] as List<Account>;
      _txns = results[3] as List<Txn>;
      try {
        _plan = await widget.api.plan(days: _days);
      } on ApiException catch (e) {
        if (!e.needsSurvey) rethrow;
        _plan = null; // no survey yet — still show the raw spending
      }
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---- aggregation ----

  bool _isTransfer(Txn t) =>
      t.category == 'transfer' ||
      t.category == 'transfer-in' ||
      t.category == 'transfer-out';

  List<Txn> get _spend =>
      _txns.where((t) => t.isSpend && !_isTransfer(t)).toList();

  double get _outflow => _spend.fold(0.0, (s, t) => s + -t.amount);

  double get _income => _txns
      .where((t) => t.amount > 0 && t.category == 'income')
      .fold(0.0, (s, t) => s + t.amount);

  double get _moved => _txns
      .where((t) => t.isSpend && _isTransfer(t))
      .fold(0.0, (s, t) => s + -t.amount);

  Map<String, ({double amount, int count})> get _byCategory {
    final m = <String, ({double amount, int count})>{};
    for (final t in _spend) {
      final prev = m[t.category] ?? (amount: 0.0, count: 0);
      m[t.category] = (amount: prev.amount + -t.amount, count: prev.count + 1);
    }
    final sorted = m.entries.toList()
      ..sort((a, b) => b.value.amount.compareTo(a.value.amount));
    return {for (final e in sorted) e.key: e.value};
  }

  static const _bucketColor = {
    'invest': Color(0xff2f7d50),
    'stable': Color(0xff3f6ea8),
    'living': Color(0xff8a6d3b),
    'reward': Color(0xffb4553f),
  };

  static const _categoryBucket = {
    'groceries': 'living',
    'housing': 'living',
    'utilities': 'living',
    'transport': 'living',
    'health': 'living',
    'education': 'living',
    'fees': 'living',
    'cash': 'living',
    'debt': 'living',
    'other': 'living',
    'eating-out': 'reward',
    'subscriptions': 'reward',
    'lifestyle': 'reward',
    'bnpl': 'reward',
    'savings': 'stable',
    'investment': 'invest',
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Where your money went'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _days,
            onSelected: (d) {
              setState(() => _days = d);
              _load();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text('Last 7 days')),
              PopupMenuItem(value: 30, child: Text('Last 30 days')),
              PopupMenuItem(value: 90, child: Text('Last 90 days')),
              PopupMenuItem(value: 365, child: Text('Last 12 months')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text('${_days}d'),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      bottomNavigationBar: widget.onShowForest == null
          ? null
          : AppNavBar(
              selectedIndex: 1,
              onShowForest: widget.onShowForest!,
              onShowSpending: () {},
              onShowCalendar: widget.onShowCalendar!,
              onShowHomestead: widget.onShowHomestead!,
              onShowAchievements: widget.onShowAchievements!,
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  _sourceBanner(context),
                  const SizedBox(height: 16),
                  if (_accounts.isNotEmpty) ...[
                    Text('Accounts', style: t.titleMedium),
                    const SizedBox(height: 8),
                    for (final a in _accounts) _accountTile(a),
                    const SizedBox(height: 24),
                  ],
                  _summaryRow(context),
                  const SizedBox(height: 24),
                  if (_plan != null) ...[
                    Text('Against your plan', style: t.titleMedium),
                    const SizedBox(height: 4),
                    Text(_plan!.headline, style: t.bodySmall),
                    const SizedBox(height: 12),
                    for (final b in _plan!.buckets) _bucketRow(context, b),
                    const SizedBox(height: 24),
                  ],
                  Text('By category', style: t.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Transfers between your own accounts are excluded.',
                    style: t.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  CategoryPieChart(
                    slices: topCategorySlices({
                      for (final e in _byCategory.entries)
                        e.key: e.value.amount,
                    }),
                    total: _outflow,
                  ),
                  const SizedBox(height: 20),
                  if (_byCategory.isEmpty)
                    const Text('No spending in this period.')
                  else
                    for (final e in _byCategory.entries)
                      _categoryRow(
                        context,
                        e.key,
                        e.value.amount,
                        e.value.count,
                      ),
                  const SizedBox(height: 24),
                  Text('Transactions', style: t.titleMedium),
                  const SizedBox(height: 8),
                  for (final tx in _txns.take(40)) _txnTile(context, tx),
                  if (_txns.length > 40)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        '+ ${_txns.length - 40} more',
                        style: t.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _sourceBanner(BuildContext context) {
    final label = switch (_provider) {
      'basiq' => 'Live bank connection',
      'csv' => 'Bank statement export',
      _ => 'Demo data',
    };
    final colour = _trusted ? const Color(0xff2f7d50) : Colors.amber.shade800;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            _trusted ? Icons.verified_outlined : Icons.science_outlined,
            color: colour,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _trusted
                  ? '$label — data comes straight from your bank.'
                  : '$label — you could have edited this, so nothing here is bank-verified.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (!_trusted)
            TextButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ConnectBankScreen(api: widget.api),
                  ),
                );
                _load();
              },
              child: const Text('Connect'),
            ),
        ],
      ),
    );
  }

  Widget _accountTile(Account a) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(a.name)),
        Text(a.kind, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 12),
        Text(
          formatMoney(a.balance),
          style: TextStyle(
            fontFeatures: const [],
            fontWeight: FontWeight.w600,
            color: a.balance < 0 ? Colors.red.shade700 : null,
          ),
        ),
      ],
    ),
  );

  Widget _summaryRow(BuildContext context) {
    Widget cell(String label, String value, {Color? c}) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: c,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
    return Row(
      children: [
        cell('In', formatMoney(_income), c: const Color(0xff2f7d50)),
        cell('Spent', formatMoney(_outflow), c: const Color(0xffb4553f)),
        cell('Moved', formatMoney(_moved)),
      ],
    );
  }

  Widget _bucketRow(BuildContext context, BucketPlan b) {
    final pct = b.targetAmount == 0 ? 0.0 : (b.actualAmount / b.targetAmount);
    final colour = _bucketColor[b.bucket] ?? Colors.grey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${b.bucket}  ·  ${(b.targetPct * 100).round()}% target',
                ),
              ),
              Text(
                '${formatMoney(b.actualAmount)} / ${formatMoney(b.targetAmount)}',
                style: TextStyle(
                  color: b.onTrack ? null : const Color(0xffb4553f),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: colour.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(
                pct > 1.05 ? const Color(0xffb4553f) : colour,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRow(BuildContext c, String cat, double amt, int n) {
    final share = _outflow == 0 ? 0.0 : amt / _outflow;
    final colour = _bucketColor[_categoryBucket[cat] ?? 'living']!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(cat)),
              Text('$n', style: Theme.of(c).textTheme.bodySmall),
              const SizedBox(width: 12),
              SizedBox(
                width: 74,
                child: Text(
                  formatMoney(amt),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(
                width: 46,
                child: Text(
                  '${(share * 100).round()}%',
                  textAlign: TextAlign.right,
                  style: Theme.of(c).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 5,
              backgroundColor: colour.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation(colour),
            ),
          ),
        ],
      ),
    );
  }

  Widget _txnTile(BuildContext c, Txn tx) {
    final out = tx.amount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${tx.postDate}  ·  ${tx.category}',
                  style: Theme.of(c).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            (out ? '-' : '+') + formatMoney(tx.amount.abs()),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: out ? null : const Color(0xff2f7d50),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 40),
          const SizedBox(height: 12),
          const Text('Could not reach the backend.'),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
