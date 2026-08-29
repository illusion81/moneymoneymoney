import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moneymoneymoney/data/api_client.dart';
import 'package:moneymoneymoney/data/models.dart';

void main() { test('posts behavioural fields only', () async { late http.Request request; final client=ApiClient(baseUrl:'http://x',client:MockClient((r) async { request=r; return http.Response(r.body,200,headers:{'content-type':'application/json'}); })); final value=MoneyStyleSubmission(sessionId:'s',questionVersion:'money-style-v1',selectedAnswers:{'1':'q01_plan'},skippedQuestionIds:[2],answeredCount:1); await client.submitMoneyStyle(value); expect(request.url.path,'/api/money-style'); expect(request.body, isNot(contains('monthly_income'))); }); }
