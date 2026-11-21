import 'package:flutter/foundation.dart';
import '../../ui/models/product_item.dart';
import '../../ui/products/inventory_product_item.dart';
import '../pos_local_store.dart';

/// Focused, injectable Inventory & Product Catalog Service.
///
/// Can be injected directly via `Provider<InventoryService>` or accessed through `store.inventoryService`.
class InventoryService extends ChangeNotifier {
  InventoryService(this._store) {
    _snapshot = _captureSnapshot();
    _store.addListener(_onStoreUpdate);
  }

  final PosLocalStore _store;
  late (int, int, int) _snapshot;

  (int, int, int) _captureSnapshot() => (
        _store.products.length,
        _store.inventory.length,
        Object.hashAll(
          _store.inventory.map((item) => Object.hash(item.code, item.stockCount, item.sellingPrice, item.name)),
        ),
      );

  void _onStoreUpdate() {
    final next = _captureSnapshot();
    if (next == _snapshot) return;
    _snapshot = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreUpdate);
    super.dispose();
  }

  List<ProductItem> get products => _store.products;
  List<InventoryProductItem> get inventory => _store.inventory;

  int availableStockForProduct(ProductItem product) =>
      _store.availableStockForProduct(product);

  Future<InventoryProductItem> addProduct(InventoryProductItem product) =>
      _store.addProduct(product);

  Future<void> updateProduct(InventoryProductItem product) =>
      _store.updateProduct(product);

  Future<void> removeProduct(String code) => _store.removeProduct(code);

  Future<void> applyInventoryAdjustments(
    Map<String, int> adjustments,
  ) =>
      _store.applyInventoryAdjustments(adjustments);
}
