import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/money_style.dart';
import '../data/money_style_questions.dart';
import 'money_style_engine.dart';

abstract interface class MoneyStyleStore { Future<void> save(MoneyStyleCompletion completion); Future<MoneyStyleCompletion?> load(); Future<void> clear(); }

class SharedPreferencesMoneyStyleRepository implements MoneyStyleStore {
  SharedPreferencesMoneyStyleRepository({Future<SharedPreferences>? preferences}) : _preferences = preferences ?? SharedPreferences.getInstance();
  static const _key = 'money_style_completion_v1';
  final Future<SharedPreferences> _preferences;
  @override Future<void> save(MoneyStyleCompletion c) async { await (await _preferences).setString(_key, jsonEncode({'schemaVersion': 2, 'questionVersion': 'money-style-v1', 'userId': c.session.userId, 'sessionId': c.session.sessionId, 'selectedAnswerIds': c.session.answerIdsFor(moneyStyleQuestions), 'skippedQuestionIds': c.session.skippedQuestions.toList()})); }
  @override Future<MoneyStyleCompletion?> load() async { try { final raw = (await _preferences).getString(_key); if(raw == null) return null; final map=jsonDecode(raw) as Map<String,dynamic>; if(map['schemaVersion'] != 2 || map['questionVersion'] != 'money-style-v1') return null; final answers=<int,int>{}; for(final entry in (map['selectedAnswerIds'] as Map).entries) { final q=moneyStyleQuestions.firstWhere((q)=>q.id==int.parse('${entry.key}')); final index=q.answers.indexWhere((a)=>a.id==entry.value); if(index >= 0) answers[q.id]=index; } final session=AnswerSession(userId: map['userId'] as String, sessionId: map['sessionId'] as String, selectedAnswers: answers, skippedQuestions: (map['skippedQuestionIds'] as List).cast<int>().toSet()); return MoneyStyleCompletion(session:session,result:MoneyStyleEngine().generateResult(session,moneyStyleQuestions)); } catch (_) { return null; } }
  @override Future<void> clear() async { await (await _preferences).remove(_key); }
}
