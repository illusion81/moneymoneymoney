import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/eggs/egg_rarity.dart';
import 'package:moneymoneymoney/sprites/asset_paths.dart';
import 'package:moneymoneymoney/sprites/egg_sprites.dart';

void main() {
  test('four variants map onto four distinct tiers', () {
    expect(
      EggVariant.values.map((v) => v.tier).toSet(),
      EggTier.values.toSet(),
    );
  });

  test('rarer eggs cost more, and none are free', () {
    final prices = EggVariant.values.map((v) => v.priceCoins).toList();
    for (final price in prices) {
      expect(price, greaterThan(0));
    }
    expect(prices, <int>[5, 12, 25, 40]);
  });

  test('every variant publishes a weight for every tier', () {
    for (final variant in EggVariant.values) {
      expect(variant.weights, hasLength(EggTier.values.length));
      expect(
        variant.weights.fold<int>(0, (sum, w) => sum + w),
        greaterThan(0),
        reason: variant.name,
      );
    }
  });

  test('the common egg can never drop a legendary', () {
    expect(EggVariant.cream.weights[EggTier.legendary.index], 0);
  });

  test('the legendary egg can never drop a common', () {
    expect(EggVariant.grey.weights[EggTier.common.index], 0);
  });

  test('the animal buckets partition all 25 pack animals', () {
    final bucketIds = <String>[
      for (final tier in EggTier.values) ...EggCatalog.animalsOfTier(tier),
    ];
    expect(bucketIds.toSet().length, 25);
    expect(bucketIds.toSet(), SpriteAssets.animalIds.toSet());
  });

  test('every tier has animals to drop', () {
    for (final tier in EggTier.values) {
      expect(EggCatalog.animalsOfTier(tier), isNotEmpty, reason: tier.name);
    }
  });

  test('tierOf inverts the buckets', () {
    for (final tier in EggTier.values) {
      for (final id in EggCatalog.animalsOfTier(tier)) {
        expect(EggCatalog.tierOf(id), tier, reason: id);
      }
    }
  });
}
