import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/money_style_questions.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/screens/money_style_quiz_screen.dart';

/// The question currently rendered — the screen picks it adaptively, so tests
/// read it off the widget tree rather than assuming a fixed order.
MoneyStyleQuestion currentQuestion() => moneyStyleQuestionPool.firstWhere(
  (q) => find.text(q.prompt).evaluate().isNotEmpty,
  orElse: () => throw StateError('no question is on screen'),
);

/// Taps the option with the given band on whatever question is on screen.
Future<void> answerCurrent(WidgetTester tester, PoleBand band) async {
  final answer = currentQuestion().answers.firstWhere((a) => a.band == band);
  await tester.ensureVisible(find.text(answer.text));
  await tester.tap(find.text(answer.text));
  await tester.pump();
}

void main() {
  group('MoneyStyleQuizScreen', () {
    late MoneyStyleCompletion? completedResult;

    setUp(() {
      completedResult = null;
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.views.first.physicalSize = const Size(
        1000,
        2600,
      );
      binding.platformDispatcher.views.first.devicePixelRatio = 1;
      addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
      addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
    });

    Future<void> pumpQuiz(
      WidgetTester tester, {
      VoidCallback? onSkipAll,
      ValueChanged<AnswerSession>? onProgress,
      AnswerSession? initialSession,
    }) => tester.pumpWidget(
      MaterialApp(
        home: MoneyStyleQuizScreen(
          userId: 'test-user',
          answerOrderSeed: 1,
          initialSession: initialSession,
          onProgress: onProgress,
          onSkipAll: onSkipAll,
          onComplete: (result) => completedResult = result,
        ),
      ),
    );

    testWidgets('opens on the first fixed opener', (tester) async {
      await pumpQuiz(tester);

      // The app bar says 'Money Style': the full phrase truncated to
      // "Discover your Money S…" on a 390pt phone, and it already appears in
      // full on the screen that launches the quiz.
      expect(find.text('Money Style'), findsOneWidget);
      expect(find.text('1 of 12'), findsOneWidget);
      expect(find.text(moneyStyleQuestionsById[1]!.prompt), findsOneWidget);
      expect(find.text(moneyStyleQuestionsById[1]!.scenario), findsOneWidget);
    });

    testWidgets('displays all three answer options', (tester) async {
      await pumpQuiz(tester);

      for (final answer in moneyStyleQuestionsById[1]!.answers) {
        expect(find.text(answer.text), findsOneWidget);
      }
    });

    testWidgets('next is disabled until an answer is selected', (tester) async {
      await pumpQuiz(tester);

      expect(
        find.byWidgetPredicate((w) => w is FilledButton && w.onPressed == null),
        findsOneWidget,
      );

      await answerCurrent(tester, PoleBand.bad);

      expect(
        find.byWidgetPredicate((w) => w is FilledButton && w.onPressed != null),
        findsOneWidget,
      );
    });

    testWidgets('skip moves to the next question', (tester) async {
      await pumpQuiz(tester);

      expect(find.text('1 of 12'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('2 of 12'), findsOneWidget);
      expect(find.text(moneyStyleQuestionsById[2]!.prompt), findsOneWidget);
    });

    testWidgets('the back button only appears after the first question', (
      tester,
    ) async {
      await pumpQuiz(tester);
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      await answerCurrent(tester, PoleBand.bad);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('progress callbacks receive immutable session snapshots', (
      tester,
    ) async {
      final progress = <AnswerSession>[];
      await pumpQuiz(tester, onProgress: progress.add);

      await answerCurrent(tester, PoleBand.bad);
      final firstSnapshot = progress.single;

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await answerCurrent(tester, PoleBand.bad);

      expect(firstSnapshot.selectedAnswers.keys, [1]);
      expect(progress.last.selectedAnswers.keys, [1, 2]);
      expect(identical(firstSnapshot, progress.last), isFalse);
    });

    testWidgets('pages 1 and 2 are the six fixed openers', (tester) async {
      await pumpQuiz(tester);

      for (var i = 1; i <= 6; i++) {
        expect(
          find.text(moneyStyleQuestionsById[i]!.prompt),
          findsOneWidget,
          reason: 'opener $i',
        );
        await answerCurrent(tester, PoleBand.mixed);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('page 3 is routed from the running score, not a fixed list', (
      tester,
    ) async {
      await pumpQuiz(tester);

      // Answer the six openers exactly as the design doc's "Alex" does.
      const bands = [
        PoleBand.bad, // RD
        PoleBand.good, // CI
        PoleBand.mixed, // PA
        PoleBand.mixed, // SB
        PoleBand.bad, // SA
        PoleBand.good, // FA
      ];
      for (final band in bands) {
        await answerCurrent(tester, band);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Page 3 leads with the Revolving Debt bad-drill-down (Q7).
      expect(find.text('7 of 12'), findsOneWidget);
      expect(currentQuestion().id, 7);
      expect(currentQuestion().branch, QuestionBranch.badDrill);
    });

    testWidgets('a full run completes with a result and 12 shown questions', (
      tester,
    ) async {
      await pumpQuiz(tester);

      for (var i = 0; i < 12; i++) {
        await answerCurrent(tester, PoleBand.bad);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(completedResult, isNotNull);
      expect(completedResult!.result, isNotNull);
      expect(completedResult!.session.shownQuestionIds, hasLength(12));
      expect(completedResult!.session.totalAnswered, 12);
      expect(
        completedResult!.result!.confidenceTier,
        ConfidenceTier.fullClarity,
      );
    });

    testWidgets('a skipped opener is re-shown as a page-3 catch-up slot', (
      tester,
    ) async {
      await pumpQuiz(tester);

      for (var i = 0; i < 6; i++) {
        if (currentQuestion().id == 5) {
          // Skip the Savings Avoidance opener.
          await tester.tap(find.text('Skip'));
          await tester.pumpAndSettle();
          continue;
        }
        await answerCurrent(tester, PoleBand.mixed);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // The unscored dimension outranks everything, so its opener comes back.
      expect(currentQuestion().id, 5);
      expect(currentQuestion().branch, QuestionBranch.opening);
    });

    testWidgets('the skip-everything action is on every page', (tester) async {
      var skipped = 0;
      await pumpQuiz(tester, onSkipAll: () => skipped++);

      for (var i = 0; i < 12; i++) {
        expect(
          find.byKey(const Key('skip-questionnaire-button')),
          findsOneWidget,
          reason: 'app-bar skip on question ${i + 1}',
        );
        expect(
          find.byKey(const Key('skip-questionnaire-footer-button')),
          findsOneWidget,
          reason: 'footer skip on question ${i + 1}',
        );
        if (i == 11) break;
        await answerCurrent(tester, PoleBand.mixed);
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const Key('skip-questionnaire-button')));
      await tester.pump();
      expect(skipped, 1);
    });

    testWidgets('a resumed session opens at the first unanswered question', (
      tester,
    ) async {
      await pumpQuiz(
        tester,
        initialSession: AnswerSession(
          userId: 'u',
          sessionId: 's',
          selectedAnswers: {1: 0},
          skippedQuestions: {2},
        ),
      );

      expect(find.text('3 of 12'), findsOneWidget);
      expect(currentQuestion().id, 3);
    });
  });
}
