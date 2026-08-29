import 'dart:math' as math;
import 'dart:ui';

import '../rig/color_slot.dart';
import '../rig/shapes.dart';
import '../rig/viz_clip.dart';
import '../rig/viz_palette.dart';
import '../rig/viz_rig.dart';

const VizPalette foxDefaultPalette = VizPalette(
  id: 'fox_default',
  label: 'Fox',
  colors: {
    ColorSlot.primary: Color(0xffd96a2e),
    ColorSlot.secondary: Color(0xffb04f20),
    ColorSlot.belly: Color(0xfff5e9d8),
    ColorSlot.accent: Color(0xfff2a65a),
    ColorSlot.eye: Color(0xff2a2320),
    ColorSlot.outline: Color(0xff2a2320),
  },
);

/// Side-on fox facing right. Design space 200x140, ground line at y = 130.
class Fox extends VizRig {
  @override
  String get id => 'fox';

  @override
  String get displayName => 'Fox';

  @override
  Size get canvasSize => const Size(200, 140);

  @override
  VizPalette get defaultPalette => foxDefaultPalette;

  @override
  Set<VizClip> get supportedClips => VizClip.values.toSet();

  @override
  List<RigPart> get parts => [
    RigPart(
      id: 'tail',
      path: curvedPath(const Offset(0, 0), [
        (const Offset(-22, -4), const Offset(-40, -18), const Offset(-46, -40)),
        (const Offset(-30, -46), const Offset(-8, -30), const Offset(0, -12)),
      ]),
      slot: ColorSlot.primary,
      pivot: const Offset(58, 78),
      z: 0,
    ),
    RigPart(
      id: 'tailTip',
      parent: 'tail',
      path: ovalPath(0, 0, 11, 10),
      slot: ColorSlot.belly,
      pivot: const Offset(-44, -40),
      z: 1,
    ),
    RigPart(
      id: 'hindLegFar',
      path: capsulePath(0, 19, 11, 38),
      slot: ColorSlot.secondary,
      pivot: const Offset(78, 92),
      z: 2,
    ),
    RigPart(
      id: 'foreLegFar',
      path: capsulePath(0, 19, 10, 38),
      slot: ColorSlot.secondary,
      pivot: const Offset(132, 92),
      z: 3,
    ),
    RigPart(
      id: 'body',
      path: ovalPath(0, 0, 44, 26),
      slot: ColorSlot.primary,
      pivot: const Offset(104, 80),
      z: 4,
    ),
    RigPart(
      id: 'chest',
      parent: 'body',
      path: ovalPath(0, 0, 20, 17),
      slot: ColorSlot.belly,
      pivot: const Offset(30, 8),
      z: 5,
    ),
    RigPart(
      id: 'hindLegNear',
      path: capsulePath(0, 18, 11, 36),
      slot: ColorSlot.primary,
      pivot: const Offset(88, 94),
      z: 6,
    ),
    RigPart(
      id: 'foreLegNear',
      path: capsulePath(0, 18, 10, 36),
      slot: ColorSlot.primary,
      pivot: const Offset(142, 94),
      z: 7,
    ),
    RigPart(
      id: 'earFar',
      parent: 'head',
      path: trianglePath(
        const Offset(0, 4),
        const Offset(-11, -23),
        const Offset(7, -10),
      ),
      slot: ColorSlot.secondary,
      pivot: const Offset(-7, -14),
      z: 8,
    ),
    RigPart(
      id: 'neck',
      path: capsulePath(0, 0, 24, 28),
      slot: ColorSlot.primary,
      pivot: const Offset(140, 68),
      z: 9,
    ),
    RigPart(
      id: 'head',
      parent: 'neck',
      path: ovalPath(0, 0, 22, 19),
      slot: ColorSlot.primary,
      pivot: const Offset(12, -18),
      z: 10,
    ),
    RigPart(
      id: 'earNear',
      parent: 'head',
      path: trianglePath(
        const Offset(0, 4),
        const Offset(6, -24),
        const Offset(14, -6),
      ),
      slot: ColorSlot.secondary,
      pivot: const Offset(6, -15),
      z: 11,
    ),
    RigPart(
      id: 'snout',
      parent: 'head',
      path: curvedPath(const Offset(0, -4), [
        (const Offset(14, -3), const Offset(22, 2), const Offset(24, 5)),
        (const Offset(16, 9), const Offset(6, 8), const Offset(0, 6)),
      ]),
      slot: ColorSlot.belly,
      pivot: const Offset(12, 4),
      z: 12,
    ),
    RigPart(
      id: 'eye',
      parent: 'head',
      path: ovalPath(0, 0, 2.8, 3.2),
      slot: ColorSlot.eye,
      pivot: const Offset(8, -3),
      z: 13,
    ),
  ];

  @override
  Pose poseAt(VizClip clip, double t) => switch (clip) {
    VizClip.breathe => _breathe(t),
    VizClip.walk => _walk(t),
    VizClip.run => _run(t),
  };

  Pose _breathe(double t) {
    final theta = 2 * math.pi * t;
    return {
      'body': PartPose(
        scaleX: 1 + 0.012 * math.sin(theta),
        scaleY: 1 + 0.035 * math.sin(theta),
      ),
      'chest': PartPose(scaleY: 1 + 0.05 * math.sin(theta)),
      'neck': PartPose(offset: Offset(0, 1.6 * math.sin(theta + 0.6))),
      'tail': PartPose(rotation: 0.09 * math.sin(theta)),
      'earNear': PartPose(rotation: 0.14 * math.max(0, math.sin(3 * theta))),
    };
  }

  Pose _walk(double t) {
    final theta = 2 * math.pi * t;
    final bounce = -2.0 * math.sin(2 * theta).abs();
    return {
      'body': PartPose(
        offset: Offset(0, bounce),
        scaleY: 1 + 0.01 * math.sin(theta),
      ),
      'neck': PartPose(
        offset: Offset(0, bounce),
        rotation: 0.06 * math.sin(theta + 0.4),
      ),
      'tail': PartPose(rotation: 0.18 * math.sin(theta + 0.9)),
      'hindLegNear': PartPose(rotation: 0.55 * math.sin(theta)),
      'foreLegNear': PartPose(rotation: 0.55 * math.sin(theta + math.pi)),
      'hindLegFar': PartPose(rotation: 0.55 * math.sin(theta + math.pi)),
      'foreLegFar': PartPose(rotation: 0.55 * math.sin(theta)),
    };
  }

  Pose _run(double t) {
    final theta = 2 * math.pi * t;
    final bound = -6.0 * math.sin(theta).abs();
    return {
      'body': PartPose(
        offset: Offset(0, bound),
        rotation: 0.10 * math.sin(theta),
      ),
      'neck': PartPose(
        offset: Offset(0, bound),
        rotation: 0.10 * math.sin(theta) + 0.08,
      ),
      'tail': PartPose(rotation: 0.30 * math.sin(theta + 0.6) - 0.18),
      'hindLegNear': PartPose(rotation: 0.95 * math.sin(theta)),
      'hindLegFar': PartPose(rotation: 0.95 * math.sin(theta + 0.35)),
      'foreLegNear': PartPose(rotation: 0.95 * math.sin(theta + math.pi)),
      'foreLegFar': PartPose(
        rotation: 0.95 * math.sin(theta + math.pi + 0.35),
      ),
    };
  }
}
