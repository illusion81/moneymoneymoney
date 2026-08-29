import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/main.dart';
import 'package:moneymoneymoney/viz/viz_stage.dart';
import 'package:moneymoneymoney/viz/workbench/viz_workbench_screen.dart';

void main() {
  testWidgets('the app boots into the workbench in viz mode', (tester) async {
    await tester.pumpWidget(const MyApp(vizMode: true));
    expect(find.byType(VizWorkbenchScreen), findsOneWidget);
    expect(find.text('Viz Workbench'), findsOneWidget);
  });

  testWidgets('shows a stage and a chip for every catalog subject', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(vizMode: true));
    expect(find.byKey(const Key('viz-stage')), findsOneWidget);
    expect(find.byKey(const Key('viz-subject-fox')), findsOneWidget);
  });

  testWidgets('selecting a clip changes what the stage plays', (tester) async {
    await tester.pumpWidget(const MyApp(vizMode: true));
    await tester.tap(find.byKey(const Key('viz-clip-run')));
    await tester.pump();
    final stage = tester.widget<VizStage>(find.byType(VizStage));
    expect(stage.clip.name, 'run');
  });

  testWidgets('the speed slider changes playback speed', (tester) async {
    await tester.pumpWidget(const MyApp(vizMode: true));
    final before = tester.widget<VizStage>(find.byType(VizStage)).speed;
    await tester.drag(
      find.byKey(const Key('viz-speed-slider')),
      const Offset(-120, 0),
    );
    await tester.pump();
    expect(tester.widget<VizStage>(find.byType(VizStage)).speed,
        lessThan(before));
  });

  testWidgets('the pivot toggle reaches the stage', (tester) async {
    await tester.pumpWidget(const MyApp(vizMode: true));
    await tester.tap(find.byKey(const Key('viz-pivots-toggle')));
    await tester.pump();
    expect(tester.widget<VizStage>(find.byType(VizStage)).showPivots, isTrue);
  });
}
