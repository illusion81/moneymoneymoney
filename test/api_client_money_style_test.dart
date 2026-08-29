import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moneymoneymoney/data/api_client.dart';
import 'package:moneymoneymoney/data/models.dart';
import 'package:moneymoneymoney/data/money_style_archetypes.dart';
import 'package:moneymoneymoney/models/money_style.dart';

void main() { test('posts behavioural fields only', () async { late http.Request request; final client=ApiClient(baseUrl:'http://x',client:MockClient((r) async { request=r; return http.Response(r.body,200,headers:{'content-type':'application/json'}); })); final value=MoneyStyleSubmission(sessionId:'s',questionVersion:'money-style-v1',selectedAnswers:{'1':'q01_plan'},skippedQuestionIds:[2],answeredCount:1); await client.submitMoneyStyle(value); expect(request.url.path,'/api/money-style'); expect(request.body, isNot(contains('monthly_income'))); });
test('maps early standard and full tier names', () { for (final tier in ConfidenceTier.values) { final result=MoneyStyleResult(archetype:archetypeMap['steady_pause_self']!,confidenceTier:tier,dimensionScores:DimensionScores(),moneyRhythmWinner:MoneyRhythmPole.steady,decisionStyleWinner:DecisionStylePole.pause,supportStyleWinner:SupportStylePole.selfDirected,totalAnswered: tier==ConfidenceTier.earlySnapshot?3:tier==ConfidenceTier.standard?4:9); final value=MoneyStyleSubmission.fromCompletion(MoneyStyleCompletion(session:AnswerSession(userId:'u',sessionId:'s',selectedAnswers:{1:0}),result:result)); expect(value.confidenceTier, tier==ConfidenceTier.earlySnapshot?'early_snapshot':tier==ConfidenceTier.standard?'standard':'full_clarity'); expect(value.archetypeId,'steady_pause_self'); expect(value.selectedAnswers['1'],'q01_plan'); } }); }
