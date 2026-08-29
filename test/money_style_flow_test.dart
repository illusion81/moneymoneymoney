import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/screens/money_style_flow.dart';

void main() {
  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1000,
      2600,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('existing session offers resume and start over', (tester) async {
    var cleared = false;
    final completion = MoneyStyleCompletion(
      session: AnswerSession(
        userId: 'u',
        sessionId: 's',
        selectedAnswers: {1: 0},
      ),
      result: null,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MoneyStyleFlow(
          userId: 'u',
          existingCompletion: completion,
          onComplete: (_) {},
          onStartOver: () async {
            cleared = true;
          },
        ),
      ),
    );
    expect(find.text('Resume'), findsOneWidget);
    await tester.tap(find.text('Start over'));
    expect(cleared, isTrue);
  });

  testWidgets('the entry screen offers a way out before any question', (
    tester,
  ) async {
    var skipped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MoneyStyleFlow(
          userId: 'u',
          onComplete: (_) {},
          onSkipAll: () => skipped++,
        ),
      ),
    );

    expect(find.byKey(const Key('skip-questionnaire-button')), findsOneWidget);
    expect(find.textContaining('come back to this any time'), findsOneWidget);

    await tester.tap(find.byKey(const Key('skip-questionnaire-button')));
    await tester.pump();
    expect(skipped, 1);
  });

  testWidgets('the way out stays available once the quiz has started', (
    tester,
  ) async {
    var skipped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MoneyStyleFlow(
          userId: 'u',
          onComplete: (_) {},
          onSkipAll: () => skipped++,
        ),
      ),
    );

    await tester.tap(find.text('Find My Style'));
    await tester.pumpAndSettle();

    expect(find.text('1 of 12'), findsOneWidget);
    await tester.tap(find.byKey(const Key('skip-questionnaire-button')));
    await tester.pump();
    expect(skipped, 1);
  });
}
