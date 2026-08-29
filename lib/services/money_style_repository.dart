import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/money_style.dart';
import '../data/money_style_questions.dart';
import 'money_style_engine.dart';

abstract interface class MoneyStyleStore {
  Future<void> save(MoneyStyleCompletion completion);
  Future<MoneyStyleCompletion?> load();
  Future<void> clear();

  /// Remembers that the user chose to skip the questionnaire, so the app can
  /// offer to pick it up later instead of silently dropping it.
  Future<void> deferQuestionnaire();

  /// True when the user skipped and has not completed or dismissed it since.
  Future<bool> isQuestionnaireDeferred();

  /// Clears the "complete it later" state — on completion, or when the user
  /// dismisses the reminder.
  Future<void> clearDeferral();
}

class SharedPreferencesMoneyStyleRepository implements MoneyStyleStore {
  SharedPreferencesMoneyStyleRepository({
    Future<SharedPreferences>? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _key = 'money_style_completion_v1';
  static const _deferralKey = 'money_style_deferred_v1';

  /// Bumped for the v2 content pass: the 24-question pool has different
  /// question IDs and answer IDs, so a v1 payload cannot be read against it.
  static const questionVersion = 'money-style-v2';
  static const _schemaVersion = 3;

  final Future<SharedPreferences> _preferences;

  @override
  Future<void> save(MoneyStyleCompletion c) async {
    final encoded = jsonEncode({
      'schemaVersion': _schemaVersion,
      'questionVersion': questionVersion,
      'userId': c.session.userId,
      'sessionId': c.session.sessionId,
      'selectedAnswerIds': c.session.answerIdsFor(moneyStyleQuestionPool),
      'skippedQuestionIds': c.session.skippedQuestions.toList()..sort(),
      'shownQuestionIds': List<int>.from(c.session.shownQuestionIds),
    });
    await (await _preferences).setString(_key, encoded);
  }

  @override
  Future<MoneyStyleCompletion?> load() async {
    try {
      final raw = (await _preferences).getString(_key);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['schemaVersion'] != _schemaVersion ||
          map['questionVersion'] != questionVersion) {
        return null;
      }
      final answers = <int, int>{};
      for (final entry in (map['selectedAnswerIds'] as Map).entries) {
        final question = moneyStyleQuestionsById[int.parse('${entry.key}')];
        if (question == null) continue;
        final index = question.answers.indexWhere((a) => a.id == entry.value);
        if (index >= 0) answers[question.id] = index;
      }
      final session = AnswerSession(
        userId: map['userId'] as String,
        sessionId: map['sessionId'] as String,
        selectedAnswers: answers,
        skippedQuestions: (map['skippedQuestionIds'] as List)
            .cast<int>()
            .toSet(),
        shownQuestionIds: ((map['shownQuestionIds'] as List?) ?? const [])
            .cast<int>()
            .toList(),
      );
      return MoneyStyleCompletion(
        session: session,
        result: session.isCompleteFor(moneyStyleQuestionPool)
            ? const MoneyStyleEngine().generateResult(
                session,
                moneyStyleQuestionPool,
              )
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    await (await _preferences).remove(_key);
  }

  @override
  Future<void> deferQuestionnaire() async {
    await (await _preferences).setBool(_deferralKey, true);
  }

  @override
  Future<bool> isQuestionnaireDeferred() async {
    try {
      return (await _preferences).getBool(_deferralKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> clearDeferral() async {
    await (await _preferences).remove(_deferralKey);
  }
}
