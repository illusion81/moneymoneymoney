import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'data/api_client.dart';
import 'data/models.dart';
import 'data/money_style_questions.dart';
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
import 'screens/money_style_ideas_screen.dart';
import 'screens/plan_range_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/report_screen.dart';
import 'screens/plus_screen.dart';
import 'screens/diamond_store_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/spending_screen.dart';
import 'services/bank_spending_service.dart';
import 'services/forest_engine.dart';
import 'services/home_layout_service.dart';
import 'services/profile_suggestions.dart';
import 'services/progression_engine.dart';
import 'services/report_generator.dart';
import 'services/risk_assessment.dart' show RiskLevel;
import 'services/ad_service.dart';
import 'services/payment_service.dart';
import 'services/shop_service.dart';
import 'services/money_style_repository.dart';
import 'widgets/level_up_overlay.dart';
import 'widgets/celebration_dialog.dart';

void main() {
  runApp(const MyApp());
}

enum AppView {
  onboarding,
  moneyStyleFlow,
  moneyStyleResult,
  moneyStyleIdeas,
  rangePlan,
  report,
  forest,
  calendar,
  spending,
  plus,
  homestead,
  achievements,
  shop,
  diamonds,
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.apiClient,
    this.moneyStyleStore,
    this.showOnboardingInitially = false,
  });
  final ApiClient? apiClient;
  final MoneyStyleStore? moneyStyleStore;
  final bool showOnboardingInitially;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ForestEngine _forestEngine = ForestEngine();
  final ProgressionEngine _progressionEngine = ProgressionEngine();
  final ShopService _shopService = ShopService();
  final HomeLayoutService _homeLayoutService = HomeLayoutService();
  late final ApiClient _apiClient;
  late final MoneyStyleStore _moneyStyleStore;
  Future<void> _moneyStyleWrites = Future<void>.value();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  // The messenger's context sits above the Navigator, so dialogs need their
  // own key to push a route from.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  WealthReport? _report;

  /// The answers the report was built from. Kept so a later import can offer
  /// to replace the money figures while leaving the person's own choices —
  /// savings goal, risk, priority — alone.
  FinanceProfile? _profile;
  MoneyStyleCompletion? _moneyStyleCompletion;
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
  late AppView _view;
  String? _lastEarnedSummary;
  bool _planStarted = false;

  /// True while the user has skipped the Money Style questionnaire and has
  /// neither completed it nor dismissed the "do it later" reminder.
  bool _moneyStyleDeferred = false;

  /// Demo-only membership flag — see PlusScreen; no real payment exists.
  bool _isPlusMember = false;
  int _diamonds = 0;

  /// Streak freezes. Free players hold one; Plus members hold three and earn
  /// them twice as fast. This is the perk that matters — everything else Plus
  /// sells is decoration, and this is the one that protects the thing people
  /// actually care about losing.
  static const int _freeFreezeCap = 1;
  static const int _plusFreezeCap = 3;
  FreezeState _freezes = const FreezeState(available: 1, capacity: 1);

  /// Healthy days banked toward the next freeze.
  int _daysTowardFreeze = 0;

  int get _freezeEarnEvery => _isPlusMember ? 3 : 7;

  /// The diamond store is reachable from more than one place (the shop, and
  /// the Plus screen). Back should return where you came from rather than
  /// always dumping you on the forest.
  AppView _diamondsReturnTo = AppView.forest;
  final PaymentGateway _payments = MockPaymentGateway();
  final AdGateway _ads = MockAdGateway();

  _MyAppState() {
    _shopState = _shopService.initialState();
    _homeLayout = _homeLayoutService.initialState();
    // Everyone starts at zero coins. Debug builds can grant more on demand
    // via the shop's debug panel, but never automatically.
    _progression = _progressionEngine.compute(
      days: const [],
      achievements: const [],
      spendEvents: _spendEvents,
    );
  }

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient();
    _moneyStyleStore =
        widget.moneyStyleStore ?? SharedPreferencesMoneyStyleRepository();
    _view = widget.showOnboardingInitially
        ? AppView.onboarding
        : AppView.moneyStyleFlow;
    unawaited(_loadMoneyStyle());
  }

  /// Plus gets a warmer, richer look: deeper greens, a brass accent and a
  /// darker ground. It is purely cosmetic — nothing about the plan, the
  /// leaderboard or the tree changes — but it makes the membership feel like
  /// something rather than a flag in a database.
  ThemeData _buildTheme({required bool plus}) {
    final seed = plus ? const Color(0xff1f5d3c) : const Color(0xff2f7d50);
    final base = ColorScheme.fromSeed(seedColor: seed);
    return ThemeData(
      useMaterial3: true,
      colorScheme: plus
          ? base.copyWith(
              secondary: const Color(0xffb08d3f),
              tertiary: const Color(0xffd9b45f),
              surfaceContainerHighest: const Color(0xffe9e2d2),
            )
          : base,
      scaffoldBackgroundColor: plus
          ? const Color(0xfff2ede0)
          : const Color(0xfff5f1e8),
      cardTheme: CardThemeData(
        elevation: plus ? 2 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(plus ? 16 : 12),
          side: plus
              ? const BorderSide(color: Color(0xffd9c79a))
              : BorderSide.none,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: plus
            ? const Color(0xffe8e0cd)
            : const Color(0xffe8f0ea),
        foregroundColor: const Color(0xff173b2f),
        // Material's default 22pt title plus three or four action icons does
        // not fit a 390pt phone — "Homestead" was rendering as "Homes…".
        // 18pt with tighter spacing fits every screen's title in full.
        titleSpacing: 12,
        titleTextStyle: const TextStyle(
          color: Color(0xff173b2f),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Money Money',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      navigatorKey: _navigatorKey,
      theme: _buildTheme(plus: _isPlusMember),
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
          onCancel: () => setState(
            () => _view = _moneyStyleCompletion?.result == null
                ? AppView.moneyStyleFlow
                : AppView.moneyStyleResult,
          ),
          onFetchSuggestion: _fetchProfileSuggestion,
          showMoneyStyleReminder: _moneyStyleDeferred,
          onDismissMoneyStyleReminder: _dismissMoneyStyleReminder,
        );
      case AppView.moneyStyleFlow:
        return MoneyStyleFlow(
          userId: 'user-1', // TODO: Replace with actual user ID
          onComplete: _handleMoneyStyleComplete,
          existingCompletion: _moneyStyleCompletion,
          onProgress: _handleMoneyStyleProgress,
          onStartOver: _clearMoneyStyle,
          onSkipAll: _skipMoneyStyleQuestionnaire,
        );
      case AppView.moneyStyleResult:
        return MoneyStyleResultScreen(
          completion: _moneyStyleCompletion!,
          onExploreIdeas: () => setState(() => _view = AppView.moneyStyleIdeas),
          onBuildRangePlan: () => setState(() => _view = AppView.rangePlan),
          onAnswerMore: () => setState(() => _view = AppView.moneyStyleFlow),
          onStartOver: () async {
            await _clearMoneyStyle();
            if (mounted) {
              setState(() {
                _view = AppView.moneyStyleFlow;
              });
            }
          },
        );
      case AppView.moneyStyleIdeas:
        final result = _moneyStyleCompletion!.result;
        return result == null
            ? _buildCurrentView()
            : MoneyStyleIdeasScreen(
                result: result,
                onBack: () => setState(() => _view = AppView.moneyStyleResult),
              );
      case AppView.rangePlan:
        return PlanRangeScreen(
          onKeep: _handleRangeSnapshot,
          onExact: () => setState(() => _view = AppView.onboarding),
        );
      case AppView.report:
        if (report == null) {
          return OnboardingScreen(
            onProfileSubmitted: _handleProfileSubmitted,
            onStartMoneyStyleQuiz: _startMoneyStyleQuiz,
            onFetchSuggestion: _fetchProfileSuggestion,
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
            onFetchSuggestion: _fetchProfileSuggestion,
          );
        }
        return HomeScreen(
          report: report,
          summary: _summary,
          progression: _progression,
          shopState: _shopState,
          lastEarnedSummary: _lastEarnedSummary,
          onCheckIn: _handleCheckIn,
          freezes: _freezes,
          onStatementImported: _offerPlanRebuildFromStatement,
          onRestore: _handleRestore,
          onShowReport: () => setState(() => _view = AppView.report),
          onRetakeQuestionnaire: () => setState(
            () => _view = widget.showOnboardingInitially
                ? AppView.onboarding
                : AppView.moneyStyleFlow,
          ),
          onShowAchievements: () =>
              setState(() => _view = AppView.achievements),
          onShowShop: () => setState(() => _view = AppView.shop),
          onShowSpending: () => setState(() => _view = AppView.spending),
          onShowPlus: () => setState(() => _view = AppView.plus),
          isPlusMember: _isPlusMember,
          onShowCalendar: () => setState(() => _view = AppView.calendar),
          onShowHomestead: () => setState(() => _view = AppView.homestead),
          onFetchTodaySpending: _fetchTodaySpending,
          api: _apiClient,
          showMoneyStyleReminder: _moneyStyleDeferred,
          onResumeMoneyStyle: _startMoneyStyleQuiz,
          onDismissMoneyStyleReminder: _dismissMoneyStyleReminder,
          onDebugSimulate: _handleDebugSimulateStreak,
          onDebugFillFarm: _handleDebugFillFarm,
        );
      case AppView.calendar:
        return CalendarScreen(
          summary: _summary,
          shopState: _shopState,
          onShowForest: () => setState(() => _view = AppView.forest),
          onShowSpending: () => setState(() => _view = AppView.spending),
          onShowHomestead: () => setState(() => _view = AppView.homestead),
          onShowReport: () => setState(() => _view = AppView.report),
          onShowAchievements: () =>
              setState(() => _view = AppView.achievements),
          onShowShop: () => setState(() => _view = AppView.shop),
        );
      case AppView.spending:
        return SpendingScreen(
          api: _apiClient,
          onShowForest: () => setState(() => _view = AppView.forest),
          onShowCalendar: () => setState(() => _view = AppView.calendar),
          onShowHomestead: () => setState(() => _view = AppView.homestead),
          onShowAchievements: () =>
              setState(() => _view = AppView.achievements),
        );
      case AppView.plus:
        return PlusScreen(
          isPlusMember: _isPlusMember,
          onSubscribe: _handleSubscribePlus,
          onCancelMembership: _handleCancelPlus,
          onBuyFreezeTicket: _handleBuyFreezeTicket,
          onBack: () => setState(() => _view = AppView.forest),
        );
      case AppView.homestead:
        return HomesteadScreen(
          shopState: _shopState,
          layout: _homeLayout,
          days: _summary.days,
          onPlace: _handlePlaceDecoration,
          onRemove: _handleRemoveDecoration,
          onShowForest: () => setState(() => _view = AppView.forest),
          onShowSpending: () => setState(() => _view = AppView.spending),
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
            onFetchSuggestion: _fetchProfileSuggestion,
          );
        }
        return AchievementsScreen(
          summary: _summary,
          progression: _progression,
          onShowForest: () => setState(() => _view = AppView.forest),
          onShowSpending: () => setState(() => _view = AppView.spending),
          onShowCalendar: () => setState(() => _view = AppView.calendar),
          onShowHomestead: () => setState(() => _view = AppView.homestead),
        );
      case AppView.diamonds:
        return DiamondStoreScreen(
          gateway: _payments,
          diamonds: _diamonds,
          isPlusMember: _isPlusMember,
          onPurchased: (delta) => setState(() => _diamonds += delta),
          onSubscribe: _handleSubscribePlus,
          onBack: () => setState(() => _view = _diamondsReturnTo),
          onWatchAd: () async {
            final result = await _ads.showRewarded();
            return result.rewarded ? result.amount : 0;
          },
        );
      case AppView.shop:
        if (report == null) {
          return OnboardingScreen(
            onProfileSubmitted: _handleProfileSubmitted,
            onStartMoneyStyleQuiz: _startMoneyStyleQuiz,
            onFetchSuggestion: _fetchProfileSuggestion,
          );
        }
        return ShopScreen(
          progression: _progression,
          shopState: _shopState,
          onPurchase: _handlePurchase,
          onEquip: _handleEquip,
          isPlusMember: _isPlusMember,
          onShowPlus: () => setState(() => _view = AppView.plus),
          onBack: () => setState(() => _view = AppView.forest),
          diamonds: _diamonds,
          onShowDiamonds: () => setState(() {
            _diamondsReturnTo = AppView.shop;
            _view = AppView.diamonds;
          }),
          onDebugMaxCoins: _handleDebugMaxCoins,
          onDebugUnlockAll: _handleDebugUnlockAll,
          onDebugGrantXp: _handleDebugSimulateStreak,
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
    setState(() {
      _profile = profile;
      // The Money Style quiz, when taken, adds a daily action tailored to
      // how this person actually decides — so it changes something they
      // see every day, not just a one-off result screen.
      _report = ReportGenerator().generate(
        profile,
        style: styleActionForResult(_moneyStyleCompletion?.result),
      );
      _summary = _forestEngine.summarize(
        _summary.days,
        progression: _progression,
        shopState: _shopState,
      );
      // Submitting the questionnaire drops the user straight into the app.
      // The report is still one tap away from the Forest app bar, so nothing
      // is lost by skipping it as a mandatory step.
      _view = AppView.forest;
      _planStarted = true;
    });
  }

  /// "Keep this range-based snapshot" used to bounce straight back to the
  /// result screen, which looked like a dead button. A range answer is still an
  /// answer: turn it into a profile using the midpoint of each band and open
  /// the app, exactly like the exact-numbers path does. The user can always
  /// redo it precisely from the questionnaire later.
  void _handleRangeSnapshot(RangeSnapshot snap) {
    final income = switch (snap.income) {
      IncomeRange.under2500 => 2000.0,
      IncomeRange.from2500To5000 => 3750.0,
      IncomeRange.from5000To8000 => 6500.0,
      IncomeRange.over8000 => 9500.0,
      IncomeRange.preferNotToSay => 4000.0,
    };
    final fixedShare = switch (snap.costs) {
      FixedCostShareRange.underHalf => 0.35,
      FixedCostShareRange.aboutHalf => 0.50,
      FixedCostShareRange.overHalf => 0.65,
      FixedCostShareRange.unsure => 0.50,
      FixedCostShareRange.preferNotToSay => 0.50,
    };
    final fixed = (income * fixedShare).roundToDouble();
    // A quarter of what is left, rounded to $50 so the target reads like a
    // number a person would choose rather than a calculation.
    final savings = (((income - fixed) * 0.25) / 50).round() * 50.0;

    final goal = switch (snap.priority) {
      PlanningPriority.breathingRoom => FinancialGoal.emergencyFund,
      PlanningPriority.upcomingCost => FinancialGoal.saveForPurchase,
      PlanningPriority.reduceSpending => FinancialGoal.reduceSpending,
      PlanningPriority.debtOrganisation => FinancialGoal.debtControl,
      PlanningPriority.explore => FinancialGoal.emergencyFund,
    };
    final risk = switch (snap.priority) {
      PlanningPriority.breathingRoom ||
      PlanningPriority.debtOrganisation => RiskLevel.cautious,
      PlanningPriority.upcomingCost ||
      PlanningPriority.reduceSpending => RiskLevel.steady,
      PlanningPriority.explore => RiskLevel.balanced,
    };
    final pressure = switch (snap.costs) {
      FixedCostShareRange.underHalf => SpendingPressure.low,
      FixedCostShareRange.overHalf => SpendingPressure.high,
      _ => SpendingPressure.medium,
    };

    _handleProfileSubmitted(
      FinanceProfile(
        monthlyIncome: income,
        fixedMonthlyExpenses: fixed,
        monthlySavingsGoal: savings,
        riskLevel: risk,
        financialGoal: goal,
        spendingPressure: pressure,
      ),
    );
  }

  void _startMoneyStyleQuiz() {
    setState(() {
      _view = AppView.moneyStyleFlow;
    });
  }

  /// Leaving the questionnaire entirely, from the entry screen or any page.
  /// The user is handed to the manual exact-number form — the app's existing
  /// alternative route to a plan — rather than being left with nowhere to go,
  /// and the decision is persisted so the offer can be picked up later.
  void _skipMoneyStyleQuestionnaire() {
    setState(() {
      _moneyStyleDeferred = true;
      _view = AppView.onboarding;
    });
    unawaited(_deferMoneyStyle());
  }

  Future<void> _deferMoneyStyle() async {
    try {
      await _moneyStyleStore.deferQuestionnaire();
    } catch (error) {
      debugPrint('Money Style deferral could not be saved: $error');
    }
  }

  void _dismissMoneyStyleReminder() {
    setState(() => _moneyStyleDeferred = false);
    unawaited(_clearMoneyStyleDeferral());
  }

  Future<void> _clearMoneyStyleDeferral() async {
    try {
      await _moneyStyleStore.clearDeferral();
    } catch (error) {
      debugPrint('Money Style deferral could not be cleared: $error');
    }
  }

  Future<void> _loadMoneyStyle() async {
    MoneyStyleCompletion? completion;
    var deferred = false;
    try {
      completion = await _moneyStyleStore.load();
      deferred = await _moneyStyleStore.isQuestionnaireDeferred();
    } catch (error) {
      debugPrint('Money Style progress could not be loaded: $error');
    }
    if (!mounted) {
      return;
    }
    if (completion == null) {
      if (deferred) {
        setState(() {
          _moneyStyleDeferred = true;
          _view = AppView.onboarding;
        });
      }
      return;
    }
    final showResult =
        completion.result != null ||
        completion.session.isCompleteFor(moneyStyleQuestionPool);
    setState(() {
      _moneyStyleDeferred = deferred;
      _moneyStyleCompletion = completion;
      _view = showResult ? AppView.moneyStyleResult : AppView.moneyStyleFlow;
    });
  }

  void _handleMoneyStyleProgress(AnswerSession session) {
    unawaited(
      _saveMoneyStyle(
        MoneyStyleCompletion(session: session.snapshot(), result: null),
      ),
    );
  }

  Future<void> _saveMoneyStyle(MoneyStyleCompletion completion) {
    final snapshot = MoneyStyleCompletion(
      session: completion.session.snapshot(),
      result: completion.result,
    );
    _moneyStyleWrites = _moneyStyleWrites.then((_) async {
      try {
        await _moneyStyleStore.save(snapshot);
      } catch (error) {
        debugPrint('Money Style progress could not be saved: $error');
      }
    });
    return _moneyStyleWrites;
  }

  Future<void> _clearMoneyStyle() async {
    await _moneyStyleWrites;
    try {
      await _moneyStyleStore.clear();
    } catch (error) {
      debugPrint('Money Style progress could not be cleared: $error');
    }
    if (mounted) {
      setState(() => _moneyStyleCompletion = null);
    }
  }

  Future<void> _handleMoneyStyleComplete(
    MoneyStyleCompletion completion,
  ) async {
    final snapshot = MoneyStyleCompletion(
      session: completion.session.snapshot(),
      result: completion.result,
    );
    await _saveMoneyStyle(snapshot);
    // Finishing the quiz retires the "complete it later" reminder.
    await _clearMoneyStyleDeferral();
    if (!mounted) {
      return;
    }
    setState(() {
      _moneyStyleDeferred = false;
      _moneyStyleCompletion = snapshot;
      _view = AppView.moneyStyleResult;
    });
    unawaited(_syncMoneyStyle(snapshot));
  }

  Future<void> _syncMoneyStyle(MoneyStyleCompletion completion) async {
    try {
      await _apiClient.submitMoneyStyle(
        MoneyStyleSubmission.fromCompletion(completion),
      );
    } catch (error) {
      debugPrint('Money Style not sent to backend: $error');
    }
  }

  void _startPlan() {
    setState(() {
      _planStarted = true;
      _view = AppView.forest;
    });
  }

  void _handleCheckIn({required double spending}) {
    final report = _report;
    if (report == null) {
      return;
    }

    final result = _forestEngine.checkIn(
      existingDays: _summary.days,
      report: report,
      date: DateTime.now(),
      spending: spending,
      freezesAvailable: _freezes.available,
    );

    final beforeXp = _progression.totalXp;
    final beforeCoins = _progression.coinBalance;
    final beforeLevel = _progression.level.level;
    var earnedXp = 0;
    var earnedCoins = 0;

    setState(() {
      _summary = result.summary;
      if (result.freezesUsed > 0) {
        _freezes = _freezes.copyWith(
          available: _freezes.available - result.freezesUsed,
        );
      }
      if (result.day.status == TreeStatus.healthy) _bankFreezeProgress();
      _recomputeProgression();
      earnedXp = _progression.totalXp - beforeXp;
      earnedCoins = _progression.coinBalance - beforeCoins;
      _lastEarnedSummary = '+$earnedXp XP, +$earnedCoins coins';
    });

    if (result.freezesUsed > 0) {
      final n = result.freezesUsed;
      _showMessage(
        n == 1
            ? 'You missed a day. A streak freeze covered it — your '
                  '${_summary.currentStreak}-day streak is intact.'
            : '$n streak freezes covered the days you missed. Your '
                  '${_summary.currentStreak}-day streak is intact.',
      );
    }

    // Two celebrations exist and they must not stack. Levelling up is the
    // bigger moment, so it wins; otherwise a within-budget day gets the
    // ordinary check-in celebration. An over-budget day gets neither — it
    // gets the restoration panel instead.
    if (_progression.level.level > beforeLevel) {
      _celebrateIfLevelled(beforeLevel, xp: earnedXp, coins: earnedCoins);
    } else if (result.day.status == TreeStatus.healthy) {
      final context = _navigatorKey.currentContext;
      if (context != null) {
        showCelebrationDialog(
          context: context,
          earnedXp: earnedXp,
          earnedCoins: earnedCoins,
          streak: _summary.currentStreak,
        );
      }
    }
  }

  /// Freezes are earned, not given: every [_freezeEarnEvery] healthy days
  /// tops one back up. Must be called inside setState.
  void _bankFreezeProgress() {
    if (_freezes.isFull) {
      _daysTowardFreeze = 0;
      return;
    }
    _daysTowardFreeze++;
    if (_daysTowardFreeze >= _freezeEarnEvery) {
      _daysTowardFreeze = 0;
      _freezes = _freezes.copyWith(available: _freezes.available + 1);
    }
  }

  /// Keeps the freeze capacity in step with membership. Subscribing raises the
  /// cap and hands over the extra freezes immediately — the perk should be
  /// visible the moment it is paid for. Lapsing lowers the cap but never takes
  /// back a freeze already held.
  void _syncFreezeCapacity() {
    final cap = _isPlusMember ? _plusFreezeCap : _freeFreezeCap;
    if (cap == _freezes.capacity) return;
    final gained = cap > _freezes.capacity ? cap - _freezes.capacity : 0;
    _freezes = FreezeState(
      available: (_freezes.available + gained).clamp(0, cap),
      capacity: cap,
    );
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
      isPlusMember: _isPlusMember,
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

  /// Suggests income and fixed expenses from the last 90 days of bank
  /// activity, so onboarding asks the user to confirm rather than recall.
  Future<ProfileSuggestion?> _fetchProfileSuggestion() async {
    const days = 90;
    final transactions = await _apiClient.transactions(days: days);
    return suggestProfileFromTransactions(transactions, days: days);
  }

  /// After a statement import, offer to rebuild the plan from what the
  /// statement actually says.
  ///
  /// Until now the loop was half open: we read your transactions, but the plan
  /// they were judged against was still the numbers you typed in. That made
  /// "we check your transactions" true of the spending screen and not much
  /// else. This closes it — the income and fixed costs come from the bank
  /// feed, and the daily budget follows.
  ///
  /// It asks rather than just doing it: silently rewriting someone's stated
  /// income from an inferred figure is not a thing a money app should do.
  Future<void> _offerPlanRebuildFromStatement() async {
    final existing = _report;
    if (existing == null) return;

    ProfileSuggestion? suggestion;
    try {
      suggestion = await _fetchProfileSuggestion();
    } catch (error) {
      debugPrint('Could not read the imported statement: $error');
      return;
    }
    if (suggestion == null || !mounted) return;

    final profile = _profile;
    if (profile == null) return;

    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return;

    final accepted = await showDialog<bool>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rebuild your plan from this statement?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your statement suggests:'),
            const SizedBox(height: 12),
            _suggestionLine('Monthly income', profile.monthlyIncome,
                suggestion.monthlyIncome),
            _suggestionLine('Fixed costs', profile.fixedMonthlyExpenses,
                suggestion.fixedMonthlyExpenses),
            const SizedBox(height: 12),
            const Text(
              'Your savings goal and preferences stay as they are.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep my numbers'),
          ),
          FilledButton(
            key: const Key('accept-statement-plan'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Use the statement'),
          ),
        ],
      ),
    );

    if (accepted != true || !mounted) return;

    _handleProfileSubmitted(FinanceProfile(
      monthlyIncome: suggestion.monthlyIncome,
      fixedMonthlyExpenses: suggestion.fixedMonthlyExpenses,
      monthlySavingsGoal: profile.monthlySavingsGoal,
      riskLevel: profile.riskLevel,
      financialGoal: profile.financialGoal,
      spendingPressure: profile.spendingPressure,
    ));
    _showMessage('Plan rebuilt from your statement.');
  }

  /// "Monthly income   $3,200 -> $3,412"
  Widget _suggestionLine(String label, double before, double after) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text('\$${before.round()} → ',
              style: const TextStyle(color: Color(0xff8a8a8a))),
          Text('\$${after.round()}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
      );

  Future<double> _fetchTodaySpending() async {
    final transactions = await _apiClient.transactions(days: 7);
    return sumTodaySpending(transactions);
  }

  /// Fires the level-up overlay when the level number actually increased.
  /// Called after any action that can award XP.
  void _celebrateIfLevelled(
    int beforeLevel, {
    required int xp,
    required int coins,
  }) {
    final after = _progression.level.level;
    if (after <= beforeLevel) return;
    final ctx = _messengerKey.currentContext;
    if (ctx == null) return;
    LevelUpOverlay.show(
      ctx,
      newLevel: after,
      xpGained: xp,
      coinsGained: coins,
      unlockedLabel: after % 5 == 0 ? 'New tower stage unlocked' : null,
    );
  }

  /// Debug only: build a run of consecutive within-budget days.
  ///
  /// This replaces an earlier "grant XP" button that did not work. Two reasons
  /// it could not:
  ///   1. ProgressionEngine derives XP from the DAYS list; spendEvents only
  ///      ever contribute coins. A synthetic XP event was silently ignored.
  ///   2. The tree's size comes from ForestEngine's streak (1/2/3), not from
  ///      the player level at all — so XP could never grow the tree.
  ///
  /// Feeding real days through the real engine fixes both: the streak grows the
  /// tree, and the XP those days earn levels the player up for real.
  void _handleDebugSimulateStreak() {
    final report = _report;
    if (report == null) return;

    final beforeLevel = _progression.level.level;
    final beforeXp = _progression.totalXp;
    final beforeCoins = _progression.coinBalance;

    var days = _summary.days;
    // Walk BACKWARDS from the earliest day we already have. Re-running over the
    // same dates just overwrites them, which is why pressing this repeatedly
    // used to do nothing after the first time.
    final earliest = days.isEmpty
        ? DateTime.now()
        : days.map((d) => d.date).reduce((a, b) => a.isBefore(b) ? a : b);

    for (var i = 1; i <= 7; i++) {
      final result = _forestEngine.checkIn(
        existingDays: days,
        report: report,
        date: earliest.subtract(Duration(days: i)),
        spending: report.dailyBudget * 0.6, // comfortably under budget
      );
      days = result.summary.days;
    }

    setState(() {
      _summary = _forestEngine.summarize(
        days,
        progression: _progression,
        shopState: _shopState,
      );
      _recomputeProgression();
    });

    _celebrateIfLevelled(
      beforeLevel,
      xp: _progression.totalXp - beforeXp,
      coins: _progression.coinBalance - beforeCoins,
    );
  }

  /// Demo only: own everything and lay it out.
  ///
  /// Buying eleven animals and placing ten decorations by hand is two minutes
  /// of clicking that nobody wants to watch in a three-minute pitch. This grants
  /// the lot and arranges the homestead in one press. It writes state directly
  /// rather than going through ShopService, so it deliberately bypasses coin
  /// and level checks — which is exactly why it sits behind the dev PIN.
  void _handleDebugFillFarm() {
    final owned = <String>{
      ..._shopState.ownedItemIds,
      for (final item in kShopCatalog) item.id,
    };

    // Equip a chosen showcase set, not "whatever is last in the catalog".
    // Picking the last item landed on Crystal Pine, whose canopy paints as
    // bare branches over Autumn's sand-coloured ground — the demo opened on
    // what looks like a dead forest. These three are picked to look alive.
    final equipped = <ShopItemCategory, String>{
      ..._shopState.equippedItemIds,
      ShopItemCategory.treeSkin: 'tree-cherry-blossom',
      ShopItemCategory.ground: 'ground-meadow',
      ShopItemCategory.sky: 'sky-sunset',
    };

    // Spread the decorations over the grid rather than stacking them.
    var layout = _homeLayoutService.initialState();
    final decor = kShopCatalog
        .where((i) => i.category == ShopItemCategory.decoration)
        .toList();
    var slot = 0;
    for (final item in decor) {
      final row = (slot ~/ kHomeGridSize) % kHomeGridSize;
      final col = slot % kHomeGridSize;
      layout = _homeLayoutService.place(
        state: layout,
        itemId: item.id,
        row: row,
        col: col,
      );
      slot += 2; // leave a gap so it does not look like a wall
    }

    // The forest paints from the MOST RECENT day, so if today is withered (or
    // was never checked in after an over-budget day) the demo opens on bare
    // branches no matter how high the level is. Record a healthy today.
    final report = _report;
    var days = _summary.days;
    if (report != null) {
      days = _forestEngine
          .checkIn(
            existingDays: days,
            report: report,
            date: DateTime.now(),
            spending: report.dailyBudget * 0.5,
          )
          .summary
          .days;
    }

    setState(() {
      if (report != null) {
        _summary = _forestEngine.summarize(
          days,
          progression: _progression,
          shopState: _shopState,
        );
      }
      _shopState = ShopState(ownedItemIds: owned, equippedItemIds: equipped);
      _homeLayout = layout;
      _isPlusMember = true;
      _diamonds = _diamonds < 500 ? 500 : _diamonds;
      _spendEvents.add(
        RewardEvent(
          date: DateTime.now(),
          type: RewardEventType.debugGrant,
          xp: 0,
          coins: 5000,
          description: 'Debug: demo setup',
        ),
      );
      _recomputeProgression();
    });
    _showMessage('Demo farm ready — everything owned and placed.');
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

  void _handleSubscribePlus() {
    setState(() {
      _isPlusMember = true;
      _syncFreezeCapacity();
    });
    _showMessage(
      'Plus activated (demo — no payment was taken). '
      'You now hold ${_freezes.available} streak freezes.',
    );
  }

  /// A bought freeze is an extra slot, not one of the earned ones — raising
  /// the cap too means buying still does something when you are already full.
  void _handleBuyFreezeTicket() {
    setState(() {
      _freezes = _freezes.copyWith(
        available: _freezes.available + 1,
        capacity: _freezes.capacity + 1,
      );
    });
    _showMessage('Freeze ticket added (demo — no payment was taken).');
  }

  void _handleCancelPlus() {
    setState(() {
      _isPlusMember = false;
      _syncFreezeCapacity();
    });
    _showMessage('Plus membership cancelled.');
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
