// The ONLY place the Flutter app talks to the backend.
// Owner: Lane A (data). UI code calls these methods; it never builds URLs.
//
// Setup:
//   1. add to pubspec.yaml dependencies:   http: ^1.2.0
//   2. flutter pub get
//   3. run the backend:  cd "backend,dataAPI" && uvicorn main:app --port 8000
//
// Base URL by platform (see _defaultBase below):
//   Android emulator -> 10.0.2.2   (localhost on the host machine)
//   iOS sim / desktop / web -> localhost
//   Physical phone -> pass your laptop's LAN IP explicitly:
//       ApiClient(baseUrl: 'http://192.168.1.42:8000')

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});

  /// True when the backend has no profile yet — send the user to the survey.
  bool get needsSurvey => statusCode == 409;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Override at build time so the app can point at a deployed backend:
///   flutter run  --dart-define=API_BASE_URL=https://wealth-tower-api.onrender.com
///   flutter build web --dart-define=API_BASE_URL=https://...
const _envBase = String.fromEnvironment('API_BASE_URL');

String _defaultBase() {
  if (_envBase.isNotEmpty) return _envBase;
  if (kIsWeb) return 'http://localhost:8000';
  try {
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  } catch (_) {
    // Platform is unavailable on some targets; localhost is the safe default.
  }
  return 'http://localhost:8000';
}

class ApiClient {
  final String baseUrl;
  final Duration timeout;
  final http.Client _http;

  ApiClient({String? baseUrl, http.Client? client, this.timeout = const Duration(seconds: 15)})
      : baseUrl = baseUrl ?? _defaultBase(),
        _http = client ?? http.Client();

  void close() => _http.close();

  // ---------------------------------------------------------------- core

  Uri _uri(String path, [Map<String, dynamic>? query]) => Uri.parse('$baseUrl$path').replace(
        queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
      );

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? query, Object? body}) async {
    late http.Response r;
    try {
      final uri = _uri(path, query);
      final headers = {'Accept': 'application/json', if (body != null) 'Content-Type': 'application/json'};
      final encoded = body == null ? null : jsonEncode(body);
      r = await (switch (method) {
        'POST' => _http.post(uri, headers: headers, body: encoded),
        'DELETE' => _http.delete(uri, headers: headers),
        _ => _http.get(uri, headers: headers),
      })
          .timeout(timeout);
    } on TimeoutException {
      throw ApiException('The backend did not respond. Is uvicorn running on $baseUrl?');
    } catch (e) {
      throw ApiException('Could not reach the backend at $baseUrl. $e');
    }

    if (r.statusCode >= 400) {
      String msg = r.reasonPhrase ?? 'Request failed';
      try {
        final d = jsonDecode(r.body);
        if (d is Map && d['detail'] != null) msg = '${d['detail']}';
      } catch (_) {}
      throw ApiException(msg, statusCode: r.statusCode);
    }
    if (r.body.isEmpty) return null;
    return jsonDecode(r.body);
  }

  Future<Map<String, dynamic>> _getObj(String p, [Map<String, dynamic>? q]) async =>
      (await _send('GET', p, query: q)) as Map<String, dynamic>;

  Future<List<dynamic>> _getList(String p, [Map<String, dynamic>? q]) async =>
      (await _send('GET', p, query: q)) as List<dynamic>;

  // ---------------------------------------------------------------- survey

  Future<Profile> submitSurvey(SurveyAnswers a) async =>
      Profile.fromJson((await _send('POST', '/api/survey', body: a.toJson())) as Map<String, dynamic>);

  /// Throws ApiException with needsSurvey == true if the user hasn't done the survey.
  Future<Profile> profile() async => Profile.fromJson(await _getObj('/api/profile'));

  // ---------------------------------------------------------------- bank

  Future<ConnectionStatus> connectBank({String persona = 'Whistler'}) async =>
      ConnectionStatus.fromJson(
          (await _send('POST', '/api/bank/connect', body: {'persona': persona}))
              as Map<String, dynamic>);

  Future<List<Account>> accounts() async =>
      (await _getList('/api/bank/accounts')).map((e) => Account.fromJson(e)).toList();

  Future<List<Txn>> transactions({int days = 30}) async =>
      (await _getList('/api/bank/transactions', {'days': days}))
          .map((e) => Txn.fromJson(e))
          .toList();

  // ---------------------------------------------------------------- plan + game

  Future<Plan> plan({int days = 30}) async =>
      Plan.fromJson(await _getObj('/api/plan', {'days': days}));

  Future<List<Mission>> missions() async =>
      (await _getList('/api/missions')).map((e) => Mission.fromJson(e)).toList();

  Future<ClaimResult> claim(String missionId) async => ClaimResult.fromJson(
      (await _send('POST', '/api/missions/$missionId/claim')) as Map<String, dynamic>);

  Future<Progression> progression() async =>
      Progression.fromJson(await _getObj('/api/progression'));

  Future<TowerState> tower() async => TowerState.fromJson(await _getObj('/api/tower'));

  Future<List<ShopItem>> shop() async =>
      (await _getList('/api/shop')).map((e) => ShopItem.fromJson(e)).toList();

  Future<Progression> buy(String itemId) async => Progression.fromJson(
      (await _send('POST', '/api/shop/buy', body: {'item_id': itemId})) as Map<String, dynamic>);

  // ---------------------------------------------------------------- goals

  Future<List<Goal>> goals() async =>
      (await _getList('/api/goals')).map((e) => Goal.fromJson(e)).toList();

  /// [targetDate] is an ISO date: '2026-10-10'.
  Future<Goal> addGoal({
    required String name,
    required double targetAmount,
    required String targetDate,
    double savedSoFar = 0,
  }) async =>
      Goal.fromJson((await _send('POST', '/api/goals', body: {
        'name': name,
        'target_amount': targetAmount,
        'target_date': targetDate,
        'saved_so_far': savedSoFar,
      })) as Map<String, dynamic>);

  Future<Goal> contributeToGoal(String goalId, double amount) async =>
      Goal.fromJson((await _send('POST', '/api/goals/$goalId/contribute',
          query: {'amount': amount})) as Map<String, dynamic>);

  Future<void> deleteGoal(String goalId) =>
      _send('DELETE', '/api/goals/$goalId');

  // ---------------------------------------------------------------- demo

  Future<void> resetDemo() => _send('POST', '/api/demo/reset');

  /// Returns 'basiq', 'csv' or 'mock'. Check this before you walk on stage.
  Future<String> providerName() async =>
      (await _getObj('/api/health'))['provider'] as String;

  /// True only for a direct bank connection, where the user cannot have edited
  /// the data before we saw it. A CSV export is editable; mock data is invented.
  ///
  /// UI rule: when this is false, show a "demo data" banner and do NOT render
  /// any per-mission "verified by your bank" badge. Saying a mission was bank
  /// verified when it came from a file the user supplied is a lie.
  Future<bool> dataTrusted() async =>
      (await _getObj('/api/health'))['data_trusted'] as bool? ?? false;

  /// Upload a .csv or .pdf statement. Bytes go to our own backend only.
  Future<ConnectionStatus> uploadStatement(
      {required String filename, required List<int> bytes}) async {
    final req = http.MultipartRequest('POST', _uri('/api/bank/upload'))
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 400) {
      String msg = 'Upload failed';
      try {
        final d = jsonDecode(body);
        if (d is Map && d['detail'] != null) msg = '${d['detail']}';
      } catch (_) {}
      throw ApiException(msg, statusCode: streamed.statusCode);
    }
    return ConnectionStatus.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  /// Self-report a mission the transaction feed cannot see (cancelling a
  /// subscription, a daily streak). Claim stays locked until this is called.
  Future<Mission> markDone(String missionId) async => Mission.fromJson(
      (await _send('POST', '/api/missions/$missionId/mark_done'))
          as Map<String, dynamic>);

  // ---------------------------------------------------------------- convenience

  /// One round trip per screen is wasteful — the home screen needs all four.
  Future<HomeData> home({int days = 30}) async {
    final results = await Future.wait([
      plan(days: days),
      tower(),
      missions(),
      progression(),
    ]);
    return HomeData(
      plan: results[0] as Plan,
      tower: results[1] as TowerState,
      missions: results[2] as List<Mission>,
      progression: results[3] as Progression,
    );
  }
}

class HomeData {
  final Plan plan;
  final TowerState tower;
  final List<Mission> missions;
  final Progression progression;
  const HomeData({
    required this.plan,
    required this.tower,
    required this.missions,
    required this.progression,
  });
}
