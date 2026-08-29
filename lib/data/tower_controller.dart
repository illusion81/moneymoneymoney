// Auto-sync for the UI. Lane C: you do not write API calls or refresh logic —
// you listen to this and rebuild.
//
//   final state = TowerController(api: ApiClient());
//   ...
//   ChangeNotifierProvider.value(value: state)          // or just pass it down
//   AnimatedBuilder(animation: state, builder: (_, __) => ...)
//
// It refreshes on: first load, app resume, pull-to-refresh, and after any
// action that changes server state (claim, mark done, buy).

import 'package:flutter/widgets.dart';

import 'api_client.dart';
import 'models.dart';

class TowerController extends ChangeNotifier with WidgetsBindingObserver {
  final ApiClient api;

  TowerController({required this.api}) {
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  Plan? plan;
  TowerState? tower;
  List<Mission> missions = const [];
  Progression? progression;
  Profile? profile;

  bool loading = false;
  bool needsSurvey = false;
  String? error;

  /// 'basiq' | 'csv' | 'mock'
  String provider = 'mock';

  /// False for CSV and mock. When false the UI must show a "demo data" banner
  /// and must NOT show any per-mission "verified by your bank" badge.
  bool dataTrusted = false;

  DateTime? lastSynced;

  /// Re-sync when the user comes back to the app. This is what makes the tower
  /// feel alive: they open it and their spending has already moved it, with no
  /// logging and no button.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();

    try {
      provider = await api.providerName();
      dataTrusted = await api.dataTrusted();

      try {
        profile = await api.profile();
        needsSurvey = false;
      } on ApiException catch (e) {
        if (e.needsSurvey) {
          needsSurvey = true;
          return; // no profile yet — send them to the survey
        }
        rethrow;
      }

      final home = await api.home();
      plan = home.plan;
      tower = home.tower;
      missions = home.missions;
      progression = home.progression;
      lastSynced = DateTime.now();
    } on ApiException catch (e) {
      error = e.message;
    } catch (e) {
      error = 'Something went wrong: $e';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> submitSurvey(SurveyAnswers a) async {
    profile = await api.submitSurvey(a);
    needsSurvey = false;
    await api.connectBank();
    await refresh();
  }

  /// Returns the claim result so the UI can fire the level-up animation,
  /// then re-syncs so the tower reflects the new level.
  Future<ClaimResult> claim(String missionId) async {
    final r = await api.claim(missionId);
    await refresh();
    return r;
  }

  Future<void> markDone(String missionId) async {
    await api.markDone(missionId);
    await refresh();
  }

  Future<void> buy(String itemId) async {
    progression = await api.buy(itemId);
    await refresh();
  }

  // ---- convenience for the UI ----

  bool get ready => plan != null && tower != null && progression != null;

  List<Mission> get claimable =>
      missions.where((m) => m.complete && !m.claimed).toList();

  String get syncLabel {
    if (loading) return 'Syncing…';
    if (lastSynced == null) return '';
    final secs = DateTime.now().difference(lastSynced!).inSeconds;
    if (secs < 60) return 'Synced just now';
    final mins = secs ~/ 60;
    return mins < 60 ? 'Synced ${mins}m ago' : 'Synced ${mins ~/ 60}h ago';
  }
}
