import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/money_style_questions.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/screens/money_style_result_screen.dart';
import 'package:moneymoneymoney/services/money_style_engine.dart';

MoneyStyleResult _result() {
  final engine = MoneyStyleEngine();
  final questions = moneyStyleQuestions;
  final session = AnswerSession(userId: 'u1', sessionId: 's1');
  for (final q in questions) {
    session.selectedAnswers[q.id] = 0;
  }
  return engine.generateResult(session, questions);
}

void main() {
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1000,
      2600,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('the result screen offers a way to continue', (tester) async {
    var continued = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MoneyStyleResultScreen(
          result: _result(),
          onContinue: () => continued = true,
        ),
      ),
    );

    final button = find.byKey(const Key('money-style-continue-button'));
    expect(button, findsOneWidget);

    await tester.ensureVisible(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(continued, isTrue);
  });

  testWidgets('no button silently does nothing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MoneyStyleResultScreen(result: _result(), onContinue: () {})),
    );

    // Every button on this screen must actually lead somewhere; a stub that
    // only shows "coming soon" strands the user after a 12-question quiz.
    expect(find.textContaining('coming soon'), findsNothing);
  });
}
