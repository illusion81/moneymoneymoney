import 'progression.dart';

enum ShopItemCategory { treeSkin, ground, sky, decoration }

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.requiredLevel,
    required this.isDefault,
  });

  final String id;
  final String name;
  final String description;
  final ShopItemCategory category;
  final int price;
  final int requiredLevel;
  final bool isDefault;
}

class ShopState {
  const ShopState({
    required this.ownedItemIds,
    required this.equippedItemIds,
  });

  final Set<String> ownedItemIds;
  final Map<ShopItemCategory, String> equippedItemIds;
}

enum PurchaseFailure { alreadyOwned, insufficientCoins, levelTooLow, unknownItem }

class PurchaseResult {
  const PurchaseResult({
    required this.success,
    required this.state,
    required this.progression,
    required this.message,
    this.failure,
  });

  final bool success;
  final PurchaseFailure? failure;
  final ShopState state;
  final ProgressionState progression;
  final String message;
}

/// The hard-coded shop catalog. Default items are owned and equipped from
/// the start at price 0.
const List<ShopItem> kShopCatalog = [
  ShopItem(
    id: 'tree-classic-oak',
    name: 'Classic Oak',
    description: 'The familiar oak your forest started with.',
    category: ShopItemCategory.treeSkin,
    price: 0,
    requiredLevel: 1,
    isDefault: true,
  ),
  ShopItem(
    id: 'tree-golden-ginkgo',
    name: 'Golden Ginkgo',
    description: 'A ginkgo that turns gold as it grows.',
    category: ShopItemCategory.treeSkin,
    price: 120,
    requiredLevel: 2,
    isDefault: false,
  ),
  ShopItem(
    id: 'tree-cherry-blossom',
    name: 'Cherry Blossom',
    description: 'Soft pink blossoms for a healthy streak.',
    category: ShopItemCategory.treeSkin,
    price: 200,
    requiredLevel: 3,
    isDefault: false,
  ),
  ShopItem(
    id: 'tree-bonsai',
    name: 'Patient Bonsai',
    description: 'A slow, deliberate tree for patient savers.',
    category: ShopItemCategory.treeSkin,
    price: 320,
    requiredLevel: 5,
    isDefault: false,
  ),
  ShopItem(
    id: 'tree-crystal-pine',
    name: 'Crystal Pine',
    description: 'A crystalline pine for seasoned planners.',
    category: ShopItemCategory.treeSkin,
    price: 600,
    requiredLevel: 8,
    isDefault: false,
  ),
  ShopItem(
    id: 'ground-meadow',
    name: 'Meadow',
    description: 'The default green meadow ground.',
    category: ShopItemCategory.ground,
    price: 0,
    requiredLevel: 1,
    isDefault: true,
  ),
  ShopItem(
    id: 'ground-riverbank',
    name: 'Riverbank',
    description: 'A cool riverbank beneath your tree.',
    category: ShopItemCategory.ground,
    price: 150,
    requiredLevel: 2,
    isDefault: false,
  ),
  ShopItem(
    id: 'ground-autumn',
    name: 'Autumn Field',
    description: 'A field of fallen autumn leaves.',
    category: ShopItemCategory.ground,
    price: 260,
    requiredLevel: 4,
    isDefault: false,
  ),
  ShopItem(
    id: 'sky-clear-day',
    name: 'Clear Day',
    description: 'The default clear sky.',
    category: ShopItemCategory.sky,
    price: 0,
    requiredLevel: 1,
    isDefault: true,
  ),
  ShopItem(
    id: 'sky-sunset',
    name: 'Sunset',
    description: 'A warm sunset sky.',
    category: ShopItemCategory.sky,
    price: 180,
    requiredLevel: 3,
    isDefault: false,
  ),
  ShopItem(
    id: 'sky-aurora',
    name: 'Aurora',
    description: 'An aurora dancing above your forest.',
    category: ShopItemCategory.sky,
    price: 400,
    requiredLevel: 6,
    isDefault: false,
  ),

  // Decorations are placed in the homestead rather than equipped, so
  // several owned items can be in use at the same time.
  ShopItem(
    id: 'deco-garden-lantern',
    name: 'Garden Lantern',
    description: 'A warm lantern to light up your homestead.',
    category: ShopItemCategory.decoration,
    price: 80,
    requiredLevel: 1,
    isDefault: false,
  ),
  ShopItem(
    id: 'deco-flower-bed',
    name: 'Flower Bed',
    description: 'A bed of bright flowers.',
    category: ShopItemCategory.decoration,
    price: 100,
    requiredLevel: 1,
    isDefault: false,
  ),
  ShopItem(
    id: 'deco-garden-bench',
    name: 'Garden Bench',
    description: 'A place to sit and admire your progress.',
    category: ShopItemCategory.decoration,
    price: 160,
    requiredLevel: 2,
    isDefault: false,
  ),
  ShopItem(
    id: 'deco-bird-bath',
    name: 'Bird Bath',
    description: 'Draws birds to your homestead.',
    category: ShopItemCategory.decoration,
    price: 220,
    requiredLevel: 3,
    isDefault: false,
  ),
  ShopItem(
    id: 'deco-beehive',
    name: 'Beehive',
    description: 'A buzzing beehive for the garden.',
    category: ShopItemCategory.decoration,
    price: 280,
    requiredLevel: 4,
    isDefault: false,
  ),
  ShopItem(
    id: 'deco-garden-cabin',
    name: 'Garden Cabin',
    description: 'A cozy little cabin for the homestead.',
    category: ShopItemCategory.decoration,
    price: 450,
    requiredLevel: 6,
    isDefault: false,
  ),
];
