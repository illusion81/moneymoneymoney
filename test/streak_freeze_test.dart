// The freeze is the product's answer to the day someone misses. These tests
// pin the two things that make it trustworthy: it covers the days nearest
// today (so the chain survives), and it never quietly rewards you for a day
// you did not show up.

import 'package:flutter_test/flutter_test.dart';
import 'package:moneymoneymoney/models/forest_day.dart';
import 'package:moneymoneymoney/models/wealth_report.dart';
import 'package:moneymoneymoney/services/forest_engine.dart';

const _report = WealthReport(
  profileSummary: 'summary',
  disposableIncome: 3000,
  dailyBudget: 50,
  savingsAdvice: 'save',
  riskAdvice: 'risk',
  warning: null,
  dailyActions: ['Record every expense today.'],
);

ForestDay _healthy(DateTime date) => ForestDay(
      date: DateTime(date.year, date.month, date.day),
      status: TreeStatus.healthy,
      treeLevel: 1,
      spending: 20,
      dailyBudget: 50,
      actionCompleted: true,
      message: 'ok',
    );

void main() {
  final engine = ForestEngine();
  final today = DateTime(2026, 8, 30);
  DateTime daysAgo(int n) => today.subtract(Duration(days: n));

  test('one missed day is covered and the streak survives', () {
    final days = [for (var i = 5; i >= 2; i--) _healthy(daysAgo(i))];

    final result = engine.checkIn(
      existingDays: days,
      report: _report,
      date: today,
      spending: 20,
      freezesAvailable: 1,
    );

    expect(result.freezesUsed, 1);
    final yesterday = result.summary.days
        .firstWhere((d) => d.date == DateTime(2026, 8, 29));
    expect(yesterday.status, TreeStatus.frozen);
    // 4 healthy + 1 frozen + today = 6
    expect(result.summary.currentStreak, 6);
  });

  test('with no freezes the day withers and the streak resets', () {
    final days = [for (var i = 5; i >= 2; i--) _healthy(daysAgo(i))];

    final result = engine.checkIn(
      existingDays: days,
      report: _report,
      date: today,
      spending: 20,
      freezesAvailable: 0,
    );

    expect(result.freezesUsed, 0);
    expect(result.summary.currentStreak, 1);
  });

  test('freezes cover the most recent days, not the oldest', () {
    // Missed the 26th, 27th, 28th and 29th; only one freeze in hand.
    final days = [_healthy(daysAgo(5))];

    final result = engine.checkIn(
      existingDays: days,
      report: _report,
      date: today,
      spending: 20,
      freezesAvailable: 1,
    );

    expect(result.freezesUsed, 1);
    final byDate = {for (final d in result.summary.days) d.date: d.status};
    expect(byDate[DateTime(2026, 8, 29)], TreeStatus.frozen);
    expect(byDate[DateTime(2026, 8, 28)], TreeStatus.withered);
    // The gap is still broken further back, so the streak is yesterday + today.
    expect(result.summary.currentStreak, 2);
  });

  test('a frozen day is not counted as a healthy day', () {
    final days = [for (var i = 5; i >= 2; i--) _healthy(daysAgo(i))];

    final result = engine.checkIn(
      existingDays: days,
      report: _report,
      date: today,
      spending: 20,
      freezesAvailable: 1,
    );

    expect(result.summary.healthyTreeCount, 5);
    expect(result.summary.witheredTreeCount, 0);
  });

  test('a freeze is never spent when nothing was missed', () {
    final result = engine.checkIn(
      existingDays: [_healthy(daysAgo(1))],
      report: _report,
      date: today,
      spending: 20,
      freezesAvailable: 3,
    );

    expect(result.freezesUsed, 0);
  });
}
