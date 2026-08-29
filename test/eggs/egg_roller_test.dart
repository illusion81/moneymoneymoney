import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/eggs/egg_rarity.dart';
import 'package:moneymoneymoney/eggs/egg_roller.dart';
import 'package:moneymoneymoney/sprites/egg_sprites.dart';

void main() {
  test('the roll is deterministic per seed', () {
    for (final variant in EggVariant.values) {
      for (final seed in <int>[0, 1, 7, 12345, -99]) {
        expect(
          EggRoller.roll(variant, seed),
          EggRoller.roll(variant, seed),
          reason: '$variant / $seed',
        );
      }
    }
  });

  test('every roll returns a real pack animal', () {
    final animals = EggCatalog.allAnimalIds.toSet();
    for (var seed = 0; seed < 500; seed++) {
      for (final variant in EggVariant.values) {
        expect(animals, contains(EggRoller.roll(variant, seed)));
      }
    }
  });

  test('a common egg never hatches a legendary animal', () {
    for (var seed = 0; seed < 1000; seed++) {
      final id = EggRoller.roll(EggVariant.cream, seed);
      expect(EggCatalog.tierOf(id), isNot(EggTier.legendary));
    }
  });

  test('a legendary egg never hatches a common animal', () {
    for (var seed = 0; seed < 1000; seed++) {
      final id = EggRoller.roll(EggVariant.grey, seed);
      expect(EggCatalog.tierOf(id), isNot(EggTier.common));
    }
  });

  test('the cream egg drops match its published weights', () {
    final counts = <EggTier, int>{for (final t in EggTier.values) t: 0};
    const rolls = 4000;
    for (var seed = 0; seed < rolls; seed++) {
      final tier = EggCatalog.tierOf(EggRoller.roll(EggVariant.cream, seed));
      counts[tier] = counts[tier]! + 1;
    }
    // Cream weights are [70, 25, 5, 0] over 4000 rolls: ~2800 common,
    // ~1000 uncommon, ~200 rare, 0 legendary. Wide slack for sampling noise.
    expect(counts[EggTier.common], inInclusiveRange(2500, 3100));
    expect(counts[EggTier.uncommon], inInclusiveRange(800, 1200));
    expect(counts[EggTier.rare], inInclusiveRange(50, 350));
    expect(counts[EggTier.legendary], 0);
  });

  test('rarer eggs skew toward rarer animals', () {
    double meanTier(EggVariant variant) {
      var sum = 0.0;
      const rolls = 4000;
      for (var seed = 0; seed < rolls; seed++) {
        sum += EggCatalog.tierOf(EggRoller.roll(variant, seed)).index;
      }
      return sum / rolls;
    }

    final cream = meanTier(EggVariant.cream);
    final brown = meanTier(EggVariant.brown);
    final purple = meanTier(EggVariant.purple);
    final grey = meanTier(EggVariant.grey);

    expect(cream, lessThan(brown));
    expect(brown, lessThan(purple));
    expect(purple, lessThan(grey));
  });
}
