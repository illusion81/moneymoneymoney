import 'dart:ui';

import 'color_slot.dart';

/// One drawable piece of a rig.
///
/// [path] is in part-local space with the pivot at (0, 0). [pivot] positions
/// the part in its parent's space, or in rig space when [parent] is null.
/// [z] is the global draw order and must be unique within a rig, because
/// Dart's List.sort is not stable.
class RigPart {
  const RigPart({
    required this.id,
    required this.path,
    required this.slot,
    required this.pivot,
    required this.z,
    this.parent,
  });

  final String id;
  final String? parent;
  final Path path;
  final ColorSlot slot;
  final Offset pivot;
  final int z;
}

/// A per-frame transform applied to one part, about its pivot.
class PartPose {
  const PartPose({
    this.rotation = 0,
    this.offset = Offset.zero,
    this.scaleX = 1,
    this.scaleY = 1,
  });

  /// Radians, clockwise in screen space.
  final double rotation;

  /// Extra translation, added to the part's pivot.
  final Offset offset;

  final double scaleX;
  final double scaleY;
}

/// Part id -> transform for a single animation frame. Parts absent from the map
/// are drawn at rest.
typedef Pose = Map<String, PartPose>;
