import 'dart:ui';

import '../sprites/sprite_strip.dart';

/// Animals wander their field; items hold station and only pulse.
enum ActorKind { animal, item }

/// One drawable subject on the field.
///
/// [sprite] is the real art. [color] and [label] stay as the fallback the box
/// painter uses while the sprite is still decoding.
class PlaceholderActor {
  const PlaceholderActor({
    required this.id,
    required this.label,
    required this.color,
    required this.size,
    required this.kind,
    this.sprite,
  });

  final String id;

  /// Drawn centred in the box, e.g. 'FOX'.
  final String label;

  final Color color;

  /// Design-space size before squash and stretch.
  final Size size;

  final ActorKind kind;

  /// This subject's art, or null if it has none yet. A still sprite is a
  /// one-frame strip.
  final SpriteStrip? sprite;
}