import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/animals/hummingbird.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';

void main() {
  final bird = Hummingbird();

  test('declares a stable identity and all three clips', () {
    expect(bird.id, 'hummingbird');
    expect(bird.displayName, 'Hummingbird');
    expect(bird.supportedClips, VizClip.values.toSet());
  });

  test('every part has a unique z', () {
    final zs = bird.parts.map((p) => p.z).toList();
    expect(zs.toSet().length, zs.length);
  });

  test('every parent reference resolves to a real part', () {
    final ids = bird.parts.map((p) => p.id).toSet();
    for (final part in bird.parts) {
      if (part.parent != null) {
        expect(ids, contains(part.parent), reason: '${part.id} parent');
      }
    }
  });

  test('both wings hang off the body', () {
    final byId = {for (final p in bird.parts) p.id: p};
    expect(byId['wingNear']!.parent, 'body');
    expect(byId['wingFar']!.parent, 'body');
  });

  test('every clip loops: pose at t=0 matches pose at t->1', () {
    for (final clip in bird.supportedClips) {
      final start = bird.poseAt(clip, 0);
      final end = bird.poseAt(clip, 0.9999);
      for (final id in start.keys) {
        expect(end[id]!.rotation, closeTo(start[id]!.rotation, 0.02),
            reason: '$clip / $id rotation');
        expect(end[id]!.offset.dx, closeTo(start[id]!.offset.dx, 0.05),
            reason: '$clip / $id offset.dx');
        expect(end[id]!.offset.dy, closeTo(start[id]!.offset.dy, 0.05),
            reason: '$clip / $id offset.dy');
        expect(end[id]!.scaleX, closeTo(start[id]!.scaleX, 0.02),
            reason: '$clip / $id scaleX');
        expect(end[id]!.scaleY, closeTo(start[id]!.scaleY, 0.02),
            reason: '$clip / $id scaleY');
      }
    }
  });

  test('wings squash horizontally during the beat', () {
    // At t = 0.025 the 10-beat wing is at the top of its stroke (wing = pi/2),
    // where the squash is deepest. At t = 0.05 it is broadside and scaleX is
    // exactly 1.0.
    final pose = bird.poseAt(VizClip.walk, 0.025);
    expect(pose['wingNear']!.scaleX, lessThan(1.0));
    expect(pose['wingNear']!.scaleX, greaterThan(0.0));
  });

  test('the dart beats the wings harder than the hover', () {
    var hoverPeak = 0.0;
    var dartPeak = 0.0;
    for (var i = 0; i < 200; i++) {
      final t = i / 200;
      hoverPeak = hoverPeak > bird.poseAt(VizClip.walk, t)['wingNear']!
              .rotation.abs()
          ? hoverPeak
          : bird.poseAt(VizClip.walk, t)['wingNear']!.rotation.abs();
      dartPeak = dartPeak > bird.poseAt(VizClip.run, t)['wingNear']!
              .rotation.abs()
          ? dartPeak
          : bird.poseAt(VizClip.run, t)['wingNear']!.rotation.abs();
    }
    expect(dartPeak, greaterThan(hoverPeak));
  });

  test('is registered in the catalog', () {
    expect(VizCatalog.byId('hummingbird'), isA<VizRig>());
  });
}
