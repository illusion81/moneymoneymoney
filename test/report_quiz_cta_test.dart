import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:moneymoneymoney/screens/report_screen.dart';

/// The report closes with a call to take the money quiz. It is demo dressing,
/// so the tap has to announce itself as a placeholder rather than navigate.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpReport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(402, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // ReportScreen is a bare ListView; the router's shell supplies the
    // Scaffold in the real app, and the SnackBar needs one to land in.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: ReportScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets('the report invites you to take the quiz', (tester) async {
    await pumpReport(tester);

    expect(find.text('How do you really spend?'), findsOneWidget);
    expect(find.text('Take the quiz'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the quiz admits it is a placeholder', (tester) async {
    await pumpReport(tester);

    await tester.tap(find.text('Take the quiz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('The quiz is a demo placeholder.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
