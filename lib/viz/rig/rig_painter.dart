import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'viz_clip.dart';
import 'viz_palette.dart';
import 'viz_rig.dart';

/// Draws a [VizRig] at a single animation phase.
class RigPainter extends CustomPainter {
  RigPainter({
    required this.rig,
    required this.clip,
    required this.phase,
    required this.palette,
    this.showPivots = false,
  });

  final VizRig rig;
  final VizClip clip;

  /// Loop phase in [0, 1).
  final double phase;

  final VizPalette palette;

  /// Debug aid for the workbench: marks each part's pivot.
  final bool showPivots;

  @override
  void paint(Canvas canvas, Size size) {
    final pose = rig.poseAt(clip, phase);
    final byId = {for (final part in rig.parts) part.id: part};
    final world = <String, Matrix4>{};

    final fit = math.min(
      size.width / rig.canvasSize.width,
      size.height / rig.canvasSize.height,
    );
    final dx = (size.width - rig.canvasSize.width * fit) / 2;
    final dy = (size.height - rig.canvasSize.height * fit) / 2;
    final root = _translation(dx, dy).multiplied(_scale(fit, fit));

    final ordered = [...rig.parts]..sort((a, b) => a.z.compareTo(b.z));
    for (final part in ordered) {
      final matrix = root.multiplied(_worldOf(part.id, byId, pose, world));
      canvas.save();
      canvas.transform(matrix.storage);
      canvas.drawPath(
        part.path,
        Paint()
          ..color = palette.of(part.slot)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true,
      );
      if (showPivots) {
        canvas.drawCircle(
          Offset.zero,
          1.6,
          Paint()..color = const Color(0xffff2d55),
        );
      }
      canvas.restore();
    }
  }

  Matrix4 _worldOf(
    String id,
    Map<String, RigPart> byId,
    Pose pose,
    Map<String, Matrix4> memo,
  ) {
    final cached = memo[id];
    if (cached != null) {
      return cached;
    }
    final part = byId[id]!;
    final p = pose[id] ?? const PartPose();
    final local = _translation(
      part.pivot.dx + p.offset.dx,
      part.pivot.dy + p.offset.dy,
    ).multiplied(Matrix4.rotationZ(p.rotation)).multiplied(
      _scale(p.scaleX, p.scaleY),
    );
    final parentId = part.parent;
    final result = parentId == null
        ? local
        : _worldOf(parentId, byId, pose, memo).multiplied(local);
    memo[id] = result;
    return result;
  }

  static Matrix4 _translation(double x, double y) => Matrix4.identity()
    ..setEntry(0, 3, x)
    ..setEntry(1, 3, y);

  static Matrix4 _scale(double x, double y) => Matrix4.identity()
    ..setEntry(0, 0, x)
    ..setEntry(1, 1, y);

  @override
  bool shouldRepaint(RigPainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.clip != clip ||
      oldDelegate.rig != rig ||
      oldDelegate.palette != palette ||
      oldDelegate.showPivots != showPivots;
}
