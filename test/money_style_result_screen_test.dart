import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/money_style_archetypes.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/screens/money_style_result_screen.dart';

void main() {
  testWidgets(
    'insufficient result explains coverage and exposes recovery actions',
    (tester) async {
      var more = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MoneyStyleResultScreen(
            completion: MoneyStyleCompletion(
              session: AnswerSession(
                userId: 'u',
                sessionId: 's',
                selectedAnswers: {1: 0},
              ),
              result: null,
            ),
            onAnswerMore: () => more = true,
            onStartOver: () {},
          ),
        ),
      );
      expect(find.text('1 of 12 questions answered'), findsOneWidget);
      expect(find.textContaining('each area'), findsOneWidget);
      await tester.tap(find.text('Answer a few more'));
      expect(more, isTrue);
    },
  );

  testWidgets('early snapshot qualifies the result and invites more answers', (
    tester,
  ) async {
    var more = false;
    final session = AnswerSession(
      userId: 'u',
      sessionId: 's',
      selectedAnswers: {1: 0, 2: 0, 4: 0},
      skippedQuestions: {3, 5, 6, 7, 8, 9, 10, 11, 12},
    );
    final result = MoneyStyleResult(
      archetype: archetypeMap['steady_pause_collaborative']!,
      confidenceTier: ConfidenceTier.earlySnapshot,
      dimensionScores: DimensionScores(
        steadyCount: 1,
        pauseCount: 1,
        collaborativeCount: 1,
      ),
      moneyRhythmWinner: MoneyRhythmPole.steady,
      decisionStyleWinner: DecisionStylePole.pause,
      supportStyleWinner: SupportStylePole.collaborative,
      totalAnswered: 3,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MoneyStyleResultScreen(
          completion: MoneyStyleCompletion(session: session, result: result),
          onAnswerMore: () => more = true,
        ),
      ),
    );

    expect(
      find.textContaining('Based on what you shared today'),
      findsOneWidget,
    );
    await tester.tap(find.text('Answer a few more'));
    expect(more, isTrue);
  });
}
