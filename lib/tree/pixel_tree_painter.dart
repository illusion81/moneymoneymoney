import 'dart:math';

import 'package:flutter/material.dart';

import 'tree_segment.dart';

/// Bark and leaf colours for one tree state.
class TreePalette {
  const TreePalette({
    required this.bark,
    required this.leaf,
    required this.leafAlt,
  });

  const TreePalette.healthy()
    : bark = const Color(0xff6b4a2f),
      leaf = const Color(0xff2f7d50),
      leafAlt = const Color(0xff3f9b64);

  const TreePalette.withered()
    : bark = const Color(0xff6a4f39),
      leaf = const Color(0xff8a6a4f),
      leafAlt = const Color(0xff9c8163);

  final Color bark;
  final Color leaf;
  final Color leafAlt;
}

/// Walks each visible segment and returns the set of grid cells it covers.
///
/// Deduping through a Set is what stops overlapping branches double-drawing,
/// which is what makes the result read as pixel art rather than stacked strokes.
Set<Point<int>> quantizeSegments(
  List<TreeSegment> segments, {
  required double progress,
  required double cell,
}) {
  final cells = <Point<int>>{};
  for (final segment in segments) {
    if (segment.growthAt > progress) {
      continue;
    }
    final dx = segment.b.dx - segment.a.dx;
    final dy = segment.b.dy - segment.a.dy;
    final length = sqrt(dx * dx + dy * dy);
    final steps = max(1, (length / (cell * 0.5)).ceil());
    final band = max(0, (segment.weight / cell / 2).round());

    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = segment.a.dx + dx * t;
      final y = segment.a.dy + dy * t;
      final cx = (x / cell).floor();
      final cy = (y / cell).floor();
      for (var ox = -band; ox <= band; ox++) {
        for (var oy = -band; oy <= band; oy++) {
          cells.add(Point<int>(cx + ox, cy + oy));
        }
      }
    }
  }
  return cells;
}

/// Draws the tree as snapped squares on a fixed grid.
class PixelTreePainter extends CustomPainter {
  PixelTreePainter({
    required this.segments,
    required this.progress,
    required this.palette,
    required this.designSize,
    this.cell = 4,
  });

  final List<TreeSegment> segments;

  /// Grow-in progress in [0, 1].
  final double progress;

  final TreePalette palette;

  /// The space the segments were generated in; letterboxed into the paint size.
  final Size designSize;

  /// Grid cell edge, in design units.
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final fit = min(
      size.width / designSize.width,
      size.height / designSize.height,
    );
    final dx = (size.width - designSize.width * fit) / 2;
    final dy = (size.height - designSize.height * fit) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(fit);

    // Bark first, then leaves on top, so foliage always reads in front.
    _paintLayer(canvas, leaves: false);
    _paintLayer(canvas, leaves: true);

    canvas.restore();
  }

  void _paintLayer(Canvas canvas, {required bool leaves}) {
    final subset = segments.where((s) => s.isLeaf == leaves).toList();
    final cells = quantizeSegments(
      subset,
      progress: progress,
      cell: cell,
    );
    final paint = Paint()..style = PaintingStyle.fill;
    for (final c in cells) {
      // Two leaf tones, chosen from position so the canopy is not flat.
      paint.color = leaves
          ? ((c.x + c.y).isEven ? palette.leaf : palette.leafAlt)
          : palette.bark;
      canvas.drawRect(
        Rect.fromLTWH(c.x * cell, c.y * cell, cell, cell),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PixelTreePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.segments != segments ||
      oldDelegate.palette != palette ||
      oldDelegate.cell != cell;
}