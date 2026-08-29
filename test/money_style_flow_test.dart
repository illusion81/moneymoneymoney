import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/screens/money_style_flow.dart';

void main() {
  testWidgets('existing session offers resume and start over', (tester) async {
    var cleared = false;
    final completion = MoneyStyleCompletion(
      session: AnswerSession(userId: 'u', sessionId: 's', selectedAnswers: {1: 0}),
      result: null,
    );
    await tester.pumpWidget(MaterialApp(home: MoneyStyleFlow(userId: 'u', existingCompletion: completion, onComplete: (_) {}, onStartOver: () => cleared = true)));
    expect(find.text('Resume'), findsOneWidget);
    await tester.tap(find.text('Start over'));
    expect(cleared, isTrue);
  });
}
