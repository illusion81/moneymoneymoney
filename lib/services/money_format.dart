/// Formats an amount for display.
///
/// Cents are shown below $1000 and dropped above it, where two decimal
/// places are noise rather than information. The threshold uses the
/// magnitude, so a large negative amount is abbreviated the same way.
String formatMoney(double value) {
  return '\$${value.toStringAsFixed(value.abs() >= 1000 ? 0 : 2)}';
}
