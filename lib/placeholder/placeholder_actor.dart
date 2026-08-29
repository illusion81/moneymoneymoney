import 'dart:ui';

/// Animals wander their field; items hold station and only pulse.
enum ActorKind { animal, item }

/// A stand-in for real art: a coloured box with a text label.
///
/// Swapping in real assets later means changing the painter, not this type.
class PlaceholderActor {
  const PlaceholderActor({
    required this.id,
    required this.label,
    required this.color,
    required this.size,
    required this.kind,
  });

  final String id;

  /// Drawn centred in the box, e.g. 'FOX'.
  final String label;

  final Color color;

  /// Design-space size before squash and stretch.
  final Size size;

  final ActorKind kind;
}