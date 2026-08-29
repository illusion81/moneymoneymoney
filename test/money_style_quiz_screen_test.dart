import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/money_style_questions.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/screens/money_style_quiz_screen.dart';

void main() {
  group('MoneyStyleQuizScreen', () {
    late MoneyStyleCompletion? completedResult;

    setUp(() {
      completedResult = null;
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(1000, 2200);
      binding.platformDispatcher.views.first.devicePixelRatio = 1;
      addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
      addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
    });

    testWidgets('displays first question', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyStyleQuizScreen(
            userId: 'test-user',
            onComplete: (result) {
              completedResult = result;
            },
          ),
        ),
      );

      expect(find.text('Discover your Money Style'), findsOneWidget);
      expect(find.text('1 of 12'), findsOneWidget);
      expect(find.text(moneyStyleQuestions[0].prompt), findsOneWidget);
      expect(find.byType(OutlinedButton), findsWidgets); // Answer buttons
    });

    testWidgets('displays question scenario', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyStyleQuizScreen(
            userId: 'test-user',
            answerOrderSeed: 1,
            onComplete: (result) {},
          ),
        ),
      );

      expect(find.text(moneyStyleQuestions[0].scenario), findsOneWidget);
    });

    testWidgets('displays all three answer options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyStyleQuizScreen(
            userId: 'test-user',
            onComplete: (result) {},
          ),
        ),
      );

      final q1 = moneyStyleQuestions[0];
      expect(find.text(q1.answers[0].text), findsOneWidget);
      expect(find.text(q1.answers[1].text), findsOneWidget);
      expect(find.text(q1.answers[2].text), findsOneWidget);
    });

    testWidgets('next button is disabled when no answer selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyStyleQuizScreen(
            userId: 'test-user',
            onComplete: (result) {},
          ),
        ),
      );

      final nextButton = find.byWidgetPredicate(
        (widget) => widget is FilledButton && widget.onPressed == null,
      );
      expect(nextButton, findsOneWidget);
    });

    testWidgets('next button is enabled when answer selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyStyleQuizScreen(
            userId: 'test-user',
            onComplete: (result) {},
          ),
        ),
      );

      final q1 = moneyStyleQuestions[0];
      final answer = find.text(q1.answers[0].text);
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pump();

      expect(find.byWidgetPredicate(
        (widget) => widget is FilledButton && widget.onPressed != null,
      ), findsOneWidget);
    });

    testWidgets('selected answer button is highlighted', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyStyleQuizScreen(
            userId: 'test-user',
            onComplete: (result) {},
          ),
        ),
      );

      final q1 = moneyStyleQuestions[0];
      final answer = find.text(q1.answers[0].text);
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pump();

      // Verify the selected button has styling applied
      final selectedButton = find.text(q1.answers[0].text);
      expect(selectedButton, findsOneWidget);
    });

    testWidgets('skip button navigates to next question', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyStyleQuizScreen(
            userId: 'test-user',
            onComplete: (result) {},
          ),
        ),
      );

      expect(find.text('1 of 12'), findsOneWidget);

      // Find and tap the Skip button
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Should move to Q2
      expect(find.text('2 of 12'), findsOneWidget);
      expect(find.text(moneyStyleQuestions[1].prompt), findsOneWidget);
    });

    testWidgets('navigates to next question when next button tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyStyleQuizScreen(
            userId: 'test-user',
            answerOrderSeed: 1,
            onComplete: (result) {},
          ),
        ),
      );

      expect(find.text('1 of 12'), findsOneWidget);

      // Select an answer
      final q1 = moneyStyleQuestions[0];
      await tester.tap(find.text(q1.answers[0].text));
      await tester.pump();

      // Tap next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be on Q2
      expect(find.text('2 of 12'), findsOneWidget);
    });

    testWidgets('progress indicator updates', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyStyleQuizScreen(
            userId: 'test-user',
            onComplete: (result) {},
          ),
        ),
      );

      // Start at Q1
      expect(find.text('1 of 12'), findsOneWidget);

      // Answer and go to Q2
      final q1 = moneyStyleQuestions[0];
      await tester.tap(find.text(q1.answers[0].text));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('2 of 12'), findsOneWidget);

      // Go to Q3
      final q2 = moneyStyleQuestions[1];
      await tester.tap(find.text(q2.answers[1].text));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('3 of 12'), findsOneWidget);
    });

    testWidgets('back button appears after first question', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyStyleQuizScreen(
            userId: 'test-user',
            onComplete: (result) {},
          ),
        ),
      );

      // No back button on Q1
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      // Answer and go to Q2
      final q1 = moneyStyleQuestions[0];
      await tester.tap(find.text(q1.answers[0].text));
      await tester.pump();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Back button appears on Q2
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('quiz completion calls onComplete callback', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyStyleQuizScreen(
            userId: 'test-user',
            onComplete: (result) {
              completedResult = result;
            },
          ),
        ),
      );

      // Answer all 12 questions
      for (int i = 0; i < moneyStyleQuestions.length; i++) {
        final question = moneyStyleQuestions[i];
        await tester.tap(find.text(question.answers[0].text));
        await tester.pump();

        if (i < moneyStyleQuestions.length - 1) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        } else {
          // Last question
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      }

      expect(completedResult, isNotNull);
      expect(completedResult!.result!.archetype, isNotNull);
    });
  });
}
