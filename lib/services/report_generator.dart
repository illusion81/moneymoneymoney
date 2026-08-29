import '../models/finance_profile.dart';
import '../models/wealth_report.dart';

class ReportGenerator {
  WealthReport generate(FinanceProfile profile) {
    final disposableIncome =
        profile.monthlyIncome - profile.fixedMonthlyExpenses;
    final flexibleMonthly = disposableIncome - profile.monthlySavingsGoal;
    final dailyBudget = flexibleMonthly > 0 ? flexibleMonthly / 30 : 0.0;
    final String? warning;
    if (flexibleMonthly < 0) {
      warning =
          'Your current savings target looks unrealistic because fixed expenses and savings exceed income.';
    } else if (flexibleMonthly < profile.monthlyIncome * 0.1) {
      warning = 'Your flexible budget is tight. Keep daily spending deliberate.';
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
