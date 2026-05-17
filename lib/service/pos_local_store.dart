import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../ui/models/product_item.dart';
import '../ui/products/inventory_product_item.dart';
import 'pos_local_database.dart';
import 'pos_order_models.dart';

const _seedInventory = <InventoryProductItem>[
  InventoryProductItem(
    code: 'P001',
    name: 'Mineral Water 500ml',
    category: 'Beverages',
    purchasePrice: 2200,
    sellingPrice: 3000,
    stockCount: 120,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.aquafina,
  ),
  InventoryProductItem(
    code: 'P002',
    name: 'Coca-Cola',
    category: 'Beverages',
    purchasePrice: 2800,
    sellingPrice: 3750,
    stockCount: 85,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.coke,
  ),
  InventoryProductItem(
    code: 'P003',
    name: "Lay's Classic",
    category: 'Snacks',
    purchasePrice: 3400,
    sellingPrice: 4500,
    stockCount: 60,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.lays,
  ),
  InventoryProductItem(
    code: 'P004',
    name: 'Galaxy Milk',
    category: 'Snacks',
    purchasePrice: 3100,
    sellingPrice: 4000,
    stockCount: 40,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.galaxy,
  ),
  InventoryProductItem(
    code: 'P005',
    name: "Kellogg's Corn Flakes",
    category: 'Groceries',
    purchasePrice: 6400,
    sellingPrice: 8500,
    stockCount: 32,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.kelloggs,
  ),
  InventoryProductItem(
    code: 'P006',
    name: 'Dove Beauty Bar',
    category: 'Personal Care',
    purchasePrice: 2400,
    sellingPrice: 3125,
    stockCount: 54,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.dove,
  ),
  InventoryProductItem(
    code: 'P007',
    name: 'Colgate',
    category: 'Personal Care',
    purchasePrice: 3900,
    sellingPrice: 5250,
    stockCount: 28,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.colgate,
  ),
  InventoryProductItem(
    code: 'P008',
    name: 'Dettol Hand Wash',
    category: 'Personal Care',
    purchasePrice: 5200,
    sellingPrice: 7125,
    stockCount: 24,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.dettol,
  ),
  InventoryProductItem(
    code: 'P009',
    name: 'Tide Original',
    category: 'Household',
    purchasePrice: 9100,
    sellingPrice: 12250,
    stockCount: 18,
    stockState: InventoryStockState.lowStock,
    artType: ProductArtType.tide,
  ),
];

class PosLocalStore extends ChangeNotifier {
  PosLocalStore({PosLocalDatabase? database})
      : _database = database ?? PosLocalDatabase.instance;

  final PosLocalDatabase _database;

  final List<ProductItem> _products = <ProductItem>[];
  final List<ProductItem> _cartItems = <ProductItem>[];
  final List<CompletedOrder> _orders = <CompletedOrder>[];
  final List<InventoryProductItem> _allInventory = <InventoryProductItem>[];

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  static PosLocalStore of(BuildContext context) {
    return context.read<PosLocalStore>();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    final storedInventory = await _database.loadInventory();
    if (storedInventory.isEmpty) {
      _allInventory
        ..clear()
        ..addAll(_seedInventory);
      await _database.replaceInventory(_allInventory);
    } else {
      _allInventory
        ..clear()
        ..addAll(storedInventory);
    }

    _syncProductsFromInventory();

    final storedCart = await _database.loadCart();
    if (storedCart.isEmpty) {
      _cartItems
        ..clear()
        ..addAll(_products.take(3));
      await _database.replaceCart(_cartItems);
    } else {
      _cartItems
        ..clear()
        ..addAll(storedCart);
    }

    _orders
      ..clear()
      ..addAll(await _database.loadOrders());

    _updateCartTotals();
    _isInitialized = true;
    notifyListeners();
  }

  List<ProductItem> get products => List.unmodifiable(_products);
  List<ProductItem> get cartItems => List.unmodifiable(_cartItems);
  List<CompletedOrder> get orders => List.unmodifiable(_orders);
  List<InventoryProductItem> get inventory => List.unmodifiable(_allInventory);

  int _cartCount = 0;
  int get cartCount => _cartCount;

  double _cartTotal = 0;
  double get cartTotal => _cartTotal;

  bool addToCart(ProductItem product) {
    final availableStock = _availableStockForProduct(product);
    final currentCartQuantity = _cartItems.where(_sameProduct(product)).length;
    if (availableStock > 0 && currentCartQuantity >= availableStock) {
      return false;
    }

    _cartItems.add(product);
    _updateCartTotals();
    notifyListeners();
    unawaited(_database.replaceCart(_cartItems));
    return true;
  }

  bool removeSingleFromCart(ProductItem product) {
    final index = _cartItems.indexWhere(_sameProduct(product));
    if (index == -1) return false;
    _cartItems.removeAt(index);
    _updateCartTotals();
    notifyListeners();
    unawaited(_database.replaceCart(_cartItems));
    return true;
  }

  void removeFromCart(int index) {
    if (index < 0 || index >= _cartItems.length) return;
    _cartItems.removeAt(index);
    _updateCartTotals();
    notifyListeners();
    unawaited(_database.replaceCart(_cartItems));
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
    unawaited(_database.replaceCart(_cartItems));
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    _updateCartTotals();
    notifyListeners();
    await _database.replaceCart(_cartItems);
  }

  InventoryProductItem addProduct(InventoryProductItem product) {
    _allInventory.insert(0, product);
    _syncProductsFromInventory();
    notifyListeners();
    unawaited(_database.replaceInventory(_allInventory));
    return product;
  }

  Future<CompletedOrder> completeCashSale({
    required List<OrderLineItem> items,
    required double cashTendered,
    required String cashierName,
    required String registerName,
  }) async {
    if (items.isEmpty) {
      throw StateError('Cannot complete a sale with no items.');
    }

    final normalized = items
        .where((line) => line.quantity > 0)
        .map(
          (line) => OrderLineItem(
            product: line.product,
            quantity: line.quantity,
          ),
        )
        .toList();
    if (normalized.isEmpty) {
      throw StateError('Cannot complete a sale with no items.');
    }

    final total = normalized.fold<double>(
      0,
      (sum, line) => sum + line.totalPrice,
    );
    if (cashTendered < total) {
      throw StateError('Cash tendered is less than total due.');
    }

    for (final line in normalized) {
      final inventoryIndex = _findInventoryIndex(line.product);
      if (inventoryIndex == -1) {
        throw StateError('Product ${line.product.name} is no longer in inventory.');
      }
      final inventoryItem = _allInventory[inventoryIndex];
      if (inventoryItem.stockCount < line.quantity) {
        throw StateError(
          'Only ${inventoryItem.stockCount} unit(s) of ${inventoryItem.name} left in stock.',
        );
      }
    }

    for (final line in normalized) {
      final index = _findInventoryIndex(line.product);
      final item = _allInventory[index];
      final nextStock = item.stockCount - line.quantity;
      _allInventory[index] = InventoryProductItem(
        code: item.code,
        name: item.name,
        category: item.category,
        purchasePrice: item.purchasePrice,
        sellingPrice: item.sellingPrice,
        stockCount: nextStock,
        stockState: _deriveStockState(nextStock),
        artType: item.artType,
        imagePath: item.imagePath,
      );
    }

    _syncProductsFromInventory();

    final now = DateTime.now();
    final order = CompletedOrder(
      id: 'ORD-${now.millisecondsSinceEpoch}',
      dateTime: now.toIso8601String(),
      date: _formatDate(now),
      time: _formatTime(now),
      total: total,
      status: 'Completed',
      cashierName: cashierName,
      register: registerName,
      paymentMethod: 'Cash',
      cashTendered: cashTendered,
      changeDue: cashTendered - total,
      lines: normalized
          .map(
            (line) => OrderLine(
              itemCode: line.product.code,
              itemCategory: line.product.category,
              itemName: line.product.name,
              itemSize: line.product.size,
              quantity: line.quantity,
              unitPrice: line.product.price,
              unitPriceValue: line.product.priceValue,
              artType: line.product.type,
              imagePath: line.product.imagePath,
            ),
          )
          .toList(),
    );

    _orders.insert(0, order);
    _cartItems.clear();
    _updateCartTotals();
    notifyListeners();

    await _database.replaceInventory(_allInventory);
    await _database.replaceCart(_cartItems);
    await _database.insertOrder(order);
    return order;
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
      product.sellingPrice.toStringAsFixed(0),
      product.artType,
      code: product.code,
      category: product.category,
      imagePath: product.imagePath,
    );
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
    return (item) =>
        item.code == product.code &&
        item.name == product.name &&
        item.price == product.price &&
        item.size == product.size;
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
    if (stockCount <= 20) return InventoryStockState.lowStock;
    return InventoryStockState.inStock;
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

  String _formatDate(DateTime dateTime) {
    final monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $suffix';
  }
}
