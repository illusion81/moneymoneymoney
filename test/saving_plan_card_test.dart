import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/services/daily_saving_plan.dart';
import 'package:moneymoneymoney/widgets/saving_plan_card.dart';

const _plan = DailySavingPlan(
  category: 'eating-out',
  monthlyCategorySpend: 420,
  monthlySaving: 126,
  dailySaving: 4.2,
  trimFraction: 0.30,
);

void main() {
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1000,
      2000,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('leads with the daily figure as the biggest number', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SavingPlanCard(plan: _plan))),
    );

    final daily = tester.widget<Text>(
      find.byKey(const Key('saving-plan-daily-amount')),
    );
    final monthly = tester.widget<Text>(
      find.byKey(const Key('saving-plan-monthly-amount')),
    );

    expect(daily.style!.fontSize, greaterThan(monthly.style!.fontSize!));
  });

  testWidgets('names the category and the monthly payoff', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SavingPlanCard(plan: _plan))),
    );

    expect(find.textContaining('eating-out'), findsOneWidget);
    expect(find.textContaining('126'), findsOneWidget);
    expect(find.textContaining('30%'), findsOneWidget);
  });

  testWidgets('renders nothing when there is no plan', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SavingPlanCard(plan: null))),
    );

    expect(find.byKey(const Key('saving-plan-card')), findsNothing);
  });
}
