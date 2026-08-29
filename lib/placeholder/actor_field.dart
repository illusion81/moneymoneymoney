import 'package:flutter/material.dart';

import 'motion/squash_stretch.dart';
import 'motion/wander_motion.dart';
import '../sprites/sprite_cache.dart';
import '../sprites/sprite_painter.dart';
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
  void initState() {
    super.initState();
    _preloadSprites();
  }

  /// Sprites arrive asynchronously; repaint once they do so the boxes give way.
  Future<void> _preloadSprites() async {
    final paths = <String>[
      for (final actor in widget.actors)
        if (actor.sprite != null) actor.sprite!.assetPath,
    ];
    if (paths.isEmpty) return;
    await SpriteCache.instance.loadAll(paths);
    if (mounted) setState(() {});
  }

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
    final scale = squashStretch(phase, amplitude: isAnimal ? 0.10 : 0.05);
    final strip = actor.sprite;
    final image = strip == null
        ? null
        : SpriteCache.instance.peek(strip.assetPath);

    return Positioned.fill(
      child: CustomPaint(
        painter: image == null || strip == null
            ? PlaceholderBoxPainter(
                actor: actor,
                position: position,
                scale: scale,
              )
            : SpriteActorPainter(
                image: image,
                strip: strip,
                // Offset each actor so identical clips do not march in step.
                frame: strip.frameAt(seconds + index * 0.19),
                position: position,
                designSize: actor.size,
                scale: scale,
              ),
      ),
    );
  }
}