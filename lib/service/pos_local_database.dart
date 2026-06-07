import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'daftari_recovery_models.dart';
import 'duka_ai_service.dart';
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
      version: 10,
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
        await db.execute('''
          CREATE TABLE app_profile (
            id INTEGER PRIMARY KEY,
            store_name TEXT NOT NULL,
            owner_name TEXT NOT NULL,
            role_title TEXT NOT NULL,
            business_category TEXT NOT NULL,
            contact_number TEXT NOT NULL,
            email_address TEXT NOT NULL,
            physical_address TEXT NOT NULL,
            logo_path TEXT,
            member_since TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE staff_roles (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            subtitle TEXT NOT NULL,
            permissions_json TEXT NOT NULL,
            sort_order INTEGER NOT NULL
          )
        ''');
        await db.execute('''  
          CREATE TABLE staff_members (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            phone TEXT NOT NULL,
            role_id TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE daftari_recovery_sessions (
            id TEXT PRIMARY KEY,
            created_at TEXT NOT NULL,
            stage TEXT NOT NULL,
            image_path TEXT,
            raw_text TEXT NOT NULL,
            extracted_lines_json TEXT NOT NULL,
            lines_json TEXT NOT NULL,
            matched_count INTEGER NOT NULL,
            unresolved_count INTEGER NOT NULL,
            confidence REAL NOT NULL,
            estimated_total REAL NOT NULL,
            imported_order_id TEXT,
            failure_reason TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE daftari_learning_rules (
            id TEXT PRIMARY KEY,
            source_text TEXT NOT NULL UNIQUE,
            target_product_code TEXT NOT NULL,
            target_product_name TEXT NOT NULL,
            created_at TEXT NOT NULL,
            hit_count INTEGER NOT NULL,
            last_used_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE myduka_ai_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            thread_id TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            image_path TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE myduka_ai_threads (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            preview TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            payment_method TEXT NOT NULL,
            date TEXT NOT NULL,
            notes TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS app_profile (
              id INTEGER PRIMARY KEY,
              store_name TEXT NOT NULL,
              owner_name TEXT NOT NULL,
              role_title TEXT NOT NULL,
              business_category TEXT NOT NULL,
              contact_number TEXT NOT NULL,
              email_address TEXT NOT NULL,
              physical_address TEXT NOT NULL,
              logo_path TEXT,
              member_since TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS staff_roles (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              subtitle TEXT NOT NULL,
              permissions_json TEXT NOT NULL,
              sort_order INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS staff_members (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT NOT NULL,
              phone TEXT NOT NULL,
              role_id TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS daftari_recovery_sessions (
              id TEXT PRIMARY KEY,
              created_at TEXT NOT NULL,
              stage TEXT NOT NULL,
              image_path TEXT,
              raw_text TEXT NOT NULL,
              extracted_lines_json TEXT NOT NULL,
              lines_json TEXT NOT NULL,
              matched_count INTEGER NOT NULL,
              unresolved_count INTEGER NOT NULL,
              confidence REAL NOT NULL,
              estimated_total REAL NOT NULL,
              imported_order_id TEXT,
              failure_reason TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS daftari_learning_rules (
              id TEXT PRIMARY KEY,
              source_text TEXT NOT NULL UNIQUE,
              target_product_code TEXT NOT NULL,
              target_product_name TEXT NOT NULL,
              created_at TEXT NOT NULL,
              hit_count INTEGER NOT NULL,
              last_used_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS myduka_ai_messages (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              thread_id TEXT NOT NULL,
              role TEXT NOT NULL,
              content TEXT NOT NULL,
              image_path TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 6) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS myduka_ai_threads (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              preview TEXT NOT NULL DEFAULT '',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          final tableInfo = await db.rawQuery('PRAGMA table_info(myduka_ai_messages)');
          final hasThreadId = tableInfo.any((column) => column['name'] == 'thread_id');
          if (!hasThreadId) {
            await db.execute(
              'ALTER TABLE myduka_ai_messages ADD COLUMN thread_id TEXT',
            );
          }
          final hasImagePath = tableInfo.any((column) => column['name'] == 'image_path');
          if (!hasImagePath) {
            await db.execute(
              'ALTER TABLE myduka_ai_messages ADD COLUMN image_path TEXT',
            );
          }
          await db.execute('''
            UPDATE myduka_ai_messages
            SET thread_id = COALESCE(thread_id, 'thread-default')
          ''');
          await db.execute('''
            INSERT OR IGNORE INTO myduka_ai_threads (id, title, created_at, updated_at)
            VALUES ('thread-default', 'Duka AI', datetime('now'), datetime('now'))
          ''');
        }
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS customers (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              email TEXT NOT NULL DEFAULT '',
              phone TEXT NOT NULL,
              address TEXT NOT NULL DEFAULT '',
              created_at TEXT NOT NULL DEFAULT '',
              tags TEXT NOT NULL DEFAULT ''
            )
          ''');
        }
        if (oldVersion < 7) {
          final tableInfo = await db.rawQuery('PRAGMA table_info(myduka_ai_threads)');
          final hasPreview = tableInfo.any((column) => column['name'] == 'preview');
          if (!hasPreview) {
            await db.execute(
              'ALTER TABLE myduka_ai_threads ADD COLUMN preview TEXT NOT NULL DEFAULT \'\'',
            );
          }
        }
        if (oldVersion < 10) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS expenses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              amount REAL NOT NULL,
              category TEXT NOT NULL,
              payment_method TEXT NOT NULL,
              date TEXT NOT NULL,
              notes TEXT
            )
          ''');
        }
      },
    );
    return _database!;
  }

  Future<Map<String, Object?>?> loadAppProfile() async {
    final db = await database;
    final rows = await db.query('app_profile', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> saveAppProfile(Map<String, Object?> profile) async {
    final db = await database;
    await db.insert(
      'app_profile',
      <String, Object?>{'id': 1, ...profile},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> loadStaffRoles() async {
    final db = await database;
    return db.query(
      'staff_roles',
      orderBy: 'sort_order ASC, title ASC',
    );
  }

  Future<void> replaceStaffRoles(List<Map<String, Object?>> roles) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('staff_roles');
    for (final role in roles) {
      batch.insert(
        'staff_roles',
        role,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, Object?>>> loadStaffMembers() async {
    final db = await database;
    return db.query(
      'staff_members',
      orderBy: 'created_at DESC',
    );
  }

  Future<void> replaceStaffMembers(List<Map<String, Object?>> members) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('staff_members');
    for (final member in members) {
      batch.insert(
        'staff_members',
        member,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveStaffMember(Map<String, Object?> member) async {
    final db = await database;
    await db.insert(
      'staff_members',
      member,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteStaffMember(String id) async {
    final db = await database;
    await db.delete(
      'staff_members',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
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

  Future<List<Map<String, dynamic>>> loadCustomers() async {
    final db = await database;
    return await db.query('customers');
  }

  Future<void> replaceCustomers(List<Map<String, Object?>> customers) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('customers');
      for (final customer in customers) {
        await txn.insert('customers', customer);
      }
    });
  }

  Future<List<DaftariRecoverySession>> loadDaftariSessions() async {
    final db = await database;
    final rows = await db.query(
      'daftari_recovery_sessions',
      orderBy: 'created_at DESC',
    );
    return rows.map(DaftariRecoverySession.fromMap).toList();
  }

  Future<void> upsertDaftariSession(DaftariRecoverySession session) async {
    final db = await database;
    await db.insert(
      'daftari_recovery_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DaftariLearningRule>> loadDaftariLearningRules() async {
    final db = await database;
    final rows = await db.query(
      'daftari_learning_rules',
      orderBy: 'last_used_at DESC, hit_count DESC',
    );
    return rows.map(DaftariLearningRule.fromMap).toList();
  }

  Future<void> upsertDaftariLearningRule(DaftariLearningRule rule) async {
    final db = await database;
    await db.insert(
      'daftari_learning_rules',
      rule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DukaAiThread>> loadDukaAiThreads() async {
    final db = await database;
    final rows = await db.query(
      'myduka_ai_threads',
      orderBy: 'updated_at DESC, created_at DESC',
    );
    return rows
        .map(
          (row) => DukaAiThread(
            id: row['id'] as String,
            title: row['title'] as String,
            preview: (row['preview'] as String?) ?? '',
            createdAt: row['created_at'] as String,
            updatedAt: row['updated_at'] as String,
          ),
        )
        .toList();
  }

  Future<void> upsertDukaAiThread(DukaAiThread thread) async {
    final db = await database;
    await db.insert(
      'myduka_ai_threads',
      <String, Object?>{
        'id': thread.id,
        'title': thread.title,
        'preview': thread.preview,
        'created_at': thread.createdAt,
        'updated_at': thread.updatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDukaAiThread(String threadId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'myduka_ai_messages',
        where: 'thread_id = ?',
        whereArgs: <Object?>[threadId],
      );
      await txn.delete(
        'myduka_ai_threads',
        where: 'id = ?',
        whereArgs: <Object?>[threadId],
      );
    });
  }

  Future<List<DukaAiMessage>> loadDukaAiMessages(String threadId) async {
    final db = await database;
    final rows = await db.query(
      'myduka_ai_messages',
      where: 'thread_id = ?',
      whereArgs: <Object?>[threadId],
      orderBy: 'id ASC',
    );
    return rows
        .map(
            (row) => DukaAiMessage(
              role: row['role'] as String,
              content: row['content'] as String,
              imagePath: row['image_path'] as String?,
              createdAt: row['created_at'] as String?,
            ),
        )
        .toList();
  }

  Future<void> replaceDukaAiMessages(
    String threadId,
    List<DukaAiMessage> messages,
  ) async {
    final db = await database;
    final batch = db.batch();
    batch.delete(
      'myduka_ai_messages',
      where: 'thread_id = ?',
      whereArgs: <Object?>[threadId],
    );
    for (final message in messages) {
      batch.insert(
        'myduka_ai_messages',
        <String, Object?>{
          'thread_id': threadId,
          'role': message.role,
          'content': message.content,
          'image_path': message.imagePath,
          'created_at': message.createdAt ?? DateTime.now().toIso8601String(),
        },
      );
    }
    await batch.commit(noResult: true);
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
      stockState:
          InventoryStockState.values.byName(map['stock_state'] as String),
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

  Future<List<Map<String, Object?>>> loadExpenses() async {
    final db = await database;
    return db.query('expenses', orderBy: 'date DESC');
  }

  Future<void> insertExpense(Map<String, Object?> expense) async {
    final db = await database;
    await db.insert('expenses', expense);
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  String encodeJson(List<String> values) {
    return jsonEncode(values);
  }

  List<String> decodeStringList(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! List) {
      return const <String>[];
    }
    return decoded.map((item) => item.toString()).toList();
  }
}
