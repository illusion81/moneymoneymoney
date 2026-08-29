# Wealth Forest App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the default Flutter counter app with a local AI-style wealth-management forest MVP.

**Architecture:** Keep business logic in focused Dart models and services, with Flutter screens consuming those APIs through top-level in-memory state owned by `MyApp`. The report generator and forest engine are pure Dart units so their behavior can be tested before UI work.

**Tech Stack:** Flutter Material, Dart, `flutter_test`, no external runtime dependencies.

**Spec:** `docs/superpowers/specs/2026-08-29-wealth-forest-design.md`

## Global Constraints

- The app uses a local AI simulation only; it must not call Gemini, OpenAI, or any external service.
- Persistent storage is out of scope; app state stays in memory while the app is running.
- The first usable screen is the questionnaire, not a splash or landing page.
- Use Flutter Material components only.
- Keep UI calm and finance-focused using green, gold, ink, and soft neutral surfaces.
- Invalid numeric form values block questionnaire submission and daily check-in.
- Unrealistic budget profiles still generate a report with a warning and a daily budget of 0.

---

## File Structure

- `lib/main.dart`: app entry, theme, top-level in-memory state, navigation between onboarding, report, home, and achievements views.
- `lib/models/finance_profile.dart`: questionnaire model and enums for risk preference, financial goal, and spending pressure.
- `lib/models/wealth_report.dart`: generated report model.
- `lib/models/forest_day.dart`: daily tree record, tree status enum, achievement model.
- `lib/services/report_generator.dart`: pure local AI-style report generator.
- `lib/services/forest_engine.dart`: pure daily check-in, streak, tree-level, penalty, and achievement logic.
- `lib/screens/onboarding_screen.dart`: questionnaire form UI.
- `lib/screens/report_screen.dart`: generated report UI.
- `lib/screens/home_screen.dart`: forest check-in UI.
- `lib/screens/achievements_screen.dart`: progress and achievement UI.
- `test/report_generator_test.dart`: unit tests for report generation.
- `test/forest_engine_test.dart`: unit tests for forest logic.
- `test/widget_test.dart`: app flow widget tests replacing the default counter test.

---

### Task 1: Finance Profile And Report Generator

**Files:**
- Create: `lib/models/finance_profile.dart`
- Create: `lib/models/wealth_report.dart`
- Create: `lib/services/report_generator.dart`
- Create: `test/report_generator_test.dart`

**Interfaces:**
- Produces: `enum RiskPreference { conservative, balanced, growth }`
- Produces: `enum FinancialGoal { emergencyFund, reduceSpending, saveForPurchase, invest, debtControl }`
- Produces: `enum SpendingPressure { low, medium, high }`
- Produces: `class FinanceProfile { const FinanceProfile({required double monthlyIncome, required double fixedMonthlyExpenses, required double monthlySavingsGoal, required RiskPreference riskPreference, required FinancialGoal financialGoal, required SpendingPressure spendingPressure}); }`
- Produces: `class WealthReport { const WealthReport({required String profileSummary, required double disposableIncome, required double dailyBudget, required String savingsAdvice, required String riskAdvice, required String? warning, required List<String> dailyActions}); }`
- Produces: `class ReportGenerator { WealthReport generate(FinanceProfile profile); }`

- [ ] **Step 1: Write failing report generation tests**

Create `test/report_generator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/finance_profile.dart';
import 'package:moneymoneymoney/services/report_generator.dart';

void main() {
  group('ReportGenerator', () {
    test('calculates disposable income and daily budget from profile', () {
      final report = ReportGenerator().generate(
        const FinanceProfile(
          monthlyIncome: 6000,
          fixedMonthlyExpenses: 2500,
          monthlySavingsGoal: 900,
          riskPreference: RiskPreference.balanced,
          financialGoal: FinancialGoal.emergencyFund,
          spendingPressure: SpendingPressure.medium,
        ),
      );

      expect(report.disposableIncome, 3500);
      expect(report.dailyBudget, closeTo(86.67, 0.01));
      expect(report.warning, isNull);
      expect(report.dailyActions, hasLength(3));
      expect(report.profileSummary, contains('6000'));
    });

    test('warns and sets daily budget to zero when savings target is unrealistic', () {
      final report = ReportGenerator().generate(
        const FinanceProfile(
          monthlyIncome: 3000,
          fixedMonthlyExpenses: 2600,
          monthlySavingsGoal: 800,
          riskPreference: RiskPreference.conservative,
          financialGoal: FinancialGoal.reduceSpending,
          spendingPressure: SpendingPressure.high,
        ),
      );

      expect(report.disposableIncome, 400);
      expect(report.dailyBudget, 0);
      expect(report.warning, isNotNull);
      expect(report.warning, contains('unrealistic'));
      expect(report.dailyActions.join(' '), contains('spending'));
    });

    test('uses risk preference and goal to tailor advice', () {
      final report = ReportGenerator().generate(
        const FinanceProfile(
          monthlyIncome: 8000,
          fixedMonthlyExpenses: 3000,
          monthlySavingsGoal: 1200,
          riskPreference: RiskPreference.growth,
          financialGoal: FinancialGoal.invest,
          spendingPressure: SpendingPressure.low,
        ),
      );

      expect(report.riskAdvice, contains('long-term'));
      expect(report.savingsAdvice, contains('1200'));
      expect(report.dailyActions.join(' '), contains('investment'));
    });
  });
}
```

- [ ] **Step 2: Run tests and verify red**

Run: `flutter test test/report_generator_test.dart`

Expected: FAIL because `models/finance_profile.dart` and `services/report_generator.dart` do not exist.

- [ ] **Step 3: Implement models and generator**

Create `lib/models/finance_profile.dart`:

```dart
enum RiskPreference { conservative, balanced, growth }

enum FinancialGoal {
  emergencyFund,
  reduceSpending,
  saveForPurchase,
  invest,
  debtControl,
}

enum SpendingPressure { low, medium, high }

class FinanceProfile {
  const FinanceProfile({
    required this.monthlyIncome,
    required this.fixedMonthlyExpenses,
    required this.monthlySavingsGoal,
    required this.riskPreference,
    required this.financialGoal,
    required this.spendingPressure,
  });

  final double monthlyIncome;
  final double fixedMonthlyExpenses;
  final double monthlySavingsGoal;
  final RiskPreference riskPreference;
  final FinancialGoal financialGoal;
  final SpendingPressure spendingPressure;
}
```

Create `lib/models/wealth_report.dart`:

```dart
class WealthReport {
  const WealthReport({
    required this.profileSummary,
    required this.disposableIncome,
    required this.dailyBudget,
    required this.savingsAdvice,
    required this.riskAdvice,
    required this.warning,
    required this.dailyActions,
  });

  final String profileSummary;
  final double disposableIncome;
  final double dailyBudget;
  final String savingsAdvice;
  final String riskAdvice;
  final String? warning;
  final List<String> dailyActions;
}
```

Create `lib/services/report_generator.dart`:

```dart
import '../models/finance_profile.dart';
import '../models/wealth_report.dart';

class ReportGenerator {
  WealthReport generate(FinanceProfile profile) {
    final disposableIncome =
        profile.monthlyIncome - profile.fixedMonthlyExpenses;
    final flexibleMonthly =
        disposableIncome - profile.monthlySavingsGoal;
    final dailyBudget = flexibleMonthly > 0 ? flexibleMonthly / 30 : 0.0;
    final warning = flexibleMonthly < 0
        ? 'Your current savings target looks unrealistic because fixed expenses and savings exceed income.'
        : flexibleMonthly < profile.monthlyIncome * 0.1
            ? 'Your flexible budget is tight. Keep daily spending deliberate.'
            : null;

    return WealthReport(
      profileSummary:
          'Monthly income ${profile.monthlyIncome.toStringAsFixed(0)}, fixed expenses ${profile.fixedMonthlyExpenses.toStringAsFixed(0)}, and target savings ${profile.monthlySavingsGoal.toStringAsFixed(0)}.',
      disposableIncome: disposableIncome,
      dailyBudget: double.parse(dailyBudget.toStringAsFixed(2)),
      savingsAdvice:
          'Protect ${profile.monthlySavingsGoal.toStringAsFixed(0)} each month before flexible spending.',
      riskAdvice: _riskAdvice(profile.riskPreference),
      warning: warning,
      dailyActions: _dailyActions(profile),
    );
  }

  String _riskAdvice(RiskPreference preference) {
    switch (preference) {
      case RiskPreference.conservative:
        return 'Prioritize a cash buffer and low-volatility choices before taking extra risk.';
      case RiskPreference.balanced:
        return 'Split attention between steady savings and learning broad investing basics.';
      case RiskPreference.growth:
        return 'Use a long-term investment mindset, but only after daily spending stays controlled.';
    }
  }

  List<String> _dailyActions(FinanceProfile profile) {
    final pressureText = profile.spendingPressure == SpendingPressure.high
        ? 'Set a hard spending pause before any non-essential purchase.'
        : 'Review one non-essential purchase before paying.';

    switch (profile.financialGoal) {
      case FinancialGoal.emergencyFund:
        return [
          'Move a small amount into your emergency fund.',
          'Record every expense today.',
          pressureText,
        ];
      case FinancialGoal.reduceSpending:
        return [
          'Review spending before buying anything non-essential.',
          'Record every expense today.',
          pressureText,
        ];
      case FinancialGoal.saveForPurchase:
        return [
          'Move money toward your purchase goal.',
          'Record every expense today.',
          pressureText,
        ];
      case FinancialGoal.invest:
        return [
          'Read one short investment note before making decisions.',
          'Record every expense today.',
          pressureText,
        ];
      case FinancialGoal.debtControl:
        return [
          'Avoid adding new debt today.',
          'Record every expense today.',
          pressureText,
        ];
    }
  }
}
```

- [ ] **Step 4: Run tests and verify green**

Run: `flutter test test/report_generator_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/finance_profile.dart lib/models/wealth_report.dart lib/services/report_generator.dart test/report_generator_test.dart
git commit -m "feat: add local wealth report generator"
```

---

### Task 2: Forest Engine And Achievements

**Files:**
- Create: `lib/models/forest_day.dart`
- Create: `lib/services/forest_engine.dart`
- Create: `test/forest_engine_test.dart`

**Interfaces:**
- Consumes: `WealthReport`
- Produces: `enum TreeStatus { pending, healthy, withered }`
- Produces: `class ForestDay { const ForestDay({required DateTime date, required TreeStatus status, required int treeLevel, required double spending, required bool actionCompleted, required String message}); }`
- Produces: `class Achievement { const Achievement({required String id, required String title, required String description, required bool unlocked}); }`
- Produces: `class ForestSummary { const ForestSummary({required List<ForestDay> days, required int currentStreak, required int healthyTreeCount, required int witheredTreeCount, required List<Achievement> achievements}); }`
- Produces: `class CheckInResult { const CheckInResult({required ForestDay day, required ForestSummary summary}); }`
- Produces: `class ForestEngine { CheckInResult checkIn({required List<ForestDay> existingDays, required WealthReport report, required DateTime date, required double spending, required bool actionCompleted}); ForestSummary summarize(List<ForestDay> days); }`

- [ ] **Step 1: Write failing forest engine tests**

Create `test/forest_engine_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/forest_day.dart';
import 'package:moneymoneymoney/models/wealth_report.dart';
import 'package:moneymoneymoney/services/forest_engine.dart';

void main() {
  const report = WealthReport(
    profileSummary: 'summary',
    disposableIncome: 3000,
    dailyBudget: 50,
    savingsAdvice: 'save',
    riskAdvice: 'risk',
    warning: null,
    dailyActions: ['Record every expense today.'],
  );

  group('ForestEngine', () {
    test('marks today healthy when action is complete and spending is within budget', () {
      final result = ForestEngine().checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 40,
        actionCompleted: true,
      );

      expect(result.day.status, TreeStatus.healthy);
      expect(result.day.treeLevel, 1);
      expect(result.summary.currentStreak, 1);
      expect(result.summary.healthyTreeCount, 1);
    });

    test('marks today withered when action is incomplete', () {
      final result = ForestEngine().checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 20,
        actionCompleted: false,
      );

      expect(result.day.status, TreeStatus.withered);
      expect(result.day.treeLevel, 0);
      expect(result.day.message, contains('action'));
      expect(result.summary.currentStreak, 0);
    });

    test('marks today withered when spending exceeds daily budget', () {
      final result = ForestEngine().checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 75,
        actionCompleted: true,
      );

      expect(result.day.status, TreeStatus.withered);
      expect(result.day.message, contains('budget'));
      expect(result.summary.witheredTreeCount, 1);
    });

    test('unlocks streak and budget achievements', () {
      final engine = ForestEngine();
      final first = engine.checkIn(
        existingDays: const [],
        report: report,
        date: DateTime(2026, 8, 27),
        spending: 30,
        actionCompleted: true,
      );
      final second = engine.checkIn(
        existingDays: first.summary.days,
        report: report,
        date: DateTime(2026, 8, 28),
        spending: 35,
        actionCompleted: true,
      );
      final third = engine.checkIn(
        existingDays: second.summary.days,
        report: report,
        date: DateTime(2026, 8, 29),
        spending: 39,
        actionCompleted: true,
      );

      final unlocked = third.summary.achievements
          .where((achievement) => achievement.unlocked)
          .map((achievement) => achievement.title);

      expect(third.day.treeLevel, 2);
      expect(third.summary.currentStreak, 3);
      expect(unlocked, contains('First Sapling'));
      expect(unlocked, contains('Three Day Streak'));
      expect(unlocked, contains('Budget Guardian'));
    });
  });
}
```

- [ ] **Step 2: Run tests and verify red**

Run: `flutter test test/forest_engine_test.dart`

Expected: FAIL because `models/forest_day.dart` and `services/forest_engine.dart` do not exist.

- [ ] **Step 3: Implement forest models and engine**

Create `lib/models/forest_day.dart`:

```dart
enum TreeStatus { pending, healthy, withered }

class ForestDay {
  const ForestDay({
    required this.date,
    required this.status,
    required this.treeLevel,
    required this.spending,
    required this.actionCompleted,
    required this.message,
  });

  final DateTime date;
  final TreeStatus status;
  final int treeLevel;
  final double spending;
  final bool actionCompleted;
  final String message;
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;
}

class ForestSummary {
  const ForestSummary({
    required this.days,
    required this.currentStreak,
    required this.healthyTreeCount,
    required this.witheredTreeCount,
    required this.achievements,
  });

  final List<ForestDay> days;
  final int currentStreak;
  final int healthyTreeCount;
  final int witheredTreeCount;
  final List<Achievement> achievements;
}

class CheckInResult {
  const CheckInResult({
    required this.day,
    required this.summary,
  });

  final ForestDay day;
  final ForestSummary summary;
}
```

Create `lib/services/forest_engine.dart`:

```dart
import '../models/forest_day.dart';
import '../models/wealth_report.dart';

class ForestEngine {
  CheckInResult checkIn({
    required List<ForestDay> existingDays,
    required WealthReport report,
    required DateTime date,
    required double spending,
    required bool actionCompleted,
  }) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final previousDays = existingDays
        .where((day) => !_isSameDate(day.date, normalizedDate))
        .toList();
    final overBudget = spending > report.dailyBudget;
    final healthy = actionCompleted && !overBudget;
    final provisionalDays = [
      ...previousDays,
      ForestDay(
        date: normalizedDate,
        status: healthy ? TreeStatus.healthy : TreeStatus.withered,
        treeLevel: 0,
        spending: spending,
        actionCompleted: actionCompleted,
        message: _message(actionCompleted: actionCompleted, overBudget: overBudget),
      ),
    ]..sort((a, b) => a.date.compareTo(b.date));
    final streak = _currentStreak(provisionalDays);
    final day = provisionalDays.last;
    final updatedDay = ForestDay(
      date: day.date,
      status: day.status,
      treeLevel: day.status == TreeStatus.healthy ? _treeLevel(streak) : 0,
      spending: day.spending,
      actionCompleted: day.actionCompleted,
      message: day.message,
    );
    final updatedDays = [
      ...provisionalDays.take(provisionalDays.length - 1),
      updatedDay,
    ];

    return CheckInResult(
      day: updatedDay,
      summary: summarize(updatedDays),
    );
  }

  ForestSummary summarize(List<ForestDay> days) {
    final orderedDays = [...days]..sort((a, b) => a.date.compareTo(b.date));
    final healthyTreeCount =
        orderedDays.where((day) => day.status == TreeStatus.healthy).length;
    final witheredTreeCount =
        orderedDays.where((day) => day.status == TreeStatus.withered).length;
    final currentStreak = _currentStreak(orderedDays);

    return ForestSummary(
      days: orderedDays,
      currentStreak: currentStreak,
      healthyTreeCount: healthyTreeCount,
      witheredTreeCount: witheredTreeCount,
      achievements: _achievements(
        days: orderedDays,
        currentStreak: currentStreak,
        healthyTreeCount: healthyTreeCount,
      ),
    );
  }

  String _message({required bool actionCompleted, required bool overBudget}) {
    if (!actionCompleted && overBudget) {
      return 'Today withered because the action was incomplete and spending exceeded the budget.';
    }
    if (!actionCompleted) {
      return 'Today withered because the money action was not completed.';
    }
    if (overBudget) {
      return 'Today withered because spending exceeded the daily budget.';
    }
    return 'Healthy growth: action complete and spending stayed within budget.';
  }

  int _treeLevel(int streak) {
    if (streak >= 7) {
      return 3;
    }
    if (streak >= 3) {
      return 2;
    }
    return 1;
  }

  int _currentStreak(List<ForestDay> days) {
    var streak = 0;
    for (final day in days.reversed) {
      if (day.status == TreeStatus.healthy) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  List<Achievement> _achievements({
    required List<ForestDay> days,
    required int currentStreak,
    required int healthyTreeCount,
  }) {
    final budgetGuardian = days.any(
      (day) => day.status == TreeStatus.healthy && day.spending <= 40,
    );
    final recoveryDay = _hasRecoveryDay(days);

    return [
      Achievement(
        id: 'first-sapling',
        title: 'First Sapling',
        description: 'Grow your first healthy wealth tree.',
        unlocked: healthyTreeCount >= 1,
      ),
      Achievement(
        id: 'three-day-streak',
        title: 'Three Day Streak',
        description: 'Keep your plan alive for three days.',
        unlocked: currentStreak >= 3,
      ),
      Achievement(
        id: 'budget-guardian',
        title: 'Budget Guardian',
        description: 'Finish a day below 80 percent of budget.',
        unlocked: budgetGuardian,
      ),
      Achievement(
        id: 'recovery-day',
        title: 'Recovery Day',
        description: 'Grow again after a withered day.',
        unlocked: recoveryDay,
      ),
      Achievement(
        id: 'forest-builder',
        title: 'Forest Builder',
        description: 'Grow seven healthy trees.',
        unlocked: healthyTreeCount >= 7,
      ),
    ];
  }

  bool _hasRecoveryDay(List<ForestDay> days) {
    for (var index = 1; index < days.length; index++) {
      if (days[index - 1].status == TreeStatus.withered &&
          days[index].status == TreeStatus.healthy) {
        return true;
      }
    }
    return false;
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
```

- [ ] **Step 4: Run tests and verify green**

Run: `flutter test test/forest_engine_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/models/forest_day.dart lib/services/forest_engine.dart test/forest_engine_test.dart
git commit -m "feat: add wealth forest engine"
```

---

### Task 3: App Shell And Onboarding Flow

**Files:**
- Replace: `lib/main.dart`
- Create: `lib/screens/onboarding_screen.dart`
- Create: `lib/screens/report_screen.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `FinanceProfile`, `WealthReport`, `ReportGenerator`
- Produces: `class MyApp extends StatefulWidget`
- Produces: `class OnboardingScreen extends StatefulWidget { const OnboardingScreen({super.key, required this.onProfileSubmitted}); final ValueChanged<FinanceProfile> onProfileSubmitted; }`
- Produces: `class ReportScreen extends StatelessWidget { const ReportScreen({super.key, required this.report, required this.onStartPlan}); final WealthReport report; final VoidCallback onStartPlan; }`

- [ ] **Step 1: Replace widget test with failing onboarding and report flow tests**

Replace `test/widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/main.dart';

void main() {
  testWidgets('first app screen shows the questionnaire', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Money Profile'), findsOneWidget);
    expect(find.text('Monthly income'), findsOneWidget);
    expect(find.text('Generate Report'), findsOneWidget);
  });

  testWidgets('valid questionnaire submission shows generated report', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.enterText(find.byKey(const Key('income-field')), '6000');
    await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
    await tester.enterText(find.byKey(const Key('savings-field')), '900');
    await tester.tap(find.text('Generate Report'));
    await tester.pumpAndSettle();

    expect(find.text('AI Wealth Report'), findsOneWidget);
    expect(find.textContaining('Daily flexible budget'), findsOneWidget);
    expect(find.text('Start Plan'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run widget tests and verify red**

Run: `flutter test test/widget_test.dart`

Expected: FAIL because the current app still shows the default counter screen.

- [ ] **Step 3: Implement app shell and two screens**

Replace `lib/main.dart` with:

```dart
import 'package:flutter/material.dart';

import 'models/finance_profile.dart';
import 'models/wealth_report.dart';
import 'screens/onboarding_screen.dart';
import 'screens/report_screen.dart';
import 'services/report_generator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  WealthReport? _report;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Money Money',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2f7d50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: _report == null
          ? OnboardingScreen(onProfileSubmitted: _handleProfileSubmitted)
          : ReportScreen(report: _report!, onStartPlan: () {}),
    );
  }

  void _handleProfileSubmitted(FinanceProfile profile) {
    setState(() {
      _report = ReportGenerator().generate(profile);
    });
  }
}
```

Create `lib/screens/onboarding_screen.dart` with a `Form`, three numeric `TextFormField`s keyed `income-field`, `expenses-field`, and `savings-field`, dropdowns defaulting to balanced, emergency fund, and medium pressure, and a submit button labeled `Generate Report`. On valid submit, call `onProfileSubmitted(FinanceProfile(...))`.

Create `lib/screens/report_screen.dart` with title `AI Wealth Report`, report sections, text containing `Daily flexible budget`, warning text when present, all daily actions, and a button labeled `Start Plan`.

- [ ] **Step 4: Run widget tests and verify green**

Run: `flutter test test/widget_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/screens/onboarding_screen.dart lib/screens/report_screen.dart test/widget_test.dart
git commit -m "feat: add wealth onboarding and report flow"
```

---

### Task 4: Forest Home And Achievements UI

**Files:**
- Modify: `lib/main.dart`
- Create: `lib/screens/home_screen.dart`
- Create: `lib/screens/achievements_screen.dart`
- Modify: `test/widget_test.dart`

**Interfaces:**
- Consumes: `WealthReport`, `ForestDay`, `ForestSummary`, `ForestEngine`
- Produces: `class HomeScreen extends StatefulWidget { const HomeScreen({super.key, required this.report, required this.summary, required this.onCheckIn, required this.onShowReport, required this.onShowAchievements}); }`
- Produces: `class AchievementsScreen extends StatelessWidget { const AchievementsScreen({super.key, required this.summary, required this.onBack}); }`

- [ ] **Step 1: Add failing widget tests for starting plan and check-ins**

Append to `test/widget_test.dart`:

```dart
testWidgets('starting the plan shows the forest home screen', (tester) async {
  await tester.pumpWidget(const MyApp());

  await tester.enterText(find.byKey(const Key('income-field')), '6000');
  await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
  await tester.enterText(find.byKey(const Key('savings-field')), '900');
  await tester.tap(find.text('Generate Report'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start Plan'));
  await tester.pumpAndSettle();

  expect(find.text('Wealth Forest'), findsOneWidget);
  expect(find.text('Today\'s money action'), findsOneWidget);
  expect(find.text('Check In'), findsOneWidget);
});

testWidgets('successful check-in changes tree status to healthy', (tester) async {
  await tester.pumpWidget(const MyApp());

  await tester.enterText(find.byKey(const Key('income-field')), '6000');
  await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
  await tester.enterText(find.byKey(const Key('savings-field')), '900');
  await tester.tap(find.text('Generate Report'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start Plan'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('spending-field')), '40');
  await tester.tap(find.byKey(const Key('action-complete-checkbox')));
  await tester.tap(find.text('Check In'));
  await tester.pumpAndSettle();

  expect(find.text('Healthy tree'), findsOneWidget);
});

testWidgets('overspending changes tree status to withered', (tester) async {
  await tester.pumpWidget(const MyApp());

  await tester.enterText(find.byKey(const Key('income-field')), '6000');
  await tester.enterText(find.byKey(const Key('expenses-field')), '2500');
  await tester.enterText(find.byKey(const Key('savings-field')), '900');
  await tester.tap(find.text('Generate Report'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Start Plan'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('spending-field')), '200');
  await tester.tap(find.byKey(const Key('action-complete-checkbox')));
  await tester.tap(find.text('Check In'));
  await tester.pumpAndSettle();

  expect(find.text('Withered tree'), findsOneWidget);
});
```

- [ ] **Step 2: Run widget tests and verify red**

Run: `flutter test test/widget_test.dart`

Expected: FAIL because the report start button does not navigate to the forest home screen yet.

- [ ] **Step 3: Implement home, achievements, and app navigation**

Update `lib/main.dart` to track:

```dart
enum AppView { onboarding, report, home, achievements }
```

State fields:

```dart
WealthReport? _report;
ForestSummary _summary = const ForestSummary(
  days: [],
  currentStreak: 0,
  healthyTreeCount: 0,
  witheredTreeCount: 0,
  achievements: [],
);
AppView _view = AppView.onboarding;
final ForestEngine _forestEngine = ForestEngine();
```

Navigation behavior:

- Submit profile: set `_report`, set `_summary = _forestEngine.summarize(const [])`, set `_view = AppView.report`.
- Start plan: set `_view = AppView.home`.
- Show report: set `_view = AppView.report`.
- Show achievements: set `_view = AppView.achievements`.
- Back from achievements: set `_view = AppView.home`.
- Check-in: call `_forestEngine.checkIn(...)` with `DateTime.now()`, update `_summary`.

Create `lib/screens/home_screen.dart`:

- Shows `Wealth Forest`.
- Shows large tree visual using `Icons.park`, `Icons.eco`, or `Icons.yard`.
- Shows exact status text `Healthy tree`, `Withered tree`, or `Ready to grow`.
- Shows `Today's money action`.
- Shows daily budget.
- Provides `TextField` keyed `spending-field`.
- Provides `CheckboxListTile` keyed `action-complete-checkbox`.
- Provides `Check In` button.
- Provides buttons for `Report` and `Achievements`.

Create `lib/screens/achievements_screen.dart`:

- Shows `Achievements`.
- Shows current streak, healthy trees, withered trees.
- Shows each achievement from `ForestSummary.achievements`.
- Locked achievements display `Locked`.
- Unlocked achievements display `Unlocked`.
- Provides `Back to Forest` button.

- [ ] **Step 4: Run widget tests and verify green**

Run: `flutter test test/widget_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/main.dart lib/screens/home_screen.dart lib/screens/achievements_screen.dart test/widget_test.dart
git commit -m "feat: add wealth forest check-in UI"
```

---

### Task 5: Polish, Full Verification, And Push

**Files:**
- Modify as needed: `lib/**/*.dart`
- Modify as needed: `test/**/*.dart`

**Interfaces:**
- Consumes all previous tasks.
- Produces a passing, runnable Flutter MVP on branch `alan`.

- [ ] **Step 1: Run static analysis**

Run: `flutter analyze`

Expected: exits 0. Fix any lints in the files touched by this plan.

- [ ] **Step 2: Run full test suite**

Run: `flutter test`

Expected: exits 0 with all unit and widget tests passing.

- [ ] **Step 3: Inspect final status**

Run: `git status --short --branch`

Expected: branch `alan`, clean except intentional final edits before commit.

- [ ] **Step 4: Commit final polish if needed**

If Step 1 or Step 2 required code edits:

```bash
git add lib test
git commit -m "chore: polish wealth forest app"
```

- [ ] **Step 5: Push branch**

Run: `git push origin alan`

Expected: remote `alan` receives all new commits.

---

## Self-Review

- Spec coverage: questionnaire, local report generation, report screen, forest check-in, withered penalty, achievements, no persistence, and local-only AI are each covered by tasks.
- Placeholder scan: no task depends on unspecified external services or future persistence.
- Type consistency: model and service names used by UI tasks match the interfaces produced in Tasks 1 and 2.
