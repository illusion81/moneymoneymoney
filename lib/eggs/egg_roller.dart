import '../placeholder/motion/value_noise.dart';
import '../sprites/egg_sprites.dart';
import 'egg_rarity.dart';

/// Deterministically turns an [EggVariant] and a seed into an animal id.
///
/// The roll is a pure function of the seed: the same seed always hatches the
/// same animal, so the result is recomputed on demand rather than stored. The
/// integer hash in [hash01] keeps it stable across runs and platforms, unlike
/// `Random`, whose sequence Dart reserves the right to change.
class EggRoller {
  const EggRoller._();

  /// Rolls the animal a [variant] egg of the given [seed] hatches into.
  static String roll(EggVariant variant, int seed) {
    final tier = _rollTier(variant, seed);
    final bucket = EggCatalog.animalsOfTier(tier);
    return bucket[_pickUniform(bucket.length, hash01(seed, 1))];
  }

  static EggTier _rollTier(EggVariant variant, int seed) {
    final weights = variant.weights;
    final total = weights.fold(0, (sum, w) => sum + w);
    var cursor = _pickUniform(total, hash01(seed, 0));
    for (final tier in EggTier.values) {
      final weight = weights[tier.index];
      if (cursor < weight) return tier;
      cursor -= weight;
    }
    return EggTier.legendary;
  }

  static int _pickUniform(int count, double unit) =>
      (unit * count).floor().clamp(0, count - 1);
}
