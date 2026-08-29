import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/placeholder/actor_catalog.dart';
import 'package:moneymoneymoney/placeholder/placeholder_actor.dart';
import 'package:moneymoneymoney/sprites/asset_paths.dart';
import 'package:moneymoneymoney/sprites/egg_sprites.dart';

void main() {
  test('every actor has a unique id', () {
    final ids = ActorCatalog.all.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('holds the 25 pack animals plus three items', () {
    expect(ActorCatalog.animals, hasLength(25));
    expect(ActorCatalog.items, hasLength(3));
    expect(ActorCatalog.all, hasLength(28));
    expect(
      ActorCatalog.animals.map((a) => a.id).toList(),
      SpriteAssets.animalIds,
    );
    expect(ActorCatalog.items.map((a) => a.id).toSet(), <String>{
      'coin',
      'egg',
      'xp_orb',
    });
  });

  test('the dropped placeholders are gone', () {
    final ids = ActorCatalog.all.map((a) => a.id).toSet();
    // The pack has no sprite for these three.
    expect(ids, isNot(contains('deer')));
    expect(ids, isNot(contains('hummingbird')));
    expect(ids, isNot(contains('raccoon')));
  });

  test('every actor has a label, a positive size and a sprite', () {
    for (final actor in ActorCatalog.all) {
      expect(actor.label, isNotEmpty, reason: actor.id);
      expect(actor.size.width, greaterThan(0), reason: actor.id);
      expect(actor.size.height, greaterThan(0), reason: actor.id);
      expect(actor.sprite, isNotNull, reason: actor.id);
    }
  });

  test('animals are animal-kind and point at the animal pack', () {
    for (final actor in ActorCatalog.animals) {
      expect(actor.kind, ActorKind.animal);
      expect(actor.sprite!.assetPath, SpriteAssets.animal(actor.id));
      expect(actor.sprite!.isAnimated, isFalse);
    }
  });

  test('spritePaths lists one registered path per actor', () {
    expect(ActorCatalog.spritePaths, hasLength(28));
    final known = <String>{...SpriteAssets.allPaths, ...EggSprites.allPaths};
    for (final path in ActorCatalog.spritePaths) {
      expect(known, contains(path));
    }
  });

  test('the egg uses its own animated pack, not a market icon', () {
    final egg = ActorCatalog.byId('egg');
    expect(egg.sprite!.assetPath, EggSprites.path(EggVariant.cream, EggClip.rock));
    expect(egg.sprite!.isAnimated, isTrue);
    expect(egg.sprite!.frameCount, 4);
  });

  test('byId throws for an unknown actor', () {
    expect(() => ActorCatalog.byId('nope'), throwsStateError);
  });
}
