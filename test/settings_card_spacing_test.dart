import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:moneymoneymoney/screens/settings_screen.dart';

/// Cards inside a settings group used to stack flush against each other, so
/// the group read as one slab. They should be separated by a visible gap.
///
/// The assertion measures laid-out rectangles rather than looking for a
/// particular spacer widget, so it survives a change of technique.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  /// The outermost card container behind a row's label.
  Rect cardRect(WidgetTester tester, String label) {
    final Finder card = find
        .ancestor(of: find.text(label), matching: find.byType(Container))
        .first;
    return tester.getRect(card);
  }

  testWidgets('cards in a settings group are separated by a gap',
      (tester) async {
    tester.view.physicalSize = const Size(520, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    const List<String> nudges = <String>[
      'Morning check-in reminder',
      'Alert me when a category drifts',
      'Let hive-mates see my streak',
    ];

    for (int i = 1; i < nudges.length; i++) {
      final Rect above = cardRect(tester, nudges[i - 1]);
      final Rect below = cardRect(tester, nudges[i]);
      expect(
        below.top - above.bottom,
        greaterThanOrEqualTo(6.0),
        reason: 'no gap between "${nudges[i - 1]}" and "${nudges[i]}"',
      );
    }

    expect(tester.takeException(), isNull);
  });
}
