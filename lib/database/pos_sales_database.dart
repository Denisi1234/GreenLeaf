part of '../service/pos_local_database.dart';

mixin PosSalesDatabaseMixin {
  Future<Database> get database;

  Future<List<InventoryProductItem>> loadInventory(String storeId) async {
    final db = await database;
    final rows = await db.query(
      'inventory_products',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'code ASC',
    );
    return rows.map(inventoryFromMap).toList();
  }

  Future<void> replaceInventory(
      List<InventoryProductItem> items, String storeId) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('inventory_products',
        where: 'store_id = ?', whereArgs: <Object?>[storeId]);
    for (final item in items) {
      batch.insert(
        'inventory_products',
        inventoryToMap(item, storeId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertInventoryItem(
    InventoryProductItem item,
    String storeId,
  ) async {
    final db = await database;
    await db.insert(
      'inventory_products',
      inventoryToMap(item, storeId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteInventoryItem(String code, String storeId) async {
    final db = await database;
    await db.delete(
      'inventory_products',
      where: 'store_id = ? AND code = ?',
      whereArgs: <Object?>[storeId, code],
    );
  }

  Future<void> _ensureSuspendedSalesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS suspended_sales (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> loadSuspendedSales(String storeId) async {
    final db = await database;
    await _ensureSuspendedSalesTable(db);
    final rows = await db.query(
      'suspended_sales',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'created_at DESC',
    );
    return rows
        .map((row) {
          try {
            return Map<String, dynamic>.from(
              jsonDecode(row['payload_json'] as String) as Map,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> replaceSuspendedSales(
    List<Map<String, dynamic>> sales,
    String storeId,
  ) async {
    final db = await database;
    await _ensureSuspendedSalesTable(db);
    await db.transaction((txn) async {
      await txn.delete(
        'suspended_sales',
        where: 'store_id = ?',
        whereArgs: <Object?>[storeId],
      );
      for (final sale in sales) {
        await txn.insert(
          'suspended_sales',
          <String, Object?>{
            'id': sale['id'] as String? ?? '',
            'store_id': storeId,
            'payload_json': jsonEncode(sale),
            'created_at':
                sale['createdAt'] as String? ?? DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> upsertSuspendedSale(
    Map<String, dynamic> sale,
    String storeId,
  ) async {
    final db = await database;
    await _ensureSuspendedSalesTable(db);
    await db.insert(
      'suspended_sales',
      <String, Object?>{
        'id': sale['id'] as String? ?? '',
        'store_id': storeId,
        'payload_json': jsonEncode(sale),
        'created_at':
            sale['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteSuspendedSaleRecord(String id, String storeId) async {
    final db = await database;
    await _ensureSuspendedSalesTable(db);
    await db.delete(
      'suspended_sales',
      where: 'store_id = ? AND id = ?',
      whereArgs: <Object?>[storeId, id],
    );
  }

  Future<void> adjustInventoryStock(
    Map<String, num> deltas,
    String storeId, {
    int lowStockThreshold = 20,
  }) async {
    if (deltas.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      for (final entry in deltas.entries) {
        if (entry.value == 0) continue;
        final rows = await txn.query(
          'inventory_products',
          columns: <String>['stock_count'],
          where: 'store_id = ? AND code = ?',
          whereArgs: <Object?>[storeId, entry.key],
          limit: 1,
        );
        if (rows.isEmpty) continue;
        final current = (rows.first['stock_count'] as num).toDouble();
        final next =
            roundQuantity((current + entry.value.toDouble()).clamp(0.0, 1e12).toDouble());
        final state = next <= 0
            ? InventoryStockState.outOfStock
            : next <= lowStockThreshold
                ? InventoryStockState.lowStock
                : InventoryStockState.inStock;
        await txn.update(
          'inventory_products',
          <String, Object?>{
            'stock_count': next,
            'stock_state': state.name,
          },
          where: 'store_id = ? AND code = ?',
          whereArgs: <Object?>[storeId, entry.key],
        );
      }
    });
  }

  Future<List<ProductItem>> loadCart(String storeId) async {
    final db = await database;
    await _ensureMeasurementColumns(db);
    final rows = await db.query(
      'cart_items',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'id ASC',
    );
    return rows.map(productFromMap).toList();
  }

  Future<void> replaceCart(List<ProductItem> items, String storeId) async {
    final db = await database;
    await _ensureMeasurementColumns(db);
    final batch = db.batch();
    batch.delete(
      'cart_items',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
    );
    for (final item in items) {
      batch.insert('cart_items', productToMap(item, storeId));
    }
    await batch.commit(noResult: true);
  }

  Future<List<CompletedOrder>> loadOrders(String storeId) async {
    final db = await database;
    final orderRows = await db.query(
      'orders',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'date_time DESC',
    );
    final lineRows = await db.query(
      'order_lines',
      where: 'order_id IN (SELECT id FROM orders WHERE store_id = ?)',
      whereArgs: <Object?>[storeId],
      orderBy: 'id ASC',
    );

    final linesByOrder = <String, List<OrderLine>>{};
    for (final row in lineRows) {
      final orderId = row['order_id'] as String;
      linesByOrder.putIfAbsent(orderId, () => <OrderLine>[]).add(
            orderLineFromMap(row),
          );
    }

    return orderRows
        .map(
          (row) => CompletedOrder(
            id: row['id'] as String,
            dateTime: row['date_time'] as String,
            date: row['date_label'] as String,
            time: row['time_label'] as String,
            total: (row['total'] as num).toDouble(),
            status: row['status'] as String,
            cashierName: row['cashier_name'] as String,
            register: row['register_name'] as String,
            paymentMethod: row['payment_method'] as String,
            cashTendered: (row['cash_tendered'] as num).toDouble(),
            changeDue: (row['change_due'] as num).toDouble(),
            customerName: row['customer_name'] as String?,
            discountAmount: (row['discount_amount'] as num?)?.toDouble(),
            discountLabel: row['discount_label'] as String?,
            lines: linesByOrder[row['id'] as String] ?? const <OrderLine>[],
          ),
        )
        .toList();
  }

  Future<void> saveCheckout({
    required CompletedOrder order,
    required String storeId,
    required List<InventoryProductItem> stockUpdates,
    Map<String, Object?>? creditCustomer,
  }) async {
    final db = await database;
    await _ensureMeasurementColumns(db);
    await db.transaction((txn) async {
      await txn.insert(
        'orders',
        <String, Object?>{
          'id': order.id,
          'store_id': storeId,
          'date_time': order.dateTime,
          'date_label': order.date,
          'time_label': order.time,
          'total': order.total,
          'status': order.status,
          'cashier_name': order.cashierName,
          'register_name': order.register,
          'payment_method': order.paymentMethod,
          'cash_tendered': order.cashTendered,
          'change_due': order.changeDue,
          'customer_name': order.customerName,
          'discount_amount': order.discountAmount,
          'discount_label': order.discountLabel,
        },
      );
      for (final line in order.lines) {
        await txn.insert(
          'order_lines',
          <String, Object?>{
            'order_id': order.id,
            'item_code': line.itemCode,
            'item_category': line.itemCategory,
            'item_name': line.itemName,
            'item_size': line.itemSize,
            'quantity': roundQuantity(line.quantity),
            'unit_price': line.unitPrice,
            'unit_price_value': line.unitPriceValue,
            'unit_cost': line.unitCost,
            'art_type': line.artType.name,
            'image_path': line.imagePath,
            'item_unit': line.unit,
          },
        );
      }
      for (final item in stockUpdates) {
        final updated = await txn.update(
          'inventory_products',
          {'stock_count': item.stockCount, 'stock_state': item.stockState.name},
          where: 'store_id = ? AND code = ?',
          whereArgs: [storeId, item.code],
        );
        if (updated != 1) {
          throw StateError('Stock record missing for ${item.code}.');
        }
      }
      if (creditCustomer != null) {
        final updated = await txn.update(
          'customers',
          {'debit_balance': creditCustomer['debit_balance']},
          where: 'store_id = ? AND id = ?',
          whereArgs: [storeId, creditCustomer['id']],
        );
        if (updated != 1) {
          throw StateError('Customer credit account is unavailable.');
        }
      }
      await txn
          .delete('cart_items', where: 'store_id = ?', whereArgs: [storeId]);
    });
  }

  Future<void> deleteOrder(String orderId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'order_lines',
        where: 'order_id = ?',
        whereArgs: <Object?>[orderId],
      );
      await txn.delete(
        'orders',
        where: 'id = ?',
        whereArgs: <Object?>[orderId],
      );
    });
  }

  Future<void> clearCart() async {
    final db = await database;
    await db.delete('cart_items');
  }

  Future<List<Map<String, dynamic>>> loadCustomers(String storeId) async {
    final db = await database;
    return db.query(
      'customers',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
    );
  }

  Future<void> replaceCustomers(
    List<Map<String, Object?>> customers,
    String storeId,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn
          .delete('customers', where: 'store_id = ?', whereArgs: [storeId]);
      for (final customer in customers) {
        await txn.insert('customers', {...customer, 'store_id': storeId});
      }
    });
  }

  Future<void> upsertCustomer(
    Map<String, Object?> customer,
    String storeId,
  ) async {
    final db = await database;
    await db.insert(
      'customers',
      {...customer, 'store_id': storeId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteCustomerRecord(String customerId, String storeId) async {
    final db = await database;
    await db.delete(
      'customers',
      where: 'store_id = ? AND id = ?',
      whereArgs: <Object?>[storeId, customerId],
    );
  }

  Future<List<Map<String, Object?>>> loadDebitEntries(String storeId) async {
    final db = await database;
    return db.query(
      'debit_entries',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> replaceDebitEntries(
    List<Map<String, Object?>> entries,
    String storeId,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'debit_entries',
        where: 'store_id = ?',
        whereArgs: [storeId],
      );
      for (final entry in entries) {
        await txn.insert('debit_entries', {...entry, 'store_id': storeId});
      }
    });
  }

  Future<void> insertDebitEntry(
    Map<String, Object?> entry,
    String storeId,
  ) async {
    final db = await database;
    await db.insert(
      'debit_entries',
      {...entry, 'store_id': storeId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDebitEntryRecord(String entryId, String storeId) async {
    final db = await database;
    await db.delete(
      'debit_entries',
      where: 'store_id = ? AND id = ?',
      whereArgs: <Object?>[storeId, entryId],
    );
  }

  Map<String, Object?> inventoryToMap(
      InventoryProductItem item, String storeId) {
    final metadata = Map<String, Object?>.from(item.categoryData)
      ..['unit'] = item.unit
      ..['allow_fractional'] = item.allowFractional;
    if (item.hasBulkPack) {
      metadata['pack_name'] = item.packName!.trim();
      metadata['pack_size'] = item.packSize!;
    } else {
      metadata.remove('pack_name');
      metadata.remove('pack_size');
    }
    return <String, Object?>{
      'code': item.code,
      'store_id': storeId,
      'name': item.name,
      'category': item.category,
      'purchase_price': item.purchasePrice,
      'selling_price': item.sellingPrice,
      'stock_count': roundQuantity(item.stockCount),
      'stock_state': item.stockState.name,
      'art_type': item.artType.name,
      'image_path': item.imagePath,
      'category_data_json': jsonEncode(metadata),
    };
  }

  InventoryProductItem inventoryFromMap(Map<String, Object?> map) {
    final rawMetadata = map['category_data_json'] as String? ?? '{}';
    final metadata = Map<String, Object?>.from(
        jsonDecode(rawMetadata) as Map<dynamic, dynamic>);
    final unit = (metadata['unit'] ?? map['unit'])?.toString().trim();
    final allowFractionalRaw =
        metadata['allow_fractional'] ?? map['allow_fractional'];
    final allowFractional =
        allowFractionalRaw == true || allowFractionalRaw == 1;
    final packName =
        (metadata['pack_name'] ?? map['pack_name'])?.toString().trim();
    final packSize =
        ((metadata['pack_size'] ?? map['pack_size']) as num?)?.toDouble();
    return InventoryProductItem(
      code: map['code'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      stockCount: roundQuantity((map['stock_count'] as num).toDouble()),
      stockState:
          InventoryStockState.values.byName(map['stock_state'] as String),
      artType: ProductArtType.values.byName(map['art_type'] as String),
      imagePath: map['image_path'] as String?,
      unit: (unit == null || unit.isEmpty) ? 'Pcs' : unit,
      allowFractional: allowFractional,
      packName: (packName == null || packName.isEmpty) ? null : packName,
      packSize: (packSize != null && packSize > 0) ? packSize : null,
      categoryData: metadata,
    );
  }

  Map<String, Object?> productToMap(ProductItem item, String storeId) {
    return <String, Object?>{
      'code': item.code,
      'store_id': storeId,
      'category': item.category,
      'name': item.name,
      'size': item.size,
      'price': item.price,
      'art_type': item.type.name,
      'image_path': item.imagePath,
      'quantity': roundQuantity(item.quantity),
      'unit': item.unit,
      'allow_fractional': item.allowFractional ? 1 : 0,
      'custom_price': item.customPrice,
    };
  }

  ProductItem productFromMap(Map<String, Object?> map) {
    final allowRaw = map['allow_fractional'];
    return ProductItem(
      map['name'] as String,
      map['size'] as String,
      map['price'] as String,
      ProductArtType.values.byName(map['art_type'] as String),
      code: map['code'] as String?,
      category: map['category'] as String?,
      imagePath: map['image_path'] as String?,
      unit: (map['unit'] as String?) ?? 'Pcs',
      allowFractional: allowRaw == true || allowRaw == 1,
      quantity: roundQuantity((map['quantity'] as num?)?.toDouble() ?? 1.0),
      customPrice: (map['custom_price'] as num?)?.toDouble(),
    );
  }

  OrderLine orderLineFromMap(Map<String, Object?> map) {
    final unit = (map['item_unit'] ?? map['unit'])?.toString().trim();
    return OrderLine(
      itemCode: map['item_code'] as String?,
      itemCategory: map['item_category'] as String?,
      itemName: map['item_name'] as String,
      itemSize: map['item_size'] as String,
      quantity: roundQuantity((map['quantity'] as num).toDouble()),
      unitPrice: map['unit_price'] as String,
      unitPriceValue: (map['unit_price_value'] as num).toDouble(),
      unitCost: (map['unit_cost'] as num?)?.toDouble(),
      artType: ProductArtType.values.byName(map['art_type'] as String),
      imagePath: map['image_path'] as String?,
      unit: (unit == null || unit.isEmpty) ? 'Pcs' : unit,
    );
  }
}
