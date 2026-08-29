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

  testWidgets('both result-screen buttons lead somewhere', (tester) async {
    var explored = false;
    var planned = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MoneyStyleResultScreen(
          result: _result(),
          onExplore: () => explored = true,
          onBuildPlan: () => planned = true,
        ),
      ),
    );

    final explore = find.widgetWithText(
      FilledButton,
      'Explore ideas that fit my style',
    );
    await tester.ensureVisible(explore);
    await tester.pump();
    await tester.tap(explore);
    await tester.pumpAndSettle();
    expect(explored, isTrue);

    final plan = find.widgetWithText(
      FilledButton,
      'Build a practical plan with ranges',
    );
    await tester.ensureVisible(plan);
    await tester.pump();
    await tester.tap(plan);
    await tester.pumpAndSettle();
    expect(planned, isTrue);
  });

  testWidgets('no button silently does nothing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MoneyStyleResultScreen(
          result: _result(),
          onExplore: () {},
          onBuildPlan: () {},
        ),
      ),
    );

    // Every button on this screen must actually lead somewhere; a stub that
    // only shows "coming soon" strands the user after a 12-question quiz.
    expect(find.textContaining('coming soon'), findsNothing);
  });
}
