import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/forest_day.dart';
import 'package:moneymoneymoney/screens/calendar_screen.dart';
import 'package:moneymoneymoney/services/forest_engine.dart';
import 'package:moneymoneymoney/services/shop_service.dart';

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

  testWidgets('calendar screen renders current month forest calendar statuses', (
    tester,
  ) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final witheredDate = monthStart;
    final healthyDate = monthStart.add(const Duration(days: 1));
    final summary = ForestEngine().summarize([
      ForestDay(
        date: witheredDate,
        status: TreeStatus.withered,
        treeLevel: 0,
        spending: 80,
        dailyBudget: 50,
        actionCompleted: false,
        message: 'Today withered because the money action was not completed.',
      ),
      ForestDay(
        date: healthyDate,
        status: TreeStatus.healthy,
        treeLevel: 1,
        spending: 20,
        dailyBudget: 50,
        actionCompleted: true,
        message:
            'Healthy growth: action complete and spending stayed within budget.',
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: CalendarScreen(
          summary: summary,
          shopState: ShopService().initialState(),
          onShowForest: () {},
          onShowHomestead: () {},
          onShowReport: () {},
          onShowAchievements: () {},
          onShowShop: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('forest-calendar-grid')), findsOneWidget);

    final witheredCell = find.byKey(
      Key('forest-day-${_dateKey(witheredDate)}'),
    );
    final healthyCell = find.byKey(Key('forest-day-${_dateKey(healthyDate)}'));

    expect(witheredCell, findsOneWidget);
    expect(healthyCell, findsOneWidget);
    expect(
      find.descendant(
        of: witheredCell,
        matching: find.byKey(
          Key('forest-tree-withered-${_dateKey(witheredDate)}'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: healthyCell,
        matching: find.byKey(
          Key('forest-tree-healthy-${_dateKey(healthyDate)}'),
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('calendar screen bottom nav can navigate to the Forest tab', (
    tester,
  ) async {
    var forestTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: CalendarScreen(
          summary: const ForestSummary(
            days: [],
            currentStreak: 0,
            healthyTreeCount: 0,
            witheredTreeCount: 0,
            restoredTreeCount: 0,
            achievements: [],
          ),
          shopState: ShopService().initialState(),
          onShowForest: () => forestTapped = true,
          onShowHomestead: () {},
          onShowReport: () {},
          onShowAchievements: () {},
          onShowShop: () {},
        ),
      ),
    );

    await tester.tap(find.text('Forest'));
    await tester.pumpAndSettle();

    expect(forestTapped, isTrue);
  });
}
