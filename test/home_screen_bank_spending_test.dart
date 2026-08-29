import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/progression.dart';
import 'package:moneymoneymoney/models/wealth_report.dart';
import 'package:moneymoneymoney/screens/home_screen.dart';
import 'package:moneymoneymoney/services/forest_engine.dart';
import 'package:moneymoneymoney/services/shop_service.dart';

const _testReport = WealthReport(
  profileSummary: 'summary',
  disposableIncome: 3000,
  dailyBudget: 50,
  savingsAdvice: 'save',
  riskAdvice: 'risk',
  warning: null,
  dailyActions: ['Record every expense today.'],
);

const _testProgression = ProgressionState(
  totalXp: 0,
  level: LevelProgress(
    level: 1,
    xpIntoLevel: 0,
    xpForNextLevel: 100,
    fraction: 0,
  ),
  coinBalance: 0,
  lifetimeCoinsEarned: 0,
  lifetimeCoinsSpent: 0,
  ledger: [],
);

Widget _harness({required Future<double> Function() onFetchTodaySpending}) {
  return MaterialApp(
    home: HomeScreen(
      report: _testReport,
      summary: ForestEngine().summarize(const []),
      progression: _testProgression,
      shopState: ShopService().initialState(),
      onCheckIn: ({required spending}) {},
      onRestore: (_) {},
      onShowReport: () {},
      onShowAchievements: () {},
      onShowShop: () {},
      onShowSpending: () {},
      onShowPlus: () {},
      isPlusMember: false,
      onShowCalendar: () {},
      onShowHomestead: () {},
      onFetchTodaySpending: onFetchTodaySpending,
    ),
  );
}

void main() {
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

  testWidgets('bank mode is the default and pulls the figure on open', (
    tester,
  ) async {
    var fetched = false;
    await tester.pumpWidget(
      _harness(
        onFetchTodaySpending: () async {
          fetched = true;
          return 19.75;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(fetched, isTrue);
    final field = tester.widget<TextField>(
      find.byKey(const Key('spending-field')),
    );
    expect(field.readOnly, isTrue);
    expect(find.text('19.75'), findsOneWidget);
  });

  testWidgets('switching to manual makes the field editable again', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(onFetchTodaySpending: () async => 19.75));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('spending-mode-manual')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('spending-field')),
    );
    expect(field.readOnly, isFalse);
  });

  testWidgets('a bank failure on open falls back to an editable manual field', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(onFetchTodaySpending: () async => throw Exception('offline')),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('spending-field')),
    );
    expect(field.readOnly, isFalse);
    expect(find.textContaining('Could not load bank data'), findsOneWidget);
  });

  testWidgets('switching to bank mode fetches and fills the spending field', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(onFetchTodaySpending: () async => 19.75));

    await tester.tap(find.byKey(const Key('spending-mode-bank')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('spending-field')),
    );
    expect(field.readOnly, isTrue);
    expect(find.text('19.75'), findsOneWidget);
  });

  testWidgets(
    'a failed bank fetch reverts to manual mode with an error message',
    (tester) async {
      await tester.pumpWidget(
        _harness(onFetchTodaySpending: () async => throw Exception('offline')),
      );

      await tester.tap(find.byKey(const Key('spending-mode-bank')));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
        find.byKey(const Key('spending-field')),
      );
      expect(field.readOnly, isFalse);
      expect(find.textContaining('Could not load bank data'), findsOneWidget);
    },
  );
}
