/// Formats an amount for display.
///
/// Cents are shown below $1000 and dropped above it, where two decimal
/// places are noise rather than information. The threshold uses the
/// magnitude, so a large negative amount is abbreviated the same way.
String formatMoney(double value) {
  return '\$${value.toStringAsFixed(value.abs() >= 1000 ? 0 : 2)}';
}

/// Turns an internal category or bucket id into something a person reads:
/// 'eating-out' -> 'Eating out', 'invest' -> 'Invest'.
///
/// These ids come from the backend classifier and are lowercase kebab-case by
/// design — that is right for code and wrong for a screen.
String prettyLabel(String id) {
  if (id.isEmpty) return id;
  final words = id.replaceAll('-', ' ').replaceAll('_', ' ');
  return words[0].toUpperCase() + words.substring(1);
}
