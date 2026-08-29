class BenchmarkComparison {
  const BenchmarkComparison({
    required this.differences,
    required this.overspendFlags,
  });
  final Map<String, double> differences; // user - benchmark, per category
  final List<String> overspendFlags;     // categories flagged as overspending
}

BenchmarkComparison benchmarkComparator(
  Map<String, double> userExpenseRatios,   // category -> percentage
  Map<String, double> benchmarkRatios,     // category -> percentage
  {double flagTolerance = 5.0}) {
  final keys = <String>{...userExpenseRatios.keys, ...benchmarkRatios.keys};
  final differences = <String, double>{};
  final overspendFlags = <String>[];

  for (final category in keys) {
    final user = userExpenseRatios[category] ?? 0.0;
    final benchmark = benchmarkRatios[category] ?? 0.0;
    differences[category] = user - benchmark;
    if (user > benchmark + flagTolerance) {
      overspendFlags.add(category);
    }
  }

  return BenchmarkComparison(
    differences: differences,
    overspendFlags: overspendFlags,
  );
}

const Map<String, double> nationalBenchmark = {
  'housing': 30,
  'food': 15,
  'transport': 15,
  'entertainment': 5,
  'savings': 20,
  'other': 15,
};
