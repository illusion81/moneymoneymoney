import '../sprites/egg_sprites.dart';
import 'egg_rarity.dart';
import 'egg_roller.dart';

/// The lifecycle of one egg instance.
enum EggState { locked, ready, hatching, hatched }

/// One egg. Immutable: the state machine returns a new [Egg] on every move.
///
/// The animal is never stored. [animalId] recomputes the seeded roll each time
/// it is read, so a hatched egg can never disagree with the egg that made it.
class Egg {
  const Egg({required this.variant, required this.state, required this.seed});

  factory Egg.locked(EggVariant variant, int seed) =>
      Egg(variant: variant, state: EggState.locked, seed: seed);

  final EggVariant variant;
  final EggState state;
  final int seed;

  int get priceCoins => variant.priceCoins;

  /// The animal this egg will hatch into, recomputed from [seed].
  String get animalId => EggRoller.roll(variant, seed);

  EggTier get animalTier => EggCatalog.tierOf(animalId);

  /// The only moves an egg may make: unlock (locked -> ready), start hatching
  /// (ready -> hatching) and reveal (hatching -> hatched).
  static const Map<EggState, Set<EggState>> _legal = <EggState, Set<EggState>>{
    EggState.locked: <EggState>{EggState.ready},
    EggState.ready: <EggState>{EggState.hatching},
    EggState.hatching: <EggState>{EggState.hatched},
    EggState.hatched: <EggState>{},
  };

  bool canTransitionTo(EggState target) => _legal[state]!.contains(target);

  /// Moves to [target], throwing if the transition is illegal — for example
  /// starting to hatch an egg that has already hatched.
  Egg to(EggState target) {
    if (!canTransitionTo(target)) {
      throw StateError('Cannot move an egg from $state to $target');
    }
    return Egg(variant: variant, state: target, seed: seed);
  }

  Egg startHatching() => to(EggState.hatching);

  Egg reveal() => to(EggState.hatched);
}
