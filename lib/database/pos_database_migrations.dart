part of '../service/pos_local_database.dart';

Future<void> _upgradePosDatabase(
  Database db,
  int oldVersion,
  int newVersion,
) async {
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
    final tableInfo = await db.rawQuery('PRAGMA table_info(store_locations)');
    final hasProfileJson =
        tableInfo.any((column) => column['name'] == 'profile_json');
    if (!hasProfileJson) {
      await db.execute(
        'ALTER TABLE store_locations ADD COLUMN profile_json TEXT',
      );
    }
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
        await db.execute('ALTER TABLE app_profile ADD COLUMN $definition');
      }
    }

    await addColumn('tax_id', 'tax_id TEXT NOT NULL DEFAULT \'\'');
    await addColumn('weekday_open', 'weekday_open TEXT NOT NULL DEFAULT \'\'');
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
      'expenses',
      'customers'
    ];
    for (final table in tables) {
      await db.execute(
          'ALTER TABLE $table ADD COLUMN store_id TEXT NOT NULL DEFAULT "store-default"');
    }
  }
  if (oldVersion < 18) {
    await db.execute('ALTER TABLE orders ADD COLUMN customer_name TEXT');
    await db.execute('ALTER TABLE orders ADD COLUMN discount_amount REAL');
    await db.execute('ALTER TABLE orders ADD COLUMN discount_label TEXT');
    await db.execute('ALTER TABLE order_lines ADD COLUMN unit_cost REAL');
  }
  final appProfileInfo = await db.rawQuery('PRAGMA table_info(app_profile)');
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
    await addColumn('password_hash', "password_hash TEXT NOT NULL DEFAULT ''");
    await addColumn('password_salt', "password_salt TEXT NOT NULL DEFAULT ''");
    await addColumn(
        'employee_number', "employee_number TEXT NOT NULL DEFAULT ''");
    await addColumn('job_title', "job_title TEXT NOT NULL DEFAULT ''");
    await addColumn('department', "department TEXT NOT NULL DEFAULT ''");
    await addColumn('hire_date', "hire_date TEXT NOT NULL DEFAULT ''");
    await addColumn(
        'employment_type', "employment_type TEXT NOT NULL DEFAULT ''");
    await addColumn('hourly_rate', 'hourly_rate REAL NOT NULL DEFAULT 0');
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
  if (oldVersion < 22) {
    final receiptInfo =
        await db.rawQuery('PRAGMA table_info(receipt_settings)');
    final existingColumns =
        receiptInfo.map((column) => column['name'] as String).toSet();
    Future<void> addReceiptColumn(String name, String definition) async {
      if (!existingColumns.contains(name)) {
        await db.execute(
          'ALTER TABLE receipt_settings ADD COLUMN $definition',
        );
      }
    }

    await addReceiptColumn(
        'show_tax_id', 'show_tax_id INTEGER NOT NULL DEFAULT 1');
    await addReceiptColumn(
        'show_order_number', 'show_order_number INTEGER NOT NULL DEFAULT 1');
    await addReceiptColumn(
        'show_date_time', 'show_date_time INTEGER NOT NULL DEFAULT 1');
    await addReceiptColumn(
        'show_cashier', 'show_cashier INTEGER NOT NULL DEFAULT 1');
    await addReceiptColumn(
        'show_customer', 'show_customer INTEGER NOT NULL DEFAULT 1');
    await addReceiptColumn(
        'show_payment_method', 'show_payment_method INTEGER NOT NULL DEFAULT 1');
    await addReceiptColumn(
        'show_item_count', 'show_item_count INTEGER NOT NULL DEFAULT 1');
    await addReceiptColumn(
        'show_discount', 'show_discount INTEGER NOT NULL DEFAULT 1');
    await addReceiptColumn('header', "header TEXT NOT NULL DEFAULT ''");
  }
  if (oldVersion < 23) {
    final expenseInfo = await db.rawQuery('PRAGMA table_info(expenses)');
    final expenseColumns =
        expenseInfo.map((column) => column['name'] as String).toSet();
    Future<void> addExpenseColumn(String name, String definition) async {
      if (!expenseColumns.contains(name)) {
        await db.execute('ALTER TABLE expenses ADD COLUMN $definition');
      }
    }

    await addExpenseColumn('vendor', "vendor TEXT NOT NULL DEFAULT ''");
    await addExpenseColumn('tax_amount', 'tax_amount REAL NOT NULL DEFAULT 0');
    await addExpenseColumn('receipt_path', 'receipt_path TEXT');
    await addExpenseColumn('status', "status TEXT NOT NULL DEFAULT 'submitted'");
    await addExpenseColumn('created_at', "created_at TEXT NOT NULL DEFAULT ''");
    await addExpenseColumn('updated_at', "updated_at TEXT NOT NULL DEFAULT ''");
  }
  if (oldVersion < 24) {
    await db.execute(_debitEntriesSchema);
  }
  if (oldVersion < 25) {
    await db.execute(_registerShiftsSchema);
    await db.execute(_cashMovementsSchema);
  }
  if (oldVersion < 26) {
    await db.execute(_suppliersSchema);
    await db.execute(_receivingsSchema);
    await db.execute(_receivingLinesSchema);
  }
  if (oldVersion < 27) {
    await db.execute(_taxSettingsSchema);
  }
  if (oldVersion < 28) {
    await db.execute(_accountsSchema);
    await db.execute(_journalEntriesSchema);
    await db.execute(_journalLinesSchema);
    await db.execute(_fixedAssetsSchema);
    await db.execute(_bankTransactionsSchema);
  }
  if (oldVersion < 29) {
    await db.execute(_registerShiftsSchema);
    await db.execute(_cashMovementsSchema);
    await db.execute(_suppliersSchema);
    await db.execute(_receivingsSchema);
    await db.execute(_receivingLinesSchema);
    await db.execute(_taxSettingsSchema);
    await db.execute(_accountsSchema);
    await db.execute(_journalEntriesSchema);
    await db.execute(_journalLinesSchema);
    await db.execute(_fixedAssetsSchema);
    await db.execute(_bankTransactionsSchema);
  }
  if (oldVersion < 30) {
    await db.execute(_suspendedSalesSchema);
  }
}

Future<void> _onOpenPosDatabase(Database db) async {
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
  await db.execute(_registerShiftsSchema);
  await db.execute(_cashMovementsSchema);
  await db.execute(_suppliersSchema);
  await db.execute(_receivingsSchema);
  await db.execute(_receivingLinesSchema);
  await db.execute(_taxSettingsSchema);
  await db.execute(_accountsSchema);
  await db.execute(_journalEntriesSchema);
  await db.execute(_journalLinesSchema);
  await db.execute(_fixedAssetsSchema);
  await db.execute(_bankTransactionsSchema);
  await db.execute(_suspendedSalesSchema);
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
