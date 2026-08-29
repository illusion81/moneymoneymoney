import '../data/models.dart';

/// A concrete, daily-sized cut derived from where the money actually went.
class DailySavingPlan {
  const DailySavingPlan({
    required this.category,
    required this.monthlyCategorySpend,
    required this.monthlySaving,
    required this.dailySaving,
    required this.trimFraction,
  });

  /// The category being trimmed, e.g. 'eating-out'.
  final String category;

  /// What that category currently costs per month.
  final double monthlyCategorySpend;

  /// What the proposed trim saves per month, and per day.
  final double monthlySaving;
  final double dailySaving;

  /// The proportion of the category being trimmed, 0..1.
  final double trimFraction;
}

/// Categories a person can realistically choose to spend less on. Rent,
/// utilities and debt are excluded deliberately — telling someone to "spend
/// 30% less on housing" is not advice they can act on this week.
const Set<String> _discretionaryCategories = {
  'eating-out',
  'subscriptions',
  'lifestyle',
  'bnpl',
};

bool _isTransfer(Txn t) =>
    t.category == 'transfer' ||
    t.category == 'transfer-in' ||
    t.category == 'transfer-out';

/// Finds the biggest discretionary category in [transactions] covering
/// [days] and proposes trimming it by [trimFraction], expressed as a daily
/// figure. Returns null when there is nothing discretionary to cut, so the
/// UI can stay silent rather than inventing advice.
DailySavingPlan? buildDailySavingPlan(
  List<Txn> transactions, {
  required int days,
  double trimFraction = 0.30,
}) {
  if (days <= 0 || transactions.isEmpty) {
    return null;
  }

  final totals = <String, double>{};
  for (final t in transactions) {
    if (!t.isSpend || _isTransfer(t)) {
      continue;
    }
    if (!_discretionaryCategories.contains(t.category)) {
      continue;
    }
    totals[t.category] = (totals[t.category] ?? 0) + -t.amount;
  }
  if (totals.isEmpty) {
    return null;
  }

  final biggest = totals.entries.reduce((a, b) => b.value > a.value ? b : a);
  final monthly = biggest.value * 30 / days;
  final monthlySaving = monthly * trimFraction;

  return DailySavingPlan(
    category: biggest.key,
    monthlyCategorySpend: monthly,
    monthlySaving: monthlySaving,
    dailySaving: monthlySaving / 30,
    trimFraction: trimFraction,
  );
}
