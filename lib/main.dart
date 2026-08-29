import 'package:flutter/material.dart';

import 'models/finance_profile.dart';
import 'models/forest_day.dart';
import 'models/wealth_report.dart';
import 'screens/achievements_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/report_screen.dart';
import 'services/forest_engine.dart';
import 'services/report_generator.dart';

void main() {
  runApp(const MyApp());
}

enum AppView { onboarding, report, home, achievements }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ForestEngine _forestEngine = ForestEngine();
  WealthReport? _report;
  ForestSummary _summary = const ForestSummary(
    days: [],
    currentStreak: 0,
    healthyTreeCount: 0,
    witheredTreeCount: 0,
    achievements: [],
  );
  AppView _view = AppView.onboarding;
  bool _planStarted = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Money Money',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2f7d50),
        ),
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
          onCheckIn: _handleCheckIn,
          onShowReport: () => setState(() => _view = AppView.report),
          onShowAchievements: () =>
              setState(() => _view = AppView.achievements),
        );
      case AppView.achievements:
        return AchievementsScreen(
          summary: _summary,
          onBack: () => setState(() => _view = AppView.home),
        );
    }
  }

  void _handleProfileSubmitted(FinanceProfile profile) {
    setState(() {
      _report = ReportGenerator().generate(profile);
      _summary = _forestEngine.summarize(const []);
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

    setState(() {
      _summary = result.summary;
    });
  }
}
