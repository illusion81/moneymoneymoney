import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data/api_client.dart';
import 'data/models.dart';
import 'data/survey_adapter.dart';
import 'models/finance_profile.dart';
import 'models/forest_day.dart';
import 'models/home_layout.dart';
import 'models/money_style.dart';
import 'models/progression.dart';
import 'models/shop_item.dart';
import 'models/wealth_report.dart';
import 'screens/achievements_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/home_screen.dart';
import 'screens/homestead_screen.dart';
import 'screens/money_style_flow.dart';
import 'screens/money_style_result_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/report_screen.dart';
import 'screens/shop_screen.dart';
import 'services/bank_spending_service.dart';
import 'services/forest_engine.dart';
import 'services/home_layout_service.dart';
import 'services/progression_engine.dart';
import 'services/report_generator.dart';
import 'services/shop_service.dart';

void main() {
  runApp(const MyApp());
}

enum AppView {
  onboarding,
  moneyStyleFlow,
  moneyStyleResult,
  report,
  forest,
  calendar,
  homestead,
  achievements,
  shop,
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ForestEngine _forestEngine = ForestEngine();
  final ProgressionEngine _progressionEngine = ProgressionEngine();
  final ShopService _shopService = ShopService();
  final HomeLayoutService _homeLayoutService = HomeLayoutService();
  final ApiClient _apiClient = ApiClient();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  WealthReport? _report;
  MoneyStyleResult? _moneyStyleResult;
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
  late HomeLayoutState _homeLayout;
  final List<RewardEvent> _spendEvents = [];
  AppView _view = AppView.onboarding;
  String? _lastEarnedSummary;
  bool _planStarted = false;

  _MyAppState() {
    _shopState = _shopService.initialState();
    _homeLayout = _homeLayoutService.initialState();
    if (kDebugMode) {
      // Debug builds start with an effectively unlimited coin balance so
      // the shop/homestead can be tested without grinding for coins.
      _spendEvents.add(
        RewardEvent(
          date: DateTime.now(),
          type: RewardEventType.debugGrant,
          xp: 0,
          coins: 999999,
          description: 'Debug: max coins',
        ),
      );
    }
    _progression = _progressionEngine.compute(
      days: const [],
      achievements: const [],
      spendEvents: _spendEvents,
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

  @override
  void dispose() {
    _apiClient.close();
    super.dispose();
  }

  Widget _buildCurrentView() {
    final report = _report;

    switch (_view) {
      case AppView.onboarding:
        return OnboardingScreen(
          onProfileSubmitted: _handleProfileSubmitted,
          onStartMoneyStyleQuiz: _startMoneyStyleQuiz,
        );
      case AppView.moneyStyleFlow:
        return MoneyStyleFlow(
          userId: 'user-1', // TODO: Replace with actual user ID
          onComplete: _handleMoneyStyleComplete,
        );
      case AppView.moneyStyleResult:
        return MoneyStyleResultScreen(result: _moneyStyleResult!);
      case AppView.report:
        if (report == null) {
          return OnboardingScreen(
            onProfileSubmitted: _handleProfileSubmitted,
            onStartMoneyStyleQuiz: _startMoneyStyleQuiz,
          );
        }
        return ReportScreen(
          report: report,
          onStartPlan: _startPlan,
          onShowForest: _planStarted
              ? () => setState(() => _view = AppView.forest)
              : null,
        );
      case AppView.forest:
        if (report == null) {
          return OnboardingScreen(
            onProfileSubmitted: _handleProfileSubmitted,
            onStartMoneyStyleQuiz: _startMoneyStyleQuiz,
          );
        }
        return HomeScreen(
          report: report,
          summary: _summary,
          progression: _progression,
          shopState: _shopState,
          lastEarnedSummary: _lastEarnedSummary,
          onCheckIn: _handleCheckIn,
          onRestore: _handleRestore,
          onShowReport: () => setState(() => _view = AppView.report),
          onRetakeQuestionnaire: () =>
              setState(() => _view = AppView.onboarding),
          onShowAchievements: () =>
              setState(() => _view = AppView.achievements),
          onShowShop: () => setState(() => _view = AppView.shop),
          onShowCalendar: () => setState(() => _view = AppView.calendar),
          onShowHomestead: () => setState(() => _view = AppView.homestead),
          onFetchTodaySpending: _fetchTodaySpending,
          api: _apiClient,
        );
      case AppView.calendar:
        return CalendarScreen(
          summary: _summary,
          shopState: _shopState,
          onShowForest: () => setState(() => _view = AppView.forest),
          onShowHomestead: () => setState(() => _view = AppView.homestead),
          onShowReport: () => setState(() => _view = AppView.report),
          onShowAchievements: () =>
              setState(() => _view = AppView.achievements),
          onShowShop: () => setState(() => _view = AppView.shop),
        );
      case AppView.homestead:
        return HomesteadScreen(
          shopState: _shopState,
          layout: _homeLayout,
          days: _summary.days,
          onPlace: _handlePlaceDecoration,
          onRemove: _handleRemoveDecoration,
          onShowForest: () => setState(() => _view = AppView.forest),
          onShowCalendar: () => setState(() => _view = AppView.calendar),
          onShowReport: () => setState(() => _view = AppView.report),
          onShowAchievements: () =>
              setState(() => _view = AppView.achievements),
          onShowShop: () => setState(() => _view = AppView.shop),
          onExportImage: _handleExportImage,
        );
      case AppView.achievements:
        if (report == null) {
          return OnboardingScreen(
            onProfileSubmitted: _handleProfileSubmitted,
            onStartMoneyStyleQuiz: _startMoneyStyleQuiz,
          );
        }
        return AchievementsScreen(
          summary: _summary,
          progression: _progression,
          onShowForest: () => setState(() => _view = AppView.forest),
          onShowCalendar: () => setState(() => _view = AppView.calendar),
          onShowHomestead: () => setState(() => _view = AppView.homestead),
        );
      case AppView.shop:
        if (report == null) {
          return OnboardingScreen(
            onProfileSubmitted: _handleProfileSubmitted,
            onStartMoneyStyleQuiz: _startMoneyStyleQuiz,
          );
        }
        return ShopScreen(
          progression: _progression,
          shopState: _shopState,
          onPurchase: _handlePurchase,
          onEquip: _handleEquip,
          onBack: () => setState(() => _view = AppView.forest),
          onDebugMaxCoins: _handleDebugMaxCoins,
          onDebugUnlockAll: _handleDebugUnlockAll,
        );
    }
  }

  /// Send the questionnaire to the backend as well as computing locally, so
  /// the plan, missions and tower all come from the same answers. Fire and
  /// forget: if the backend is down the app still works on local data.
  void _pushProfileToBackend(FinanceProfile profile) {
    _apiClient.submitSurvey(profile.toSurveyAnswers()).catchError((e) {
      debugPrint('Survey not sent to backend: $e');
      return Future<Profile>.error(e);
    }).ignore();
  }

  void _handleProfileSubmitted(FinanceProfile profile) {
    _pushProfileToBackend(profile);
    final alreadyStarted = _planStarted;
    setState(() {
      _report = ReportGenerator().generate(profile);
      _summary = _forestEngine.summarize(
        _summary.days,
        progression: _progression,
        shopState: _shopState,
      );
      _view = AppView.report;
      _planStarted = alreadyStarted;
    });
  }

  void _startMoneyStyleQuiz() {
    setState(() {
      _view = AppView.moneyStyleFlow;
    });
  }

  void _handleMoneyStyleComplete(MoneyStyleResult result) {
    setState(() {
      _moneyStyleResult = result;
      _view = AppView.moneyStyleResult;
    });
  }

  void _startPlan() {
    setState(() {
      _planStarted = true;
      _view = AppView.forest;
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

  void _handlePlaceDecoration(String itemId, int row, int col) {
    setState(() {
      _homeLayout = _homeLayoutService.place(
        state: _homeLayout,
        itemId: itemId,
        row: row,
        col: col,
      );
    });
  }

  void _handleRemoveDecoration(String itemId) {
    setState(() {
      _homeLayout = _homeLayoutService.remove(
        state: _homeLayout,
        itemId: itemId,
      );
    });
  }

  Future<void> _handleExportImage(Uint8List pngBytes) async {
    final home =
        Platform.environment['USERPROFILE'] ??
        Platform.environment['HOME'] ??
        '.';
    final picturesDir = Directory('$home${Platform.pathSeparator}Pictures');
    if (!await picturesDir.exists()) {
      await picturesDir.create(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${picturesDir.path}${Platform.pathSeparator}homestead_$timestamp.png',
    );
    await file.writeAsBytes(pngBytes);
    _showMessage('Saved to ${file.path}');
  }

  Future<double> _fetchTodaySpending() async {
    final transactions = await _apiClient.transactions(days: 7);
    return sumTodaySpending(transactions);
  }

  void _handleDebugMaxCoins() {
    setState(() {
      _spendEvents.add(
        RewardEvent(
          date: DateTime.now(),
          type: RewardEventType.debugGrant,
          xp: 0,
          coins: 999999,
          description: 'Debug: max coins',
        ),
      );
      _recomputeProgression();
    });
  }

  void _handleDebugUnlockAll() {
    setState(() {
      _shopState = ShopState(
        ownedItemIds: {for (final item in kShopCatalog) item.id},
        equippedItemIds: _shopState.equippedItemIds,
      );
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
    assert(
      stable,
      'Progression/achievement convergence did not reach fixed point within 6 passes',
    );
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
