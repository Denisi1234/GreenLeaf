import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'pos_order_models.dart';
import '../ui/models/product_item.dart';
import '../ui/products/inventory_product_item.dart';

class PosLocalDatabase {
  PosLocalDatabase._();

  static final PosLocalDatabase instance = PosLocalDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'pos_local_storage.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE inventory_products (
            code TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            purchase_price REAL NOT NULL,
            selling_price REAL NOT NULL,
            stock_count INTEGER NOT NULL,
            stock_state TEXT NOT NULL,
            art_type TEXT NOT NULL,
            image_path TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE cart_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT,
            category TEXT,
            name TEXT NOT NULL,
            size TEXT NOT NULL,
            price TEXT NOT NULL,
            art_type TEXT NOT NULL,
            image_path TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE orders (
            id TEXT PRIMARY KEY,
            date_time TEXT NOT NULL,
            date_label TEXT NOT NULL,
            time_label TEXT NOT NULL,
            total REAL NOT NULL,
            status TEXT NOT NULL,
            cashier_name TEXT NOT NULL,
            register_name TEXT NOT NULL,
            payment_method TEXT NOT NULL,
            cash_tendered REAL NOT NULL,
            change_due REAL NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE order_lines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id TEXT NOT NULL,
            item_code TEXT,
            item_category TEXT,
            item_name TEXT NOT NULL,
            item_size TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price TEXT NOT NULL,
            unit_price_value REAL NOT NULL,
            art_type TEXT NOT NULL,
            image_path TEXT,
            FOREIGN KEY(order_id) REFERENCES orders(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    return _database!;
  }

  Future<List<InventoryProductItem>> loadInventory() async {
    final db = await database;
    final rows = await db.query(
      'inventory_products',
      orderBy: 'code ASC',
    );
    return rows.map(_inventoryFromMap).toList();
  }

  Future<void> replaceInventory(List<InventoryProductItem> items) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('inventory_products');
    for (final item in items) {
      batch.insert(
        'inventory_products',
        _inventoryToMap(item),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ProductItem>> loadCart() async {
    final db = await database;
    final rows = await db.query(
      'cart_items',
      orderBy: 'id ASC',
    );
    return rows.map(_productFromMap).toList();
  }

  Future<void> replaceCart(List<ProductItem> items) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('cart_items');
    for (final item in items) {
      batch.insert('cart_items', _productToMap(item));
    }
    await batch.commit(noResult: true);
  }

  Future<List<CompletedOrder>> loadOrders() async {
    final db = await database;
    final orderRows = await db.query(
      'orders',
      orderBy: 'date_time DESC',
    );
    final lineRows = await db.query(
      'order_lines',
      orderBy: 'id ASC',
    );

    final linesByOrder = <String, List<OrderLine>>{};
    for (final row in lineRows) {
      final orderId = row['order_id'] as String;
      linesByOrder.putIfAbsent(orderId, () => <OrderLine>[]).add(
            _orderLineFromMap(row),
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
            lines: linesByOrder[row['id'] as String] ?? const <OrderLine>[],
          ),
        )
        .toList();
  }

  Future<void> insertOrder(CompletedOrder order) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'orders',
        <String, Object?>{
          'id': order.id,
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
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await txn.delete(
        'order_lines',
        where: 'order_id = ?',
        whereArgs: <Object?>[order.id],
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
            'quantity': line.quantity,
            'unit_price': line.unitPrice,
            'unit_price_value': line.unitPriceValue,
            'art_type': line.artType.name,
            'image_path': line.imagePath,
          },
        );
      }
    });
  }

  Map<String, Object?> _inventoryToMap(InventoryProductItem item) {
    return <String, Object?>{
      'code': item.code,
      'name': item.name,
      'category': item.category,
      'purchase_price': item.purchasePrice,
      'selling_price': item.sellingPrice,
      'stock_count': item.stockCount,
      'stock_state': item.stockState.name,
      'art_type': item.artType.name,
      'image_path': item.imagePath,
    };
  }

  InventoryProductItem _inventoryFromMap(Map<String, Object?> map) {
    return InventoryProductItem(
      code: map['code'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      stockCount: (map['stock_count'] as num).toInt(),
      stockState: InventoryStockState.values.byName(map['stock_state'] as String),
      artType: ProductArtType.values.byName(map['art_type'] as String),
      imagePath: map['image_path'] as String?,
    );
  }

  Map<String, Object?> _productToMap(ProductItem item) {
    return <String, Object?>{
      'code': item.code,
      'category': item.category,
      'name': item.name,
      'size': item.size,
      'price': item.price,
      'art_type': item.type.name,
      'image_path': item.imagePath,
    };
  }

  ProductItem _productFromMap(Map<String, Object?> map) {
    return ProductItem(
      map['name'] as String,
      map['size'] as String,
      map['price'] as String,
      ProductArtType.values.byName(map['art_type'] as String),
      code: map['code'] as String?,
      category: map['category'] as String?,
      imagePath: map['image_path'] as String?,
    );
  }

  OrderLine _orderLineFromMap(Map<String, Object?> map) {
    return OrderLine(
      itemCode: map['item_code'] as String?,
      itemCategory: map['item_category'] as String?,
      itemName: map['item_name'] as String,
      itemSize: map['item_size'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: map['unit_price'] as String,
      unitPriceValue: (map['unit_price_value'] as num).toDouble(),
      artType: ProductArtType.values.byName(map['art_type'] as String),
      imagePath: map['image_path'] as String?,
    );
  }
}
