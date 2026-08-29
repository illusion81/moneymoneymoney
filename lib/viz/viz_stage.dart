import 'package:flutter/material.dart';

import 'rig/rig_painter.dart';
import 'rig/viz_clip.dart';
import 'rig/viz_palette.dart';
import 'rig/viz_rig.dart';

/// Mounts a [VizRig] and loops one clip.
///
/// The subtree is wrapped in [IgnorePointer]: viz objects never take input.
class VizStage extends StatefulWidget {
  const VizStage({
    super.key,
    required this.rig,
    required this.clip,
    this.palette,
    this.speed = 1.0,
    this.showPivots = false,
  });

  final VizRig rig;
  final VizClip clip;

  /// Defaults to [VizRig.defaultPalette].
  final VizPalette? palette;

  /// Playback multiplier; 0.5 is half speed.
  final double speed;

  final bool showPivots;

  @override
  State<VizStage> createState() => _VizStageState();
}

class _VizStageState extends State<VizStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _durationFor(widget.clip, widget.speed),
  )..repeat();

  static Duration _durationFor(VizClip clip, double speed) {
    final safeSpeed = speed <= 0 ? 1.0 : speed;
    final micros = (clip.period.inMicroseconds / safeSpeed).round();
    return Duration(microseconds: micros.clamp(16000, 60000000));
  }

  @override
  void didUpdateWidget(VizStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip != widget.clip || oldWidget.speed != widget.speed) {
      _controller
        ..stop()
        ..duration = _durationFor(widget.clip, widget.speed)
        ..forward(from: 0)
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: RigPainter(
            rig: widget.rig,
            clip: widget.clip,
            phase: _controller.value,
            palette: widget.palette ?? widget.rig.defaultPalette,
            showPivots: widget.showPivots,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
