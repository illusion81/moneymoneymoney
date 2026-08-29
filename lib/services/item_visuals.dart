import 'package:flutter/material.dart';

import '../models/shop_item.dart';

/// The single source of icon/color mapping for shop items, shared by the
/// shop, forest, and homestead screens.
class ShopItemVisual {
  const ShopItemVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

IconData treeSkinIcon({required String? equippedId, required int level}) {
  switch (equippedId) {
    case 'tree-crystal-pine':
      return Icons.ac_unit;
    case 'tree-bonsai':
      return Icons.spa;
    case 'tree-cherry-blossom':
      return Icons.local_florist;
    case 'tree-golden-ginkgo':
      return level >= 2 ? Icons.park : Icons.eco;
    default:
      if (level >= 3) {
        return Icons.forest;
      }
      if (level >= 2) {
        return Icons.park;
      }
      return Icons.eco;
  }
}

Color groundColor(ShopState shopState) {
  switch (shopState.equippedItemIds[ShopItemCategory.ground]) {
    case 'ground-riverbank':
      return const Color(0xffcfe8ea);
    case 'ground-autumn':
      return const Color(0xffe9d1a3);
    default:
      return const Color(0xffdcefd9);
  }
}

Color skyColor(ShopState shopState) {
  switch (shopState.equippedItemIds[ShopItemCategory.sky]) {
    case 'sky-sunset':
      return const Color(0xfffbe3d0);
    case 'sky-aurora':
      return const Color(0xffe3ecfb);
    default:
      return Colors.white;
  }
}

const Map<String, ShopItemVisual> _decorationVisuals = {
  'deco-garden-lantern': ShopItemVisual(
    icon: Icons.wb_incandescent,
    color: Color(0xffc79a33),
  ),
  'deco-flower-bed': ShopItemVisual(
    icon: Icons.local_florist,
    color: Color(0xffd97fa3),
  ),
  'deco-garden-bench': ShopItemVisual(
    icon: Icons.weekend,
    color: Color(0xff8a6a4f),
  ),
  'deco-bird-bath': ShopItemVisual(
    icon: Icons.water_drop,
    color: Color(0xff3f8f8a),
  ),
  'deco-beehive': ShopItemVisual(
    icon: Icons.hive,
    color: Color(0xffc79a33),
  ),
  'deco-garden-cabin': ShopItemVisual(
    icon: Icons.cabin,
    color: Color(0xff2f7d50),
  ),
};

/// Resolves the icon and accent color used to represent [item] in the shop
/// list, the forest scene, and the homestead canvas/tray.
ShopItemVisual shopItemVisual(ShopItem item) {
  switch (item.category) {
    case ShopItemCategory.treeSkin:
      return ShopItemVisual(
        icon: treeSkinIcon(equippedId: item.id, level: 3),
        color: const Color(0xff2f7d50),
      );
    case ShopItemCategory.ground:
      return const ShopItemVisual(
        icon: Icons.landscape,
        color: Color(0xff8a6a4f),
      );
    case ShopItemCategory.sky:
      return const ShopItemVisual(
        icon: Icons.cloud,
        color: Color(0xff3f8f8a),
      );
    case ShopItemCategory.decoration:
      return _decorationVisuals[item.id] ??
          const ShopItemVisual(
            icon: Icons.deck,
            color: Color(0xff8a6a4f),
          );
  }
}
