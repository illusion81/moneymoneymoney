import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/frps/slm/mock_slm.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';
import 'package:moneymoneymoney/screens/frps_report_screen.dart';

import 'fake_frps_repository.dart';

const _profile = FinanceProfile(
  monthlyIncome: 6000,
  fixedMonthlyExpenses: 2600,
  monthlySavingsGoal: 900,
  riskPreference: RiskPreference.balanced,
  financialGoal: FinancialGoal.invest,
  spendingPressure: SpendingPressure.medium,
);

void main() {
  testWidgets('shows an empty state when there is no data on file', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FrpsReportScreen(
          repository: FakeFrpsRepository(),
          userId: 'nobody',
          slm: MockSlm(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing to report yet'), findsOneWidget);
  });

  testWidgets('renders a report when seeded from the on-device profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: FrpsReportScreen(
          repository: FakeFrpsRepository(),
          userId: 'user-1',
          seedProfile: _profile,
          slm: MockSlm(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deep Financial Report'), findsOneWidget);
    expect(find.text('Executive Summary'), findsOneWidget);
  });

  testWidgets('offers a back button when onBack is supplied', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: FrpsReportScreen(
          repository: FakeFrpsRepository(),
          userId: 'nobody',
          slm: MockSlm(),
          onBack: () => tapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(IconButton));
    expect(tapped, isTrue);
  });
}
