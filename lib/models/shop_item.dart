import 'progression.dart';

enum ShopItemCategory { treeSkin, ground, sky, decoration, animal }

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.requiredLevel,
    required this.isDefault,
    this.plusOnly = false,
    this.asset,
  });

  final String id;
  final String name;
  final String description;
  final ShopItemCategory category;
  final int price;
  final int requiredLevel;
  final bool isDefault;

  /// Premium item: buying it requires an active Plus membership on top of
  /// the usual coin and level cost.
  final bool plusOnly;

  /// Artwork file stem, e.g. 'cow' -> assets/animals/cow.png.
  final String? asset;
}

class ShopState {
  const ShopState({required this.ownedItemIds, required this.equippedItemIds});

  final Set<String> ownedItemIds;
  final Map<ShopItemCategory, String> equippedItemIds;
}

enum PurchaseFailure {
  alreadyOwned,
  insufficientCoins,
  levelTooLow,
  plusRequired,
  unknownItem,
}

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
/// Animals live on the farm. You buy them with coins earned by holding your
/// plan — they do not just appear, which is the point of having an economy.
const List<ShopItem> _kAnimals = [
  ShopItem(id: 'animal-chicken', name: 'Chicken', description: 'First resident of any decent farm.', category: ShopItemCategory.animal, price: 40, requiredLevel: 1, isDefault: false, asset: 'chiken'),
  ShopItem(id: 'animal-rabbit', name: 'Rabbit', description: 'Quiet, tidy, eats your clover.', category: ShopItemCategory.animal, price: 60, requiredLevel: 1, isDefault: false, asset: 'rabbit'),
  ShopItem(id: 'animal-cat', name: 'Cat', description: 'Supervises. Contributes nothing.', category: ShopItemCategory.animal, price: 90, requiredLevel: 2, isDefault: false, asset: 'cat'),
  ShopItem(id: 'animal-dog', name: 'Dog', description: 'Keeps the others honest.', category: ShopItemCategory.animal, price: 120, requiredLevel: 2, isDefault: false, asset: 'dog'),
  ShopItem(id: 'animal-pig', name: 'Pig', description: 'Surprisingly good company.', category: ShopItemCategory.animal, price: 160, requiredLevel: 3, isDefault: false, asset: 'pig'),
  ShopItem(id: 'animal-goat', name: 'Goat', description: 'Will eat a subscription reminder.', category: ShopItemCategory.animal, price: 200, requiredLevel: 3, isDefault: false, asset: 'goat'),
  ShopItem(id: 'animal-cow', name: 'Cow', description: 'The sign you have properly arrived.', category: ShopItemCategory.animal, price: 300, requiredLevel: 4, isDefault: false, asset: 'cow'),
  ShopItem(id: 'animal-fox', name: 'Fox', description: 'Turned up uninvited. Stayed.', category: ShopItemCategory.animal, price: 350, requiredLevel: 5, isDefault: false, asset: 'fox'),
  // Plus-only, and deliberately available from level 1 — a membership that
  // unlocks nothing until level 8 is a membership that sells nothing.
  ShopItem(id: 'animal-panda', name: 'Panda', description: 'Plus members only.', category: ShopItemCategory.animal, price: 0, requiredLevel: 1, isDefault: false, plusOnly: true, asset: 'panda'),
  ShopItem(id: 'animal-penguin', name: 'Penguin', description: 'Plus members only.', category: ShopItemCategory.animal, price: 0, requiredLevel: 1, isDefault: false, plusOnly: true, asset: 'penguin'),
  ShopItem(id: 'animal-tiger', name: 'Tiger', description: 'Plus members only. Ignore the goat.', category: ShopItemCategory.animal, price: 0, requiredLevel: 2, isDefault: false, plusOnly: true, asset: 'tiger'),
  ShopItem(id: 'animal-elephant', name: 'Elephant', description: 'Plus members only.', category: ShopItemCategory.animal, price: 0, requiredLevel: 3, isDefault: false, plusOnly: true, asset: 'elephant'),
];

/// More things to put on the homestead. A yard with four items looks unfinished
/// no matter how well each one is drawn.
const List<ShopItem> _kMoreDecor = [
  ShopItem(id: 'deco-pond', name: 'Pond', description: 'Still water, a lily pad, no maintenance.', category: ShopItemCategory.decoration, price: 180, requiredLevel: 2, isDefault: false),
  ShopItem(id: 'deco-fence', name: 'Picket Fence', description: 'Marks the edge of what is yours.', category: ShopItemCategory.decoration, price: 140, requiredLevel: 2, isDefault: false),
  ShopItem(id: 'deco-vegetable-patch', name: 'Vegetable Patch', description: 'Cheaper than the delivery app.', category: ShopItemCategory.decoration, price: 220, requiredLevel: 3, isDefault: false),
  ShopItem(id: 'deco-signpost', name: 'Signpost', description: 'Points at where you are heading.', category: ShopItemCategory.decoration, price: 120, requiredLevel: 2, isDefault: false),
  ShopItem(id: 'deco-lamp-post', name: 'Lamp Post', description: 'Keeps the yard warm after dark.', category: ShopItemCategory.decoration, price: 260, requiredLevel: 4, isDefault: false),
  ShopItem(id: 'deco-windmill', name: 'Windmill', description: 'Plus members only. Turns whether or not anyone is watching.', category: ShopItemCategory.decoration, price: 0, requiredLevel: 3, isDefault: false, plusOnly: true),
];

const List<ShopItem> kShopCatalog = [
  ..._kAnimals,
  ..._kMoreDecor,
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
    plusOnly: true,
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
    plusOnly: true,
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
    plusOnly: true,
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
    plusOnly: true,
  ),
];
