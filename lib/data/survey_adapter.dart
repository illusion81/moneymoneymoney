// Bridges Lane C's questionnaire to Lane A's backend.
//
// The app asks the questions; the backend turns them into allocation
// percentages, a plan, missions and the tower. Without this, the two halves
// compute different things from the same person and /api/plan returns 409.

import '../models/finance_profile.dart';
import '../services/risk_assessment.dart';
import 'models.dart';

/// Risk appetite is 1..5 on the backend; the questionnaire offers three steps.
int _risk(RiskLevel p) => switch (p) {
  RiskLevel.cautious => 1,
  RiskLevel.steady => 2,
  RiskLevel.balanced => 3,
  RiskLevel.growth => 4,
  RiskLevel.aggressive => 5,
};

/// How far ahead they're planning, inferred from the goal they picked.
/// Short horizons make the backend keep money liquid instead of locking it up.
int _horizonMonths(FinancialGoal g) => switch (g) {
  FinancialGoal.emergencyFund => 6,
  FinancialGoal.reduceSpending => 6,
  FinancialGoal.debtControl => 12,
  FinancialGoal.saveForPurchase => 18,
  FinancialGoal.invest => 36,
};

/// The worry drives which missions get generated first.
String _worry(FinancialGoal g, SpendingPressure p) {
  if (g == FinancialGoal.reduceSpending) {
    return p == SpendingPressure.high ? 'impulse' : 'subscriptions';
  }
  return switch (p) {
    SpendingPressure.high => 'impulse',
    SpendingPressure.medium => 'subscriptions',
    SpendingPressure.low => 'none',
  };
}

/// Someone already targeting an emergency fund does not have one yet — that is
/// the whole reason it is their goal. The backend uses this to route everything
/// to a cushion before it allows any growth allocation.
bool _hasBuffer(FinancialGoal g) => g != FinancialGoal.emergencyFund;

extension FinanceProfileSurvey on FinanceProfile {
  SurveyAnswers toSurveyAnswers() => SurveyAnswers(
    monthlyIncome: monthlyIncome,
    fixedCosts: fixedMonthlyExpenses,
    riskAppetite: _risk(riskLevel),
    horizonMonths: _horizonMonths(financialGoal),
    hasEmergencyFund: _hasBuffer(financialGoal),
    topWorry: _worry(financialGoal, spendingPressure),
  );
}
