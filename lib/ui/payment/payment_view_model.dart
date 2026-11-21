import 'package:flutter/foundation.dart';

import '../../service/pos_local_store.dart';
import '../../service/pos_suspended_sale_model.dart';
import '../../service/tax_settings.dart';
import '../models/product_item.dart';

/// Decoupled state & business-logic controller for [PaymentPage].
///
/// Keeps tax, discount, split-payment, and change calculations out of the
/// widget tree so the UI stays thin and logic is independently testable.
class PaymentViewModel extends ChangeNotifier {
  PaymentViewModel({
    required this.store,
    required List<ProductItem> initialItems,
  }) {
    final byKey = <String, OrderLineItem>{};
    for (final item in initialItems) {
      final key = '${item.name}|${item.size}|${item.price}|${item.type.name}';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = OrderLineItem(product: item, quantity: 1);
      } else {
        existing.quantity += 1;
      }
    }
    _orderLines = byKey.values.toList();
  }

  final PosLocalStore store;
  late final List<OrderLineItem> _orderLines;

  String? _selectedCustomer;
  double _discountAmount = 0;
  String? _discountLabel;
  double? _cashReceived;
  String _paymentMethod = 'Cash';
  final List<SplitPaymentEntry> _splitPayments = <SplitPaymentEntry>[];
  bool _savingSale = false;
  bool _saleCompleted = false;

  List<OrderLineItem> get orderLines => _orderLines;
  String? get selectedCustomer => _selectedCustomer;
  double get discountAmount => _discountAmount;
  String? get discountLabel => _discountLabel;
  double? get cashReceived => _cashReceived;
  String get paymentMethod => _paymentMethod;
  List<SplitPaymentEntry> get splitPayments => _splitPayments;
  bool get savingSale => _savingSale;
  bool get saleCompleted => _saleCompleted;

  double get subtotal =>
      _orderLines.fold(0, (sum, line) => sum + line.totalPrice);
  TaxSettings get taxSettings => store.taxSettings;
  double get appliedDiscount => _discountAmount.clamp(0, subtotal);
  double get netAfterDiscount =>
      (subtotal - appliedDiscount).clamp(0.0, double.infinity).toDouble();
  double get taxAdded => taxSettings.taxFromNet(netAfterDiscount);
  double get tax => taxSettings.pricesIncludeTax
      ? taxSettings.taxFromGross(netAfterDiscount)
      : taxAdded;
  double get grandTotal => ((netAfterDiscount + taxAdded) * 100).round() / 100;
  double get totalSplitPaid =>
      _splitPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
  double get remainingDue =>
      (grandTotal - totalSplitPaid).clamp(0, double.infinity);
  double get changeDue =>
      (_cashReceived != null && _cashReceived! > grandTotal)
          ? _cashReceived! - grandTotal
          : 0;
  int get itemTypes => _orderLines.length;
  int get unitCount => _orderLines.fold(0, (sum, line) => sum + line.quantity);
  bool get hasItems => _orderLines.isNotEmpty;

  void setCustomer(String? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setDiscount(double amount, String? label) {
    _discountAmount = amount;
    _discountLabel = label;
    notifyListeners();
  }

  void setCashReceived(double? amount) {
    _cashReceived = amount;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setSavingSale(bool value) {
    _savingSale = value;
    notifyListeners();
  }

  void markSaleCompleted() {
    _saleCompleted = true;
    notifyListeners();
  }

  void addSplitPayment(SplitPaymentEntry entry) {
    _splitPayments.add(entry);
    notifyListeners();
  }

  void removeSplitPaymentAt(int index) {
    _splitPayments.removeAt(index);
    notifyListeners();
  }

  void clearAll() {
    _orderLines.clear();
    _discountAmount = 0;
    _discountLabel = null;
    _cashReceived = null;
    _splitPayments.clear();
    notifyListeners();
  }
}
