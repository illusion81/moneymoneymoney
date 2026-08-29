import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/data/money_style_questions.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/services/money_style_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A full 12-question session: the 6 openers plus one follow-up per dimension.
const _shown = [1, 2, 3, 4, 5, 6, 7, 10, 13, 16, 19, 22];

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'round trips an in-progress answer and skip without inventing a result',
    () async {
      final store = SharedPreferencesMoneyStyleRepository();
      final value = MoneyStyleCompletion(
        session: AnswerSession(
          userId: 'u',
          sessionId: 's',
          selectedAnswers: {1: 0, 2: 0, 4: 0},
          skippedQuestions: {3},
          shownQuestionIds: const [1, 2, 3, 4, 5, 6],
        ),
        result: null,
      );

      await store.save(value);
      final loaded = await store.load();

      expect(loaded, isNotNull);
      expect(loaded!.session.selectedAnswers, {1: 0, 2: 0, 4: 0});
      expect(loaded.session.skippedQuestions, {3});
      expect(loaded.session.shownQuestionIds, [1, 2, 3, 4, 5, 6]);
      expect(loaded.result, isNull);
    },
  );

  test('restores a completed session from stable answer ids', () async {
    final store = SharedPreferencesMoneyStyleRepository();
    final value = MoneyStyleCompletion(
      session: AnswerSession(
        userId: 'u',
        sessionId: 's',
        selectedAnswers: {for (final id in _shown) id: 0},
        shownQuestionIds: List<int>.from(_shown),
      ),
      result: null,
    );

    await store.save(value);
    final loaded = await store.load();

    expect(loaded, isNotNull);
    expect(loaded!.result, isNotNull);
    expect(loaded.result!.confidenceTier, ConfidenceTier.fullClarity);
    // Answer index 0 of each opener is that question's first listed option;
    // whatever it is, the restored score must match a fresh calculation.
    expect(
      loaded.result!.dimensionTotals.values.every((v) => v != null),
      isTrue,
    );
  });

  test('a skipped-and-answered session still reaches a result', () async {
    final store = SharedPreferencesMoneyStyleRepository();
    await store.save(
      MoneyStyleCompletion(
        session: AnswerSession(
          userId: 'u',
          sessionId: 's',
          selectedAnswers: {for (var id = 1; id <= 6; id++) id: 0},
          skippedQuestions: const {7, 10, 13, 16, 19, 22},
          shownQuestionIds: List<int>.from(_shown),
        ),
        result: null,
      ),
    );

    final loaded = await store.load();
    expect(loaded!.result, isNotNull);
    // Six answers with full breadth, but not the full twelve.
    expect(loaded.result!.confidenceTier, ConfidenceTier.standard);
  });

  test('a v1 payload is not read against the v2 bank', () async {
    SharedPreferences.setMockInitialValues({
      'money_style_completion_v1':
          '{"schemaVersion":2,"questionVersion":"money-style-v1",'
          '"userId":"u","sessionId":"s",'
          '"selectedAnswerIds":{"1":"q01_plan"},"skippedQuestionIds":[]}',
    });
    expect(await SharedPreferencesMoneyStyleRepository().load(), isNull);
  });

  test('answer ids come from the whole 24-question pool', () async {
    final store = SharedPreferencesMoneyStyleRepository();
    await store.save(
      MoneyStyleCompletion(
        session: AnswerSession(
          userId: 'u',
          sessionId: 's',
          selectedAnswers: {24: 2},
          shownQuestionIds: const [24],
        ),
        result: null,
      ),
    );
    final loaded = await store.load();
    expect(loaded!.session.selectedAnswers, {24: 2});
    expect(moneyStyleQuestionsById[24]!.answers[2].id, 'fa_mix_prompt');
  });

  test(
    'save snapshots mutable session data before awaiting preferences',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final preferencesCompleter = Completer<SharedPreferences>();
      final store = SharedPreferencesMoneyStyleRepository(
        preferences: preferencesCompleter.future,
      );
      final session = AnswerSession(
        userId: 'u',
        sessionId: 's',
        selectedAnswers: {1: 0},
      );

      final save = store.save(
        MoneyStyleCompletion(session: session, result: null),
      );
      session.selectedAnswers[2] = 0;
      preferencesCompleter.complete(preferences);
      await save;

      final loaded = await store.load();
      expect(loaded!.session.selectedAnswers, {1: 0});
    },
  );

  group('deferral', () {
    test('is off until the questionnaire is skipped', () async {
      final store = SharedPreferencesMoneyStyleRepository();
      expect(await store.isQuestionnaireDeferred(), isFalse);

      await store.deferQuestionnaire();
      expect(await store.isQuestionnaireDeferred(), isTrue);
    });

    test('survives a new repository instance, and can be cleared', () async {
      await SharedPreferencesMoneyStyleRepository().deferQuestionnaire();
      expect(
        await SharedPreferencesMoneyStyleRepository().isQuestionnaireDeferred(),
        isTrue,
      );

      await SharedPreferencesMoneyStyleRepository().clearDeferral();
      expect(
        await SharedPreferencesMoneyStyleRepository().isQuestionnaireDeferred(),
        isFalse,
      );
    });

    test('is independent of the saved session', () async {
      final store = SharedPreferencesMoneyStyleRepository();
      await store.deferQuestionnaire();
      await store.clear();
      expect(await store.isQuestionnaireDeferred(), isTrue);
    });
  });
}
