import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'daftari_recovery_models.dart';
import 'duka_ai_service.dart';
import 'pos_order_models.dart';
import 'receipt_settings.dart';
import '../ui/models/product_item.dart';
import '../ui/products/inventory_product_item.dart';

class PosLocalDatabase {
  PosLocalDatabase._();

  static final PosLocalDatabase instance = PosLocalDatabase._();

  static const _receiptSettingsSchema = '''
    CREATE TABLE receipt_settings (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      show_store_contact INTEGER NOT NULL DEFAULT 1,
      footer TEXT NOT NULL DEFAULT ''
    )
  ''';

  static const _storeLocationsSchema = '''
          CREATE TABLE IF NOT EXISTS store_locations (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            address TEXT NOT NULL,
            contact_number TEXT NOT NULL,
            tax_id TEXT NOT NULL DEFAULT '',
            status_key TEXT NOT NULL,
            accent_color INTEGER NOT NULL,
            tint_color INTEGER NOT NULL,
            logo_path TEXT,
            profile_json TEXT,
            created_at TEXT NOT NULL,
            is_active INTEGER NOT NULL DEFAULT 0
          )
  ''';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'pos_local_storage.db');
    _database = await openDatabase(
      path,
      version: 21,
      onCreate: (db, version) async {
        await db.execute(_receiptSettingsSchema);
        await db.execute('''
          CREATE TABLE inventory_products (
            code TEXT,
            store_id TEXT NOT NULL,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            purchase_price REAL NOT NULL,
            selling_price REAL NOT NULL,
            stock_count INTEGER NOT NULL,
            stock_state TEXT NOT NULL,
            art_type TEXT NOT NULL,
            image_path TEXT,
            category_data_json TEXT NOT NULL DEFAULT '{}',
            PRIMARY KEY (code, store_id)
          )
        ''');
        await db.execute('''
          CREATE TABLE cart_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            store_id TEXT NOT NULL,
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
            store_id TEXT NOT NULL,
            date_time TEXT NOT NULL,
            date_label TEXT NOT NULL,
            time_label TEXT NOT NULL,
            total REAL NOT NULL,
            status TEXT NOT NULL,
            cashier_name TEXT NOT NULL,
            register_name TEXT NOT NULL,
            payment_method TEXT NOT NULL,
            cash_tendered REAL NOT NULL,
            change_due REAL NOT NULL,
            customer_name TEXT,
            discount_amount REAL,
            discount_label TEXT
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
            unit_cost REAL,
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
            tax_id TEXT NOT NULL DEFAULT '',
            weekday_open TEXT NOT NULL DEFAULT '',
            weekday_close TEXT NOT NULL DEFAULT '',
            saturday_open TEXT NOT NULL DEFAULT '',
            saturday_close TEXT NOT NULL DEFAULT '',
            sunday_schedule TEXT NOT NULL DEFAULT '',
            open_24_hours INTEGER NOT NULL DEFAULT 0,
            logo_path TEXT,
            capability_overrides_json TEXT,
            member_since TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE stores (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            contact TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE staff_roles (
            id TEXT PRIMARY KEY,
            store_id TEXT NOT NULL,
            title TEXT NOT NULL,
            subtitle TEXT NOT NULL,
            permissions_json TEXT NOT NULL,
            sort_order INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE staff_members (
            id TEXT PRIMARY KEY,
            store_id TEXT NOT NULL,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            phone TEXT NOT NULL,
            role_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            username TEXT NOT NULL DEFAULT '',
            password_hash TEXT NOT NULL DEFAULT '',
            password_salt TEXT NOT NULL DEFAULT '',
            employee_number TEXT NOT NULL DEFAULT '',
            job_title TEXT NOT NULL DEFAULT '',
            department TEXT NOT NULL DEFAULT '',
            hire_date TEXT NOT NULL DEFAULT '',
            employment_type TEXT NOT NULL DEFAULT '',
            hourly_rate REAL NOT NULL DEFAULT 0,
            emergency_contact_name TEXT NOT NULL DEFAULT '',
            emergency_contact_phone TEXT NOT NULL DEFAULT '',
            emergency_contact_relation TEXT NOT NULL DEFAULT '',
            address TEXT NOT NULL DEFAULT '',
            notes TEXT NOT NULL DEFAULT '',
            avatar_path TEXT,
            status TEXT NOT NULL DEFAULT 'active',
            updated_at TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE daftari_recovery_sessions (
            id TEXT PRIMARY KEY,
            store_id TEXT NOT NULL,
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
            store_id TEXT NOT NULL,
            source_text TEXT NOT NULL,
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
            store_id TEXT NOT NULL,
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
            store_id TEXT NOT NULL,
            title TEXT NOT NULL,
            preview TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            store_id TEXT NOT NULL,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT NOT NULL,
            payment_method TEXT NOT NULL,
            date TEXT NOT NULL,
            notes TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE customers (
            id TEXT PRIMARY KEY,
            store_id TEXT NOT NULL,
            name TEXT NOT NULL,
            email TEXT NOT NULL DEFAULT '',
            phone TEXT NOT NULL,
            address TEXT NOT NULL DEFAULT '',
            debit_balance REAL NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL DEFAULT '',
            tags TEXT NOT NULL DEFAULT ''
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
        if (oldVersion < 15) {
          await db.execute(_storeLocationsSchema);
        }
        if (oldVersion < 16) {
          final tableInfo =
              await db.rawQuery('PRAGMA table_info(store_locations)');
          final hasProfileJson =
              tableInfo.any((column) => column['name'] == 'profile_json');
          if (!hasProfileJson) {
            await db.execute(
              'ALTER TABLE store_locations ADD COLUMN profile_json TEXT',
            );
          }
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
          final tableInfo =
              await db.rawQuery('PRAGMA table_info(myduka_ai_messages)');
          final hasThreadId =
              tableInfo.any((column) => column['name'] == 'thread_id');
          if (!hasThreadId) {
            await db.execute(
              'ALTER TABLE myduka_ai_messages ADD COLUMN thread_id TEXT',
            );
          }
          final hasImagePath =
              tableInfo.any((column) => column['name'] == 'image_path');
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
            debit_balance REAL NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL DEFAULT '',
            tags TEXT NOT NULL DEFAULT ''
          )
        ''');
        }
        if (oldVersion < 7) {
          final tableInfo =
              await db.rawQuery('PRAGMA table_info(myduka_ai_threads)');
          final hasPreview =
              tableInfo.any((column) => column['name'] == 'preview');
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
        if (oldVersion < 12) {
          final tableInfo = await db.rawQuery('PRAGMA table_info(app_profile)');
          Future<void> addColumn(String name, String definition) async {
            final exists = tableInfo.any((column) => column['name'] == name);
            if (!exists) {
              await db
                  .execute('ALTER TABLE app_profile ADD COLUMN $definition');
            }
          }

          await addColumn('tax_id', 'tax_id TEXT NOT NULL DEFAULT \'\'');
          await addColumn(
              'weekday_open', 'weekday_open TEXT NOT NULL DEFAULT \'\'');
          await addColumn(
              'weekday_close', 'weekday_close TEXT NOT NULL DEFAULT \'\'');
          await addColumn(
              'saturday_open', 'saturday_open TEXT NOT NULL DEFAULT \'\'');
          await addColumn(
              'saturday_close', 'saturday_close TEXT NOT NULL DEFAULT \'\'');
          await addColumn(
              'sunday_schedule', 'sunday_schedule TEXT NOT NULL DEFAULT \'\'');
          await addColumn(
              'open_24_hours', 'open_24_hours INTEGER NOT NULL DEFAULT 0');
          await addColumn(
              'capability_overrides_json', 'capability_overrides_json TEXT');
        }
        if (oldVersion < 13) {
          final tableInfo = await db.rawQuery('PRAGMA table_info(customers)');
          final hasDebitBalance =
              tableInfo.any((column) => column['name'] == 'debit_balance');
          if (!hasDebitBalance) {
            await db.execute(
              'ALTER TABLE customers ADD COLUMN debit_balance REAL NOT NULL DEFAULT 0',
            );
          }
        }
        if (oldVersion < 17) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS stores (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              address TEXT NOT NULL,
              contact TEXT NOT NULL
            )
          ''');

          // 1. Create Default Store
          await db.execute('''
            INSERT OR IGNORE INTO stores (id, name, address, contact)
            VALUES ('store-default', 'Default Store', 'N/A', 'N/A')
          ''');

          // 2. Add store_id to existing tables
          final tables = [
            'inventory_products',
            'cart_items',
            'orders',
            'staff_roles',
            'staff_members',
            'daftari_recovery_sessions',
            'daftari_learning_rules',
            'myduka_ai_messages',
            'myduka_ai_threads',
            'expenses',
            'customers'
          ];
          for (final table in tables) {
            await db.execute('ALTER TABLE $table ADD COLUMN store_id TEXT NOT NULL DEFAULT "store-default"');
          }
        }
        if (oldVersion < 18) {
          await db.execute('ALTER TABLE orders ADD COLUMN customer_name TEXT');
          await db.execute('ALTER TABLE orders ADD COLUMN discount_amount REAL');
          await db.execute('ALTER TABLE orders ADD COLUMN discount_label TEXT');
          await db.execute('ALTER TABLE order_lines ADD COLUMN unit_cost REAL');
        }
        final appProfileInfo =
            await db.rawQuery('PRAGMA table_info(app_profile)');
        final hasCapabilityOverridesJson = appProfileInfo
            .any((column) => column['name'] == 'capability_overrides_json');
        if (!hasCapabilityOverridesJson) {
          await db.execute(
            'ALTER TABLE app_profile ADD COLUMN capability_overrides_json TEXT',
          );
        }
        if (oldVersion < 19) {
          await _restoreDefaultStoreProfile(db);
          await db.update('app_profile', {'business_category': 'Retail'});
        }
        if (oldVersion < 20) {
          await db.execute(_receiptSettingsSchema);
        }
        if (oldVersion < 21) {
          final staffInfo = await db.rawQuery('PRAGMA table_info(staff_members)');
          final existingColumns =
              staffInfo.map((column) => column['name'] as String).toSet();
          Future<void> addColumn(String name, String definition) async {
            if (!existingColumns.contains(name)) {
              await db.execute(
                'ALTER TABLE staff_members ADD COLUMN $definition',
              );
            }
          }

          await addColumn('username', "username TEXT NOT NULL DEFAULT ''");
          await addColumn(
              'password_hash', "password_hash TEXT NOT NULL DEFAULT ''");
          await addColumn(
              'password_salt', "password_salt TEXT NOT NULL DEFAULT ''");
          await addColumn(
              'employee_number', "employee_number TEXT NOT NULL DEFAULT ''");
          await addColumn('job_title', "job_title TEXT NOT NULL DEFAULT ''");
          await addColumn('department', "department TEXT NOT NULL DEFAULT ''");
          await addColumn('hire_date', "hire_date TEXT NOT NULL DEFAULT ''");
          await addColumn(
              'employment_type', "employment_type TEXT NOT NULL DEFAULT ''");
          await addColumn(
              'hourly_rate', 'hourly_rate REAL NOT NULL DEFAULT 0');
          await addColumn('emergency_contact_name',
              "emergency_contact_name TEXT NOT NULL DEFAULT ''");
          await addColumn('emergency_contact_phone',
              "emergency_contact_phone TEXT NOT NULL DEFAULT ''");
          await addColumn('emergency_contact_relation',
              "emergency_contact_relation TEXT NOT NULL DEFAULT ''");
          await addColumn('address', "address TEXT NOT NULL DEFAULT ''");
          await addColumn('notes', "notes TEXT NOT NULL DEFAULT ''");
          await addColumn('avatar_path', 'avatar_path TEXT');
          await addColumn('status', "status TEXT NOT NULL DEFAULT 'active'");
          await addColumn('updated_at', "updated_at TEXT NOT NULL DEFAULT ''");
        }
      },
      onOpen: (db) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS stores (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            address TEXT NOT NULL,
            contact TEXT NOT NULL
          )
        ''');
        await db.execute('''
          INSERT OR IGNORE INTO stores (id, name, address, contact)
          VALUES ('store-default', 'Default Store', 'N/A', 'N/A')
        ''');
      },
    );
    return _database!;
  }

  Future<void> _restoreDefaultStoreProfile(Database db) async {
    final schema = await db.rawQuery('PRAGMA table_info(store_locations)');
    if (schema.isEmpty) return;

    final activeLocations = await db.query(
      'store_locations',
      columns: ['id'],
      where: 'is_active = 1 AND id != ?',
      whereArgs: ['store-current'],
      limit: 1,
    );
    if (activeLocations.isEmpty) return;

    final locations = await db.query(
      'store_locations',
      where: 'id = ?',
      whereArgs: ['store-current'],
      limit: 1,
    );
    if (locations.isEmpty) return;

    final location = locations.single;
    final profile = <String, Object?>{};
    final snapshot = location['profile_json'];
    if (snapshot is String && snapshot.isNotEmpty) {
      try {
        final decoded = jsonDecode(snapshot);
        if (decoded is Map<String, dynamic>) {
          const textFields = [
            'owner_name',
            'role_title',
            'email_address',
            'member_since',
            'weekday_open',
            'weekday_close',
            'saturday_open',
            'saturday_close',
            'sunday_schedule',
          ];
          for (final field in textFields) {
            if (decoded[field] is String) profile[field] = decoded[field];
          }
          final open24Hours = decoded['open_24_hours'];
          if (open24Hours is int) profile['open_24_hours'] = open24Hours;
        }
      } on FormatException {
        // Legacy location columns still contain the default store's details.
      }
    }

    await db.update(
      'app_profile',
      {
        ...profile,
        'store_name': location['name'],
        'contact_number': location['contact_number'],
        'physical_address': location['address'],
        'tax_id': location['tax_id'],
        'logo_path': location['logo_path'],
      },
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<ReceiptSettings> loadReceiptSettings() async {
    final db = await database;
    final rows = await db.query('receipt_settings', limit: 1);
    if (rows.isEmpty) return const ReceiptSettings();

    final row = rows.single;
    return ReceiptSettings(
      showStoreContact: row['show_store_contact'] == 1,
      footer: row['footer'] as String,
    );
  }

  Future<void> saveReceiptSettings(ReceiptSettings settings) async {
    final db = await database;
    await db.insert(
      'receipt_settings',
      {
        'id': 1,
        'show_store_contact': settings.showStoreContact ? 1 : 0,
        'footer': settings.footer,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, Object?>?> loadAppProfile() async {
    final db = await database;
    final rows = await db.query('app_profile', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> saveAppProfile(Map<String, Object?> profile) async {
    final db = await database;
    final tableInfo = await db.rawQuery('PRAGMA table_info(app_profile)');
    final availableColumns = tableInfo
        .map((column) => column['name'] as String?)
        .whereType<String>()
        .toSet();
    final writableProfile = <String, Object?>{'id': 1};
    for (final entry in profile.entries) {
      if (availableColumns.contains(entry.key)) {
        writableProfile[entry.key] = entry.value;
      }
    }
    await db.insert(
      'app_profile',
      writableProfile,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> loadStaffRoles(String storeId) async {
    final db = await database;
    return db.query(
      'staff_roles',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'sort_order ASC, title ASC',
    );
  }

  Future<void> replaceStaffRoles(
    List<Map<String, Object?>> roles,
    String storeId,
  ) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('staff_roles', where: 'store_id = ?', whereArgs: [storeId]);
    for (final role in roles) {
      batch.insert(
        'staff_roles',
        {...role, 'store_id': storeId},
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, Object?>>> loadStaffMembers(String storeId) async {
    final db = await database;
    return db.query(
      'staff_members',
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> replaceStaffMembers(List<Map<String, Object?>> members, String storeId) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('staff_members', where: 'store_id = ?', whereArgs: <Object?>[storeId]);
    for (final member in members) {
      batch.insert(
        'staff_members',
        {...member, 'store_id': storeId},
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

  Future<List<InventoryProductItem>> loadInventory(String storeId) async {
    final db = await database;
    final rows = await db.query(
      'inventory_products',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'code ASC',
    );
    return rows.map(_inventoryFromMap).toList();
  }

  Future<void> replaceInventory(List<InventoryProductItem> items, String storeId) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('inventory_products', where: 'store_id = ?', whereArgs: <Object?>[storeId]);
    for (final item in items) {
      batch.insert(
        'inventory_products',
        _inventoryToMap(item, storeId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ProductItem>> loadCart(String storeId) async {
    final db = await database;
    final rows = await db.query(
      'cart_items',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'id ASC',
    );
    return rows.map(_productFromMap).toList();
  }

  Future<void> replaceCart(List<ProductItem> items, String storeId) async {
    final db = await database;
    final batch = db.batch();
    batch.delete(
      'cart_items',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
    );
    for (final item in items) {
      batch.insert('cart_items', _productToMap(item, storeId));
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
            'quantity': line.quantity,
            'unit_price': line.unitPrice,
            'unit_price_value': line.unitPriceValue,
            'unit_cost': line.unitCost,
            'art_type': line.artType.name,
            'image_path': line.imagePath,
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
        if (updated != 1) throw StateError('Stock record missing for ${item.code}.');
      }
      if (creditCustomer != null) {
        final updated = await txn.update(
          'customers',
          {'debit_balance': creditCustomer['debit_balance']},
          where: 'store_id = ? AND id = ?',
          whereArgs: [storeId, creditCustomer['id']],
        );
        if (updated != 1) throw StateError('Customer credit account is unavailable.');
      }
      await txn.delete('cart_items', where: 'store_id = ?', whereArgs: [storeId]);
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
      await txn.delete('customers', where: 'store_id = ?', whereArgs: [storeId]);
      for (final customer in customers) {
        await txn.insert('customers', {...customer, 'store_id': storeId});
      }
    });
  }

  Future<List<DaftariRecoverySession>> loadDaftariSessions(String storeId) async {
    final db = await database;
    final rows = await db.query(
      'daftari_recovery_sessions',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'created_at DESC',
    );
    return rows.map(DaftariRecoverySession.fromMap).toList();
  }

  Future<void> upsertDaftariSession(DaftariRecoverySession session, String storeId) async {
    final db = await database;
    await db.insert(
      'daftari_recovery_sessions',
      {...session.toMap(), 'store_id': storeId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DaftariLearningRule>> loadDaftariLearningRules(String storeId) async {
    final db = await database;
    final rows = await db.query(
      'daftari_learning_rules',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'last_used_at DESC, hit_count DESC',
    );
    return rows.map(DaftariLearningRule.fromMap).toList();
  }

  Future<void> upsertDaftariLearningRule(DaftariLearningRule rule, String storeId) async {
    final db = await database;
    await db.insert(
      'daftari_learning_rules',
      {...rule.toMap(), 'store_id': storeId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DukaAiThread>> loadDukaAiThreads(String storeId) async {
    final db = await database;
    final rows = await db.query(
      'myduka_ai_threads',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
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

  Future<void> upsertDukaAiThread(DukaAiThread thread, String storeId) async {
    final db = await database;
    await db.insert(
      'myduka_ai_threads',
      <String, Object?>{
        'id': thread.id,
        'store_id': storeId,
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
    String storeId,
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
          'store_id': storeId,
          'role': message.role,
          'content': message.content,
          'image_path': message.imagePath,
          'created_at': message.createdAt ?? DateTime.now().toIso8601String(),
        },
      );
    }
    await batch.commit(noResult: true);
  }

  Map<String, Object?> _inventoryToMap(InventoryProductItem item, String storeId) {
    return <String, Object?>{
      'code': item.code,
      'store_id': storeId,
      'name': item.name,
      'category': item.category,
      'purchase_price': item.purchasePrice,
      'selling_price': item.sellingPrice,
      'stock_count': item.stockCount,
      'stock_state': item.stockState.name,
      'art_type': item.artType.name,
      'image_path': item.imagePath,
      'category_data_json': jsonEncode(item.categoryData),
    };
  }

  InventoryProductItem _inventoryFromMap(Map<String, Object?> map) {
    final rawMetadata = map['category_data_json'] as String? ?? '{}';
    final metadata = Map<String, Object?>.from(
        jsonDecode(rawMetadata) as Map<dynamic, dynamic>);
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
      categoryData: metadata,
    );
  }

  Map<String, Object?> _productToMap(ProductItem item, String storeId) {
    return <String, Object?>{
      'code': item.code,
      'store_id': storeId,
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
      unitCost: (map['unit_cost'] as num?)?.toDouble(),
      artType: ProductArtType.values.byName(map['art_type'] as String),
      imagePath: map['image_path'] as String?,
    );
  }

  Future<List<Map<String, Object?>>> loadExpenses(String storeId) async {
    final db = await database;
    return db.query(
      'expenses',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'date DESC',
    );
  }

  Future<void> insertExpense(Map<String, Object?> expense, String storeId) async {
    final db = await database;
    await db.insert('expenses', {...expense, 'store_id': storeId});
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
