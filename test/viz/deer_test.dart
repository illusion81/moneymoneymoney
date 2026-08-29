import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/animals/deer.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/rig/viz_rig.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';

void main() {
  final deer = Deer();

  test('declares a stable identity and all three clips', () {
    expect(deer.id, 'deer');
    expect(deer.displayName, 'Deer');
    expect(deer.supportedClips, VizClip.values.toSet());
  });

  test('every part has a unique z', () {
    final zs = deer.parts.map((p) => p.z).toList();
    expect(zs.toSet().length, zs.length);
  });

  test('every parent reference resolves to a real part', () {
    final ids = deer.parts.map((p) => p.id).toSet();
    for (final part in deer.parts) {
      if (part.parent != null) {
        expect(ids, contains(part.parent), reason: '${part.id} parent');
      }
    }
  });

  test('both antlers hang off the head', () {
    final byId = {for (final p in deer.parts) p.id: p};
    expect(byId['antlerFar']!.parent, 'head');
    expect(byId['antlerNear']!.parent, 'head');
  });

  test('every clip loops: pose at t=0 matches pose at t->1', () {
    for (final clip in deer.supportedClips) {
      final start = deer.poseAt(clip, 0);
      final end = deer.poseAt(clip, 0.9999);
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

  test('walking alternates the near fore and hind legs', () {
    final pose = deer.poseAt(VizClip.walk, 0.125);
    expect(pose['hindLegNear']!.rotation * pose['foreLegNear']!.rotation,
        lessThan(0));
  });

  test('running bounds: near and far fore legs move together', () {
    final pose = deer.poseAt(VizClip.run, 0.125);
    expect(pose['foreLegNear']!.rotation * pose['foreLegFar']!.rotation,
        greaterThan(0));
  });

  test('is registered in the catalog', () {
    expect(VizCatalog.byId('deer'), isA<VizRig>());
  });
}
