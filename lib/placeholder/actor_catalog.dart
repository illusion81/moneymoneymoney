import 'package:flutter/material.dart';

import 'placeholder_actor.dart';

/// Every placeholder subject in the app.
///
/// These stand in for art that does not exist yet; real assets replace the
/// painter, not this table.
class ActorCatalog {
  const ActorCatalog._();

  static final List<PlaceholderActor> all =
      List<PlaceholderActor>.unmodifiable(<PlaceholderActor>[
        const PlaceholderActor(
          id: 'fox',
          label: 'FOX',
          color: Color(0xffd96a2e),
          size: Size(78, 52),
          kind: ActorKind.animal,
        ),
        const PlaceholderActor(
          id: 'deer',
          label: 'DEER',
          color: Color(0xffb8814f),
          size: Size(80, 62),
          kind: ActorKind.animal,
        ),
        const PlaceholderActor(
          id: 'hummingbird',
          label: 'HUMMER',
          color: Color(0xff2f9e7a),
          size: Size(64, 40),
          kind: ActorKind.animal,
        ),
        const PlaceholderActor(
          id: 'raccoon',
          label: 'RACOON',
          color: Color(0xff8d8f96),
          size: Size(76, 50),
          kind: ActorKind.animal,
        ),
        const PlaceholderActor(
          id: 'coin',
          label: 'COIN',
          color: Color(0xffe0b33c),
          size: Size(48, 48),
          kind: ActorKind.item,
        ),
        const PlaceholderActor(
          id: 'egg',
          label: 'EGG',
          color: Color(0xffefe3cd),
          size: Size(46, 56),
          kind: ActorKind.item,
        ),
        const PlaceholderActor(
          id: 'xp_orb',
          label: 'XP',
          color: Color(0xff4fb8ff),
          size: Size(44, 44),
          kind: ActorKind.item,
        ),
      ]);

  static List<PlaceholderActor> get animals =>
      all.where((a) => a.kind == ActorKind.animal).toList();

  static PlaceholderActor byId(String id) => all.firstWhere((a) => a.id == id);
}