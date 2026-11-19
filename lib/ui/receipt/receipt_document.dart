import 'package:intl/intl.dart';
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
      this.settings = const ReceiptSettings()});
  final CompletedOrder order;
  final String storeName;
  final String storeAddress;
  final String storePhone;
  final String storeTaxId;
  final String? storeLogoPath;
  final String currency;
  final ReceiptSettings settings;

  String get businessName =>
      storeName.trim().isEmpty ? 'Store receipt' : storeName.trim();
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
      ? 'Voided sale'
      : isCredit
          ? 'Credit sale recorded'
          : 'Sale completed';
  String get footer => settings.footer.trim().isEmpty
      ? 'Thank you for your business.'
      : settings.footer.trim();

  List<MapEntry<String, String>> get metadata => [
        if (settings.showOrderNumber) MapEntry('Receipt', order.receiptNo),
        if (settings.showDateTime)
          MapEntry('Date', '${order.date} ${order.time}'.trim()),
        if (settings.showCashier) MapEntry('Cashier', order.cashierName),
        if (settings.showCustomer &&
            order.customerName?.trim().isNotEmpty == true)
          MapEntry('Customer', order.customerName!.trim()),
        if (settings.showPaymentMethod)
          MapEntry('Payment', order.paymentMethod),
        if (settings.showItemCount) MapEntry('Items', '$units units'),
      ];

  List<MapEntry<String, String>> get totals => [
        MapEntry('Subtotal', money(subtotal)),
        if (settings.showDiscount && (order.discountAmount ?? 0) > 0)
          MapEntry(
              order.discountLabel?.trim().isNotEmpty == true
                  ? order.discountLabel!
                  : 'Discount',
              '- ${money(order.discountAmount!)}'),
        MapEntry('Total', money(order.total)),
        if (!isVoided && isCash) ...[
          MapEntry('Cash received', money(order.cashTendered)),
          MapEntry('Change due', money(order.changeDue)),
        ] else if (!isVoided && isCredit)
          MapEntry('Balance due', money(order.total)),
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
