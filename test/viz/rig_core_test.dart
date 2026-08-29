import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/rig/color_slot.dart';
import 'package:moneymoneymoney/viz/rig/shapes.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_palette.dart';

void main() {
  test('ovalPath is centred on its local coordinates', () {
    expect(ovalPath(0, 0, 10, 5).getBounds(), const Rect.fromLTRB(-10, -5, 10, 5));
  });

  test('capsulePath spans the requested width and height', () {
    final bounds = capsulePath(0, 10, 8, 40).getBounds();
    expect(bounds.width, closeTo(8, 0.001));
    expect(bounds.height, closeTo(40, 0.001));
    expect(bounds.center.dy, closeTo(10, 0.001));
  });

  test('trianglePath closes over its three points', () {
    final path = trianglePath(Offset.zero, const Offset(10, 0), const Offset(0, 10));
    expect(path.getBounds(), const Rect.fromLTRB(0, 0, 10, 10));
  });

  test('curvedPath starts at the given point', () {
    final path = curvedPath(const Offset(0, 0), [
      (const Offset(5, -10), const Offset(15, -10), const Offset(20, 0)),
    ]);
    expect(path.getBounds().left, closeTo(0, 0.001));
    expect(path.getBounds().right, closeTo(20, 0.001));
  });

  test('every clip has a positive loop period and a label', () {
    for (final clip in VizClip.values) {
      expect(clip.period.inMilliseconds, greaterThan(0));
      expect(clip.label, isNotEmpty);
    }
  });

  test('palette resolves every slot it defines', () {
    const palette = VizPalette(
      id: 'p',
      label: 'P',
      colors: {ColorSlot.primary: Color(0xff123456)},
    );
    expect(palette.of(ColorSlot.primary), const Color(0xff123456));
  });

  test('palette falls back to opaque black for an undefined slot', () {
    const palette = VizPalette(id: 'p', label: 'P', colors: {});
    expect(palette.of(ColorSlot.eye), const Color(0xff000000));
  });
}
