// Decorations, drawn rather than represented by an icon in a coloured circle.
//
// There is no decoration artwork in the project (assets/ has 25 animals and a
// set of finance icons, nothing garden-shaped), so these are painted: simple,
// readable shapes that actually look like the thing they are. A bench reads as
// a bench at 40px; Icons.weekend in a brown disc does not.

import 'package:flutter/material.dart';

class DecorationView extends StatelessWidget {
  const DecorationView({super.key, required this.itemId, this.size = 52});

  final String itemId;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size, size),
        painter: _DecorationPainter(itemId),
      );
}

class _DecorationPainter extends CustomPainter {
  _DecorationPainter(this.id);
  final String id;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final p = Paint()..style = PaintingStyle.fill;

    // shared ground shadow so everything sits on the tile
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.92), width: w * 0.62, height: h * 0.11),
      Paint()..color = Colors.black.withValues(alpha: 0.13),
    );

    switch (id) {
      case 'deco-garden-lantern':
        p.color = const Color(0xff5b4632);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.45, h * 0.42, w * 0.10, h * 0.48),
                const Radius.circular(2)),
            p);
        p.color = const Color(0xff3f3327);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.32, h * 0.18, w * 0.36, h * 0.28),
                const Radius.circular(4)),
            p);
        p.color = const Color(0xffffd977);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.37, h * 0.23, w * 0.26, h * 0.18), p);
        p.color = const Color(0xff3f3327);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.28, h * 0.12, w * 0.44, h * 0.08),
                const Radius.circular(3)),
            p);
        break;

      case 'deco-flower-bed':
        p.color = const Color(0xff6b4a35);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.14, h * 0.60, w * 0.72, h * 0.28),
                const Radius.circular(6)),
            p);
        const petals = [Color(0xffe8657f), Color(0xffefc75a), Color(0xffd97fa3)];
        for (var i = 0; i < 3; i++) {
          final cx = w * (0.28 + i * 0.22);
          p.color = const Color(0xff3f7a4a);
          canvas.drawRect(Rect.fromLTWH(cx - 1.2, h * 0.40, 2.4, h * 0.24), p);
          p.color = petals[i];
          for (var k = 0; k < 5; k++) {
            final a = k * 1.2566;
            canvas.drawCircle(
                Offset(cx + 4.2 * (a.isFinite ? (k.isEven ? 1 : -1) * 0.9 : 0),
                    h * 0.38 + (k % 2) * 3.0),
                w * 0.045,
                p);
          }
          p.color = const Color(0xfffff3cf);
          canvas.drawCircle(Offset(cx, h * 0.39), w * 0.03, p);
        }
        break;

      case 'deco-garden-bench':
        p.color = const Color(0xff8a6a4f);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.16, h * 0.52, w * 0.68, h * 0.10),
                const Radius.circular(3)),
            p); // seat
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(w * 0.16, h * 0.30, w * 0.68, h * 0.08),
                const Radius.circular(3)),
            p); // back rail
        p.color = const Color(0xff6b5240);
        canvas.drawRect(Rect.fromLTWH(w * 0.20, h * 0.30, w * 0.05, h * 0.55), p);
        canvas.drawRect(Rect.fromLTWH(w * 0.75, h * 0.30, w * 0.05, h * 0.55), p);
        break;

      case 'deco-bird-bath':
        p.color = const Color(0xffb9b2a6);
        canvas.drawRect(Rect.fromLTWH(w * 0.45, h * 0.48, w * 0.10, h * 0.38), p);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(w / 2, h * 0.86), width: w * 0.40, height: h * 0.10),
            p);
        p.color = const Color(0xffcfc8bc);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(w / 2, h * 0.44), width: w * 0.62, height: h * 0.22),
            p);
        p.color = const Color(0xff6fb7c9);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(w / 2, h * 0.43), width: w * 0.46, height: h * 0.13),
            p);
        break;

      case 'deco-beehive':
        p.color = const Color(0xffd9a520);
        for (var i = 0; i < 3; i++) {
          final width = w * (0.60 - i * 0.10);
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH((w - width) / 2, h * (0.62 - i * 0.17), width, h * 0.16),
                  Radius.circular(h * 0.08)),
              p);
        }
        p.color = const Color(0xff8a6a2f);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(w / 2, h * 0.68), width: w * 0.12, height: h * 0.09),
            p);
        break;

      case 'deco-garden-cabin':
        p.color = const Color(0xff9a7b58);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.22, h * 0.46, w * 0.56, h * 0.40), p);
        p.color = const Color(0xff2f7d50);
        final roof = Path()
          ..moveTo(w * 0.14, h * 0.48)
          ..lineTo(w * 0.50, h * 0.18)
          ..lineTo(w * 0.86, h * 0.48)
          ..close();
        canvas.drawPath(roof, p);
        p.color = const Color(0xff5b4632);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.43, h * 0.62, w * 0.14, h * 0.24), p);
        p.color = const Color(0xffbfe3ef);
        canvas.drawRect(
            Rect.fromLTWH(w * 0.27, h * 0.54, w * 0.12, h * 0.12), p);
        break;

      default:
        p.color = const Color(0xff8a6a4f);
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.28, p);
    }
  }

  @override
  bool shouldRepaint(_DecorationPainter old) => old.id != id;
}
