/// One wedge of the spending breakdown: a category (or the folded "Other"
/// bucket) with its absolute amount and share of total spending.
class CategorySlice {
  const CategorySlice({
    required this.label,
    required this.amount,
    required this.share,
    this.isOther = false,
  });

  final String label;
  final double amount;

  /// Fraction of total spending, 0..1.
  final double share;

  /// True for the aggregate slice that folds together everything past
  /// [topCategorySlices]' `maxSlices` limit.
  final bool isOther;
}

/// Turns `{category: amount}` into at most [maxSlices] wedges ordered
/// largest-first, folding the tail into a single "Other" wedge.
///
/// The cap exists because a pie stops being readable — and a categorical
/// palette stops being distinguishable — past a handful of wedges.
List<CategorySlice> topCategorySlices(
  Map<String, double> byCategory, {
  int maxSlices = 7,
}) {
  final positive = byCategory.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (positive.isEmpty) {
    return const [];
  }

  final total = positive.fold<double>(0, (sum, e) => sum + e.value);
  if (positive.length <= maxSlices) {
    return [
      for (final e in positive)
        CategorySlice(label: e.key, amount: e.value, share: e.value / total),
    ];
  }

  // Keep maxSlices - 1 real categories so the folded "Other" fits the cap.
  final kept = positive.take(maxSlices - 1).toList();
  final otherAmount = positive
      .skip(maxSlices - 1)
      .fold<double>(0, (sum, e) => sum + e.value);

  return [
    for (final e in kept)
      CategorySlice(label: e.key, amount: e.value, share: e.value / total),
    CategorySlice(
      label: 'Other',
      amount: otherAmount,
      share: otherAmount / total,
      isOther: true,
    ),
  ];
}
