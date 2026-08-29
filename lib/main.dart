import 'package:flutter/material.dart';

import 'models/finance_profile.dart';
import 'models/forest_day.dart';
import 'models/progression.dart';
import 'models/shop_item.dart';
import 'models/wealth_report.dart';
import 'screens/achievements_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/report_screen.dart';
import 'screens/shop_screen.dart';
import 'services/forest_engine.dart';
import 'services/progression_engine.dart';
import 'services/report_generator.dart';
import 'services/shop_service.dart';

void main() {
  runApp(const MyApp());
}

enum AppView { onboarding, report, home, achievements, shop }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ForestEngine _forestEngine = ForestEngine();
  final ProgressionEngine _progressionEngine = ProgressionEngine();
  final ShopService _shopService = ShopService();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  WealthReport? _report;
  ForestSummary _summary = const ForestSummary(
    days: [],
    currentStreak: 0,
    healthyTreeCount: 0,
    witheredTreeCount: 0,
    restoredTreeCount: 0,
    achievements: [],
  );
  late ProgressionState _progression;
  late ShopState _shopState;
  final List<RewardEvent> _spendEvents = [];
  AppView _view = AppView.onboarding;
  String? _lastEarnedSummary;
  bool _planStarted = false;

  _MyAppState() {
    _shopState = _shopService.initialState();
    _progression = _progressionEngine.compute(
      days: const [],
      achievements: const [],
      spendEvents: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Money Money',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff2f7d50)),
        scaffoldBackgroundColor: const Color(0xfff5f1e8),
        useMaterial3: true,
      ),
      home: _buildCurrentView(),
    );
  }

  Widget _buildCurrentView() {
    final report = _report;
    if (report == null || _view == AppView.onboarding) {
      return OnboardingScreen(onProfileSubmitted: _handleProfileSubmitted);
    }

    switch (_view) {
      case AppView.onboarding:
        return OnboardingScreen(onProfileSubmitted: _handleProfileSubmitted);
      case AppView.report:
        return ReportScreen(
          report: report,
          onStartPlan: _startPlan,
          onShowForest: _planStarted
              ? () => setState(() => _view = AppView.home)
              : null,
        );
      case AppView.home:
        return HomeScreen(
          report: report,
          summary: _summary,
          progression: _progression,
          shopState: _shopState,
          lastEarnedSummary: _lastEarnedSummary,
          onCheckIn: _handleCheckIn,
          onRestore: _handleRestore,
          onShowReport: () => setState(() => _view = AppView.report),
          onShowAchievements: () =>
              setState(() => _view = AppView.achievements),
          onShowShop: () => setState(() => _view = AppView.shop),
        );
      case AppView.achievements:
        return AchievementsScreen(
          summary: _summary,
          progression: _progression,
          onBack: () => setState(() => _view = AppView.home),
        );
      case AppView.shop:
        return ShopScreen(
          progression: _progression,
          shopState: _shopState,
          onPurchase: _handlePurchase,
          onEquip: _handleEquip,
          onBack: () => setState(() => _view = AppView.home),
        );
    }
  }

  void _handleProfileSubmitted(FinanceProfile profile) {
    setState(() {
      _report = ReportGenerator().generate(profile);
      _summary = _forestEngine.summarize(
        const [],
        progression: _progression,
        shopState: _shopState,
      );
      _view = AppView.report;
      _planStarted = false;
    });
  }

  void _startPlan() {
    setState(() {
      _planStarted = true;
      _view = AppView.home;
    });
  }

  void _handleCheckIn({
    required double spending,
    required bool actionCompleted,
  }) {
    final report = _report;
    if (report == null) {
      return;
    }

    final result = _forestEngine.checkIn(
      existingDays: _summary.days,
      report: report,
      date: DateTime.now(),
      spending: spending,
      actionCompleted: actionCompleted,
    );

    final beforeXp = _progression.totalXp;
    final beforeCoins = _progression.coinBalance;

    setState(() {
      _summary = result.summary;
      _recomputeProgression();
      final earnedXp = _progression.totalXp - beforeXp;
      final earnedCoins = _progression.coinBalance - beforeCoins;
      _lastEarnedSummary = '+$earnedXp XP, +$earnedCoins coins';
    });
  }

  void _handleRestore(String recoveryNote) {
    final result = _forestEngine.restoreDay(
      days: _summary.days,
      dayDate: _summary.days.isEmpty ? DateTime.now() : _summary.days.last.date,
      now: DateTime.now(),
      recoveryNote: recoveryNote,
      coinBalance: _progression.coinBalance,
    );

    if (!result.success) {
      _showMessage(result.failureReason ?? 'Restoration failed.');
      return;
    }

    setState(() {
      _summary = result.summary;
      if (result.spendEvent != null) {
        _spendEvents.add(result.spendEvent!);
      }
      _recomputeProgression();
    });
  }

  void _handlePurchase(String itemId) {
    final result = _shopService.purchase(
      itemId: itemId,
      state: _shopState,
      progression: _progression,
    );

    if (!result.success) {
      _showMessage(result.message);
      return;
    }

    setState(() {
      _shopState = result.state;
      _spendEvents.add(result.progression.ledger.last);
      _recomputeProgression();
    });
    _showMessage(result.message);
  }

  void _handleEquip(String itemId) {
    setState(() {
      _shopState = _shopService.equip(itemId: itemId, state: _shopState);
    });
  }

  /// Recomputes progression and the achievement-derived parts of the summary
  /// together, since Curator and Seedling Scholar depend on progression and
  /// achievement-unlock rewards feed back into progression. A few passes are
  /// enough for this to reach a fixed point.
  void _recomputeProgression() {
    var achievements = _summary.achievements;
    var stable = false;
    for (var pass = 0; pass < 6; pass++) {
      final newProgression = _progressionEngine.compute(
        days: _summary.days,
        achievements: achievements,
        spendEvents: _spendEvents,
      );
      final newSummary = _forestEngine.summarize(
        _summary.days,
        progression: newProgression,
        shopState: _shopState,
      );
      stable =
          newProgression.totalXp == _progression.totalXp &&
          _sameUnlockState(newSummary.achievements, achievements);

      _progression = newProgression;
      _summary = newSummary;
      achievements = newSummary.achievements;

      if (stable) {
        break;
      }
    }
    assert(stable, 'Progression/achievement convergence did not reach fixed point within 6 passes');
  }

  bool _sameUnlockState(List<Achievement> a, List<Achievement> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].unlocked != b[i].unlocked) {
        return false;
      }
    }
    return true;
  }

  void _showMessage(String message) {
    _messengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }
}
