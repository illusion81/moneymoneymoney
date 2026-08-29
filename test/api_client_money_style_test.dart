import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moneymoneymoney/data/api_client.dart';
import 'package:moneymoneymoney/data/models.dart';
import 'package:moneymoneymoney/data/money_style_archetypes.dart';
import 'package:moneymoneymoney/models/money_style.dart';

MoneyStyleCompletion _completion({
  required ConfidenceTier tier,
  required int answered,
}) => MoneyStyleCompletion(
  session: AnswerSession(
    userId: 'u',
    sessionId: 's',
    selectedAnswers: {1: 0},
    shownQuestionIds: const [1, 2, 3, 4, 5, 6, 7, 10, 13, 16, 19, 22],
  ),
  result: MoneyStyleResult(
    archetype: archetypeMap['watch_watch_watch']!,
    confidenceTier: tier,
    dimensionScores: DimensionScores(),
    totalAnswered: answered,
  ),
);

void main() {
  test('posts behavioural fields only', () async {
    late http.Request request;
    final client = ApiClient(
      baseUrl: 'http://x',
      client: MockClient((r) async {
        request = r;
        return http.Response(
          r.body,
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final value = MoneyStyleSubmission(
      sessionId: 's',
      questionVersion: MoneyStyleSubmission.currentQuestionVersion,
      selectedAnswers: {'1': 'rd_open_minimum'},
      skippedQuestionIds: [2],
      shownQuestionIds: [1, 2],
      answeredCount: 1,
    );

    await client.submitMoneyStyle(value);

    expect(request.url.path, '/api/money-style');
    expect(request.body, isNot(contains('monthly_income')));
    expect(jsonDecode(request.body)['shown_question_ids'], [1, 2]);
  });

  test('maps tier names and carries the archetype id and shown questions', () {
    for (final tier in ConfidenceTier.values) {
      final answered = switch (tier) {
        ConfidenceTier.earlySnapshot => 3,
        ConfidenceTier.standard => 6,
        ConfidenceTier.fullClarity => 12,
      };
      final value = MoneyStyleSubmission.fromCompletion(
        _completion(tier: tier, answered: answered),
      );

      expect(value.confidenceTier, switch (tier) {
        ConfidenceTier.earlySnapshot => 'early_snapshot',
        ConfidenceTier.standard => 'standard',
        ConfidenceTier.fullClarity => 'full_clarity',
      });
      expect(value.archetypeId, 'watch_watch_watch');
      expect(value.questionVersion, 'money-style-v2');
      expect(value.selectedAnswers['1'], 'rd_open_minimum');
      expect(value.shownQuestionIds, hasLength(12));
    }
  });

  test('a submission round trips through json', () {
    final value = MoneyStyleSubmission.fromCompletion(
      _completion(tier: ConfidenceTier.fullClarity, answered: 12),
    );
    final decoded = MoneyStyleSubmission.fromJson(value.toJson());

    expect(decoded.shownQuestionIds, value.shownQuestionIds);
    expect(decoded.archetypeId, value.archetypeId);
    expect(decoded.questionVersion, value.questionVersion);
  });
}
