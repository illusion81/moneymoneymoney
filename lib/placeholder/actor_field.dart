import 'package:flutter/material.dart';

import 'motion/squash_stretch.dart';
import 'motion/wander_motion.dart';
import 'placeholder_actor.dart';
import 'placeholder_box_painter.dart';

/// Hosts several placeholder actors on one ticker.
///
/// Draw-only: the subtree is wrapped in [IgnorePointer].
class ActorField extends StatefulWidget {
  const ActorField({super.key, required this.actors, this.speed = 1.0});

  final List<PlaceholderActor> actors;

  /// Playback multiplier for both wander and pulse.
  final double speed;

  @override
  State<ActorField> createState() => _ActorFieldState();
}

class _ActorFieldState extends State<ActorField>
    with SingleTickerProviderStateMixin {
  /// One long cycle; wander reads elapsed seconds, not loop phase.
  static const Duration _cycle = Duration(seconds: 60);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycle,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounds = Size(constraints.maxWidth, constraints.maxHeight);
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final seconds =
                  _controller.value * _cycle.inSeconds * widget.speed;
              return Stack(
                children: [
                  for (var i = 0; i < widget.actors.length; i++)
                    _actorLayer(widget.actors[i], i, seconds, bounds),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _actorLayer(
    PlaceholderActor actor,
    int index,
    double seconds,
    Size bounds,
  ) {
    final isAnimal = actor.kind == ActorKind.animal;
    final motion = WanderMotion(
      seed: actor.id.hashCode ^ (index * 7919),
      bounds: bounds,
      actorSize: actor.size,
    );
    final position = isAnimal
        ? motion.positionAt(seconds)
        : Offset(
            (bounds.width - actor.size.width) / 2,
            (bounds.height - actor.size.height) / 2,
          );
    // Stagger phases so a row of actors does not pulse in lockstep.
    final phase = (seconds / 2.2 + index * 0.37) % 1.0;
    return Positioned.fill(
      child: CustomPaint(
        painter: PlaceholderBoxPainter(
          actor: actor,
          position: position,
          scale: squashStretch(phase, amplitude: isAnimal ? 0.10 : 0.05),
        ),
      ),
    );
  }
}