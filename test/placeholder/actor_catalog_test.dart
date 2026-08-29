import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/placeholder/actor_catalog.dart';
import 'package:moneymoneymoney/placeholder/placeholder_actor.dart';

void main() {
  test('every actor has a unique id', () {
    final ids = ActorCatalog.all.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('holds the seven placeholder subjects', () {
    expect(ActorCatalog.all.length, 7);
    final ids = ActorCatalog.all.map((a) => a.id).toSet();
    expect(ids, containsAll(<String>[
      'fox',
      'deer',
      'hummingbird',
      'raccoon',
      'coin',
      'egg',
      'xp_orb',
    ]));
  });

  test('every actor has a non-empty label and a positive size', () {
    for (final actor in ActorCatalog.all) {
      expect(actor.label, isNotEmpty, reason: actor.id);
      expect(actor.size.width, greaterThan(0), reason: actor.id);
      expect(actor.size.height, greaterThan(0), reason: actor.id);
    }
  });

  test('the four animals are the animal-kind actors', () {
    expect(ActorCatalog.animals.length, 4);
    for (final actor in ActorCatalog.animals) {
      expect(actor.kind, ActorKind.animal);
    }
  });

  test('byId throws for an unknown actor', () {
    expect(() => ActorCatalog.byId('nope'), throwsStateError);
  });
}