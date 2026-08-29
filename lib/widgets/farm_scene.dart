// The forest board.
//
// Replaces a 112px Material icon on a flat coloured rectangle. This is the
// thing people look at for most of the demo, so it is an actual scene: sky
// gradient, sun, layered hills, a ground plane, the painted tree, and the
// animals the player has earned wandering in front of it.
//
// Growth is driven by `growth` (0..1), which the caller computes from BOTH the
// check-in streak and the plan adherence — see HomeScreen. The tree is the
// product's core claim ("your money habits build this"), so it must not respond
// to streak alone.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'tree_view.dart';

class FarmScene extends StatelessWidget {
  const FarmScene({
    super.key,
    required this.growth,
    required this.health,
    this.skinId,
    this.skyColor,
    this.groundColor,
    this.animals = const [],
    this.seed = 7,
    this.height = 260,
  });

  /// 0..1 — how established the farm is. Drives tree size, hill richness and
  /// how many animals fit comfortably.
  final double growth;
  final TreeHealth health;
  final String? skinId;
  final Color? skyColor;
  final Color? groundColor;

  /// Asset stems of the animals the player owns, e.g. ['cow', 'cat'].
  /// Bought in the shop — nothing here is granted for free.
  final List<String> animals;
  final int seed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final sky = skyColor ?? const Color(0xffdff0f7);
    final ground = groundColor ?? const Color(0xffdcefd9);
    final wilted = health == TreeHealth.withered;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final h = box.maxHeight;
            final horizon = h * 0.62;
            final rng = math.Random(seed);
            final shown = animals.length;

            return Stack(
              children: [
                // sky
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: wilted
                            ? [const Color(0xffd8d2c6), const Color(0xffe8e3d8)]
                            : [sky, Color.lerp(sky, Colors.white, 0.55)!],
                      ),
                    ),
                  ),
                ),

                // sun, dimmed when things are going badly
                Positioned(
                  right: w * 0.12,
                  top: h * 0.10,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (wilted
                              ? const Color(0xffbfb49c)
                              : const Color(0xffffd977))
                          .withValues(alpha: 0.9),
                    ),
                  ),
                ),

                // layered hills
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HillPainter(
                      horizon: horizon,
                      colour: Color.lerp(ground, Colors.black, 0.10)!,
                      wilted: wilted,
                    ),
                  ),
                ),

                // ground plane
                Positioned(
                  left: 0,
                  right: 0,
                  top: horizon,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: wilted
                            ? [const Color(0xffcfc4ae), const Color(0xffbfb49c)]
                            : [ground, Color.lerp(ground, Colors.black, 0.08)!],
                      ),
                    ),
                  ),
                ),

                // the tree, standing on the horizon
                Positioned(
                  left: w * 0.5 - (h * 0.46) / 2,
                  top: horizon - h * 0.46 + 6,
                  child: TreeView(
                    level: (growth * 6).round(),
                    health: health,
                    skinId: skinId,
                    seed: seed,
                    size: Size(h * 0.46, h * 0.46),
                  ),
                ),

                // animals along the ground, spread either side of the tree
                for (var i = 0; i < shown; i++)
                  _animal(i, w, h, horizon, rng, wilted),

                if (shown == 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 10,
                    child: Text(
                      'Earn coins, then buy your first animal in the shop',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.black.withValues(alpha: 0.45)),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _animal(int i, double w, double h, double horizon, math.Random rng,
      bool wilted) {
    // Alternate sides so the farm fills outward from the tree rather than
    // stacking on one edge.
    final side = i.isEven ? -1 : 1;
    final rank = (i ~/ 2) + 1;
    final x = w * 0.5 + side * (w * 0.10 * rank) - 20;
    final depth = (i % 3) / 3.0; // pseudo-rows so they do not all line up
    final y = horizon + (h - horizon) * (0.12 + depth * 0.5);
    final scale = 0.85 + depth * 0.35;

    return Positioned(
      left: x.clamp(4.0, w - 44),
      top: y.clamp(horizon, h - 40),
      child: Opacity(
        opacity: wilted ? 0.55 : 1,
        child: Image.asset(
          'assets/animals/${animals[i]}.png',
          width: 38 * scale,
          height: 38 * scale,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _HillPainter extends CustomPainter {
  _HillPainter({
    required this.horizon,
    required this.colour,
    required this.wilted,
  });

  final double horizon;
  final Color colour;
  final bool wilted;

  @override
  void paint(Canvas canvas, Size size) {
    final base = wilted ? const Color(0xffc3b79f) : colour;
    for (var layer = 0; layer < 2; layer++) {
      final lift = 26.0 - layer * 12;
      final paint = Paint()
        ..color = base.withValues(alpha: layer == 0 ? 0.35 : 0.55);
      final path = Path()..moveTo(0, horizon);
      final bumps = 3 + layer;
      for (var i = 0; i <= bumps; i++) {
        final x1 = size.width * (i + 0.5) / bumps;
        final x2 = size.width * (i + 1) / bumps;
        path.quadraticBezierTo(x1, horizon - lift, x2, horizon);
      }
      path
        ..lineTo(size.width, horizon + 4)
        ..lineTo(0, horizon + 4)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_HillPainter old) =>
      old.horizon != horizon || old.colour != colour || old.wilted != wilted;
}
