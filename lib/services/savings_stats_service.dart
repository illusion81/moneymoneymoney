import '../models/forest_day.dart';

enum StatsPeriod { week, month, year }

/// A single point on the surplus-assets line: the running total of money
/// saved (budget minus spending) up to and including this period's bucket.
class SavingsPoint {
  const SavingsPoint({required this.label, required this.cumulativeSaved});

  final String label;
  final double cumulativeSaved;
}

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Buckets checked-in [days] by [period], sums each bucket's saved amount
/// (dailyBudget - spending), and returns the running cumulative total in
/// chronological order — the "surplus assets" line.
List<SavingsPoint> computeSavingsSeries({
  required List<ForestDay> days,
  required StatsPeriod period,
}) {
  final recorded = days.where((day) => day.status != TreeStatus.pending).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final bucketOrder = <String>[];
  final bucketSaved = <String, double>{};
  final bucketLabel = <String, String>{};

  for (final day in recorded) {
    final key = _bucketKey(day.date, period);
    if (!bucketSaved.containsKey(key)) {
      bucketOrder.add(key);
      bucketSaved[key] = 0;
      bucketLabel[key] = _bucketLabel(day.date, period);
    }
    bucketSaved[key] = bucketSaved[key]! + (day.dailyBudget - day.spending);
  }

  var running = 0.0;
  return [
    for (final key in bucketOrder)
      SavingsPoint(
        label: bucketLabel[key]!,
        cumulativeSaved: running += bucketSaved[key]!,
      ),
  ];
}

String _bucketKey(DateTime date, StatsPeriod period) {
  switch (period) {
    case StatsPeriod.week:
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      return '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    case StatsPeriod.month:
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    case StatsPeriod.year:
      return '${date.year}';
  }
}

String _bucketLabel(DateTime date, StatsPeriod period) {
  switch (period) {
    case StatsPeriod.week:
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      return '${_monthNames[weekStart.month - 1]} ${weekStart.day}';
    case StatsPeriod.month:
      return '${_monthNames[date.month - 1]} ${date.year}';
    case StatsPeriod.year:
      return '${date.year}';
  }
}
