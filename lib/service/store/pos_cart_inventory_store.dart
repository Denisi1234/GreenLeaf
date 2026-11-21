part of '../pos_local_store.dart';

/// Cart operations, suspended sales and inventory management for [PosLocalStore].
mixin PosCartInventoryStore on ChangeNotifier {
  String get _activeStoreId;
  PosLocalDatabase get _database;
  PhpApiClient? get cloudApi;
  bool get _disposed;
  set _lastPersistenceError(String? value);
  bool hasPermission(String permission);
  List<ProductItem> get _products;
  List<ProductItem> get _cartItems;
  List<InventoryProductItem> get _allInventory;
  List<SuspendedSale> get _suspendedSales;
  set _cartCount(int value);
  set _cartTotal(double value);
  StorePreferences get _storePreferences;

  /// Looks up a sellable product matching a scanned or typed barcode/SKU.
  ProductItem? findProductByBarcode(String rawCode) {
    final needle = rawCode.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final item in _allInventory) {
      if (item.code.trim().toLowerCase() == needle) {
        return _toProductItem(item);
      }
      final barcode =
          item.categoryData['barcode']?.toString().trim().toLowerCase();
      if (barcode != null && barcode == needle) {
        return _toProductItem(item);
      }
    }
    for (final product in _products) {
      if (product.code?.trim().toLowerCase() == needle) {
        return product;
      }
    }
    return null;
  }

  bool addToCart(ProductItem product) {
    final inventoryIndex = _findInventoryIndex(product);
    if (inventoryIndex != -1) {
      final availableStock = _allInventory[inventoryIndex].stockCount;
      final currentCartQuantity = _cartItems.where(_sameProduct(product)).length;
      if (availableStock <= 0 || currentCartQuantity >= availableStock) {
        return false;
      }
    }

    _cartItems.add(product);
    _updateCartTotals();
    notifyListeners();
    unawaited(_persistCart());
    return true;
  }

  bool addToCartQuantity(ProductItem product, int quantity) {
    if (quantity <= 0) return false;

    final inventoryIndex = _findInventoryIndex(product);
    if (inventoryIndex != -1) {
      final availableStock = _allInventory[inventoryIndex].stockCount;
      final currentCartQuantity = _cartItems.where(_sameProduct(product)).length;
      if (availableStock <= 0 ||
          currentCartQuantity + quantity > availableStock) {
        return false;
      }
    }

    for (var i = 0; i < quantity; i++) {
      _cartItems.add(product);
    }
    _updateCartTotals();
    notifyListeners();
    unawaited(_persistCart());
    return true;
  }

  bool removeSingleFromCart(ProductItem product) {
    final index = _cartItems.indexWhere(_sameProduct(product));
    if (index == -1) return false;
    _cartItems.removeAt(index);
    _updateCartTotals();
    notifyListeners();
    unawaited(_persistCart());
    return true;
  }

  void removeFromCart(int index) {
    if (index < 0 || index >= _cartItems.length) return;
    _cartItems.removeAt(index);
    _updateCartTotals();
    notifyListeners();
    unawaited(_persistCart());
  }

  void updateQuantity(int index, int delta) {
    if (index < 0 || index >= _cartItems.length) return;
    final item = _cartItems[index];
    if (delta > 0) {
      addToCart(item);
      return;
    }

    _cartItems.removeAt(index);
    _updateCartTotals();
    notifyListeners();
    unawaited(_persistCart());
  }

  Future<void> _persistCart() async {
    try {
      await _database.replaceCart(_cartItems, _activeStoreId);
      _lastPersistenceError = null;
    } catch (error) {
      _lastPersistenceError = error.toString();
    }
    if (!_disposed) notifyListeners();
  }

  List<SuspendedSale> get suspendedSales => List.unmodifiable(_suspendedSales);

  Future<void> _persistSuspendedSales() async {
    await _database.replaceSuspendedSales(
      _suspendedSales.map((s) => s.toJson()).toList(),
      _activeStoreId,
    );
  }

  /// Holds / parks current cart (OSPOS Suspended Sale pattern)
  Future<SuspendedSale?> suspendCurrentSale(
      {String? customerName, String? comment}) async {
    if (_cartItems.isEmpty) return null;
    final sale = SuspendedSale(
      id: 'HOLD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      createdAt: DateTime.now(),
      items: List<ProductItem>.from(_cartItems),
      customerName: customerName,
      comment: comment,
    );
    _suspendedSales.insert(0, sale);
    _cartItems.clear();
    _updateCartTotals();
    notifyListeners();
    await _persistCart();
    await _database.upsertSuspendedSale(sale.toJson(), _activeStoreId);
    return sale;
  }

  /// Resumes a previously suspended sale and puts its items back into the active cart
  Future<void> resumeSuspendedSale(String id) async {
    final index = _suspendedSales.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final sale = _suspendedSales.removeAt(index);
    _cartItems.addAll(sale.items);
    _updateCartTotals();
    notifyListeners();
    await _persistCart();
    await _database.deleteSuspendedSaleRecord(id, _activeStoreId);
  }

  /// Cancels / deletes a suspended sale without resuming it
  Future<void> deleteSuspendedSale(String id) async {
    _suspendedSales.removeWhere((s) => s.id == id);
    notifyListeners();
    await _database.deleteSuspendedSaleRecord(id, _activeStoreId);
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    _updateCartTotals();
    notifyListeners();
    await _database.replaceCart(_cartItems, _activeStoreId);
  }

  Future<InventoryProductItem> addProduct(InventoryProductItem product) async {
    if (!hasPermission('Manage Inventory')) {
      throw StateError('You do not have permission to manage inventory.');
    }
    if (_allInventory.any((item) => item.code == product.code)) {
      throw StateError(
          'A product with this code already exists. Refresh and try again.');
    }
    await _database.upsertInventoryItem(product, _activeStoreId);
    _allInventory.insert(0, product);
    _syncProductsFromInventory();
    notifyListeners();
    return product;
  }

  Future<void> updateProduct(InventoryProductItem product) async {
    if (!hasPermission('Manage Inventory')) {
      throw StateError('You do not have permission to manage inventory.');
    }
    final index = _allInventory.indexWhere((item) => item.code == product.code);
    if (index != -1) {
      await _database.upsertInventoryItem(product, _activeStoreId);
      _allInventory[index] = product;
      _syncProductsFromInventory();
      notifyListeners();
    }
  }

  Future<void> removeProduct(String code) async {
    if (!hasPermission('Manage Inventory')) {
      throw StateError('You do not have permission to manage inventory.');
    }
    final removedIndex = _allInventory.indexWhere((item) => item.code == code);
    final removedItem = removedIndex == -1 ? null : _allInventory[removedIndex];
    final cartChanged = _cartItems.any((item) => item.code?.trim() == code);

    _allInventory.removeWhere((item) => item.code == code);
    _cartItems.removeWhere((item) => item.code?.trim() == code);
    _syncProductsFromInventory();
    _updateCartTotals();
    notifyListeners();
    await _database.deleteInventoryItem(code, _activeStoreId);
    if (cartChanged) {
      await _database.replaceCart(_cartItems, _activeStoreId);
    }

    final imagePath = removedItem?.imagePath;
    if (cloudApi != null) return;
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> applyInventoryAdjustments(
    Map<String, int> adjustments,
  ) async {
    if (!hasPermission('Manage Inventory')) {
      throw StateError('You do not have permission to manage inventory.');
    }
    if (adjustments.isEmpty) return;

    final applied = <String, int>{};
    for (var index = 0; index < _allInventory.length; index++) {
      final item = _allInventory[index];
      final delta = adjustments[item.code];
      if (delta == null || delta == 0) continue;

      final nextStock = (item.stockCount + delta).clamp(0, 1 << 31).toInt();
      _allInventory[index] = item.copyWith(
        stockCount: nextStock,
        stockState: _deriveStockState(nextStock),
      );
      applied[item.code] = delta;
    }

    if (applied.isEmpty) return;
    _syncProductsFromInventory();
    notifyListeners();
    await _database.adjustInventoryStock(
      applied,
      _activeStoreId,
      lowStockThreshold: _storePreferences.lowStockThreshold,
    );
  }

  bool _isDemoProduct(String? code, String name) =>
      _demoProducts[code?.trim()] == name.trim();

  Future<void> _removeDemoInventory() async {
    final inventoryBefore = _allInventory.length;
    final cartBefore = _cartItems.length;
    _allInventory.removeWhere((item) => _isDemoProduct(item.code, item.name));
    _cartItems.removeWhere((item) => _isDemoProduct(item.code, item.name));
    if (_allInventory.length != inventoryBefore) {
      await _database.replaceInventory(_allInventory, _activeStoreId);
    }
    if (_cartItems.length != cartBefore) {
      _updateCartTotals();
      await _persistCart();
    }
  }

  void _syncProductsFromInventory() {
    _products
      ..clear()
      ..addAll(_allInventory.map(_toProductItem));
  }

  ProductItem _toProductItem(InventoryProductItem product) {
    return ProductItem(
      product.name,
      _deriveProductSize(product),
      product.sellingPrice.toStringAsFixed(2),
      product.artType,
      code: product.code,
      category: product.category,
      imagePath: product.imagePath,
    );
  }

  int availableStockForProduct(ProductItem product) {
    return _availableStockForProduct(product);
  }

  int _availableStockForProduct(ProductItem product) {
    final index = _findInventoryIndex(product);
    if (index == -1) return 0;
    return _allInventory[index].stockCount;
  }

  int _findInventoryIndex(ProductItem product) {
    return _allInventory.indexWhere(
      (item) => item.code == product.code || item.name == product.name,
    );
  }

  bool Function(ProductItem) _sameProduct(ProductItem product) {
    final productCode = product.code?.trim();
    if (productCode != null && productCode.isNotEmpty) {
      return (item) => item.code?.trim() == productCode;
    }

    final productName = product.name.trim();
    final productSize = product.size.trim();
    return (item) =>
        item.name.trim() == productName && item.size.trim() == productSize;
  }

  void _updateCartTotals() {
    _cartCount = _cartItems.length;
    _cartTotal = _cartItems.fold<double>(
      0,
      (sum, item) => sum + item.priceValue,
    );
  }

  InventoryStockState _deriveStockState(int stockCount) {
    if (stockCount <= 0) return InventoryStockState.outOfStock;
    if (stockCount <= _storePreferences.lowStockThreshold) {
      return InventoryStockState.lowStock;
    }
    return InventoryStockState.inStock;
  }

  Future<void> _recalculateStockStates() async {
    var changed = false;
    for (var i = 0; i < _allInventory.length; i++) {
      final item = _allInventory[i];
      final nextState = _deriveStockState(item.stockCount);
      if (item.stockState != nextState) {
        _allInventory[i] = item.copyWith(stockState: nextState);
        changed = true;
      }
    }
    if (!changed) return;
    _syncProductsFromInventory();
    final database = _database;
    if (database is PosHybridDatabase) {
      await database.replaceInventoryLocal(_allInventory, _activeStoreId);
    } else {
      await database.replaceInventory(_allInventory, _activeStoreId);
    }
  }

  String _deriveProductSize(InventoryProductItem product) {
    final lowerCategory = product.category.toLowerCase();
    final lowerName = product.name.toLowerCase();
    if (lowerName.contains('500ml')) return '500 ml';
    if (lowerName.contains('330ml')) return '330 ml';
    if (lowerName.contains('250ml')) return '250 ml';
    if (lowerName.contains('500g')) return '500 g';
    if (lowerName.contains('100g')) return '100 g';
    if (lowerName.contains('40g')) return '40 g';
    if (lowerCategory.contains('beverage')) return '1 item';
    if (lowerCategory.contains('snack')) return '1 pack';
    if (lowerCategory.contains('personal')) return '1 unit';
    if (lowerCategory.contains('household')) return '1 pack';
    return '1 item';
  }
}
