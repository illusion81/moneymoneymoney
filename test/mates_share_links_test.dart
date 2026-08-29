import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:moneymoneymoney/screens/mates_screen.dart';

/// The share row is demo dressing: it stands on its own rather than hiding
/// behind an invite, and a tap says out loud that it goes nowhere.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpMates(WidgetTester tester) async {
    tester.view.physicalSize = const Size(520, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: MatesScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets('the share row shows without sending an invite first',
      (tester) async {
    await pumpMates(tester);

    expect(find.text('Share your hive'), findsOneWidget);
    expect(find.text('Share to Facebook'), findsOneWidget);
    expect(find.text('Share to Instagram'), findsOneWidget);
    expect(find.text('Share to TikTok'), findsOneWidget);
  });

  testWidgets('tapping a share button admits it is a placeholder',
      (tester) async {
    await pumpMates(tester);

    await tester.tap(find.text('Share to Facebook'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.text('Sharing to Facebook is a demo placeholder.'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
