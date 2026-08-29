import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moneymoneymoney/main.dart';

/// Renders the whole app and navigates every tab, so any build/layout
/// exception (e.g. the bee swarm's ticker setup) surfaces here.
///
/// Decorative animations are infinite, so we advance the clock with explicit
/// `pump`s rather than `pumpAndSettle` (which would never settle).
void main() {
  testWidgets('TallyHiveApp renders and every tab navigates', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TallyHiveApp()));
    await tester.pump(const Duration(milliseconds: 120));

    // First-run onboarding → skip through to the hive.
    await tester.tap(find.text('Get started'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('Skip for now'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('Skip for now'));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.tap(find.text('Enter the hive'));
    await tester.pump(const Duration(milliseconds: 120));

    // Home (Hive) is the current tab; the greeting + hive header render.
    expect(find.text('Morning, Sam'), findsOneWidget);

    // Visit each remaining tab and confirm its screen title renders.
    final tabs = <String, String>{
      'Report': 'What the hive noticed',
      'Market': 'Trade your honey',
      'Comb': 'Sam\'s comb',
      'Mates': 'Sam\'s five',
    };
    for (final entry in tabs.entries) {
      await tester.tap(find.text(entry.key).last);
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.text(entry.value), findsOneWidget);
    }

    // Back to Hive.
    await tester.tap(find.text('Hive').last);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Morning, Sam'), findsOneWidget);

    // Drain the breathing hive's one-shot orbit-start timers (≤ 0.9*i s) so
    // the test ends with no pending timers.
    await tester.pump(const Duration(seconds: 3));

    expect(tester.takeException(), isNull);
  });
}
