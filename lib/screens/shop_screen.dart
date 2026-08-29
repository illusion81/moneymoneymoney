import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../models/progression.dart';
import '../models/shop_item.dart';
import '../services/item_visuals.dart';
import '../services/shop_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.progression,
    required this.shopState,
    required this.onPurchase,
    required this.onEquip,
    required this.onBack,
    this.onDebugMaxCoins,
    this.onDebugUnlockAll,
  });

  final ProgressionState progression;
  final ShopState shopState;
  final void Function(String itemId) onPurchase;
  final void Function(String itemId) onEquip;
  final VoidCallback onBack;

  /// Testing aids, only ever shown in debug builds (gated by [kDebugMode])
  /// and only while the user switches debug mode on — never real
  /// user-facing features.
  final VoidCallback? onDebugMaxCoins;

  /// Marks every catalog item as owned, bypassing price and level gates.
  final VoidCallback? onDebugUnlockAll;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  /// Debug actions stay hidden until explicitly switched on, so a normal
  /// play-through can't stumble into free coins.
  bool _debugMode = false;

  @override
  Widget build(BuildContext context) {
    final shopService = ShopService();
    final progression = widget.progression;
    final shopState = widget.shopState;
    final onBack = widget.onBack;
    final debugMaxCoins = widget.onDebugMaxCoins;
    final debugUnlockAll = widget.onDebugUnlockAll;
    final hasDebugActions = debugMaxCoins != null || debugUnlockAll != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forest Shop'),
        leading: IconButton(
          tooltip: 'Back to Forest',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (kDebugMode && hasDebugActions)
            IconButton(
              key: const Key('debug-mode-toggle'),
              tooltip: _debugMode ? 'Turn debug mode off' : 'Turn debug mode on',
              onPressed: () => setState(() => _debugMode = !_debugMode),
              icon: Icon(
                _debugMode
                    ? Icons.developer_mode
                    : Icons.developer_mode_outlined,
                color: _debugMode ? const Color(0xffc79a33) : null,
              ),
            ),
          if (kDebugMode && _debugMode && debugUnlockAll != null)
            IconButton(
              key: const Key('debug-unlock-all-button'),
              tooltip: 'Debug: unlock all items',
              onPressed: debugUnlockAll,
              icon: const Icon(Icons.lock_open_outlined),
            ),
          if (kDebugMode && _debugMode && debugMaxCoins != null)
            IconButton(
              key: const Key('debug-max-coins-button'),
              tooltip: 'Debug: max coins',
              onPressed: debugMaxCoins,
              icon: const Icon(Icons.bug_report_outlined),
            ),
        ],
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
                  child: Row(
                    children: [
                      Text(
                        'Level ${progression.level.level}',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xffc79a33),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${progression.coinBalance} coins',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                for (final category in ShopItemCategory.values) ...[
                  Text(
                    _categoryLabel(category),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  for (final item in shopService.itemsFor(category))
                    _ShopItemCard(
                      item: item,
                      owned: shopState.ownedItemIds.contains(item.id),
                      equipped:
                          shopState.equippedItemIds[item.category] == item.id,
                      progression: progression,
                      onPurchase: () => widget.onPurchase(item.id),
                      onEquip: () => widget.onEquip(item.id),
                    ),
                  const SizedBox(height: 12),
                ],
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

  String _categoryLabel(ShopItemCategory category) {
    switch (category) {
      case ShopItemCategory.treeSkin:
        return 'Tree skins';
      case ShopItemCategory.ground:
        return 'Ground';
      case ShopItemCategory.sky:
        return 'Sky';
      case ShopItemCategory.decoration:
        return 'Decorations';
    }
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.progression,
    required this.onPurchase,
    required this.onEquip,
  });

  final ShopItem item;
  final bool owned;
  final bool equipped;
  final ProgressionState progression;
  final VoidCallback onPurchase;
  final VoidCallback onEquip;

  @override
  Widget build(BuildContext context) {
    final levelLocked = progression.level.level < item.requiredLevel;
    final canAfford = progression.coinBalance >= item.price;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: _ItemIconChip(item: item),
        title: Text(item.name),
        subtitle: Text(item.description),
        trailing: _trailingControl(levelLocked, canAfford),
      ),
    );
  }

  Widget _trailingControl(bool levelLocked, bool canAfford) {
    final isDecoration = item.category == ShopItemCategory.decoration;

    if (equipped) {
      return const Chip(label: Text('Equipped'));
    }
    if (owned) {
      if (isDecoration) {
        return const Chip(label: Text('Owned'));
      }
      return OutlinedButton(
        onPressed: onEquip,
        child: const Text('Equip'),
      );
    }
    if (levelLocked) {
      return Text('Level ${item.requiredLevel} required');
    }

    return FilledButton(
      onPressed: canAfford ? onPurchase : null,
      child: Text('Buy for ${item.price}'),
    );
  }
}

class _ItemIconChip extends StatelessWidget {
  const _ItemIconChip({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final visual = shopItemVisual(item);

    return CircleAvatar(
      backgroundColor: visual.color.withValues(alpha: 0.15),
      foregroundColor: visual.color,
      child: Icon(visual.icon),
    );
  }
}
