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
    required this.isPlusMember,
    required this.onShowPlus,
    this.diamonds = 0,
    this.onShowDiamonds,
  });

  final ProgressionState progression;
  final ShopState shopState;
  final void Function(String itemId) onPurchase;
  final void Function(String itemId) onEquip;
  final VoidCallback onBack;

  /// Plus-only items stay locked behind a membership prompt until this is
  /// true; the lock opens the Plus screen rather than attempting a buy.
  final bool isPlusMember;
  final VoidCallback onShowPlus;

  /// Diamonds live here rather than in the app bar. They are a shop currency —
  /// splitting them into their own top-level icon meant the two places you
  /// spend money were two taps apart and looked unrelated.
  final int diamonds;
  final VoidCallback? onShowDiamonds;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final shopService = ShopService();
    final progression = widget.progression;
    final shopState = widget.shopState;
    final onBack = widget.onBack;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forest Shop'),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      // Wrap, not Row: level + coins + diamonds + "Get more"
                      // is 70pt wider than a phone. Each balance is its own
                      // group so a wrap breaks between them, never inside one.
                      Text(
                        'Level ${progression.level.level}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.monetization_on,
                            color: Color(0xffc79a33), size: 20),
                        const SizedBox(width: 4),
                        Text('${progression.coinBalance}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                      if (widget.onShowDiamonds != null)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.diamond,
                              color: Color(0xff4aa3df), size: 20),
                          const SizedBox(width: 4),
                          Text('${widget.diamonds}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          TextButton(
                            key: const Key('shop-get-diamonds'),
                            onPressed: widget.onShowDiamonds,
                            child: const Text('Get more'),
                          ),
                        ]),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                for (final category in ShopItemCategory.values) ...[
                  Text(
                    _categoryLabel(category),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final item in shopService.itemsFor(category))
                    _ShopItemCard(
                      item: item,
                      owned: shopState.ownedItemIds.contains(item.id),
                      equipped:
                          shopState.equippedItemIds[item.category] == item.id,
                      progression: progression,
                      isPlusMember: widget.isPlusMember,
                      onShowPlus: widget.onShowPlus,
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
      case ShopItemCategory.animal:
        return 'Animals';
    }
  }
}

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.progression,
    required this.isPlusMember,
    required this.onShowPlus,
    required this.onPurchase,
    required this.onEquip,
  });

  final ShopItem item;
  final bool owned;
  final bool equipped;
  final ProgressionState progression;
  final bool isPlusMember;
  final VoidCallback onShowPlus;
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
      // Not a ListTile: it hands the trailing control its full intrinsic
      // width first and gives the title whatever is left, which on a phone
      // was about 60pt — "Classic Oak" wrapped mid-word.
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _ItemIconChip(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _trailingControl(levelLocked, canAfford),
          ],
        ),
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
      return OutlinedButton(onPressed: onEquip, child: const Text('Equip'));
    }
    if (item.plusOnly && !isPlusMember) {
      return OutlinedButton.icon(
        key: Key('plus-lock-${item.id}'),
        onPressed: onShowPlus,
        icon: const Icon(Icons.lock, size: 16),
        label: const Text('Plus'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xffc79a33),
          side: const BorderSide(color: Color(0xffc79a33)),
        ),
      );
    }
    if (levelLocked) {
      return Text('Level ${item.requiredLevel} required');
    }

    return FilledButton(
      key: Key('buy-${item.id}'),
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
