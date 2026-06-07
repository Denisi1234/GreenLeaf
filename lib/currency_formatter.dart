import 'utils/currency_formatter.dart' as utils;

/// Utility class for formatting currency values in Tanzanian Shillings.
class CurrencyFormatter {
  static const String symbol = 'TSH ';

  /// Formats a numeric value as Tanzanian Shilling currency string with thousands separators.
  static String format(double? amount) {
    if (amount == null) return '${symbol}0';
    return utils.formatCurrencyWithPrefix(amount);
  }

  /// Formats a numeric value without currency prefix.
  static String formatCompact(double amount) {
    return utils.formatCurrency(amount);
  }
}
