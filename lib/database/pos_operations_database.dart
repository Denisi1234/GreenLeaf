part of '../service/pos_local_database.dart';

mixin PosOperationsDatabaseMixin {
  Future<Database> get database;

  Future<ReceiptSettings> loadReceiptSettings() async {
    final db = await database;
    final rows = await db.query('receipt_settings', limit: 1);
    if (rows.isEmpty) return const ReceiptSettings();

    final row = rows.single;
    bool flag(String key) => row[key] == null || row[key] == 1;
    return ReceiptSettings(
      showStoreContact: flag('show_store_contact'),
      showTaxId: flag('show_tax_id'),
      showOrderNumber: flag('show_order_number'),
      showDateTime: flag('show_date_time'),
      showCashier: flag('show_cashier'),
      showCustomer: flag('show_customer'),
      showPaymentMethod: flag('show_payment_method'),
      showItemCount: flag('show_item_count'),
      showDiscount: flag('show_discount'),
      header: row['header'] as String? ?? '',
      footer: row['footer'] as String? ?? '',
    );
  }

  Future<void> saveReceiptSettings(ReceiptSettings settings) async {
    final db = await database;
    await db.insert(
      'receipt_settings',
      {
        'id': 1,
        'show_store_contact': settings.showStoreContact ? 1 : 0,
        'show_tax_id': settings.showTaxId ? 1 : 0,
        'show_order_number': settings.showOrderNumber ? 1 : 0,
        'show_date_time': settings.showDateTime ? 1 : 0,
        'show_cashier': settings.showCashier ? 1 : 0,
        'show_customer': settings.showCustomer ? 1 : 0,
        'show_payment_method': settings.showPaymentMethod ? 1 : 0,
        'show_item_count': settings.showItemCount ? 1 : 0,
        'show_discount': settings.showDiscount ? 1 : 0,
        'header': settings.header,
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

  Future<void> upsertStaffRole(
    Map<String, Object?> role,
    String storeId,
  ) async {
    final db = await database;
    await db.insert(
      'staff_roles',
      {...role, 'store_id': storeId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteStaffRoleRecord(String roleId, String storeId) async {
    final db = await database;
    await db.delete(
      'staff_roles',
      where: 'store_id = ? AND id = ?',
      whereArgs: <Object?>[storeId, roleId],
    );
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

  Future<void> replaceStaffMembers(
      List<Map<String, Object?>> members, String storeId) async {
    final db = await database;
    final existing = await db.query(
      'staff_members',
      columns: <String>['id', 'password_hash', 'password_salt'],
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
    );
    final cachedCredentials = <String, Map<String, Object?>>{
      for (final row in existing)
        if (row['id'] is String &&
            (row['password_hash'] as String? ?? '')
                .startsWith('pbkdf2_sha256\$'))
          row['id'] as String: row,
    };
    final batch = db.batch();
    batch.delete('staff_members',
        where: 'store_id = ?', whereArgs: <Object?>[storeId]);
    for (final member in members) {
      final row = Map<String, Object?>.from(member);
      final cached = cachedCredentials['${member['id']}'];
      if (cached != null) {
        // The server only stores a non-verifiable placeholder hash, so keep
        // this device's cached hash to allow offline sign-in after a pull.
        row['password_hash'] = cached['password_hash'];
        row['password_salt'] = cached['password_salt'];
      }
      batch.insert(
        'staff_members',
        {...row, 'store_id': storeId},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveStaffMember(Map<String, Object?> member) async {
    final db = await database;
    final row = <String, Object?>{
      'store_id': 'store-default',
      ...member,
    };
    if (row['store_id'] == null || (row['store_id'] as String).isEmpty) {
      row['store_id'] = 'store-default';
    }
    await db.insert(
      'staff_members',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveStaffRecord(
    Map<String, Object?> staff,
    String? password,
  ) =>
      saveStaffMember(staff);

  Future<void> deleteStaffMember(String id) async {
    final db = await database;
    await db.delete(
      'staff_members',
      where: 'id = ?',
      whereArgs: <Object?>[id],
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

  Future<void> insertExpense(
      Map<String, Object?> expense, String storeId) async {
    final db = await database;
    await db.insert('expenses', {...expense, 'store_id': storeId});
  }

  Future<void> updateExpense(int id, Map<String, Object?> expense) async {
    final db = await database;
    final data = Map<String, Object?>.from(expense)..remove('id');
    await db
        .update('expenses', data, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<Map<String, Object?>>> loadRegisterShifts(String storeId,
      {int? limit}) async {
    final db = await database;
    return db.query(
      'register_shifts',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'opened_at DESC',
      limit: limit,
    );
  }

  Future<RegisterShift?> loadOpenShift(String storeId) async {
    final db = await database;
    final rows = await db.query(
      'register_shifts',
      where: 'store_id = ? AND closed_at IS NULL',
      whereArgs: <Object?>[storeId],
      orderBy: 'opened_at DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : RegisterShift.fromMap(rows.first);
  }

  Future<int> insertRegisterShift(
      Map<String, Object?> shift, String storeId) async {
    final db = await database;
    return db.insert('register_shifts', {...shift, 'store_id': storeId});
  }

  Future<void> updateRegisterShift(int id, Map<String, Object?> shift) async {
    final db = await database;
    final data = Map<String, Object?>.from(shift)..remove('id');
    await db.update('register_shifts', data,
        where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<List<Map<String, Object?>>> loadCashMovements(String storeId) async {
    final db = await database;
    return db.query(
      'cash_movements',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'at ASC',
    );
  }

  Future<void> insertCashMovement(
      Map<String, Object?> movement, String storeId) async {
    final db = await database;
    await db.insert('cash_movements', {...movement, 'store_id': storeId});
  }

  Future<void> deleteCashMovement(int id) async {
    final db = await database;
    await db
        .delete('cash_movements', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  Future<TaxSettings> loadTaxSettings() async {
    final db = await database;
    final rows = await db.query('tax_settings', limit: 1);
    if (rows.isEmpty) return const TaxSettings();
    return TaxSettings.fromJson(rows.first);
  }

  Future<void> saveTaxSettings(TaxSettings settings) async {
    final db = await database;
    final values = <String, Object?>{
      'enabled': settings.enabled ? 1 : 0,
      'rate_percent': settings.ratePercent,
      'prices_include_tax': settings.pricesIncludeTax ? 1 : 0,
      'tax_id': settings.taxId,
      'tax_label': settings.taxLabel,
      'track_expense_tax': settings.trackExpenseTax ? 1 : 0,
    };
    final existing = await db.query('tax_settings', limit: 1);
    if (existing.isEmpty) {
      await db.insert('tax_settings', {'id': 1, ...values});
    } else {
      await db.update('tax_settings', values, where: 'id = 1');
    }
  }

  Future<void> _ensureSyncSessionTable() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        endpoint TEXT NOT NULL,
        token TEXT NOT NULL,
        user_json TEXT NOT NULL,
        saved_at TEXT NOT NULL
      )
    ''');
  }

  static const String _keystoreTokenSentinel = '__keystore_protected__';
  static const String _syncBearerTokenKey = 'sync_bearer_token';

  Future<Map<String, Object?>?> loadSyncSession() async {
    await _ensureSyncSessionTable();
    final db = await database;
    final rows = await db.query('sync_session', limit: 1);
    if (rows.isEmpty) return null;

    final row = Map<String, Object?>.from(rows.first);
    final storedToken = row['token'] as String? ?? '';
    if (storedToken == _keystoreTokenSentinel) {
      final secret = await SecureTokenStorage.instance.read(_syncBearerTokenKey);
      if (secret == null || secret.isEmpty) return null;
      row['token'] = secret;
      return row;
    }

    if (storedToken.isNotEmpty) {
      await SecureTokenStorage.instance.write(_syncBearerTokenKey, storedToken);
      await db.update(
        'sync_session',
        {'token': _keystoreTokenSentinel},
        where: 'id = ?',
        whereArgs: [row['id'] ?? 1],
      );
    }
    return row;
  }

  Future<void> saveSyncSession({
    required String endpoint,
    required String token,
    required Map<String, Object?> user,
  }) async {
    await _ensureSyncSessionTable();
    if (token.isNotEmpty) {
      await SecureTokenStorage.instance.write(_syncBearerTokenKey, token);
    } else {
      await SecureTokenStorage.instance.delete(_syncBearerTokenKey);
    }
    final db = await database;
    await db.insert(
      'sync_session',
      {
        'id': 1,
        'endpoint': endpoint,
        'token': token.isEmpty ? '' : _keystoreTokenSentinel,
        'user_json': jsonEncode(user),
        'saved_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearSyncSession() async {
    await SecureTokenStorage.instance.delete(_syncBearerTokenKey);
    await _ensureSyncSessionTable();
    final db = await database;
    await db.delete('sync_session');
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

  Future<List<Map<String, Object?>>> loadStores() async {
    final db = await database;
    final rows = await db.query('stores', orderBy: 'name ASC');
    if (rows.isEmpty) {
      return <Map<String, Object?>>[
        <String, Object?>{
          'id': 'store-default',
          'name': 'Default Store',
          'address': '',
          'contact': '',
        },
      ];
    }
    return rows;
  }

  Future<void> upsertStore(Map<String, Object?> store) async {
    final db = await database;
    await db.insert(
      'stores',
      <String, Object?>{
        'id': store['id'],
        'name': store['name'],
        'address': store['address'] ?? '',
        'contact': store['contact'] ?? '',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteStore(String storeId) async {
    if (storeId == 'store-default') return;
    final db = await database;
    await db.delete('stores', where: 'id = ?', whereArgs: <Object?>[storeId]);
  }

  /// Appends an immutable audit entry; updates and deletes are intentionally omitted.
  Future<void> insertAuditLog(Map<String, Object?> row) async {
    final db = await database;
    await db.insert(
      'audit_logs',
      row,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, Object?>>> loadAuditLogs(
    String storeId, {
    int limit = 2000,
  }) async {
    final db = await database;
    return db.query(
      'audit_logs',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'sequence DESC, timestamp DESC',
      limit: limit,
    );
  }

  Future<Map<String, Object?>?> loadLatestAuditLog(String storeId) async {
    final db = await database;
    final rows = await db.query(
      'audit_logs',
      where: 'store_id = ?',
      whereArgs: <Object?>[storeId],
      orderBy: 'sequence DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }
}
