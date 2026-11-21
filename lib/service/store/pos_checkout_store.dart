part of '../pos_local_store.dart';

/// Checkout, order void/reopen, formatting and customer stats for [PosLocalStore].
mixin PosCheckoutStore on ChangeNotifier {
  String get _activeStoreId;
  PosLocalDatabase get _database;
  PosHybridDatabase? get _cloudApi;
  PhpApiClient? get cloudApi;
  bool get _savingCheckout;
  set _savingCheckout(bool value);
  List<CompletedOrder> get _orders;
  List<ProductItem> get _cartItems;
  List<InventoryProductItem> get _allInventory;
  List<CustomerData> get _customers;
  List<DebitEntry> get _debitEntries;
  StorePreferences get _storePreferences;
  TaxSettings get _taxSettings;
  RegisterShift? get openShift;
  bool hasPermission(String permission);

  int _findInventoryIndex(ProductItem product);
  InventoryStockState _deriveStockState(int stockCount);
  void _syncProductsFromInventory();
  void _updateCartTotals();
  bool addToCart(ProductItem product);
  Future<void> clearCart();
  Future<void> refreshFromServer();
  CustomerData _customerFromMap(Map<String, Object?> map);
  Map<String, Object?> _customerToMap(CustomerData customer);
  Future<void> _appendDebitEntry(DebitEntry entry);
  Future<void> _persistDebitEntries();

  Future<CompletedOrder> completeCashSale({
    required List<OrderLineItem> items,
    required double cashTendered,
    required String cashierName,
    required String registerName,
    String? customerName,
    double? discountAmount,
    String? discountLabel,
    String paymentMethod = 'Cash',
  }) async {
    if (_savingCheckout) throw StateError('A sale is already being saved.');
    if (_storePreferences.requireOpenShiftForSales && openShift == null) {
      throw StateError(
        'Open a cash register shift before recording sales.',
      );
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

    final subtotal = normalized.fold<double>(
      0,
      (sum, line) => sum + line.totalPrice,
    );
    if (discountAmount != null && discountAmount < 0) {
      throw StateError('Discount cannot be negative.');
    }
    final appliedDiscount =
        (discountAmount ?? 0).clamp(0.0, subtotal).toDouble();
    if (appliedDiscount > 0 && !hasPermission('Discounts')) {
      throw StateError('You do not have permission to apply discounts.');
    }
    final netAfterDiscount =
        (subtotal - appliedDiscount).clamp(0.0, double.infinity).toDouble();
    final taxAdded = _taxSettings.taxFromNet(netAfterDiscount);
    final total = ((netAfterDiscount + taxAdded) * 100).round() / 100;
    final isCashSale = paymentMethod.toLowerCase() == 'cash';
    if (isCashSale && cashTendered < total) {
      throw StateError('Cash tendered is less than total due.');
    }

    final stockUpdates = <int, InventoryProductItem>{};
    final saleLines = <OrderLine>[];
    for (final line in normalized) {
      final inventoryIndex = _findInventoryIndex(line.product);
      if (inventoryIndex == -1) {
        throw StateError(
            'Product ${line.product.name} is no longer in inventory.');
      }
      final inventoryItem =
          stockUpdates[inventoryIndex] ?? _allInventory[inventoryIndex];
      if (inventoryItem.stockCount < line.quantity) {
        throw StateError(
          'Only ${inventoryItem.stockCount} unit(s) of ${inventoryItem.name} left in stock.',
        );
      }
      final nextStock = inventoryItem.stockCount - line.quantity;
      stockUpdates[inventoryIndex] = inventoryItem.copyWith(
        stockCount: nextStock,
        stockState: _deriveStockState(nextStock),
      );
      saleLines.add(OrderLine(
        itemCode: inventoryItem.code,
        itemCategory: inventoryItem.category,
        itemName: line.product.name,
        itemSize: line.product.size,
        quantity: line.quantity,
        unitPrice: line.product.price,
        unitPriceValue: line.product.priceValue,
        unitCost: inventoryItem.purchasePrice,
        artType: line.product.type,
        imagePath: line.product.imagePath,
      ));
    }

    final now = DateTime.now();
    var order = CompletedOrder(
      id: 'ORD-${now.microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32).toRadixString(16)}',
      dateTime: now.toIso8601String(),
      date: _formatDate(now),
      time: _formatTime(now),
      total: total,
      status: 'Completed',
      cashierName: cloudApi?.user['name'] as String? ?? cashierName,
      register: registerName,
      paymentMethod: paymentMethod,
      cashTendered: isCashSale ? cashTendered : 0,
      changeDue: isCashSale ? cashTendered - total : 0,
      customerName: customerName,
      discountAmount: appliedDiscount > 0 ? appliedDiscount : null,
      discountLabel: discountLabel,
      lines: saleLines,
    );

    CustomerData? creditCustomer;
    if (paymentMethod.toLowerCase() == 'credit' &&
        customerName != null &&
        customerName.trim().isNotEmpty) {
      final customerIndex =
          _customers.indexWhere((customer) => customer.name == customerName);
      if (customerIndex != -1) {
        creditCustomer = _customers[customerIndex].copyWith(
          debitBalance: _customers[customerIndex].debitBalance + total,
        );
      } else {
        // Credit taken for a name that is not on file: create the customer so
        // the debt is tracked instead of being lost.
        final now = DateTime.now();
        creditCustomer = CustomerData(
          id: 'CUST-${now.microsecondsSinceEpoch}',
          name: customerName.trim(),
          phone: '',
          debitBalance: total,
          createdAt: now,
        );
        _customers.add(creditCustomer);
        await _database.upsertCustomer(
          _customerToMap(creditCustomer),
          _activeStoreId,
        );
      }
    }

    _savingCheckout = true;
    try {
      await _database.saveCheckout(
        order: order,
        storeId: _activeStoreId,
        stockUpdates: stockUpdates.values.toList(),
        creditCustomer:
            creditCustomer == null ? null : _customerToMap(creditCustomer),
      );
      for (final item in stockUpdates.values) {
        final index =
            _allInventory.indexWhere((product) => product.code == item.code);
        if (index >= 0) _allInventory[index] = item;
        if (item.stockCount <= _storePreferences.lowStockThreshold) {
          unawaited(
            AppNotificationService.instance
                .showLowStockNotification(
                  productName: item.name,
                  remainingQuantity: item.stockCount,
                )
                .catchError((Object _) {}),
          );
        }
      }
      if (creditCustomer != null) {
        final id = creditCustomer.id;
        final index = _customers.indexWhere((customer) => customer.id == id);
        if (index >= 0) _customers[index] = creditCustomer;
      }
      if (creditCustomer != null) {
        await _appendDebitEntry(
          DebitEntry.now(
            id: 'DEB-${order.id}',
            customerId: creditCustomer.id,
            customerName: creditCustomer.name,
            type: DebitType.charge,
            amount: total,
            orderId: order.id,
            recordedBy: order.cashierName,
            note: 'Credit sale ${order.id}',
          ),
        );
      }
      final db = _cloudApi ?? _database;
      if (db is PosCloudDatabase) {
        final cloud = db;
        order = cloud.savedCheckout!;
        _allInventory
          ..clear()
          ..addAll(cloud.inventoryAfterCheckout!);
        _customers
          ..clear()
          ..addAll(cloud.customersAfterCheckout!.map(_customerFromMap));
      }
      _syncProductsFromInventory();
      _orders.insert(0, order);
      _cartItems.clear();
      _updateCartTotals();
      notifyListeners();
    } finally {
      _savingCheckout = false;
    }
    return order;
  }

  Future<void> voidOrder(String orderId) async {
    if (!hasPermission('Process Returns')) {
      throw StateError('You do not have permission to process returns.');
    }
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    final db = _cloudApi ?? _database;
    if (db is PosCloudDatabase) {
      await db.deleteOrder(orderId);
      await refreshFromServer();
      return;
    }

    final order = _orders[index];
    final restoredDeltas = <String, int>{};

    // Restore stock
    for (final line in order.lines) {
      final invIndex =
          _allInventory.indexWhere((item) => item.code == line.itemCode);
      if (invIndex != -1) {
        final item = _allInventory[invIndex];
        final nextStock = item.stockCount + line.quantity;
        _allInventory[invIndex] = InventoryProductItem(
          code: item.code,
          name: item.name,
          category: item.category,
          purchasePrice: item.purchasePrice,
          sellingPrice: item.sellingPrice,
          stockCount: nextStock,
          stockState: _deriveStockState(nextStock),
          artType: item.artType,
          imagePath: item.imagePath,
          categoryData: item.categoryData,
        );
        restoredDeltas[item.code] =
            (restoredDeltas[item.code] ?? 0) + line.quantity;
      }
    }

    _orders.removeAt(index);
    await _reverseVoidedCredit(order);
    _syncProductsFromInventory();
    notifyListeners();

    final database = _database;
    if (database is PosHybridDatabase) {
      await database.replaceInventoryLocal(_allInventory, _activeStoreId);
      await database.deleteOrder(orderId);
    } else {
      await database.adjustInventoryStock(
        restoredDeltas,
        _activeStoreId,
        lowStockThreshold: _storePreferences.lowStockThreshold,
      );
      await database.deleteOrder(orderId);
    }
  }

  /// Removes the ledger charge created by a credit sale that is being voided
  /// and reduces the customer's outstanding balance accordingly.
  Future<void> _reverseVoidedCredit(CompletedOrder order) async {
    if (order.paymentMethod.toLowerCase() != 'credit') return;
    final name = order.customerName;
    if (name == null || name.trim().isEmpty) return;

    final index = _customers.indexWhere((customer) => customer.name == name);
    if (index == -1) return;

    final customer = _customers[index];
    final remaining = customer.debitBalance - order.total;
    _customers[index] = customer.copyWith(
      debitBalance: remaining > 0 ? remaining : 0,
    );
    _debitEntries
        .removeWhere((entry) => entry.orderId == order.id && !entry.isPayment);

    await _database.upsertCustomer(
      _customerToMap(_customers[index]),
      _activeStoreId,
    );
    await _persistDebitEntries();
  }

  Future<void> reopenOrderForEdit(String orderId) async {
    final order = _orders.firstWhere((o) => o.id == orderId);

    // 1. Clear current cart
    await clearCart();

    // 2. Add order items back to cart
    for (final line in order.lines) {
      for (var i = 0; i < line.quantity; i++) {
        addToCart(line.product);
      }
    }

    // 3. Void the original order
    await voidOrder(orderId);
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
    final month = monthNames[dateTime.month - 1];
    final day = dateTime.day.toString().padLeft(2, '0');
    final monthNumber = dateTime.month.toString().padLeft(2, '0');
    return switch (_storePreferences.dateFormat) {
      'd MMM yyyy' => '${dateTime.day} $month ${dateTime.year}',
      'dd/MM/yyyy' => '$day/$monthNumber/${dateTime.year}',
      'MM/dd/yyyy' => '$monthNumber/$day/${dateTime.year}',
      'yyyy-MM-dd' => '${dateTime.year}-$monthNumber-$day',
      _ => '$month ${dateTime.day}, ${dateTime.year}',
    };
  }

  String _formatTime(DateTime dateTime) {
    final minute = dateTime.minute.toString().padLeft(2, '0');
    if (_storePreferences.uses24HourTime) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:$minute';
    }
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  Map<String, dynamic> customerStats() {
    final total = _customers.length;
    final names = _customers.map((c) => c.name).toSet();
    final active = _orders
        .map((o) => o.customerName)
        .where((n) => n != null && names.contains(n))
        .toSet()
        .length;

    final spendByCustomer = <String, double>{};
    for (final order in _orders) {
      final name = order.customerName;
      if (name == null) continue;
      spendByCustomer[name] = (spendByCustomer[name] ?? 0) + order.total;
    }

    String? topName;
    double topValue = 0;
    spendByCustomer.forEach((name, value) {
      if (value > topValue) {
        topValue = value;
        topName = name;
      }
    });

    return <String, dynamic>{
      'total': total,
      'active': active,
      'topName': topName,
      'topValue': topValue,
    };
  }
}
