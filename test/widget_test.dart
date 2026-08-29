import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/main.dart';

void main() {
  testWidgets('first app screen shows the questionnaire', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Money Profile'), findsOneWidget);
    expect(find.text('Monthly income'), findsOneWidget);
    expect(find.text('Generate Report'), findsOneWidget);
  });

  testWidgets('valid questionnaire submission shows generated report', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(find.byKey(const Key('income-field')), '6000');
    await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
    await tester.enterText(find.byKey(const Key('savings-field')), '900');
    await tester.tap(find.text('Generate Report'));
    await tester.pumpAndSettle();

    expect(find.text('AI Wealth Report'), findsOneWidget);
    expect(find.textContaining('Daily flexible budget'), findsOneWidget);
    expect(find.text('Start Plan'), findsOneWidget);
  });

  testWidgets('starting the plan shows the forest home screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(find.byKey(const Key('income-field')), '6000');
    await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
    await tester.enterText(find.byKey(const Key('savings-field')), '900');
    await tester.tap(find.text('Generate Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Wealth Forest'), findsOneWidget);
    expect(find.text('Today\'s money action'), findsOneWidget);
    expect(find.text('Check In'), findsOneWidget);
  });

  testWidgets('successful check-in changes tree status to healthy', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(find.byKey(const Key('income-field')), '6000');
    await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
    await tester.enterText(find.byKey(const Key('savings-field')), '900');
    await tester.tap(find.text('Generate Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Plan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('spending-field')), '40');
    await tester.tap(find.byKey(const Key('action-complete-checkbox')));
    await tester.tap(find.text('Check In'));
    await tester.pumpAndSettle();

    expect(find.text('Healthy tree'), findsOneWidget);
  });

  testWidgets('overspending changes tree status to withered', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(find.byKey(const Key('income-field')), '6000');
    await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
    await tester.enterText(find.byKey(const Key('savings-field')), '900');
    await tester.tap(find.text('Generate Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Plan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('spending-field')), '200');
    await tester.tap(find.byKey(const Key('action-complete-checkbox')));
    await tester.tap(find.text('Check In'));
    await tester.pumpAndSettle();

    expect(find.text('Withered tree'), findsOneWidget);
  });
}
