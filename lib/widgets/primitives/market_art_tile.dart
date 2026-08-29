import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/hexagon.dart';

/// One absolutely-positioned shape inside a [MarketArtTile] (design.md §6).
///
/// [left]/[top] place the shape's top-left corner and [width]/[height] give
/// its size — all fractions of the tile box, in the range 0..1.
class ArtShape {
  const ArtShape({
    required this.kind,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.rotationDeg = 0,
    this.opacity = 1,
    required this.color,
  });

  /// `'rect'` (filled rounded rect, radius ≈ 2) or `'circle'` (filled ellipse).
  final String kind;

  /// Left edge as a fraction of the tile width (0..1).
  final double left;

  /// Top edge as a fraction of the tile height (0..1).
  final double top;

  /// Shape width as a fraction of the tile width (0..1).
  final double width;

  /// Shape height as a fraction of the tile width (0..1).
  final double height;

  /// Clockwise rotation in degrees about the shape's centre.
  final double rotationDeg;

  /// Fill opacity, 0..1.
  final double opacity;

  /// Fill colour.
  final Color color;
}

/// One market art tile definition (design.md §6 "MarketArtTile"): a 150°
/// background gradient plus a list of shapes drawn over it.
class ArtTile {
  const ArtTile({required this.gradient, required this.shapes});

  /// The two colours of the 150° background linear gradient.
  final List<Color> gradient;

  /// Shapes drawn over the gradient, in paint order.
  final List<ArtShape> shapes;
}

/// A hex-clipped market art tile (design.md §6): [size] wide × `size × 1.15`
/// tall (≈46×53 at the authored size), clipped to the pointy-top hexagon
/// ([HexPointyClipper], design.md §5). The tile is filled with a 150° linear
/// gradient over [ArtTile.gradient], then each [ArtShape] is drawn at its
/// fractional position within the tile box, scaled by [size].
///
/// Purely declarative — no animation.
class MarketArtTile extends StatelessWidget {
  const MarketArtTile({super.key, required this.art, this.size = 46});

  /// The tile's art definition (gradient + shapes).
  final ArtTile art;

  /// Tile width in logical pixels; the height is `size × 1.15`.
  final double size;

  @override
  Widget build(BuildContext context) {
    final double height = size * 1.15;
    return ClipPath(
      clipper: const HexPointyClipper(),
      child: SizedBox(
        width: size,
        height: height,
        child: CustomPaint(painter: _MarketArtTilePainter(art)),
      ),
    );
  }
}

/// Paints one [ArtTile]: the 150° gradient fill plus each shape.
class _MarketArtTilePainter extends CustomPainter {
  _MarketArtTilePainter(this.art);

  final ArtTile art;

  @override
  void paint(Canvas canvas, Size size) {
    // 150° gradient (design.md §6): CSS gradient angles are measured
    // clockwise from 12 o'clock, so the gradient travels toward
    // (sin 150°, −cos 150°) — down-right. Same convention as honeycomb.dart.
    final double dx = math.sin(150 * math.pi / 180); // 0.5
    final double dy = -math.cos(150 * math.pi / 180); // ≈ 0.866
    final Paint fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-dx, -dy),
        end: Alignment(dx, dy),
        colors: art.gradient,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, fill);

    final double tileWidth = size.width;
    final double tileHeight = size.height;
    for (final ArtShape shape in art.shapes) {
      // left/top are fractions of the tile box; width/height scale with the
      // tile width (design.md §6: "positioned at left×size, top×height,
      // scaled by size").
      final double x = shape.left * tileWidth;
      final double y = shape.top * tileHeight;
      final double w = shape.width * tileWidth;
      final double h = shape.height * tileWidth;
      final Paint paint = Paint()
        ..color = shape.color.withValues(alpha: shape.opacity);

      // Rotate about the shape's centre, then draw centred on the origin.
      canvas.save();
      canvas.translate(x + w / 2, y + h / 2);
      canvas.rotate(shape.rotationDeg * math.pi / 180);
      final Rect rect = Rect.fromLTWH(-w / 2, -h / 2, w, h);
      switch (shape.kind) {
        case 'rect':
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(2)),
            paint,
          );
        case 'circle':
          canvas.drawOval(rect, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _MarketArtTilePainter oldDelegate) {
    return oldDelegate.art != art;
  }
}