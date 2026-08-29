import 'dart:ui';

/// Animals wander their field; items hold station and only pulse.
enum ActorKind { animal, item }

/// One drawable subject on the field.
///
/// [spriteAsset] is the real art. [color] and [label] stay as the fallback the
/// box painter uses while the sprite is still decoding.
class PlaceholderActor {
  const PlaceholderActor({
    required this.id,
    required this.label,
    required this.color,
    required this.size,
    required this.kind,
    this.spriteAsset,
  });

  final String id;

  /// Drawn centred in the box, e.g. 'FOX'.
  final String label;

  final Color color;

  /// Design-space size before squash and stretch.
  final Size size;

  final ActorKind kind;

  /// Asset path of this subject's sprite, or null if it has no art yet.
  final String? spriteAsset;
}