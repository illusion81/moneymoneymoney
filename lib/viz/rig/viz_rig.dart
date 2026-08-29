import 'dart:ui';

import 'rig_part.dart';
import 'viz_clip.dart';
import 'viz_palette.dart';

export 'rig_part.dart';

/// A drawable gameobject: a set of parts plus pure pose functions.
///
/// Implementations must not hold mutable state, read app state, or perform I/O.
abstract class VizRig {
  /// Stable identifier, e.g. 'fox'.
  String get id;

  /// Human label for pickers, e.g. 'Fox'.
  String get displayName;

  /// The design-space box the parts are authored in. The painter letterboxes
  /// this into whatever size it is given.
  Size get canvasSize;

  /// Parts in any order; the painter sorts by [RigPart.z].
  List<RigPart> get parts;

  VizPalette get defaultPalette;

  Set<VizClip> get supportedClips;

  /// Pure function of the loop phase [t] in [0, 1).
  ///
  /// Every term must be periodic over that range: use sin(2 * pi * k * t) with
  /// integer k, never sin(pi * t).
  Pose poseAt(VizClip clip, double t);
}
