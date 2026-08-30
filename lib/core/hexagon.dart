import 'package:flutter/material.dart';

/// The pointy-top hexagon path from design.md §5, for a box of w×h:
///
/// `moveTo(w/2, 0) → lineTo(w, h/4) → lineTo(w, 3h/4) → lineTo(w/2, h)
/// → lineTo(0, 3h/4) → lineTo(0, h/4) → close`.
Path _hexagonPath(Size size) {
  final double w = size.width;
  final double h = size.height;
  return Path()
    ..moveTo(w / 2, 0)
    ..lineTo(w, h / 4)
    ..lineTo(w, 3 * h / 4)
    ..lineTo(w / 2, h)
    ..lineTo(0, 3 * h / 4)
    ..lineTo(0, h / 4)
    ..close();
}

/// Clips a rect to the pointy-top hexagon (design.md §5).
///
/// Use with `ClipPath(clipper: const HexPointyClipper(), child: ...)`.
class HexPointyClipper extends CustomClipper<Path> {
  const HexPointyClipper();

  @override
  Path getClip(Size size) => _hexagonPath(size);

  @override
  bool shouldReclip(covariant HexPointyClipper oldClipper) => false;
}

/// Draws the pointy-top hexagon as an outline (design.md §5).
///
/// The sanctioned 2.5 px selection ring and hexagon strokes (design.md
/// §4.2 / §4.7) — this is artwork/selection, not a card border.
class HexagonBorder extends ShapeBorder {
  const HexagonBorder({
    this.strokeWidth = 2.5,
    this.color = const Color(0xFF33251A),
  });

  /// The stroke width of the outline.
  final double strokeWidth;

  /// The colour of the outline.
  final Color color;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(strokeWidth);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final Rect inner = rect.deflate(strokeWidth);
    return _hexagonPath(inner.size).shift(inner.topLeft);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _hexagonPath(rect.size).shift(rect.topLeft);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Path path = getOuterPath(rect, textDirection: textDirection);
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, paint);
  }

  @override
  HexagonBorder scale(double t) {
    return HexagonBorder(strokeWidth: strokeWidth * t, color: color);
  }
}
