import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/placeholder/actor_catalog.dart';
import 'package:moneymoneymoney/placeholder/placeholder_actor.dart';
import 'package:moneymoneymoney/sprites/asset_paths.dart';

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
      expect(actor.spriteAsset, isNotNull, reason: actor.id);
    }
  });

  test('animals are animal-kind and point at the animal pack', () {
    for (final actor in ActorCatalog.animals) {
      expect(actor.kind, ActorKind.animal);
      expect(actor.spriteAsset, SpriteAssets.animal(actor.id));
    }
  });

  test('spritePaths lists one registered path per actor', () {
    expect(ActorCatalog.spritePaths, hasLength(28));
    for (final path in ActorCatalog.spritePaths) {
      expect(SpriteAssets.allPaths, contains(path));
    }
  });

  test('byId throws for an unknown actor', () {
    expect(() => ActorCatalog.byId('nope'), throwsStateError);
  });
}
