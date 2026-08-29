import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/services/money_style_repository.dart';

void main() { test('round trips answer session and skips', () async { SharedPreferences.setMockInitialValues({}); final store=SharedPreferencesMoneyStyleRepository(); final value=MoneyStyleCompletion(session: AnswerSession(userId:'u',sessionId:'s',selectedAnswers:{1:0},skippedQuestions:{2}),result:null); await store.save(value); final loaded=await store.load(); expect(loaded!.session.selectedAnswers,{1:0}); expect(loaded.session.skippedQuestions,{2}); }); }
