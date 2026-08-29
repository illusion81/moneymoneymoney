class NetWorth {
  const NetWorth({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
  });
  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
}

NetWorth netWorthTracker(Map<String, double> assets, Map<String, double> liabilities) {
  final totalAssets = assets.values.fold(0.0, (sum, value) => sum + value);
  final totalLiabilities = liabilities.values.fold(0.0, (sum, value) => sum + value);
  return NetWorth(
    totalAssets: totalAssets,
    totalLiabilities: totalLiabilities,
    netWorth: totalAssets - totalLiabilities,
  );
}
