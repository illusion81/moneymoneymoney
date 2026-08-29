import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/services/money_style_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        ),
        result: null,
      );

      await store.save(value);
      final loaded = await store.load();

      expect(loaded, isNotNull);
      expect(loaded!.session.selectedAnswers, {1: 0, 2: 0, 4: 0});
      expect(loaded.session.skippedQuestions, {3});
      expect(loaded.result, isNull);
    },
  );

  test('restores a completed early snapshot from stable answer ids', () async {
    final store = SharedPreferencesMoneyStyleRepository();
    final value = MoneyStyleCompletion(
      session: AnswerSession(
        userId: 'u',
        sessionId: 's',
        selectedAnswers: {1: 0, 2: 0, 4: 0},
        skippedQuestions: {3, 5, 6, 7, 8, 9, 10, 11, 12},
      ),
      result: null,
    );

    await store.save(value);
    final loaded = await store.load();

    expect(loaded, isNotNull);
    expect(loaded!.result, isNotNull);
    expect(loaded.result!.confidenceTier, ConfidenceTier.earlySnapshot);
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
}
