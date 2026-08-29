import 'dart:ui';

import 'sprite_strip.dart';

/// Egg shell colours. These double as lootbox rarity tiers.
enum EggVariant { cream, brown, purple, grey }

/// The clips the egg pack ships, with their frame counts.
enum EggClip {
  /// A single resting egg.
  idle(1),

  /// Rocks back and forth. Loops.
  rock(4),

  /// Hops in place. Loops.
  bounce(3),

  /// Cracks open and shatters. Plays once and holds the last frame.
  hatch(12);

  const EggClip(this.frameCount);

  final int frameCount;

  /// The hatch is a one-shot; the idle and motion clips cycle.
  bool get loops => this != EggClip.hatch;
}

/// Strips sliced out of the egg sprite sheet by `tool/extract_egg_sprites.py`.
class EggSprites {
  const EggSprites._();

  static const String dir = 'assets/eggs';

  /// Matches the source sheet's own 15/100s per frame.
  static const double fps = 6.7;

  /// Every frame in the pack is one 32x32 cell of the source sheet.
  static const Size frame = Size(32, 32);

  static String path(EggVariant variant, EggClip clip) =>
      '$dir/${variant.name}_${clip.name}.png';

  static SpriteStrip strip(EggVariant variant, EggClip clip) => SpriteStrip(
    assetPath: path(variant, clip),
    frameCount: clip.frameCount,
    frameSize: frame,
    fps: fps,
  );

  static List<String> get allPaths => <String>[
    for (final variant in EggVariant.values)
      for (final clip in EggClip.values) path(variant, clip),
  ];
}
