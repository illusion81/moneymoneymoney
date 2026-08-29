import 'package:flutter/material.dart';

import '../../theme/hive_colors.dart';

/// The five drawn tab-bar icons (design.md §4.5). Never glyph fonts.
enum HiveTabIcon { hive, report, market, comb, mates }

/// Draws a [HiveTabIcon] in [color], sized by [size].
///
/// [size] is the reference box width; the icons are authored at their design.md
/// pixel sizes inside a 20-wide box, so the default [size] of 20 renders them
/// 1:1 and any other value scales them proportionally.
class HiveTabIconView extends StatelessWidget {
  const HiveTabIconView({
    super.key,
    required this.icon,
    required this.color,
    this.size = 20,
  });

  /// Which icon to draw.
  final HiveTabIcon icon;

  /// Colour the icon is drawn in (active `#E08C1B`, inactive 20% ink).
  final Color color;

  /// Reference box width; the icon scales with it (20 = authored size).
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HiveTabIconPainter(icon: icon, color: color, scale: size / 20),
      ),
    );
  }
}

/// The pointy-top hexagon path from design.md §5, drawn into [rect].
Path _hexPath(Rect rect) {
  final double w = rect.width;
  final double h = rect.height;
  return Path()
    ..moveTo(rect.left + w / 2, rect.top)
    ..lineTo(rect.left + w, rect.top + h / 4)
    ..lineTo(rect.left + w, rect.top + 3 * h / 4)
    ..lineTo(rect.left + w / 2, rect.top + h)
    ..lineTo(rect.left, rect.top + 3 * h / 4)
    ..lineTo(rect.left, rect.top + h / 4)
    ..close();
}

/// Natural (authored) bounding box of each icon, in design.md pixels.
class _IconSpec {
  const _IconSpec(this.width, this.height);

  final double width;
  final double height;
}

const Map<HiveTabIcon, _IconSpec> _specs = <HiveTabIcon, _IconSpec>{
  HiveTabIcon.hive: _IconSpec(16, 16),
  HiveTabIcon.report: _IconSpec(15.5, 15),
  HiveTabIcon.market: _IconSpec(14, 19),
  HiveTabIcon.comb: _IconSpec(15, 17),
  HiveTabIcon.mates: _IconSpec(16, 10),
};

class _HiveTabIconPainter extends CustomPainter {
  const _HiveTabIconPainter({
    required this.icon,
    required this.color,
    required this.scale,
  });

  final HiveTabIcon icon;
  final Color color;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final _IconSpec spec = _specs[icon]!;
    final double dx = (size.width - spec.width * scale) / 2;
    final double dy = (size.height - spec.height * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final Paint knockout = Paint()
      ..color = HiveColors.light.canvas
      ..style = PaintingStyle.fill;

    switch (icon) {
      case HiveTabIcon.hive:
        // Three 8×9 pointy hexes: 2 over 1, bottom hex pulled up 2 px.
        canvas.drawPath(_hexPath(const Rect.fromLTWH(0, 0, 8, 9)), fill);
        canvas.drawPath(_hexPath(const Rect.fromLTWH(8, 0, 8, 9)), fill);
        canvas.drawPath(_hexPath(const Rect.fromLTWH(4, 7, 8, 9)), fill);

      case HiveTabIcon.report:
        // Three 3.5-wide bars h 8/15/11, r2, gap 2.5, bottom-aligned.
        _drawBar(canvas, fill, 0, 8);
        _drawBar(canvas, fill, 6, 15);
        _drawBar(canvas, fill, 12, 11);

      case HiveTabIcon.market:
        // Jar: lid 8×3 r2 + body 14×12 (top r3, bottom r6), 4 px apart.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 0, 8, 3),
            const Radius.circular(2),
          ),
          fill,
        );
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            const Rect.fromLTWH(0, 7, 14, 12),
            topLeft: const Radius.circular(3),
            topRight: const Radius.circular(3),
            bottomLeft: const Radius.circular(6),
            bottomRight: const Radius.circular(6),
          ),
          fill,
        );

      case HiveTabIcon.comb:
        // 15×17 hex with a centred 8×9 canvas-coloured hex knockout.
        canvas.drawPath(_hexPath(const Rect.fromLTWH(0, 0, 15, 17)), fill);
        canvas.drawPath(_hexPath(const Rect.fromLTWH(3.5, 4, 8, 9)), knockout);

      case HiveTabIcon.mates:
        // Two Ø10 circles, centres 6 px apart (overlap −4); right one ringed
        // with a 2 px canvas stroke.
        final Paint ring = Paint()
          ..color = HiveColors.light.canvas
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(const Offset(5, 5), 5, fill);
        canvas.drawCircle(const Offset(11, 5), 5, fill);
        canvas.drawCircle(const Offset(11, 5), 5, ring);
    }

    canvas.restore();
  }

  void _drawBar(Canvas canvas, Paint paint, double x, double barHeight) {
    const double bottom = 15;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, bottom - barHeight, 3.5, barHeight),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _HiveTabIconPainter oldDelegate) {
    return oldDelegate.icon != icon ||
        oldDelegate.color != color ||
        oldDelegate.scale != scale;
  }
}
