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
}
