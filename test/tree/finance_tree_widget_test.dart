import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';
import 'package:moneymoneymoney/models/forest_day.dart';
import 'package:moneymoneymoney/tree/finance_tree.dart';
import 'package:moneymoneymoney/tree/finance_tree_view.dart';
import 'package:moneymoneymoney/tree/pixel_tree_painter.dart';

void main() {
  const healthyProfile = FinanceProfile(
    monthlyIncome: 6000,
    fixedMonthlyExpenses: 2500,
    monthlySavingsGoal: 900,
    riskPreference: RiskPreference.balanced,
    financialGoal: FinancialGoal.emergencyFund,
    spendingPressure: SpendingPressure.medium,
  );

  ForestSummary summary(TreeStatus status) => ForestSummary(
    days: [
      ForestDay(
        date: DateTime(2026, 1, 1),
        status: status,
        treeLevel: status == TreeStatus.healthy ? 1 : 0,
        spending: status == TreeStatus.healthy ? 30 : 500,
        dailyBudget: 50,
        actionCompleted: true,
        message: 'message',
      ),
    ],
    currentStreak: status == TreeStatus.healthy ? 1 : 0,
    healthyTreeCount: status == TreeStatus.healthy ? 1 : 0,
    witheredTreeCount: status == TreeStatus.withered ? 1 : 0,
    achievements: const [],
  );

  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 300, height: 360, child: child)),
  );

  PixelTreePainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((p) => p.painter)
      .whereType<PixelTreePainter>()
      .first;

  testWidgets('renders a healthy tree for healthy finances and check-in', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FinanceTree(
          profile: healthyProfile,
          summary: summary(TreeStatus.healthy),
        ),
      ),
    );
    expect(find.byType(FinanceTreeView), findsOneWidget);
    expect(painterOf(tester).palette.leaf, const TreePalette.healthy().leaf);
  });

  testWidgets('a withered check-in overrides a healthy profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FinanceTree(
          profile: healthyProfile,
          summary: summary(TreeStatus.withered),
        ),
      ),
    );
    expect(
      painterOf(tester).palette.leaf,
      const TreePalette.withered().leaf,
    );
  });
}
