// The old version of this test asserted that the screen showed raw enum names
// ("under2500") — it was locking in the bug. It now checks the two things that
// actually matter: nothing in the form leaks an identifier, and "keep this
// snapshot" hands back the three answers so the caller can build a profile.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/screens/plan_range_screen.dart';

void main() {
  Future<void> pick(WidgetTester tester, String fieldLabel, String option) async {
    await tester.tap(find.text(fieldLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  testWidgets('keeping the snapshot hands back all three answers',
      (tester) async {
    RangeSnapshot? kept;
    var exact = false;

    await tester.pumpWidget(MaterialApp(
      home: PlanRangeScreen(
        onKeep: (s) => kept = s,
        onExact: () => exact = true,
      ),
    ));

    // Nothing is chosen yet, so "keep" must be disabled rather than sending
    // the user onward with a half-filled snapshot.
    final keep =
        find.widgetWithText(OutlinedButton, 'Keep this range-based snapshot');
    expect(tester.widget<OutlinedButton>(keep).onPressed, isNull);

    await pick(tester, 'Monthly income after tax', '\$2,500 – \$5,000 a month');
    await pick(tester, 'Rent, bills and transport take up', 'About half');
    await pick(
        tester, 'Right now you mostly want to', 'Save for something coming up');

    await tester.tap(keep);
    await tester.pump();

    expect(kept, isNotNull);
    expect(kept!.income, IncomeRange.from2500To5000);
    expect(kept!.costs, FixedCostShareRange.aboutHalf);
    expect(kept!.priority, PlanningPriority.upcomingCost);
    expect(exact, isFalse);
  });

  testWidgets('no raw enum identifiers reach the screen', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: PlanRangeScreen(onKeep: (_) {}, onExact: () {}),
    ));

    for (final leak in [
      'under2500',
      'preferNotToSay',
      'aboutHalf',
      'breathingRoom'
    ]) {
      expect(find.textContaining(leak), findsNothing,
          reason: '$leak leaked into the UI');
    }
  });

  testWidgets('the exact-numbers escape hatch is always live', (tester) async {
    var exact = false;
    await tester.pumpWidget(MaterialApp(
      home: PlanRangeScreen(onKeep: (_) {}, onExact: () => exact = true),
    ));

    await tester.tap(find.text('Use exact numbers instead'));
    await tester.pump();
    expect(exact, isTrue);
  });
}
