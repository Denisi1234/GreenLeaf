class CurrencyFormatter {
  static const String symbol = 'TSH ';

  static String format(double? amount) {
    return '$symbol${amount?.toStringAsFixed(0) ?? '0'}';
  }
}
