// Diamond store. Diamonds are the paid currency; coins are earned by holding
// your plan. Keeping them separate is deliberate — you can never buy your way
// to a bigger tree, only to cosmetics.

import 'package:flutter/material.dart';

import '../services/payment_service.dart';

class DiamondStoreScreen extends StatefulWidget {
  const DiamondStoreScreen({
    super.key,
    required this.gateway,
    required this.diamonds,
    required this.onPurchased,
    required this.isPlusMember,
    required this.onSubscribe,
    required this.onBack,
    this.onWatchAd,
  });

  final PaymentGateway gateway;
  final int diamonds;
  final ValueChanged<int> onPurchased;
  final bool isPlusMember;
  final VoidCallback onSubscribe;

  /// This screen is reached through the AppView switch rather than
  /// Navigator.push, so there is no automatic back arrow — it needs its own.
  final VoidCallback onBack;

  /// Rewarded ad: watch one, earn diamonds. Null hides the option.
  final Future<int> Function()? onWatchAd;

  @override
  State<DiamondStoreScreen> createState() => _DiamondStoreScreenState();
}

class _DiamondStoreScreenState extends State<DiamondStoreScreen> {
  String? _busyPackId;
  bool _watchingAd = false;
  bool _adWatched = false;

  Future<void> _watchAd() async {
    final handler = widget.onWatchAd;
    if (handler == null) return;
    setState(() => _watchingAd = true);
    final earned = await handler();
    if (!mounted) return;
    setState(() {
      _watchingAd = false;
      _adWatched = earned > 0;
    });
    if (earned > 0) {
      widget.onPurchased(earned);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+$earned diamonds for watching')),
      );
    }
  }

  static const int plusCostDiamonds = 250;

  Future<void> _buy(DiamondPack pack) async {
    setState(() => _busyPackId = pack.id);
    final result = await widget.gateway.buy(pack);
    if (!mounted) return;
    setState(() => _busyPackId = null);

    if (result.ok) {
      widget.onPurchased(result.diamonds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+${result.diamonds} diamonds. ${result.message}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message.isEmpty
            ? 'Purchase did not complete.'
            : result.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: widget.onBack),
        title: const Text('Diamonds'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(children: [
                const Icon(Icons.diamond, size: 18),
                const SizedBox(width: 6),
                Text('${widget.diamonds}', style: t.titleMedium),
              ]),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          if (!widget.gateway.isLive)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Demo store — no payment is taken and no card is involved. '
                    'Live purchases would go through the App Store and Google '
                    'Play, which is what the stores require for digital goods.',
                    style: t.bodySmall,
                  ),
                ),
              ]),
            ),

          if (widget.onWatchAd != null) ...[
            Card(
              margin: const EdgeInsets.only(bottom: 18),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Icon(Icons.play_circle_outline,
                    color: scheme.primary, size: 32),
                title: const Text('Watch a short video'),
                subtitle: const Text('Earn 5 diamonds. One per session.'),
                trailing: _watchingAd
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : FilledButton.tonal(
                        onPressed: _adWatched ? null : _watchAd,
                        child: Text(_adWatched ? 'Done' : 'Watch'),
                      ),
              ),
            ),
          ],
          Text('Diamond packs', style: t.titleMedium),
          const SizedBox(height: 10),
          for (final pack in kDiamondPacks) _packCard(pack, scheme, t),

          const SizedBox(height: 26),
          Text('What diamonds are for', style: t.titleMedium),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.workspace_premium, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      widget.isPlusMember ? 'Plus is active' : 'Unlock Plus',
                      style: t.titleSmall),
                ),
                if (!widget.isPlusMember)
                  Text('$plusCostDiamonds 💎', style: t.titleSmall),
              ]),
              const SizedBox(height: 8),
              Text(
                'Plus unlocks premium animals and skins. It does not make your '
                'tree grow faster, change your plan, or affect the leaderboard — '
                'those are earned, and money should not buy them.',
                style: t.bodySmall,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.isPlusMember ||
                          widget.diamonds < plusCostDiamonds
                      ? null
                      : () {
                          widget.onPurchased(-plusCostDiamonds);
                          widget.onSubscribe();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Plus unlocked')),
                          );
                        },
                  child: Text(widget.isPlusMember
                      ? 'Active'
                      : widget.diamonds < plusCostDiamonds
                          ? 'Need $plusCostDiamonds diamonds'
                          : 'Unlock Plus for $plusCostDiamonds'),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 22),
          Text(
            'Coins are earned by holding your plan. Diamonds are bought. '
            'They are kept separate on purpose — nothing you buy changes your '
            'financial progress or your standing in your circle.',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _packCard(DiamondPack pack, ColorScheme scheme, TextTheme t) {
    final busy = _busyPackId == pack.id;
    final total = pack.diamonds + pack.bonus;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(Icons.diamond, color: scheme.primary, size: 32),
        title: Text('$total diamonds', style: t.titleMedium),
        subtitle: pack.bonus > 0
            ? Text('includes ${pack.bonus} bonus')
            : const Text('starter pack'),
        trailing: busy
            ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : FilledButton.tonal(
                onPressed: _busyPackId == null ? () => _buy(pack) : null,
                child: Text(pack.priceLabel),
              ),
      ),
    );
  }
}
