import 'package:flutter/foundation.dart';
import '../../ui/models/product_item.dart';
import '../../ui/products/inventory_product_item.dart';
import '../pos_local_store.dart';

/// Focused, injectable Inventory & Product Catalog Service.
///
/// Can be injected directly via `Provider<InventoryService>` or accessed through `store.inventoryService`.
class InventoryService extends ChangeNotifier {
  InventoryService(this._store) {
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

  List<ProductItem> get products => _store.products;
  List<InventoryProductItem> get inventory => _store.inventory;

  int availableStockForProduct(String code) =>
      _store.availableStockForProduct(code);

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
