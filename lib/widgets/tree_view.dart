// The tree. This replaces a Material icon, which is what the forest was drawn
// with before — Icons.eco / park / forest swapped by level.
//
// It is a real recursive tree: the trunk and branches are generated from a seed
// so the same day always draws the same tree, and it grows with level rather
// than jumping between three fixed icons. Skins change the palette and the
// canopy shape; withering strips the leaves instead of substituting a
// different picture.

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum TreeHealth { healthy, withered, restored, pending }

class TreeSkin {
  const TreeSkin({
    required this.bark,
    required this.canopy,
    required this.canopyAlt,
    required this.blossom,
    this.canopyIsCluster = true,
    this.spread = 1.0,
  });

  final Color bark, canopy, canopyAlt;
  final Color? blossom;

  /// Cluster = rounded blobs of foliage. False = conifer triangles.
  final bool canopyIsCluster;

  /// How wide the branching fans out. Bonsai is squat and wide.
  final double spread;

  static const _defaultSkin = TreeSkin(
    bark: Color(0xff7a5c3a),
    canopy: Color(0xff2f7d50),
    canopyAlt: Color(0xff3f9a63),
    blossom: null,
  );

  static TreeSkin forId(String? id) => switch (id) {
        'tree-cherry-blossom' => const TreeSkin(
            bark: Color(0xff6b4a3a),
            canopy: Color(0xffe8a5c0),
            canopyAlt: Color(0xfff2c2d6),
            blossom: Color(0xffffffff),
          ),
        'tree-golden-ginkgo' => const TreeSkin(
            bark: Color(0xff7a6440),
            canopy: Color(0xffd9a520),
            canopyAlt: Color(0xffefc75a),
            blossom: Color(0xfffff3cf),
          ),
        'tree-crystal-pine' => const TreeSkin(
            bark: Color(0xff4c5a6b),
            canopy: Color(0xff5fa8bf),
            canopyAlt: Color(0xff9ad3e3),
            blossom: Color(0xffe8f7ff),
            canopyIsCluster: false,
          ),
        'tree-bonsai' => const TreeSkin(
            bark: Color(0xff6a4b32),
            canopy: Color(0xff2f6f4a),
            canopyAlt: Color(0xff4f9068),
            blossom: null,
            spread: 1.5,
          ),
        _ => _defaultSkin,
      };
}

class TreeView extends StatefulWidget {
  const TreeView({
    super.key,
    required this.level,
    this.health = TreeHealth.healthy,
    this.skinId,
    this.seed = 7,
    this.size = const Size(160, 160),
  });

  /// 0..6ish. Drives height, branch depth and canopy density.
  final int level;
  final TreeHealth health;
  final String? skinId;
  final int seed;
  final Size size;

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1,
  );
  late double _from = widget.level.toDouble();

  @override
  void didUpdateWidget(TreeView old) {
    super.didUpdateWidget(old);
    // Animate the growth when the level changes rather than snapping.
    if (old.level != widget.level) {
      _from = old.level.toDouble();
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = reduce ? 1.0 : Curves.easeOutBack.transform(_c.value.clamp(0, 1));
        final shown = _from + (widget.level - _from) * t;
        return CustomPaint(
          size: widget.size,
          painter: _TreePainter(
            level: shown,
            health: widget.health,
            skin: TreeSkin.forId(widget.skinId),
            seed: widget.seed,
          ),
        );
      },
    );
  }
}

/// Lighten (positive) or darken (negative) a colour, keeping its hue.
Color _shade(Color c, double amount) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
      .toColor();
}

class _TreePainter extends CustomPainter {
  _TreePainter({
    required this.level,
    required this.health,
    required this.skin,
    required this.seed,
  });

  final double level;
  final TreeHealth health;
  final TreeSkin skin;
  final int seed;

  bool get _bare => health == TreeHealth.withered;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final base = Offset(size.width / 2, size.height * 0.94);

    // Growth 0..1 across levels 0..6, never quite zero so there is always a sapling.
    final growth = (level.clamp(0, 6)) / 6.0;
    final trunkLen = size.height * (0.20 + 0.34 * growth);
    final trunkWidth = size.width * (0.035 + 0.030 * growth);
    final depth = 2 + (level.clamp(0, 6) / 1.6).round(); // 2..5 recursion levels

    // soft ground shadow
    canvas.drawOval(
      Rect.fromCenter(
          center: base.translate(0, 4),
          width: size.width * (0.34 + 0.30 * growth),
          height: size.height * 0.055),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );

    _branch(
      canvas,
      from: base,
      angle: -math.pi / 2,
      length: trunkLen,
      width: trunkWidth,
      depth: depth,
      rng: rng,
      size: size,
      growth: growth,
    );
  }

  void _branch(
    Canvas canvas, {
    required Offset from,
    required double angle,
    required double length,
    required double width,
    required int depth,
    required math.Random rng,
    required Size size,
    required double growth,
  }) {
    if (depth <= 0 || length < 3) {
      if (!_bare) _leaf(canvas, from, size, growth, rng);
      return;
    }

    final to = from + Offset(math.cos(angle) * length, math.sin(angle) * length);

    final barkColour = _bare
        ? Color.lerp(skin.bark, const Color(0xff8a6a4f), 0.6)!
        : skin.bark;

    // Draw each limb three times: a dark core, then a lit edge on the upper-left
    // and a shadow on the lower-right. Flat strokes are what made this read as a
    // 2D diagram; a light direction is most of what sells volume.
    final shadow = Paint()
      ..color = _shade(barkColour, -0.28)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from.translate(width * 0.18, width * 0.18),
        to.translate(width * 0.18, width * 0.18), shadow);

    final core = Paint()
      ..color = barkColour
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, core);

    final lit = Paint()
      ..color = _shade(barkColour, 0.26)
      ..strokeWidth = width * 0.42
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from.translate(-width * 0.20, -width * 0.16),
        to.translate(-width * 0.20, -width * 0.16), lit);

    // Two children, occasionally three on a well-grown tree.
    final children = (depth > 3 && rng.nextDouble() < 0.35) ? 3 : 2;
    for (var i = 0; i < children; i++) {
      final side = (i.isEven ? -1 : 1) * (i == 2 ? 0.15 : 1.0);
      final spreadAngle =
          (0.38 + rng.nextDouble() * 0.30) * skin.spread * side;
      _branch(
        canvas,
        from: to,
        angle: angle + spreadAngle,
        length: length * (0.66 + rng.nextDouble() * 0.12),
        width: width * 0.66,
        depth: depth - 1,
        rng: rng,
        size: size,
        growth: growth,
      );
    }
  }

  void _leaf(Canvas canvas, Offset at, Size size, double growth, math.Random rng) {
    final r = size.width * (0.055 + 0.045 * growth);
    final paint = Paint()
      ..color = (rng.nextBool() ? skin.canopy : skin.canopyAlt)
          .withValues(alpha: health == TreeHealth.restored ? 0.72 : 0.95);

    if (skin.canopyIsCluster) {
      // shaded underside
      canvas.drawCircle(at.translate(r * 0.16, r * 0.20),
          r, Paint()..color = _shade(paint.color, -0.22));
      canvas.drawCircle(at, r, paint);
      // sun catching the top-left
      canvas.drawCircle(at.translate(-r * 0.26, -r * 0.28), r * 0.52,
          Paint()..color = _shade(paint.color, 0.30));
    } else {
      // conifer: small triangle instead of a blob
      final path = Path()
        ..moveTo(at.dx, at.dy - r * 1.4)
        ..lineTo(at.dx - r, at.dy + r * 0.6)
        ..lineTo(at.dx + r, at.dy + r * 0.6)
        ..close();
      canvas.drawPath(path, paint);
    }

    // blossom flecks only once the tree is established
    if (skin.blossom != null && growth > 0.45 && rng.nextDouble() < 0.5) {
      canvas.drawCircle(
        at.translate((rng.nextDouble() - 0.5) * r, (rng.nextDouble() - 0.5) * r),
        r * 0.28,
        Paint()..color = skin.blossom!,
      );
    }
  }

  @override
  bool shouldRepaint(_TreePainter old) =>
      old.level != level || old.health != health || old.skin != skin;
}
