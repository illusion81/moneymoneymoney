import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/money_style.dart';
import '../data/money_style_archetypes.dart';

abstract interface class MoneyStyleStore { Future<void> save(MoneyStyleCompletion completion); Future<MoneyStyleCompletion?> load(); Future<void> clear(); }

class SharedPreferencesMoneyStyleRepository implements MoneyStyleStore {
  SharedPreferencesMoneyStyleRepository({Future<SharedPreferences>? preferences}) : _preferences = preferences ?? SharedPreferences.getInstance();
  static const _key = 'money_style_completion_v1';
  final Future<SharedPreferences> _preferences;
  @override Future<void> save(MoneyStyleCompletion c) async { await (await _preferences).setString(_key, jsonEncode({'schemaVersion': 1, 'userId': c.session.userId, 'sessionId': c.session.sessionId, 'selectedAnswers': c.session.selectedAnswers.map((k,v)=>MapEntry('$k',v)), 'skippedQuestionIds': c.session.skippedQuestions.toList(), 'pattern': c.result?.archetype.pattern, 'tier': c.result?.confidenceTier.name})); }
  @override Future<MoneyStyleCompletion?> load() async { try { final raw = (await _preferences).getString(_key); if(raw == null) return null; final map=jsonDecode(raw) as Map<String,dynamic>; if(map['schemaVersion'] != 1) return null; final session=AnswerSession(userId: map['userId'] as String, sessionId: map['sessionId'] as String, selectedAnswers: (map['selectedAnswers'] as Map).map((k,v)=>MapEntry(int.parse('$k'),v as int)), skippedQuestions: (map['skippedQuestionIds'] as List).cast<int>().toSet()); final pattern=map['pattern'] as String?; if(pattern==null)return MoneyStyleCompletion(session:session,result:null); final a=archetypeMap.values.firstWhere((a)=>a.pattern==pattern); return MoneyStyleCompletion(session:session,result:MoneyStyleResult(archetype:a,confidenceTier:ConfidenceTier.values.byName(map['tier'] as String),dimensionScores:DimensionScores(),moneyRhythmWinner:MoneyRhythmPole.steady,decisionStyleWinner:DecisionStylePole.pause,supportStyleWinner:SupportStylePole.selfDirected,totalAnswered:session.totalAnswered)); } catch (_) { return null; } }
  @override Future<void> clear() async { await (await _preferences).remove(_key); }
}
