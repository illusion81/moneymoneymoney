import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/services/savings_stats_service.dart';
import 'package:moneymoneymoney/widgets/savings_chart.dart';

void main() {
  testWidgets('shows an empty-state message when there are no points', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SavingsChart(points: [])),
      ),
    );

    expect(find.textContaining('No savings data yet'), findsOneWidget);
  });

  testWidgets('renders without an empty-state message when points exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SavingsChart(
            points: [
              SavingsPoint(label: 'Aug 3', cumulativeSaved: 20),
              SavingsPoint(label: 'Aug 10', cumulativeSaved: 35),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('No savings data yet'), findsNothing);
    expect(find.byKey(const Key('savings-chart-canvas')), findsOneWidget);
  });

  testWidgets('renders a single-point series without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SavingsChart(
            points: [SavingsPoint(label: 'Aug 2026', cumulativeSaved: 30)],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('savings-chart-canvas')), findsOneWidget);
  });

  testWidgets('tapping a point shows its label and value in a tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SavingsChart(
            points: [
              SavingsPoint(label: 'Aug 3', cumulativeSaved: 20),
              SavingsPoint(label: 'Aug 10', cumulativeSaved: 35),
            ],
          ),
        ),
      ),
    );

    final canvas = find.byKey(const Key('savings-chart-canvas'));
    // Tap near the right edge, closest to the second point.
    final rightEdge = tester.getTopRight(canvas) + const Offset(-4, 20);
    await tester.tapAt(rightEdge);
    await tester.pumpAndSettle();

    expect(find.textContaining('Aug 10'), findsOneWidget);
    expect(find.textContaining('35'), findsOneWidget);
  });

  testWidgets(
    'selection is cleared instead of crashing when the points list shrinks',
    (tester) async {
      Widget harness(List<SavingsPoint> points) {
        return MaterialApp(home: Scaffold(body: SavingsChart(points: points)));
      }

      await tester.pumpWidget(
        harness(const [
          SavingsPoint(label: 'Aug 3', cumulativeSaved: 20),
          SavingsPoint(label: 'Aug 10', cumulativeSaved: 35),
        ]),
      );

      final canvas = find.byKey(const Key('savings-chart-canvas'));
      await tester.tapAt(tester.getTopRight(canvas) + const Offset(-4, 20));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aug 10'), findsOneWidget);

      // Simulate switching to a period whose series has fewer points.
      await tester.pumpWidget(
        harness(const [
          SavingsPoint(label: 'Aug 2026', cumulativeSaved: 30),
        ]),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Aug 2026'), findsNothing);
    },
  );
}
