import '../data/models.dart';

/// Figures the onboarding form can pre-fill from the bank feed, so the user
/// confirms numbers instead of guessing them from memory.
class ProfileSuggestion {
  const ProfileSuggestion({
    required this.monthlyIncome,
    required this.fixedMonthlyExpenses,
  });

  final double monthlyIncome;
  final double fixedMonthlyExpenses;
}

/// Categories that represent a recurring commitment rather than day-to-day
/// discretionary spending. Groceries and eating-out deliberately excluded —
/// they vary month to month and belong in the flexible budget, not "fixed".
const Set<String> _fixedCategories = {
  'housing',
  'utilities',
  'subscriptions',
  'debt',
  'fees',
};

bool _isTransfer(Txn t) =>
    t.category == 'transfer' ||
    t.category == 'transfer-in' ||
    t.category == 'transfer-out';

/// Derives monthly income and fixed expenses from [transactions] covering
/// [days], normalised to a 30-day month. Returns null when there is nothing
/// to learn from, so the caller can leave the form blank rather than
/// pre-filling zeros the user has to clear.
ProfileSuggestion? suggestProfileFromTransactions(
  List<Txn> transactions, {
  required int days,
}) {
  if (days <= 0 || transactions.isEmpty) {
    return null;
  }

  final usable = transactions.where((t) => !_isTransfer(t));
  final income = usable
      .where((t) => t.amount > 0 && t.category == 'income')
      .fold<double>(0, (sum, t) => sum + t.amount);
  final fixed = usable
      .where((t) => t.isSpend && _fixedCategories.contains(t.category))
      .fold<double>(0, (sum, t) => sum + -t.amount);

  if (income == 0 && fixed == 0) {
    return null;
  }

  final monthly = 30 / days;
  return ProfileSuggestion(
    monthlyIncome: (income * monthly).roundToDouble(),
    fixedMonthlyExpenses: (fixed * monthly).roundToDouble(),
  );
}
