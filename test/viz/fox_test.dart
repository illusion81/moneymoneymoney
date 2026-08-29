import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/animals/fox.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';

void main() {
  final fox = Fox();

  test('declares a stable identity and all three clips', () {
    expect(fox.id, 'fox');
    expect(fox.displayName, 'Fox');
    expect(fox.supportedClips, VizClip.values.toSet());
  });

  test('every part has a unique z', () {
    final zs = fox.parts.map((p) => p.z).toList();
    expect(zs.toSet().length, zs.length);
  });

  test('every parent reference resolves to a real part', () {
    final ids = fox.parts.map((p) => p.id).toSet();
    for (final part in fox.parts) {
      if (part.parent != null) {
        expect(ids, contains(part.parent), reason: '${part.id} parent');
      }
    }
  });

  test('every clip loops: pose at t=0 matches pose at t->1', () {
    for (final clip in fox.supportedClips) {
      final start = fox.poseAt(clip, 0);
      final end = fox.poseAt(clip, 0.9999);
      for (final id in start.keys) {
        expect(end[id]!.rotation, closeTo(start[id]!.rotation, 0.01),
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

  test('breathing swells the body without moving the legs', () {
    final pose = fox.poseAt(VizClip.breathe, 0.25);
    expect(pose['body']!.scaleY, greaterThan(1.0));
    expect(pose['hindLegNear'], isNull);
  });

  test('walking puts the near fore and hind legs in opposite phase', () {
    final pose = fox.poseAt(VizClip.walk, 0.125);
    expect(pose['hindLegNear']!.rotation * pose['foreLegNear']!.rotation,
        lessThan(0));
  });

  test('running swings the legs harder than walking', () {
    final walk = fox.poseAt(VizClip.walk, 0.25)['hindLegNear']!.rotation.abs();
    final run = fox.poseAt(VizClip.run, 0.25)['hindLegNear']!.rotation.abs();
    expect(run, greaterThan(walk));
  });

  test('is registered in the catalog', () {
    expect(VizCatalog.byId('fox'), isA<VizRig>());
  });
}
