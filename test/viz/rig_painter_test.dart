import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/rig/rig_painter.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';

import 'support/recording_canvas.dart';
import 'support/stub_rig.dart';

void main() {
  final rig = StubRig();

  RecordingCanvas paintAt(double phase) {
    final canvas = RecordingCanvas();
    RigPainter(
      rig: rig,
      clip: VizClip.breathe,
      phase: phase,
      palette: rig.defaultPalette,
    ).paint(canvas, const Size(200, 200));
    return canvas;
  }

  test('paints one path per part', () {
    expect(paintAt(0).paths.length, 2);
  });

  test('paints parts in ascending z order using their slot colours', () {
    final canvas = paintAt(0);
    // Compare packed ARGB: Color == also compares colour space and float
    // components, which round-trip unequal through Paint.
    expect(canvas.paints[0].color.toARGB32(), 0xff112233); // base, primary
    expect(canvas.paints[1].color.toARGB32(), 0xffaabbcc); // tip, accent
  });

  test('a child part inherits its parent transform', () {
    // At phase 0.25 the base is rotated by 0.5 rad, which must move the tip.
    final still = paintAt(0.0).transforms[1];
    final rotated = paintAt(0.25).transforms[1];
    expect(rotated[12], isNot(closeTo(still[12], 0.01)));
  });

  test('shouldRepaint is true when the phase advances', () {
    final a = RigPainter(
      rig: rig,
      clip: VizClip.breathe,
      phase: 0.0,
      palette: rig.defaultPalette,
    );
    final b = RigPainter(
      rig: rig,
      clip: VizClip.breathe,
      phase: 0.5,
      palette: rig.defaultPalette,
    );
    expect(b.shouldRepaint(a), isTrue);
    expect(b.shouldRepaint(b), isFalse);
  });

  test('letterboxes a non-square paint size, preserving aspect and centring', () {
    final canvas = RecordingCanvas();
    RigPainter(
      rig: rig,
      clip: VizClip.breathe,
      phase: 0,
      palette: rig.defaultPalette,
    ).paint(canvas, const Size(300, 200));
    // fit = min(300/100, 200/100) = 2; dx = (300 - 200) / 2 = 50; dy = 0.
    // base sits at pivot (50, 50), so its world translation is
    // (50 + 2 * 50, 0 + 2 * 50) = (150, 100).
    final base = canvas.transforms[0];
    expect(base[12], closeTo(150, 0.001));
    expect(base[13], closeTo(100, 0.001));
  });
}
