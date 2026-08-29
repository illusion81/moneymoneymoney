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

    await _completeQuestionnaire(tester);

    expect(find.text('AI Wealth Report'), findsOneWidget);
    expect(find.textContaining('Daily flexible budget'), findsOneWidget);
    await _scrollToStartPlan(tester);
    expect(find.text('Start Plan'), findsOneWidget);
  });

  testWidgets('starting the plan shows the forest home screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    await _completeQuestionnaire(tester);
    await _startPlan(tester);
    await _scrollToCheckIn(tester);

    expect(find.text('Wealth Forest'), findsOneWidget);
    expect(find.text('Today\'s money action'), findsOneWidget);
    expect(find.text('Check In'), findsOneWidget);
  });

  testWidgets('successful check-in changes tree status to healthy', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await _completeQuestionnaire(tester);
    await _startPlan(tester);
    await _checkIn(tester, spending: '40');

    expect(find.text('Healthy tree'), findsOneWidget);
  });

  testWidgets('overspending changes tree status to withered', (tester) async {
    await tester.pumpWidget(const MyApp());

    await _completeQuestionnaire(tester);
    await _startPlan(tester);
    await _checkIn(tester, spending: '200');

    expect(find.text('Withered tree'), findsOneWidget);
  });
}

Future<void> _startPlan(WidgetTester tester) async {
  await _scrollToStartPlan(tester);
  await tester.tap(find.text('Start Plan'));
  await tester.pumpAndSettle();
}

Future<void> _checkIn(WidgetTester tester, {required String spending}) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('spending-field')),
    120,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.enterText(find.byKey(const Key('spending-field')), spending);
  await tester.scrollUntilVisible(
    find.byKey(const Key('action-complete-checkbox')),
    120,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.byKey(const Key('action-complete-checkbox')));
  await _scrollToCheckIn(tester);
  await tester.tap(find.text('Check In'));
  await tester.pumpAndSettle();
}

Future<void> _scrollToStartPlan(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Start Plan'),
    120,
    scrollable: find.byType(Scrollable).last,
  );
}

Future<void> _scrollToCheckIn(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Check In'),
    120,
    scrollable: find.byType(Scrollable).last,
  );
}

Future<void> _completeQuestionnaire(WidgetTester tester) async {
  await tester.enterText(find.byKey(const Key('income-field')), '6000');
  await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
  await tester.enterText(find.byKey(const Key('savings-field')), '900');
  await tester.ensureVisible(find.text('Generate Report'));
  await tester.tap(find.text('Generate Report'));
  await tester.pumpAndSettle();
}
