import '../models/finance_profile.dart';

double _clamp01(double v) => v.isNaN ? 0 : v.clamp(0.0, 1.0);

/// The four classic pillars of financial analysis, each normalized to [0, 1].
///
/// The formulas are deliberately rough stand-ins — each is directionally the
/// ratio it is named after, and each is easy to retune once the app tracks real
/// transactions.
class FinancePillars {
  const FinancePillars({
    required this.profitability,
    required this.liquidity,
    required this.solvency,
    required this.efficiency,
  });

  /// A neutral, healthy-looking default for previews and empty states.
  const FinancePillars.balanced()
    : profitability = 0.55,
      liquidity = 0.55,
      solvency = 0.55,
      efficiency = 0.55;

  factory FinancePillars.fromProfile(FinanceProfile profile) {
    final income = profile.monthlyIncome;
    if (income <= 0) {
      return const FinancePillars(
        profitability: 0,
        liquidity: 0,
        solvency: 0,
        efficiency: 0,
      );
    }

    final expenses = profile.fixedMonthlyExpenses;
    final disposable = income - expenses;
    final flexible = disposable - profile.monthlySavingsGoal;

    return FinancePillars(
      // Operating margin.
      profitability: _clamp01(disposable / income),
      // Buffer left over, against a 30%-of-income target.
      liquidity: _clamp01(flexible / (0.30 * income)),
      // How little of the month is already committed.
      solvency: _clamp01(1 - (expenses / income)),
      // Savings as a share of income, against a 20%-of-income target.
      efficiency: disposable <= 0
          ? 0
          : _clamp01((profile.monthlySavingsGoal / income) / 0.20),
    );
  }

  final double profitability;
  final double liquidity;
  final double solvency;
  final double efficiency;

  /// Below [witheredThreshold] the tree renders withered.
  static const double witheredThreshold = 0.25;

  double get health =>
      (profitability + liquidity + solvency + efficiency) / 4;

  bool get isWithered => health < witheredThreshold;
}