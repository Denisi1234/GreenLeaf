import 'package:flutter/foundation.dart';
import '../../ui/models/product_item.dart';
import '../pos_order_models.dart';
import '../pos_suspended_sale_model.dart';
import '../pos_local_store.dart';

/// Focused, injectable Sales & Checkout Service.
///
/// Can be injected directly via `Provider<SalesService>` or accessed through `store.salesService`.
class SalesService extends ChangeNotifier {
  SalesService(this._store) {
    _store.addListener(_onStoreUpdate);
  }

  final PosLocalStore _store;

  void _onStoreUpdate() {
    notifyListeners();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreUpdate);
    super.dispose();
  }

  List<ProductItem> get cartItems => _store.cartItems;
  List<CompletedOrder> get orders => _store.orders;
  List<SuspendedSale> get suspendedSales => _store.suspendedSales;
  double get cartSubtotal => _store.cartSubtotal;
  double get cartTax => _store.cartTax;
  double get cartTotal => _store.cartTotal;
  int get cartCount => _store.cartCount;

  void addToCart(ProductItem product) => _store.addToCart(product);

  void addToCartQuantity(ProductItem product, int quantity) =>
      _store.addToCartQuantity(product, quantity);

  void removeSingleFromCart(int index) => _store.removeSingleFromCart(index);

  void removeFromCart(int index) => _store.removeFromCart(index);

  void updateQuantity(int index, int delta) => _store.updateQuantity(index, delta);

  Future<void> clearCart() => _store.clearCart();

  Future<SuspendedSale?> suspendCurrentSale({
    String? customerName,
    String? comment,
  }) =>
      _store.suspendCurrentSale(customerName: customerName, comment: comment);

  Future<void> resumeSuspendedSale(String id) => _store.resumeSuspendedSale(id);

  void deleteSuspendedSale(String id) => _store.deleteSuspendedSale(id);

  Future<CompletedOrder> completeCashSale({
    required List<ProductItem> items,
    required double cashTendered,
    required String cashierName,
    required String registerName,
    String? customerName,
    double discountAmount = 0.0,
    String? discountLabel,
    String paymentMethod = 'Cash',
  }) =>
      _store.completeCashSale(
        items: items,
        cashTendered: cashTendered,
        cashierName: cashierName,
        registerName: registerName,
        customerName: customerName,
        discountAmount: discountAmount,
        discountLabel: discountLabel,
        paymentMethod: paymentMethod,
      );

  Future<void> voidOrder(String orderId) => _store.voidOrder(orderId);

  Future<void> reopenOrderForEdit(String orderId) =>
      _store.reopenOrderForEdit(orderId);
}
