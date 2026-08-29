import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:moneymoneymoney/screens/hive_screen.dart';

/// The hive closes on a sponsored ad. It is demo dressing, so it has to be
/// labelled as an ad, name an obviously invented backer, and admit on tap
/// that nothing sits behind it.
///
/// The viewport is wider than the 402 design width on purpose. Google Fonts
/// cannot fetch under test, so the mono meta line inside the hive card falls
/// back to a font whose glyphs are a full em wide (~10.75px at fontSize 10.5
/// against JetBrains Mono's ~6.3px) and overflows its Row by 6.8px. That is a
/// measurement artifact of the test font, not a layout defect, and widening
/// the viewport keeps it from masking a real exception here.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpHive(WidgetTester tester) async {
    tester.view.physicalSize = const Size(520, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HiveScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets('the hive closes on a labelled sponsor ad', (tester) async {
    await pumpHive(tester);

    expect(find.text('Sponsored'), findsOneWidget);
    expect(find.text('Pollen Capital'), findsOneWidget);
    expect(find.text('Park your honey at 4.8% p.a.'), findsOneWidget);
    expect(find.text('See the offer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the ad admits it is a placeholder when opened', (tester) async {
    await pumpHive(tester);

    await tester.tap(find.text('See the offer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Pollen Capital is a demo placeholder.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
