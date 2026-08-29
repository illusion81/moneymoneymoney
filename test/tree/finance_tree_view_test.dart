import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/tree/finance_pillars.dart';
import 'package:moneymoneymoney/tree/finance_tree_view.dart';
import 'package:moneymoneymoney/tree/pixel_tree_painter.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 300, height: 360, child: child)),
  );

  PixelTreePainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((p) => p.painter)
      .whereType<PixelTreePainter>()
      .first;

  testWidgets('grows in over time', (tester) async {
    await tester.pumpWidget(
      host(const FinanceTreeView(pillars: FinancePillars.balanced())),
    );
    final start = painterOf(tester).progress;
    await tester.pump(const Duration(seconds: 2));
    expect(painterOf(tester).progress, greaterThan(start));
    await tester.pump(const Duration(seconds: 5));
    expect(painterOf(tester).progress, 1.0);
  });

  testWidgets('ignores pointer events', (tester) async {
    await tester.pumpWidget(
      host(const FinanceTreeView(pillars: FinancePillars.balanced())),
    );
    expect(
      find.descendant(
        of: find.byType(FinanceTreeView),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });

  testWidgets('uses the withered palette for poor finances', (tester) async {
    await tester.pumpWidget(
      host(
        const FinanceTreeView(
          pillars: FinancePillars(
            profitability: 0.05,
            liquidity: 0.05,
            solvency: 0.05,
            efficiency: 0.05,
          ),
        ),
      ),
    );
    expect(
      painterOf(tester).palette.leaf,
      const TreePalette.withered().leaf,
    );
  });
}