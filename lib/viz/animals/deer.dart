import 'dart:math' as math;
import 'dart:ui';

import '../rig/color_slot.dart';
import '../rig/shapes.dart';
import '../rig/viz_clip.dart';
import '../rig/viz_palette.dart';
import '../rig/viz_rig.dart';

const VizPalette deerDefaultPalette = VizPalette(
  id: 'deer_default',
  label: 'Deer',
  colors: {
    ColorSlot.primary: Color(0xffb8814f),
    ColorSlot.secondary: Color(0xff8f5f38),
    ColorSlot.belly: Color(0xfff1e2cd),
    ColorSlot.accent: Color(0xffd9b98a),
    ColorSlot.eye: Color(0xff2a2320),
    ColorSlot.outline: Color(0xff3a2d22),
  },
);

/// A two-spike antler branch. [dir] is 1 for the near antler, -1 for the far.
Path _antler(double dir) => Path()
  ..moveTo(0, 0)
  ..cubicTo(2 * dir, -12, 6 * dir, -20, 4 * dir, -30)
  ..cubicTo(10 * dir, -22, 9 * dir, -12, 3 * dir, 0)
  ..close()
  ..addPath(
    trianglePath(
      const Offset(0, -16),
      Offset(12 * dir, -26),
      Offset(6 * dir, -14),
    ),
    Offset.zero,
  );

/// Side-on deer facing right. Design space 200x160, ground line at y = 148.
class Deer extends VizRig {
  @override
  String get id => 'deer';

  @override
  String get displayName => 'Deer';

  @override
  Size get canvasSize => const Size(200, 160);

  @override
  VizPalette get defaultPalette => deerDefaultPalette;

  @override
  Set<VizClip> get supportedClips => VizClip.values.toSet();

  @override
  List<RigPart> get parts => [
    RigPart(
      id: 'antlerFar',
      parent: 'head',
      path: _antler(-1),
      slot: ColorSlot.secondary,
      pivot: const Offset(-4, -11),
      z: 0,
    ),
    RigPart(
      id: 'hindLegFar',
      path: capsulePath(0, 24, 8, 50),
      slot: ColorSlot.secondary,
      pivot: const Offset(74, 100),
      z: 1,
    ),
    RigPart(
      id: 'foreLegFar',
      path: capsulePath(0, 24, 8, 50),
      slot: ColorSlot.secondary,
      pivot: const Offset(128, 100),
      z: 2,
    ),
    RigPart(
      id: 'tail',
      path: ovalPath(0, 6, 7, 10),
      slot: ColorSlot.belly,
      pivot: const Offset(64, 80),
      z: 3,
    ),
    RigPart(
      id: 'body',
      path: ovalPath(0, 0, 40, 24),
      slot: ColorSlot.primary,
      pivot: const Offset(100, 84),
      z: 4,
    ),
    RigPart(
      id: 'belly',
      parent: 'body',
      path: ovalPath(0, 0, 28, 10),
      slot: ColorSlot.belly,
      pivot: const Offset(0, 12),
      z: 5,
    ),
    RigPart(
      id: 'hindLegNear',
      path: capsulePath(0, 24, 8, 50),
      slot: ColorSlot.primary,
      pivot: const Offset(82, 102),
      z: 6,
    ),
    RigPart(
      id: 'foreLegNear',
      path: capsulePath(0, 24, 8, 50),
      slot: ColorSlot.primary,
      pivot: const Offset(136, 102),
      z: 7,
    ),
    RigPart(
      id: 'neck',
      path: capsulePath(6, -16, 20, 44),
      slot: ColorSlot.primary,
      pivot: const Offset(134, 72),
      z: 8,
    ),
    RigPart(
      id: 'ear',
      parent: 'head',
      path: trianglePath(
        const Offset(0, 0),
        const Offset(-15, -9),
        const Offset(-4, 8),
      ),
      slot: ColorSlot.secondary,
      pivot: const Offset(-8, -5),
      z: 9,
    ),
    RigPart(
      id: 'head',
      parent: 'neck',
      path: ovalPath(0, 0, 17, 13),
      slot: ColorSlot.primary,
      pivot: const Offset(14, -38),
      z: 10,
    ),
    RigPart(
      id: 'antlerNear',
      parent: 'head',
      path: _antler(1),
      slot: ColorSlot.secondary,
      pivot: const Offset(4, -12),
      z: 11,
    ),
    RigPart(
      id: 'muzzle',
      parent: 'head',
      path: ovalPath(0, 0, 9, 7),
      slot: ColorSlot.belly,
      pivot: const Offset(15, 4),
      z: 12,
    ),
    RigPart(
      id: 'eye',
      parent: 'head',
      path: ovalPath(0, 0, 2.6, 2.8),
      slot: ColorSlot.eye,
      pivot: const Offset(6, -2),
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
        scaleX: 1 + 0.010 * math.sin(theta),
        scaleY: 1 + 0.030 * math.sin(theta),
      ),
      'belly': PartPose(scaleY: 1 + 0.045 * math.sin(theta)),
      'neck': PartPose(rotation: 0.035 * math.sin(theta + 0.5)),
      'ear': PartPose(rotation: 0.20 * math.max(0, math.sin(4 * theta))),
      'tail': PartPose(rotation: 0.16 * math.sin(2 * theta)),
    };
  }

  Pose _walk(double t) {
    final theta = 2 * math.pi * t;
    final bounce = -1.8 * math.sin(2 * theta).abs();
    return {
      'body': PartPose(offset: Offset(0, bounce)),
      'neck': PartPose(
        offset: Offset(0, bounce),
        rotation: 0.05 * math.sin(theta + 0.3),
      ),
      'tail': PartPose(rotation: 0.14 * math.sin(2 * theta)),
      'hindLegNear': PartPose(rotation: 0.45 * math.sin(theta)),
      'foreLegNear': PartPose(rotation: 0.45 * math.sin(theta + math.pi)),
      'hindLegFar': PartPose(rotation: 0.45 * math.sin(theta + math.pi)),
      'foreLegFar': PartPose(rotation: 0.45 * math.sin(theta)),
    };
  }

  Pose _run(double t) {
    final theta = 2 * math.pi * t;
    final bound = -9.0 * math.sin(theta).abs();
    return {
      'body': PartPose(
        offset: Offset(0, bound),
        rotation: 0.12 * math.sin(theta),
      ),
      'neck': PartPose(
        offset: Offset(0, bound),
        rotation: 0.14 * math.sin(theta) + 0.06,
      ),
      'tail': PartPose(rotation: 0.28 * math.sin(theta) - 0.20),
      'foreLegNear': PartPose(rotation: 0.90 * math.sin(theta)),
      'foreLegFar': PartPose(rotation: 0.82 * math.sin(theta)),
      'hindLegNear': PartPose(rotation: 0.90 * math.sin(theta + math.pi)),
      'hindLegFar': PartPose(rotation: 0.82 * math.sin(theta + math.pi)),
    };
  }
}
