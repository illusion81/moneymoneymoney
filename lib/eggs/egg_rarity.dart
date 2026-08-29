import '../sprites/egg_sprites.dart';

/// How rare an animal is. Four tiers, one per [EggVariant].
///
/// An animal's tier decides which egg variants can drop it, so the rarer
/// animals only ever come from the rarer shells.
enum EggTier {
  common('Common'),
  uncommon('Uncommon'),
  rare('Rare'),
  legendary('Legendary');

  const EggTier(this.label);

  final String label;
}

/// The lootbox data attached to each egg shell colour.
extension EggVariantRarity on EggVariant {
  /// The rarity tier this shell represents. Cream is the common egg and grey
  /// the legendary one.
  EggTier get tier => switch (this) {
    EggVariant.cream => EggTier.common,
    EggVariant.brown => EggTier.uncommon,
    EggVariant.purple => EggTier.rare,
    EggVariant.grey => EggTier.legendary,
  };

  /// Display name for the lootbox card.
  String get label => switch (this) {
    EggVariant.cream => 'Common Egg',
    EggVariant.brown => 'Uncommon Egg',
    EggVariant.purple => 'Rare Egg',
    EggVariant.grey => 'Legendary Egg',
  };

  /// Coins charged to buy this egg. Rarer eggs cost more.
  int get priceCoins => switch (this) {
    EggVariant.cream => 5,
    EggVariant.brown => 12,
    EggVariant.purple => 25,
    EggVariant.grey => 40,
  };

  /// Relative drop weights over [EggTier.values], in enum order. These are
  /// weights, not percentages: a rarer shell shifts its weight toward the
  /// rarer tiers.
  List<int> get weights => switch (this) {
    EggVariant.cream => const <int>[70, 25, 5, 0],
    EggVariant.brown => const <int>[30, 45, 22, 3],
    EggVariant.purple => const <int>[5, 25, 45, 25],
    EggVariant.grey => const <int>[0, 15, 45, 40],
  };
}

/// The animals each tier can drop, and how to read a tier back off an id.
///
/// The buckets partition all 25 pack animals in [SpriteAssets.animalIds].
class EggCatalog {
  const EggCatalog._();

  static const Map<EggTier, List<String>> _byTier = <EggTier, List<String>>{
    EggTier.common: <String>[
      'bear',
      'cat',
      'chiken',
      'cow',
      'dog',
      'frog',
      'goat',
      'mouse',
      'pig',
      'rabbit',
    ],
    EggTier.uncommon: <String>[
      'crocodile',
      'fox',
      'monkey',
      'moose',
      'penguin',
      'snake',
      'turtle',
    ],
    EggTier.rare: <String>[
      'elephant',
      'giraffe',
      'gorilla',
      'hippo',
      'lion',
    ],
    EggTier.legendary: <String>[
      'panda',
      'tiger',
      'zebra',
    ],
  };

  static List<String> animalsOfTier(EggTier tier) => _byTier[tier]!;

  static EggTier tierOf(String animalId) =>
      _byTier.entries.firstWhere((e) => e.value.contains(animalId)).key;

  static List<String> get allAnimalIds => <String>[
    for (final tier in EggTier.values) ..._byTier[tier]!,
  ];
}
