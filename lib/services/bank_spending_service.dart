import '../data/models.dart';

/// Sums the absolute value of debit transactions dated [today] (defaults to
/// the current date). Deposits and transactions from other days are ignored.
double sumTodaySpending(List<Txn> transactions, {DateTime? today}) {
  final key = _dateKey(today ?? DateTime.now());
  return transactions
      .where((txn) => txn.postDate == key && txn.isSpend)
      .fold(0.0, (sum, txn) => sum + (-txn.amount));
}

String _dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
