import 'dart:math' as math;
import 'dart:ui';

import 'package:moneymoneymoney/viz/rig/color_slot.dart';
import 'package:moneymoneymoney/viz/rig/shapes.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_palette.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';

/// Minimal two-part rig used only by foundation tests.
class StubRig extends VizRig {
  @override
  String get id => 'stub';

  @override
  String get displayName => 'Stub';

  @override
  Size get canvasSize => const Size(100, 100);

  @override
  Set<VizClip> get supportedClips => const {VizClip.breathe};

  @override
  VizPalette get defaultPalette => const VizPalette(
    id: 'stub_default',
    label: 'Stub',
    colors: {
      ColorSlot.primary: Color(0xff112233),
      ColorSlot.secondary: Color(0xff445566),
      ColorSlot.belly: Color(0xff778899),
      ColorSlot.accent: Color(0xffaabbcc),
      ColorSlot.eye: Color(0xff000000),
      ColorSlot.outline: Color(0xff111111),
    },
  );

  @override
  List<RigPart> get parts => [
    RigPart(
      id: 'tip',
      parent: 'base',
      path: ovalPath(0, 0, 5, 5),
      slot: ColorSlot.accent,
      pivot: const Offset(20, 0),
      z: 1,
    ),
    RigPart(
      id: 'base',
      path: ovalPath(0, 0, 20, 20),
      slot: ColorSlot.primary,
      pivot: const Offset(50, 50),
      z: 0,
    ),
  ];

  @override
  Pose poseAt(VizClip clip, double t) {
    final theta = 2 * math.pi * t;
    return {'base': PartPose(rotation: 0.5 * math.sin(theta))};
  }
}
