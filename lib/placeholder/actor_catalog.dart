import 'package:flutter/material.dart';

import '../sprites/asset_paths.dart';
import '../sprites/egg_sprites.dart';
import '../sprites/sprite_strip.dart';
import 'placeholder_actor.dart';

/// Every drawable subject in the app.
///
/// Animals come straight from the 25-sprite pixel pack, so the table is
/// generated from [SpriteAssets.animalIds] rather than hand-written. Items
/// borrow the closest icon from the market sheet.
class ActorCatalog {
  const ActorCatalog._();

  /// Sprites are 32x32; drawn at 2x so they read on a phone without blurring.
  static const Size _animalSize = Size(64, 64);

  /// Fallback box colours, cycled so a still-decoding field is legible.
  static const List<Color> _fallbackColors = <Color>[
    Color(0xffd96a2e),
    Color(0xffb8814f),
    Color(0xff2f9e7a),
    Color(0xff8d8f96),
    Color(0xff7d6bb0),
  ];

  static final List<PlaceholderActor> animals =
      List<PlaceholderActor>.unmodifiable(<PlaceholderActor>[
        for (var i = 0; i < SpriteAssets.animalIds.length; i++)
          PlaceholderActor(
            id: SpriteAssets.animalIds[i],
            label: SpriteAssets.animalIds[i].toUpperCase(),
            color: _fallbackColors[i % _fallbackColors.length],
            size: _animalSize,
            kind: ActorKind.animal,
            sprite: SpriteStrip.single(
              SpriteAssets.animal(SpriteAssets.animalIds[i]),
            ),
          ),
      ]);

  static final List<PlaceholderActor> items =
      List<PlaceholderActor>.unmodifiable(<PlaceholderActor>[
        PlaceholderActor(
          id: 'coin',
          label: 'COIN',
          color: const Color(0xffe0b33c),
          size: const Size(48, 48),
          kind: ActorKind.item,
          sprite: SpriteStrip.single(SpriteAssets.icon('coin')),
        ),
        PlaceholderActor(
          id: 'egg',
          label: 'EGG',
          color: const Color(0xffefe3cd),
          size: const Size(56, 56),
          kind: ActorKind.item,
          // Rocks on the field; the hatch clip is played by the egg screens.
          sprite: EggSprites.strip(EggVariant.cream, EggClip.rock),
        ),
        PlaceholderActor(
          id: 'xp_orb',
          label: 'XP',
          color: const Color(0xff4fb8ff),
          size: const Size(44, 44),
          kind: ActorKind.item,
          sprite: SpriteStrip.single(SpriteAssets.icon('sparkle_eight')),
        ),
      ]);

  static final List<PlaceholderActor> all = List<PlaceholderActor>.unmodifiable(
    <PlaceholderActor>[...animals, ...items],
  );

  /// Every sprite the field needs, for preloading in one pass.
  static List<String> get spritePaths => <String>[
    for (final actor in all)
      if (actor.sprite != null) actor.sprite!.assetPath,
  ];

  static PlaceholderActor byId(String id) => all.firstWhere((a) => a.id == id);
}
