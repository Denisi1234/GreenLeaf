/// Formats a numeric value as Tanzanian Shilling currency string.
/// Returns formatted amount without currency symbol prefix.
String formatCurrency(double value) {
  final whole = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    buffer.write(whole[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

/// Formats a numeric value as full Tanzanian Shilling currency string with prefix.
String formatCurrencyWithPrefix(double value) {
  return 'TSH ${formatCurrency(value)}';
}

/// Widget-friendly currency formatter that can be used in UI.
class CurrencyFormatter {
  const CurrencyFormatter();

  String format(double value) {
    return formatCurrencyWithPrefix(value);
  }

  String formatCompact(double value) {
    return formatCurrency(value);
  }
}
