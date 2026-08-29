import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/eggs/egg.dart';
import 'package:moneymoneymoney/eggs/egg_rarity.dart';
import 'package:moneymoneymoney/eggs/egg_roller.dart';
import 'package:moneymoneymoney/sprites/egg_sprites.dart';

void main() {
  test('a new egg starts locked', () {
    final egg = Egg.locked(EggVariant.cream, 42);
    expect(egg.state, EggState.locked);
  });

  test('an egg knows its price from its variant', () {
    expect(Egg.locked(EggVariant.cream, 1).priceCoins, 5);
    expect(Egg.locked(EggVariant.grey, 1).priceCoins, 40);
  });

  test('the animal is recomputed, not stored, and agrees with the roller', () {
    for (final variant in EggVariant.values) {
      for (final seed in <int>[0, 3, 99]) {
        final egg = Egg.locked(variant, seed);
        expect(egg.animalId, EggRoller.roll(variant, seed));
        expect(egg.animalTier, EggCatalog.tierOf(egg.animalId));
      }
    }
  });

  test('the legal path is locked -> ready -> hatching -> hatched', () {
    final egg = Egg.locked(EggVariant.brown, 7);
    expect(egg.canTransitionTo(EggState.ready), isTrue);
    expect(egg.canTransitionTo(EggState.hatching), isFalse);

    final ready = egg.to(EggState.ready);
    expect(ready.state, EggState.ready);
    expect(ready.canTransitionTo(EggState.hatching), isTrue);

    final hatching = ready.startHatching();
    expect(hatching.state, EggState.hatching);

    final hatched = hatching.reveal();
    expect(hatched.state, EggState.hatched);
    expect(hatched.canTransitionTo(EggState.hatched), isFalse);
  });

  test('hatching a locked egg throws', () {
    expect(
      () => Egg.locked(EggVariant.cream, 1).startHatching(),
      throwsStateError,
    );
  });

  test('hatching an already-hatched egg throws', () {
    final hatched = Egg.locked(
      EggVariant.cream,
      1,
    ).to(EggState.ready).startHatching().reveal();
    expect(hatched.state, EggState.hatched);
    expect(() => hatched.startHatching(), throwsStateError);
  });

  test('a hatched egg cannot be relocked or revealed again', () {
    final hatched = Egg.locked(
      EggVariant.cream,
      1,
    ).to(EggState.ready).startHatching().reveal();
    expect(() => hatched.to(EggState.locked), throwsStateError);
    expect(() => hatched.reveal(), throwsStateError);
  });

  test('revealing before hatching throws', () {
    expect(() => Egg.locked(EggVariant.cream, 1).to(EggState.ready).reveal(),
        throwsStateError);
  });

  test('the hatch clip is a one-shot that holds its last frame', () {
    expect(EggClip.hatch.loops, isFalse);
    expect(EggClip.rock.loops, isTrue);
    expect(EggClip.bounce.loops, isTrue);

    final hatch = EggSprites.strip(EggVariant.cream, EggClip.hatch);
    // Long past the end, a one-shot strip stays on the final frame.
    expect(hatch.frameAt(999, loop: false), hatch.frameCount - 1);
    // Whereas a looping clip wraps back around.
    final rock = EggSprites.strip(EggVariant.cream, EggClip.rock);
    expect(rock.frameAt(999, loop: true), lessThan(rock.frameCount));
  });
}
