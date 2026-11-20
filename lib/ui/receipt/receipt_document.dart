import 'package:intl/intl.dart';
import '../../l10n/app_strings.dart';
import '../../service/pos_order_models.dart';
import '../../service/receipt_settings.dart';

/// The saved sale is the source of truth for screen, PDF and shared receipt text.
class ReceiptDocument {
  const ReceiptDocument(
      {required this.order,
      required this.storeName,
      this.storeAddress = '',
      this.storePhone = '',
      this.storeTaxId = '',
      this.storeLogoPath,
      this.currency = 'TSh',
      this.languageCode = 'en',
      this.settings = const ReceiptSettings()});
  final CompletedOrder order;
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String storeTaxId;
  final String? storeLogoPath;
  final String currency;
  final String languageCode;
  AppStrings get strings => AppStrings.of(languageCode);
  String label(String key) => strings.text(key);
  String get paymentLabel => strings.paymentMethod(order.paymentMethod);
  final ReceiptSettings settings;

  String get businessName =>
      storeName.trim().isEmpty ? label('Store receipt') : storeName.trim();
  String money(double value) =>
      '${currency.trim().isEmpty ? 'TSh' : currency.trim()} ${NumberFormat('#,##0.00').format(value)}';
  double get subtotal =>
      order.lines.fold(0, (total, line) => total + line.lineTotal);
  int get units => order.lines.fold(0, (total, line) => total + line.quantity);
  bool get isCash => order.paymentMethod.trim().toLowerCase() == 'cash';
  bool get isCredit => order.paymentMethod.toLowerCase().contains('credit');
  bool get isVoided =>
      RegExp(r'void|cancel', caseSensitive: false).hasMatch(order.status);
  String get statusLabel => isVoided
      ? label('Voided sale')
      : isCredit
          ? label('Credit sale recorded')
          : label('Sale completed');
  String get footer => settings.footer.trim().isEmpty
      ? label('Thank you for your business.')
      : settings.footer.trim();

  List<MapEntry<String, String>> get metadata => [
        if (settings.showOrderNumber) MapEntry(label('Receipt'), order.receiptNo),
        if (settings.showDateTime)
          MapEntry(label('Date'), '${order.date} ${order.time}'.trim()),
        if (settings.showCashier) MapEntry(label('Cashier'), order.cashierName),
        if (settings.showCustomer &&
            order.customerName?.trim().isNotEmpty == true)
          MapEntry(label('Customer'), order.customerName!.trim()),
        if (settings.showPaymentMethod)
          MapEntry(label('Payment'), paymentLabel),
        if (settings.showItemCount) MapEntry(label('Items'), strings.text('{p0} units', args: {'p0': units})),
      ];

  List<MapEntry<String, String>> get totals => [
        MapEntry(label('Subtotal'), money(subtotal)),
        if (settings.showDiscount && (order.discountAmount ?? 0) > 0)
          MapEntry(
              order.discountLabel?.trim().isNotEmpty == true
                  ? order.discountLabel!
                  : label('Discount'),
              '- ${money(order.discountAmount!)}'),
        MapEntry(label('Total'), money(order.total)),
        if (!isVoided && isCash) ...[
          MapEntry(label('Cash received'), money(order.cashTendered)),
          MapEntry(label('Change due'), money(order.changeDue)),
        ] else if (!isVoided && isCredit)
          MapEntry(label('Balance due'), money(order.total)),
      ];

  String toText() {
    final text = StringBuffer()..writeln(businessName);
    if (settings.showStoreContact && storeAddress.trim().isNotEmpty)
      text.writeln(storeAddress.trim());
    if (settings.showStoreContact && storePhone.trim().isNotEmpty)
      text.writeln(storePhone.trim());
    if (settings.showTaxId && storeTaxId.trim().isNotEmpty)
      text.writeln('TIN: ${storeTaxId.trim()}');
    if (settings.header.trim().isNotEmpty) text.writeln(settings.header.trim());
    text.writeln(statusLabel);
    for (final item in metadata) {
      text.writeln('${item.key}: ${item.value}');
    }
    text.writeln('');
    for (final line in order.lines) {
      text.writeln(
          '${line.itemName} | ${line.quantity} x ${money(line.unitPriceValue)} | ${money(line.lineTotal)}');
    }
    text.writeln('');
    for (final total in totals) {
      text.writeln('${total.key}: ${total.value}');
    }
    text.writeln(footer);
    return text.toString();
  }
}
