import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/sprites/sprite_strip.dart';

Future<ui.Image> stubImage(int w, int h) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xffff0000),
  );
  return recorder.endRecording().toImage(w, h);
}

const strip = SpriteStrip(
  assetPath: 'a.png',
  frameCount: 4,
  frameSize: Size(32, 32),
  fps: 10,
);

void main() {
  test('a single-frame strip covers the whole image, whatever its size', () async {
    // Market icons are all different shapes, so a still sprite must not assume
    // a 32x32 frame.
    final image = await stubImage(163, 164);
    const single = SpriteStrip.single('coin.png');
    expect(single.isAnimated, isFalse);
    expect(
      single.sourceRect(0, image),
      const Rect.fromLTWH(0, 0, 163, 164),
    );
  });

  test('frames step across the strip', () async {
    final image = await stubImage(128, 32);
    expect(strip.sourceRect(0, image), const Rect.fromLTWH(0, 0, 32, 32));
    expect(strip.sourceRect(2, image), const Rect.fromLTWH(64, 0, 32, 32));
    expect(strip.sourceRect(3, image), const Rect.fromLTWH(96, 0, 32, 32));
  });

  test('an out-of-range frame is clamped into the strip', () async {
    final image = await stubImage(128, 32);
    expect(strip.sourceRect(9, image), const Rect.fromLTWH(96, 0, 32, 32));
    expect(strip.sourceRect(-3, image), const Rect.fromLTWH(0, 0, 32, 32));
  });

  test('a looping clip wraps back to the first frame', () {
    expect(strip.frameAt(0), 0);
    expect(strip.frameAt(0.25), 2);
    expect(strip.frameAt(0.4), 0);
    expect(strip.frameAt(0.5), 1);
  });

  test('a one-shot clip holds its last frame', () {
    expect(strip.frameAt(0.2, loop: false), 2);
    expect(strip.frameAt(5, loop: false), 3);
    expect(strip.frameAt(500, loop: false), 3);
  });

  test('negative time reads as the start, not a wrapped frame', () {
    expect(strip.frameAt(-1), 0);
    expect(strip.frameAt(-1, loop: false), 0);
  });

  test('a still strip never advances', () {
    const single = SpriteStrip.single('coin.png');
    expect(single.frameAt(0), 0);
    expect(single.frameAt(99), 0);
  });

  test('duration covers every frame once', () {
    expect(strip.duration, const Duration(milliseconds: 400));
  });
}
