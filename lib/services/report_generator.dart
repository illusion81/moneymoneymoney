import '../models/finance_profile.dart';
import '../models/money_style.dart';
import 'risk_assessment.dart';
import '../models/wealth_report.dart';

class ReportGenerator {
  WealthReport generate(FinanceProfile profile, {String? style}) {
    final disposableIncome =
        profile.monthlyIncome - profile.fixedMonthlyExpenses;
    final flexibleMonthly = disposableIncome - profile.monthlySavingsGoal;
    final dailyBudget = flexibleMonthly > 0 ? flexibleMonthly / 30 : 0.0;
    final String? warning;
    if (flexibleMonthly < 0) {
      warning =
          'Your current savings target looks unrealistic because fixed expenses and savings exceed income.';
    } else if (flexibleMonthly < profile.monthlyIncome * 0.1) {
      warning =
          'Your flexible budget is tight. Keep daily spending deliberate.';
    } else {
      warning = null;
    }

    return WealthReport(
      profileSummary:
          'Monthly income ${profile.monthlyIncome.toStringAsFixed(0)}, fixed expenses ${profile.fixedMonthlyExpenses.toStringAsFixed(0)}, and target savings ${profile.monthlySavingsGoal.toStringAsFixed(0)}.',
      disposableIncome: disposableIncome,
      dailyBudget: double.parse(dailyBudget.toStringAsFixed(2)),
      savingsAdvice:
          'Protect ${profile.monthlySavingsGoal.toStringAsFixed(0)} each month before flexible spending.',
      riskAdvice: _riskAdvice(profile.riskLevel),
      warning: warning,
      dailyActions: [..._dailyActions(profile), ?style],
    );
  }

  String _riskAdvice(RiskLevel level) {
    switch (level) {
      case RiskLevel.cautious:
        return 'Keep your money in cash and capital-protected products until a full emergency buffer is in place.';
      case RiskLevel.steady:
        return 'Prioritize a cash buffer and low-volatility choices before taking extra risk.';
      case RiskLevel.balanced:
        return 'Split attention between steady savings and learning broad investing basics.';
      case RiskLevel.growth:
        return 'Use a long-term investment mindset, but only after daily spending stays controlled.';
      case RiskLevel.aggressive:
        return 'You can hold higher-risk, long-term positions — but only while the emergency buffer and daily budget stay intact.';
    }
  }

  List<String> _dailyActions(FinanceProfile profile) {
    final pressureText = profile.spendingPressure == SpendingPressure.high
        ? 'Set a hard spending pause before any non-essential spending.'
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
          'Read one short investment note before making investment decisions.',
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

/// Turns a Money Style result into one extra daily action, so the quiz
/// changes something the user sees every day rather than only a one-off
/// result screen. Returns null when the quiz has not been taken.
String? styleActionFor({required Dimension dimension, required bool positive}) {
  final part = switch (dimension) {
    Dimension.revolvingDebtNeglect =>
      positive
          ? 'Your card payment is already automated — check the interest line once while you are in there'
          : 'Check what your credit card actually charges you, and what it is set to pay',
    Dimension.convenienceImpulse =>
      positive
          ? 'Stick to your own convenience rule today, even if the day goes sideways'
          : 'Decide now what would make a delivery or rideshare worth it tonight',
    Dimension.subscriptionBlindness =>
      positive
          ? 'Keep your subscription list current — glance at one recurring charge today'
          : 'Find one recurring charge you no longer use, and cancel or keep it on purpose',
    Dimension.savingsAvoidance =>
      positive
          ? 'Leave your automatic transfer running, and note how close you are to your target'
          : 'Move any amount, however small, into savings before it gets absorbed',
    Dimension.priceAnchoring =>
      positive
          ? 'Keep naming your own price first — do it once today before you see theirs'
          : 'Before your next spend over \$20, decide what it is worth to you first',
    Dimension.financialAvoidance =>
      positive
          ? 'Keep your check-in on its usual day, whatever you expect it to say'
          : 'Open your banking app for two minutes today, whatever it says',
  };
  return '$part.';
}

/// Convenience for a full [MoneyStyleResult]: leads with the habit the quiz
/// found most critical, and falls back to confirming the strongest one when
/// nothing came out negative.
String? styleActionForResult(MoneyStyleResult? result) {
  if (result == null) {
    return null;
  }
  final critical = result.mostCriticalDimension;
  if (critical != null) {
    return styleActionFor(dimension: critical, positive: false);
  }
  final strongest = result.strongestDimension;
  if (strongest != null) {
    return styleActionFor(dimension: strongest, positive: true);
  }
  return null;
}
