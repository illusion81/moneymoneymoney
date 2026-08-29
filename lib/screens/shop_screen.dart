import 'package:flutter/material.dart';

import '../models/progression.dart';
import '../models/shop_item.dart';
import '../services/shop_service.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({
    super.key,
    required this.progression,
    required this.shopState,
    required this.onPurchase,
    required this.onEquip,
    required this.onBack,
  });

  final ProgressionState progression;
  final ShopState shopState;
  final void Function(String itemId) onPurchase;
  final void Function(String itemId) onEquip;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final shopService = ShopService();

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
                      onPurchase: () => onPurchase(item.id),
                      onEquip: () => onEquip(item.id),
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
        title: Text(item.name),
        subtitle: Text(item.description),
        trailing: _trailingControl(levelLocked, canAfford),
      ),
    );
  }

  Widget _trailingControl(bool levelLocked, bool canAfford) {
    if (equipped) {
      return const Chip(label: Text('Equipped'));
    }
    if (owned) {
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
