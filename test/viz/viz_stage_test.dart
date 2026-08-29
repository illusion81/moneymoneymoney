import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/viz/rig/rig_painter.dart';
import 'package:moneymoneymoney/viz/rig/viz_clip.dart';
import 'package:moneymoneymoney/viz/viz_catalog.dart';
import 'package:moneymoneymoney/viz/viz_stage.dart';

import 'support/stub_rig.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 300, height: 300, child: child)),
  );

  RigPainter painterOf(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(VizStage),
        matching: find.byType(CustomPaint),
      ).first,
    );
    return paint.painter! as RigPainter;
  }

  testWidgets('advances the phase as time passes', (tester) async {
    await tester.pumpWidget(
      host(VizStage(rig: StubRig(), clip: VizClip.breathe)),
    );
    final first = painterOf(tester).phase;
    await tester.pump(const Duration(milliseconds: 800));
    expect(painterOf(tester).phase, isNot(equals(first)));
  });

  testWidgets('ignores pointer events', (tester) async {
    await tester.pumpWidget(
      host(VizStage(rig: StubRig(), clip: VizClip.breathe)),
    );
    expect(
      find.descendant(
        of: find.byType(VizStage),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses the rig default palette when none is given', (
    tester,
  ) async {
    final rig = StubRig();
    await tester.pumpWidget(host(VizStage(rig: rig, clip: VizClip.breathe)));
    expect(painterOf(tester).palette.id, rig.defaultPalette.id);
  });

  test('catalog exposes registered rigs and rejects unknown ids', () {
    expect(VizCatalog.all, isNotEmpty);
    expect(() => VizCatalog.byId('nope'), throwsStateError);
  });
}
