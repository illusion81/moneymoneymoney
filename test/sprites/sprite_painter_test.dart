import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/placeholder/motion/squash_stretch.dart';
import 'package:moneymoneymoney/sprites/sprite_painter.dart';

Future<ui.Image> stubImage(int w, int h) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xffff0000),
  );
  return recorder.endRecording().toImage(w, h);
}

void main() {
  test('sprite paint never resamples pixel art', () {
    final paint = spritePaint();
    expect(paint.filterQuality, FilterQuality.none);
    expect(paint.isAntiAlias, isFalse);
  });

  test('an unscaled sprite fills its design box', () {
    final rect = spriteDestRect(
      position: const Offset(10, 20),
      designSize: const Size(64, 64),
      scale: const ScalePair(1, 1),
    );
    expect(rect, const Rect.fromLTWH(10, 20, 64, 64));
  });

  test('a squashed sprite keeps its feet on the ground', () {
    const position = Offset(10, 20);
    const designSize = Size(64, 64);
    // Squash: half as tall, twice as wide.
    final rect = spriteDestRect(
      position: position,
      designSize: designSize,
      scale: const ScalePair(2, 0.5),
    );
    expect(rect.width, 128);
    expect(rect.height, 32);
    // Bottom edge is pinned, horizontal centre is preserved.
    expect(rect.bottom, position.dy + designSize.height);
    expect(rect.center.dx, position.dx + designSize.width / 2);
  });

  test('a stretched sprite grows upward from the same feet', () {
    final rect = spriteDestRect(
      position: const Offset(0, 0),
      designSize: const Size(50, 50),
      scale: const ScalePair(0.5, 2),
    );
    expect(rect.bottom, 50);
    expect(rect.top, -50);
    expect(rect.width, 25);
  });

  testWidgets('draws the whole source image into the destination rect', (
    tester,
  ) async {
    final image = await stubImage(32, 32);
    await tester.pumpWidget(
      CustomPaint(
        painter: SpriteActorPainter(
          image: image,
          position: const Offset(4, 6),
          designSize: const Size(64, 64),
          scale: const ScalePair(1, 1),
        ),
        size: const Size(200, 200),
      ),
    );
    expect(
      find.byType(CustomPaint).first,
      paints
        ..drawImageRect(
          image: image,
          source: const Rect.fromLTWH(0, 0, 32, 32),
          destination: const Rect.fromLTWH(4, 6, 64, 64),
        ),
    );
  });

  testWidgets('repaints when the pose changes but not when it is identical', (
    tester,
  ) async {
    final image = await stubImage(32, 32);
    SpriteActorPainter at(Offset position) => SpriteActorPainter(
      image: image,
      position: position,
      designSize: const Size(64, 64),
      scale: const ScalePair(1, 1),
    );
    expect(
      at(const Offset(0, 0)).shouldRepaint(at(const Offset(0, 0))),
      isFalse,
    );
    expect(at(const Offset(1, 0)).shouldRepaint(at(const Offset(0, 0))), isTrue);
  });
}
