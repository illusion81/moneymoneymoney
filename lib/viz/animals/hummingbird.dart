import 'dart:math' as math;
import 'dart:ui';

import '../rig/color_slot.dart';
import '../rig/shapes.dart';
import '../rig/viz_clip.dart';
import '../rig/viz_palette.dart';
import '../rig/viz_rig.dart';

const VizPalette hummingbirdDefaultPalette = VizPalette(
  id: 'hummingbird_default',
  label: 'Hummingbird',
  colors: {
    ColorSlot.primary: Color(0xff2f9e7a),
    ColorSlot.secondary: Color(0xff1f7a5e),
    ColorSlot.belly: Color(0xfff3efe3),
    ColorSlot.accent: Color(0xffd94f5c),
    ColorSlot.eye: Color(0xff20201e),
    ColorSlot.outline: Color(0xff2a2320),
  },
);

/// Hovering hummingbird facing right. Design space 160x140; it never lands, so
/// there is no ground line.
///
/// Clip reinterpretation: breathe = slow hover, walk = hovering flit,
/// run = forward dart.
class Hummingbird extends VizRig {
  @override
  String get id => 'hummingbird';

  @override
  String get displayName => 'Hummingbird';

  @override
  Size get canvasSize => const Size(160, 140);

  @override
  VizPalette get defaultPalette => hummingbirdDefaultPalette;

  @override
  Set<VizClip> get supportedClips => VizClip.values.toSet();

  @override
  List<RigPart> get parts => [
    RigPart(
      id: 'tailFan',
      path: trianglePath(
        const Offset(0, 0),
        const Offset(-36, -9),
        const Offset(-32, 15),
      ),
      slot: ColorSlot.secondary,
      pivot: const Offset(70, 72),
      z: 0,
    ),
    RigPart(
      id: 'wingFar',
      parent: 'body',
      path: capsulePath(-26, -4, 13, 52),
      slot: ColorSlot.secondary,
      pivot: const Offset(-4, -8),
      z: 1,
    ),
    RigPart(
      id: 'body',
      path: ovalPath(0, 0, 24, 18),
      slot: ColorSlot.primary,
      pivot: const Offset(88, 68),
      z: 2,
    ),
    RigPart(
      id: 'belly',
      parent: 'body',
      path: ovalPath(0, 0, 15, 9),
      slot: ColorSlot.belly,
      pivot: const Offset(-2, 8),
      z: 3,
    ),
    RigPart(
      id: 'legNear',
      parent: 'body',
      path: capsulePath(0, 7, 3.5, 14),
      slot: ColorSlot.outline,
      pivot: const Offset(0, 16),
      z: 4,
    ),
    RigPart(
      id: 'head',
      parent: 'body',
      path: ovalPath(0, 0, 13, 12),
      slot: ColorSlot.primary,
      pivot: const Offset(18, -12),
      z: 5,
    ),
    RigPart(
      id: 'crest',
      parent: 'head',
      path: trianglePath(
        const Offset(0, 0),
        const Offset(-9, -9),
        const Offset(2, -10),
      ),
      slot: ColorSlot.accent,
      pivot: const Offset(-2, -10),
      z: 6,
    ),
    RigPart(
      id: 'throat',
      parent: 'head',
      path: ovalPath(0, 0, 8, 6),
      slot: ColorSlot.accent,
      pivot: const Offset(2, 8),
      z: 7,
    ),
    RigPart(
      id: 'beak',
      parent: 'head',
      path: trianglePath(
        const Offset(0, -2),
        const Offset(32, 1),
        const Offset(0, 4),
      ),
      slot: ColorSlot.outline,
      pivot: const Offset(11, 2),
      z: 8,
    ),
    RigPart(
      id: 'eye',
      parent: 'head',
      path: ovalPath(0, 0, 2.4, 2.6),
      slot: ColorSlot.eye,
      pivot: const Offset(4, -2),
      z: 9,
    ),
    RigPart(
      id: 'wingNear',
      parent: 'body',
      path: capsulePath(-26, -2, 14, 52),
      slot: ColorSlot.primary,
      pivot: const Offset(2, -6),
      z: 10,
    ),
  ];

  @override
  Pose poseAt(VizClip clip, double t) => switch (clip) {
    VizClip.breathe => _beat(t, beats: 6, amplitude: 0.45, bob: 1.5, pitch: 0),
    VizClip.walk => _beat(t, beats: 10, amplitude: 1.00, bob: 3.0, pitch: 0),
    VizClip.run => _beat(t, beats: 14, amplitude: 1.25, bob: 2.0, pitch: -0.18),
  };

  /// [beats] must be an integer so the clip closes its loop.
  Pose _beat(
    double t, {
    required int beats,
    required double amplitude,
    required double bob,
    required double pitch,
  }) {
    final theta = 2 * math.pi * t;
    final wing = beats * theta;
    // The wing is broadside as it sweeps through the middle of the stroke and
    // foreshortens at the top and bottom, so a flat capsule reads as a wing
    // rather than a spinning stick.
    final squash = 0.55 + 0.45 * math.cos(wing).abs();
    return {
      'body': PartPose(
        offset: Offset(0, -bob * math.sin(2 * theta)),
        rotation: pitch,
      ),
      'wingNear': PartPose(
        rotation: amplitude * math.sin(wing),
        scaleX: squash,
      ),
      'wingFar': PartPose(
        rotation: amplitude * 0.9 * math.sin(wing + 0.4),
        scaleX: squash,
      ),
      'head': PartPose(rotation: 0.06 * math.sin(theta)),
      'tailFan': PartPose(rotation: 0.12 * math.sin(2 * theta) - pitch),
      'legNear': PartPose(rotation: 0.10 * math.sin(2 * theta)),
    };
  }
}
