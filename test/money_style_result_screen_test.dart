import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/money_style_archetypes.dart';
import 'package:moneymoneymoney/data/money_style_questions.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/screens/money_style_result_screen.dart';
import 'package:moneymoneymoney/services/money_style_engine.dart';

/// A session with one answer per dimension, at the given band.
AnswerSession sessionWithOpeners(Map<int, PoleBand> bands) => AnswerSession(
  userId: 'u',
  sessionId: 's',
  selectedAnswers: {
    for (final entry in bands.entries)
      entry.key: moneyStyleQuestionsById[entry.key]!.answers.indexWhere(
        (a) => a.band == entry.value,
      ),
  },
  shownQuestionIds: List<int>.from(bands.keys),
);

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
    final session = sessionWithOpeners({
      1: PoleBand.bad,
      2: PoleBand.mixed,
      3: PoleBand.mixed,
      4: PoleBand.mixed,
      5: PoleBand.mixed,
    });
    final result = MoneyStyleResult(
      archetype: archetypeMap['watch_watch_watch']!,
      confidenceTier: ConfidenceTier.earlySnapshot,
      dimensionScores: const MoneyStyleEngine().calculateDimensionScores(
        session,
        moneyStyleQuestionPool,
      ),
      totalAnswered: 5,
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

  testWidgets('the result names the most critical and strongest habits', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1000,
      3000,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);

    final session = sessionWithOpeners({
      1: PoleBand.bad, // Revolving debt: -1
      2: PoleBand.good, // Convenience: +1
      3: PoleBand.mixed,
      4: PoleBand.mixed,
      5: PoleBand.mixed,
      6: PoleBand.mixed,
    });
    final result = const MoneyStyleEngine().generateResult(
      session,
      moneyStyleQuestionPool,
    )!;

    await tester.pumpWidget(
      MaterialApp(
        home: MoneyStyleResultScreen(
          completion: MoneyStyleCompletion(session: session, result: result),
        ),
      ),
    );

    expect(
      find.textContaining('Most worth a look: Credit card balances'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Already working: Convenience spending'),
      findsOneWidget,
    );
  });
}
