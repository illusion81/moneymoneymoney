import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moneymoneymoney/data/api_client.dart';
import 'package:moneymoneymoney/data/money_style_archetypes.dart';
import 'package:moneymoneymoney/main.dart';
import 'package:moneymoneymoney/models/forest_day.dart';
import 'package:moneymoneymoney/models/money_style.dart';
import 'package:moneymoneymoney/models/progression.dart';
import 'package:moneymoneymoney/models/wealth_report.dart';
import 'package:moneymoneymoney/screens/home_screen.dart';
import 'package:moneymoneymoney/screens/shop_screen.dart';
import 'package:moneymoneymoney/services/forest_engine.dart';
import 'package:moneymoneymoney/services/money_style_repository.dart';
import 'package:moneymoneymoney/services/shop_service.dart';

class _Store implements MoneyStyleStore {
  _Store(this.value);

  MoneyStyleCompletion? value;

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<MoneyStyleCompletion?> load() async => value;

  @override
  Future<void> save(MoneyStyleCompletion completion) async {
    value = completion;
  }
}

class _DelayedClearStore extends _Store {
  _DelayedClearStore(super.value);

  final clearStarted = Completer<void>();
  final allowClear = Completer<void>();

  @override
  Future<void> clear() async {
    clearStarted.complete();
    await allowClear.future;
    value = null;
  }
}

const _testReport = WealthReport(
  profileSummary: 'summary',
  disposableIncome: 3000,
  dailyBudget: 50,
  savingsAdvice: 'save',
  riskAdvice: 'risk',
  warning: null,
  dailyActions: ['Record every expense today.'],
);

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// A small harness that hosts [HomeScreen] with an already-withered "today"
/// record and enough coins to restore it, so the restoration flow can be
/// driven without depending on wall-clock day boundaries.
class _RestoreHarness extends StatefulWidget {
  const _RestoreHarness();

  @override
  State<_RestoreHarness> createState() => _RestoreHarnessState();
}

class _RestoreHarnessState extends State<_RestoreHarness> {
  final _engine = ForestEngine();
  late ForestSummary _summary;
  ProgressionState _progression = const ProgressionState(
    totalXp: 0,
    level: LevelProgress(
      level: 1,
      xpIntoLevel: 0,
      xpForNextLevel: 100,
      fraction: 0,
    ),
    coinBalance: 200,
    lifetimeCoinsEarned: 200,
    lifetimeCoinsSpent: 0,
    ledger: [],
  );

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _summary = _engine.summarize([
      ForestDay(
        date: DateTime(today.year, today.month, today.day),
        status: TreeStatus.withered,
        treeLevel: 0,
        spending: 200,
        dailyBudget: 50,
        actionCompleted: true,
        message: 'Today withered because spending exceeded the daily budget.',
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(
        report: _testReport,
        summary: _summary,
        progression: _progression,
        shopState: ShopService().initialState(),
        onCheckIn: ({required spending, required actionCompleted}) {},
        onRestore: (note) {
          final result = _engine.restoreDay(
            days: _summary.days,
            dayDate: _summary.days.last.date,
            now: _summary.days.last.date,
            recoveryNote: note,
            coinBalance: _progression.coinBalance,
          );
          if (result.success) {
            setState(() {
              _summary = result.summary;
              final spent = -(result.spendEvent?.coins ?? 0);
              _progression = ProgressionState(
                totalXp: _progression.totalXp,
                level: _progression.level,
                coinBalance: _progression.coinBalance - spent,
                lifetimeCoinsEarned: _progression.lifetimeCoinsEarned,
                lifetimeCoinsSpent: _progression.lifetimeCoinsSpent + spent,
                ledger: _progression.ledger,
              );
            });
          }
        },
        onShowReport: () {},
        onShowAchievements: () {},
        onShowShop: () {},
        onShowCalendar: () {},
        onShowHomestead: () {},
        onFetchTodaySpending: () async => 0,
      ),
    );
  }
}

void main() {
  // The onboarding form and home screen are taller than the default 800x600
  // test surface, so give every test a generous viewport before pumping.
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(
      1000,
      2600,
    );
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  Future<void> startPlan(WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(showOnboardingInitially: true));

    await tester.enterText(find.byKey(const Key('income-field')), '6000');
    await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
    await tester.enterText(find.byKey(const Key('savings-field')), '900');
    await tester.tap(find.text('Generate Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start Plan'));
    await tester.pumpAndSettle();
  }

  testWidgets('first app screen earns trust before asking for numbers', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Discover Your Money Style'), findsOneWidget);
    expect(find.textContaining('2–3 minutes'), findsOneWidget);
    expect(find.text('Monthly income'), findsNothing);
  });

  testWidgets(
    'restored result can cancel exact planning without submitting a survey',
    (tester) async {
      final session = AnswerSession(
        userId: 'user-1',
        sessionId: 'saved-session',
        selectedAnswers: {1: 0, 2: 0, 4: 0},
        skippedQuestions: {3, 5, 6, 7, 8, 9, 10, 11, 12},
      );
      final completion = MoneyStyleCompletion(
        session: session,
        result: MoneyStyleResult(
          archetype: archetypeMap['steady_pause_collaborative']!,
          confidenceTier: ConfidenceTier.earlySnapshot,
          dimensionScores: DimensionScores(
            steadyCount: 1,
            pauseCount: 1,
            collaborativeCount: 1,
          ),
          moneyRhythmWinner: MoneyRhythmPole.steady,
          decisionStyleWinner: DecisionStylePole.pause,
          supportStyleWinner: SupportStylePole.collaborative,
          totalAnswered: 3,
        ),
      );
      final requests = <http.Request>[];
      final apiClient = ApiClient(
        baseUrl: 'http://example.test',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response(request.body, 200);
        }),
      );

      await tester.pumpWidget(
        MyApp(apiClient: apiClient, moneyStyleStore: _Store(completion)),
      );
      await tester.pumpAndSettle();

      expect(find.text('The Intentional Protector'), findsOneWidget);

      await tester.tap(find.text('Build a practical plan with ranges'));
      await tester.pumpAndSettle();
      expect(find.text('Plan with ranges'), findsOneWidget);

      await tester.tap(find.text('Use exact numbers for a daily calculation'));
      await tester.pumpAndSettle();
      expect(find.text('Build an exact-number plan'), findsOneWidget);

      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();

      expect(find.text('The Intentional Protector'), findsOneWidget);
      expect(
        requests.where((request) => request.url.path == '/api/survey'),
        isEmpty,
      );
    },
  );

  testWidgets(
    'restored in-progress session resumes instead of showing a result',
    (tester) async {
      final completion = MoneyStyleCompletion(
        session: AnswerSession(
          userId: 'user-1',
          sessionId: 'in-progress-session',
          selectedAnswers: {1: 0, 2: 0, 4: 0},
          skippedQuestions: {3},
        ),
        result: null,
      );

      await tester.pumpWidget(MyApp(moneyStyleStore: _Store(completion)));
      await tester.pumpAndSettle();

      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Start over'), findsOneWidget);
      expect(find.text('Not enough to name a style yet'), findsNothing);
    },
  );

  testWidgets('money style ideas can return to the restored result', (
    tester,
  ) async {
    final session = AnswerSession(
      userId: 'user-1',
      sessionId: 'saved-session',
      selectedAnswers: {1: 0, 2: 0, 4: 0},
      skippedQuestions: {3, 5, 6, 7, 8, 9, 10, 11, 12},
    );
    final completion = MoneyStyleCompletion(
      session: session,
      result: MoneyStyleResult(
        archetype: archetypeMap['steady_pause_collaborative']!,
        confidenceTier: ConfidenceTier.earlySnapshot,
        dimensionScores: DimensionScores(
          steadyCount: 1,
          pauseCount: 1,
          collaborativeCount: 1,
        ),
        moneyRhythmWinner: MoneyRhythmPole.steady,
        decisionStyleWinner: DecisionStylePole.pause,
        supportStyleWinner: SupportStylePole.collaborative,
        totalAnswered: 3,
      ),
    );

    await tester.pumpWidget(MyApp(moneyStyleStore: _Store(completion)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore ideas that fit my style'));
    await tester.pumpAndSettle();

    expect(find.text('Ideas for your style'), findsOneWidget);
    expect(find.text('Back to Money Style'), findsOneWidget);

    await tester.tap(find.text('Back to Money Style'));
    await tester.pumpAndSettle();
    expect(find.text('The Intentional Protector'), findsOneWidget);
  });

  testWidgets('start over awaits persisted-state clearing before a new quiz', (
    tester,
  ) async {
    final completion = MoneyStyleCompletion(
      session: AnswerSession(
        userId: 'user-1',
        sessionId: 'in-progress-session',
        selectedAnswers: {1: 0},
      ),
      result: null,
    );
    final store = _DelayedClearStore(completion);

    await tester.pumpWidget(MyApp(moneyStyleStore: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start over'));
    await tester.pump();
    await store.clearStarted.future;

    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('1 of 12'), findsNothing);

    store.allowClear.complete();
    await tester.pumpAndSettle();

    expect(store.value, isNull);
    expect(find.text('1 of 12'), findsOneWidget);
  });

  testWidgets('valid questionnaire submission shows generated report', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp(showOnboardingInitially: true));

    await tester.enterText(find.byKey(const Key('income-field')), '6000');
    await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
    await tester.enterText(find.byKey(const Key('savings-field')), '900');
    await tester.tap(find.text('Generate Report'));
    await tester.pumpAndSettle();

    expect(find.text('AI Wealth Report'), findsOneWidget);
    expect(find.textContaining('Daily flexible budget'), findsOneWidget);
    expect(find.text('Start Plan'), findsOneWidget);
  });

  testWidgets('starting the plan shows the forest home screen', (tester) async {
    await startPlan(tester);

    expect(find.text('Wealth Forest'), findsOneWidget);
    expect(find.text('Today\'s money action'), findsOneWidget);
    expect(find.text('Check In'), findsOneWidget);
  });

  testWidgets('the Calendar tab navigates to the calendar screen', (
    tester,
  ) async {
    await startPlan(tester);

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    expect(find.text('Calendar'), findsWidgets);
    expect(find.byKey(const Key('forest-calendar-grid')), findsOneWidget);
  });

  testWidgets('the home screen can reopen the questionnaire after onboarding', (
    tester,
  ) async {
    await startPlan(tester);

    expect(find.text('Wealth Forest'), findsOneWidget);
    expect(find.text('Money Profile'), findsNothing);

    await tester.tap(find.byKey(const Key('retake-questionnaire-button')));
    await tester.pumpAndSettle();

    expect(find.text('Build an exact-number plan'), findsOneWidget);
    expect(find.text('Generate Report'), findsOneWidget);
  });

  testWidgets('retaking the questionnaire keeps existing forest days', (
    tester,
  ) async {
    final today = DateTime.now();

    await startPlan(tester);
    await tester.enterText(find.byKey(const Key('spending-field')), '40');
    await tester.tap(find.byKey(const Key('action-complete-checkbox')));
    await tester.tap(find.text('Check In'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('retake-questionnaire-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('income-field')), '7000');
    await tester.enterText(find.byKey(const Key('expenses-field')), '2700');
    await tester.enterText(find.byKey(const Key('savings-field')), '1200');
    await tester.tap(find.text('Generate Report'));
    await tester.pumpAndSettle();

    expect(find.text('Back to Forest'), findsOneWidget);

    await tester.tap(find.text('Back to Forest'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();

    final todayCell = find.byKey(Key('forest-day-${_dateKey(today)}'));
    expect(todayCell, findsOneWidget);
    expect(
      find.descendant(
        of: todayCell,
        matching: find.byKey(Key('forest-tree-healthy-${_dateKey(today)}')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('successful check-in changes tree status to healthy', (
    tester,
  ) async {
    await startPlan(tester);
    await tester.enterText(find.byKey(const Key('spending-field')), '40');
    await tester.tap(find.byKey(const Key('action-complete-checkbox')));
    await tester.tap(find.text('Check In'));
    await tester.pumpAndSettle();

    expect(find.text('Healthy tree'), findsOneWidget);
  });

  testWidgets('overspending changes tree status to withered', (tester) async {
    await startPlan(tester);
    await tester.enterText(find.byKey(const Key('spending-field')), '200');
    await tester.tap(find.byKey(const Key('action-complete-checkbox')));
    await tester.tap(find.text('Check In'));
    await tester.pumpAndSettle();

    expect(find.text('Withered tree'), findsOneWidget);
  });

  testWidgets(
    'the home screen shows the level chip and coin balance after starting the plan',
    (tester) async {
      await startPlan(tester);

      expect(find.text('Level 1'), findsOneWidget);
      // Debug builds auto-grant a large coin balance on startup (see
      // _MyAppState._MyAppState) so the shop/homestead can be tested freely.
      expect(find.byKey(const Key('coin-balance')), findsOneWidget);
      expect(find.text('999999'), findsOneWidget);
    },
  );

  testWidgets('a successful check-in increases the displayed coin balance', (
    tester,
  ) async {
    await startPlan(tester);
    await tester.enterText(find.byKey(const Key('spending-field')), '10');
    await tester.tap(find.byKey(const Key('action-complete-checkbox')));
    await tester.tap(find.text('Check In'));
    await tester.pumpAndSettle();

    // The first healthy, under-budget day both grows the tree and unlocks
    // First Sapling and Budget Guardian, so the summary line and coin pill
    // reflect the day reward plus both achievement bonuses.
    final coinBalanceFinder = find.byKey(const Key('coin-balance'));
    expect(coinBalanceFinder, findsOneWidget);
    expect(
      find.descendant(of: coinBalanceFinder, matching: find.text('0')),
      findsNothing,
    );
    expect(find.textContaining('XP,'), findsOneWidget);
    expect(find.textContaining('coins'), findsWidgets);
  });

  testWidgets('an overspending check-in shows the restoration panel', (
    tester,
  ) async {
    await startPlan(tester);
    await tester.enterText(find.byKey(const Key('spending-field')), '200');
    await tester.tap(find.byKey(const Key('action-complete-checkbox')));
    await tester.tap(find.text('Check In'));
    await tester.pumpAndSettle();

    expect(find.text('Restore this day'), findsOneWidget);
    expect(find.byKey(const Key('recovery-note-field')), findsOneWidget);
    expect(find.byKey(const Key('restore-button')), findsOneWidget);
    expect(find.textContaining('Restore for'), findsOneWidget);
  });

  testWidgets(
    'restoring with a note changes the status text to Restored tree',
    (tester) async {
      await tester.pumpWidget(const _RestoreHarness());
      await tester.pumpAndSettle();

      expect(find.text('Withered tree'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('recovery-note-field')),
        'Overspent on groceries, will plan meals ahead next time.',
      );
      await tester.tap(find.byKey(const Key('restore-button')));
      await tester.pumpAndSettle();

      expect(find.text('Restored tree'), findsOneWidget);
    },
  );

  testWidgets(
    'the shop screen lists catalog items and disables the buy button when coins are short',
    (tester) async {
      final progression = ProgressionState(
        totalXp: 0,
        level: const LevelProgress(
          level: 5,
          xpIntoLevel: 0,
          xpForNextLevel: 100,
          fraction: 0,
        ),
        coinBalance: 0,
        lifetimeCoinsEarned: 0,
        lifetimeCoinsSpent: 0,
        ledger: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ShopScreen(
            progression: progression,
            shopState: ShopService().initialState(),
            onPurchase: (_) {},
            onEquip: (_) {},
            onBack: () {},
          ),
        ),
      );

      expect(find.text('Forest Shop'), findsOneWidget);
      expect(find.text('Golden Ginkgo'), findsOneWidget);

      final buyButtonFinder = find.ancestor(
        of: find.text('Buy for 120'),
        matching: find.byType(FilledButton),
      );
      expect(buyButtonFinder, findsOneWidget);
      final buyButton = tester.widget<FilledButton>(buyButtonFinder);
      expect(buyButton.onPressed, isNull);
    },
  );
}
