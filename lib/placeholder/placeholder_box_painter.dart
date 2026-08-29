import 'package:flutter/material.dart';

import 'motion/squash_stretch.dart';
import 'placeholder_actor.dart';

/// Draws one placeholder actor: a rounded rect plus its label.
class PlaceholderBoxPainter extends CustomPainter {
  PlaceholderBoxPainter({
    required this.actor,
    required this.position,
    required this.scale,
  });

  final PlaceholderActor actor;

  /// Top-left of the unscaled box.
  final Offset position;

  final ScalePair scale;

  @override
  void paint(Canvas canvas, Size size) {
    final w = actor.size.width * scale.x;
    final h = actor.size.height * scale.y;
    // Scale about the bottom centre so a squash reads as weight on the ground.
    final left = position.dx + (actor.size.width - w) / 2;
    final top = position.dy + (actor.size.height - h);
    final rect = Rect.fromLTWH(left, top, w, h);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      Paint()..color = actor.color,
    );

    final luminance = actor.color.computeLuminance();
    final painter = TextPainter(
      text: TextSpan(
        text: actor.label,
        style: TextStyle(
          color: luminance > 0.5 ? const Color(0xff20201e) : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);

    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(PlaceholderBoxPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.scale.x != scale.x ||
      oldDelegate.scale.y != scale.y ||
      oldDelegate.actor != actor;
}