import 'dart:async';
import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../ui/models/product_item.dart';
import '../ui/products/inventory_product_item.dart';
import 'php_api_client.dart';
import 'pos_local_database.dart';
import 'pos_order_models.dart';
import 'receipt_settings.dart';
import 'tax_settings.dart';

/// Local-first database used in cloud mode.
///
/// Every business write is committed to SQLite first so the till keeps working
/// without a connection. The same write is appended to a persistent outbox and
/// replayed to the PHP API in the background as soon as the device is online.
class PosHybridDatabase extends PosLocalDatabase {
  PosHybridDatabase(this.api);

  String storeId = 'store-default';

  final PhpApiClient api;

  Timer? _retryTimer;
  Timer? _debounce;
  bool _syncing = false;
  bool _syncAgain = false;
  bool _prepared = false;
  bool _disposed = false;

  void Function()? onSynced;

  bool get isSyncing => _syncing;

  Future<void> prepare() async {
    if (_prepared) return;
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        kind TEXT NOT NULL,
        resource TEXT,
        record_id TEXT,
        payload TEXT,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        failed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS sync_outbox_pending '
      'ON sync_outbox (failed, id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS sync_outbox_resource '
      'ON sync_outbox (resource, kind)',
    );
    _prepared = true;
  }

  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _retryTimer?.cancel();
    // Battery-optimized background sync interval (5 minutes) while immediate local
    // changes (sales, refunds, inventory) trigger push flush within 300ms.
    _retryTimer = Timer.periodic(
      interval,
      (_) => syncNow(pull: true),
    );
    _scheduleFlush();
  }

  void stopAutoSync() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _debounce?.cancel();
    _debounce = null;
  }

  void dispose() {
    _disposed = true;
    stopAutoSync();
  }

  void _scheduleFlush() {
    if (_disposed) return;
    _debounce?.cancel();
    // Fast flush to push sales / stock changes to the cloud within 300ms
    _debounce = Timer(const Duration(milliseconds: 300), () {
      syncNow(pull: false);
    });
  }

  /// Called after a successful login. Replays any pending local work with the
  /// fresh token, then hydrates this device from the server when safe.
  Future<void> hydrate() async {
    await prepare();
    await retryFailed();
    await syncNow(pull: false);
    if (await _unresolvedCount() == 0) {
      await pullAll();
    }
  }

  Future<int> pendingCount() async {
    await prepare();
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM sync_outbox WHERE failed = 0',
    );
    return (rows.first['c'] as num).toInt();
  }

  Future<int> failedCount() async {
    await prepare();
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM sync_outbox WHERE failed = 1',
    );
    return (rows.first['c'] as num).toInt();
  }

  Future<int> _unresolvedCount() async =>
      await pendingCount() + await failedCount();

  Future<void> retryFailed() async {
    await prepare();
    final db = await database;
    await db.update(
      'sync_outbox',
      {'failed': 0, 'last_error': null},
      where: 'failed = 1',
    );
    _scheduleFlush();
  }

  /// Drops queued work. Used when a different account signs in on this device
  /// so the previous account's unsynced changes are never pushed to the new one.
  Future<void> clearOutbox() async {
    await prepare();
    final db = await database;
    await db.delete('sync_outbox');
  }

  Future<void> _enqueue({
    required String kind,
    String? resource,
    String? recordId,
    Object? payload,
  }) async {
    await prepare();
    final db = await database;
    await db.insert('sync_outbox', {
      'kind': kind,
      'resource': resource,
      'record_id': recordId,
      'payload': payload == null ? null : jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
    _scheduleFlush();
  }

  Future<List<Map<String, Object?>>> _pendingEvents() async {
    await prepare();
    final db = await database;
    return db.query(
      'sync_outbox',
      where: 'failed = 0',
      orderBy: 'id ASC',
      limit: 200,
    );
  }

  Future<void> _deleteEvent(Object? id) async {
    final db = await database;
    await db.delete('sync_outbox', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _markFailed(Object? id, String error) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_outbox SET failed = 1, attempts = attempts + 1, '
      'last_error = ? WHERE id = ?',
      [error, id],
    );
  }

  Future<Map<String, Object?>> _uploadImages(
    Map<String, Object?> row,
  ) async {
    final result = Map<String, Object?>.from(row);
    for (final key in ['image_path', 'logo_path', 'avatar_path']) {
      final value = result[key];
      if (value is String && value.isNotEmpty) {
        result[key] = await api.uploadImage(value);
      }
    }
    return result;
  }

  Future<List<Map<String, Object?>>> _uploadRows(
    List<Map<String, Object?>> rows,
  ) async {
    final result = <Map<String, Object?>>[];
    for (final row in rows) {
      result.add(await _uploadImages(row));
    }
    return result;
  }

  Future<void> syncNow({bool pull = false}) async {
    if (_disposed) return;
    if (_syncing) {
      _syncAgain = true;
      return;
    }
    _syncing = true;
    try {
      await prepare();
      final events = await _pendingEvents();
      for (final event in events) {
        if (_disposed) break;
        try {
          await _applyEvent(event);
          await _deleteEvent(event['id']);
        } on ApiException catch (error) {
          if (error.status == 401) rethrow;
          if (error.status == 409 &&
              event['kind'] == 'replace' &&
              event['resource'] is String) {
            try {
              final res = event['resource']! as String;
              final remoteRows = await api.rows(res);
              final raw = event['payload'] as String?;
              if (raw != null) {
                final localRows = (jsonDecode(raw) as List)
                    .map((row) => Map<String, Object?>.from(row as Map))
                    .toList();
                final keyField = res == 'products' ? 'code' : 'id';
                final mergedByKey = <String, Map<String, Object?>>{
                  for (final r in remoteRows)
                    if (r[keyField] != null) '${r[keyField]}': r,
                };
                for (final l in localRows) {
                  final k = l[keyField]?.toString();
                  if (k != null) {
                    mergedByKey[k] = l;
                  }
                }
                final mergedEvent = Map<String, Object?>.from(event)
                  ..['payload'] = jsonEncode(mergedByKey.values.toList());
                await _applyEvent(mergedEvent);
              } else {
                await _applyEvent(event);
              }
              await _deleteEvent(event['id']);
              continue;
            } on ApiException {
              // Fall through to failure handling below.
            }
          }
          if (error.status >= 400 && error.status < 500) {
            await _markFailed(event['id'], error.message);
            continue;
          }
          rethrow;
        }
      }
      if (await pendingCount() > 0) _scheduleFlush();
      if (pull && await _unresolvedCount() == 0) {
        await pullAll();
        onSynced?.call();
      }
    } catch (_) {
      // Offline or auth expiry. Keep the outbox and retry when possible.
    } finally {
      _syncing = false;
      if (_syncAgain && !_disposed) {
        _syncAgain = false;
        _scheduleFlush();
      }
    }
  }

  Future<void> _applyEvent(Map<String, Object?> event) async {
    final kind = event['kind'] as String;
    final resource = event['resource'] as String?;
    final recordId = event['record_id'] as String?;
    final raw = event['payload'] as String?;
    final payload = raw == null ? null : jsonDecode(raw);
    final idempotencyKey =
        'tm-${event['id']}-$kind-${recordId ?? resource ?? 'batch'}';

    switch (kind) {
      case 'checkout':
        await api.request(
          'POST',
          'checkout',
          body: Map<String, Object?>.from(payload as Map),
          idempotencyKey: idempotencyKey,
        );
      case 'void':
        await api.request(
          'POST',
          'orders/${Uri.encodeComponent(recordId ?? '')}/void',
          idempotencyKey: idempotencyKey,
        );
      case 'replace':
        final rows = (payload as List)
            .map((row) => Map<String, Object?>.from(row as Map))
            .toList();
        await api.replace(
          resource!,
          await _uploadRows(rows),
          idempotencyKey: idempotencyKey,
        );
      case 'put':
        final row = Map<String, Object?>.from(payload as Map);
        await api.put(
          resource!,
          recordId!,
          await _uploadImages(row),
          idempotencyKey: idempotencyKey,
        );
      case 'delete':
        await api.delete(
          resource!,
          recordId!,
          idempotencyKey: idempotencyKey,
        );
      case 'stock-delta':
        final payloadMap = Map<String, Object?>.from(payload as Map);
        final rawDeltas =
            Map<String, Object?>.from(payloadMap['deltas'] as Map);
        final threshold =
            (payloadMap['low_stock_threshold'] as num?)?.toInt() ?? 20;
        try {
          await api.request(
            'POST',
            'products/stock-delta',
            body: <String, Object?>{'deltas': rawDeltas},
            idempotencyKey: idempotencyKey,
          );
          break;
        } on ApiException catch (error) {
          if (error.status != 404 && error.status != 405) rethrow;
        }
        final remoteRows = await api.rows('products');
        final byCode = <String, Map<String, Object?>>{
          for (final row in remoteRows)
            if (row['code'] != null) '${row['code']}': row,
        };
        for (final entry in rawDeltas.entries) {
          final delta = (entry.value as num).toInt();
          if (delta == 0) continue;
          final remote = byCode[entry.key];
          if (remote == null) continue;
          final current = (remote['stock_count'] as num?)?.toInt() ?? 0;
          final next = (current + delta).clamp(0, 1 << 31).toInt();
          final state = next <= 0
              ? InventoryStockState.outOfStock
              : next <= threshold
                  ? InventoryStockState.lowStock
                  : InventoryStockState.inStock;
          final updated = <String, Object?>{
            ...remote,
            'stock_count': next,
            'stock_state': state.name,
          };
          await api.put('products', entry.key, await _uploadImages(updated));
        }
      case 'staff-account':
        final row = Map<String, Object?>.from(
          (payload as Map)['staff'] as Map,
        );
        await api.request(
          'POST',
          'staff/${Uri.encodeComponent(recordId ?? '')}/account',
          body: {
            'staff': await _uploadImages(row),
            'password': payload['password'],
          },
        );
      default:
        throw StateError('Unknown sync operation: $kind');
    }
  }

  Future<void> pullAll() async {
    await prepare();

    final products = await api.rows('products');
    await super.replaceInventory(
      products.map(inventoryFromMap).toList(),
      storeId,
    );

    final customers = await api.rows('customers');
    await super.replaceCustomers(customers, storeId);

    if (api.can('View Sales') || api.can('View Reports')) {
      await _replaceOrdersLocal(await api.rows('orders'));
    }

    if (api.can('Manage Staff')) {
      await super.replaceStaffRoles(await api.rows('roles'), storeId);
      await super.replaceStaffMembers(await api.rows('staff'), storeId);
    }

    if (api.can('View Reports') || api.can('Manage Payments')) {
      try {
        await _replaceExpensesLocal(await api.rows('expenses'));
      } on ApiException catch (error) {
        if (error.status != 403) rethrow;
      }
    } else {
      await _clearExpensesLocal();
    }

    final profile = await api.rows('profile');
    if (profile.isNotEmpty) {
      await super.saveAppProfile(profile.first);
    } else {
      await super.saveAppProfile(const {
        'store_name': '',
        'owner_name': '',
        'role_title': '',
        'business_category': '',
        'contact_number': '',
        'email_address': '',
        'physical_address': '',
        'tax_id': '',
        'weekday_open': '',
        'weekday_close': '',
        'saturday_open': '',
        'saturday_close': '',
        'sunday_schedule': '',
        'open_24_hours': 0,
        'logo_path': null,
        'member_since': '',
      });
    }

    final receipt = await api.rows('receipt-settings');
    if (receipt.isNotEmpty) {
      final row = receipt.first;
      bool flag(String key) => row[key] == null || row[key] != 0;
      await super.saveReceiptSettings(ReceiptSettings(
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
      ));
    } else {
      await super.saveReceiptSettings(const ReceiptSettings());
    }

    try {
      final tax = await api.rows('tax-settings');
      if (tax.isNotEmpty) {
        await super.saveTaxSettings(TaxSettings.fromJson(tax.first));
      }
    } on ApiException catch (error) {
      if (error.status != 404 && error.status != 403) rethrow;
    }

    try {
      final debitRows = await api.rows('debit-entries');
      if (debitRows.isNotEmpty) {
        await super.replaceDebitEntries(debitRows, storeId);
      }
    } on ApiException catch (error) {
      if (error.status != 404 && error.status != 403) rethrow;
    }
  }

  Future<void> _replaceOrdersLocal(List<Map<String, Object?>> orders) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'order_lines',
        where: 'order_id IN (SELECT id FROM orders WHERE store_id = ?)',
        whereArgs: [storeId],
      );
      await txn.delete(
        'orders',
        where: 'store_id = ?',
        whereArgs: [storeId],
      );
      for (final order in orders) {
        await txn.insert(
          'orders',
          {
            'id': order['id'],
            'store_id': storeId,
            'date_time': order['date_time'],
            'date_label': order['date_label'],
            'time_label': order['time_label'],
            'total': order['total'],
            'status': order['status'],
            'cashier_name': order['cashier_name'],
            'register_name': order['register_name'],
            'payment_method': order['payment_method'],
            'cash_tendered': order['cash_tendered'],
            'change_due': order['change_due'],
            'customer_name': order['customer_name'],
            'discount_amount': order['discount_amount'],
            'discount_label': order['discount_label'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        final lines = (order['lines'] as List?) ?? const [];
        for (final line in lines) {
          final row = Map<String, Object?>.from(line as Map);
          await txn.insert('order_lines', {
            'order_id': order['id'],
            'item_code': row['item_code'],
            'item_category': row['item_category'] ?? '',
            'item_name': row['item_name'],
            'item_size': row['item_size'] ?? '',
            'quantity': row['quantity'],
            'unit_price': row['unit_price'],
            'unit_price_value': row['unit_price_value'],
            'unit_cost': row['unit_cost'],
            'art_type': row['art_type'],
            'image_path': row['image_path'],
          });
        }
      }
    });
  }

  Future<void> _clearExpensesLocal() async {
    final db = await database;
    await db.delete(
      'expenses',
      where: 'store_id = ?',
      whereArgs: [storeId],
    );
  }

  Future<void> _replaceExpensesLocal(
    List<Map<String, Object?>> expenses,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'expenses',
        where: 'store_id = ?',
        whereArgs: [storeId],
      );
      for (final expense in expenses) {
        await txn.insert(
          'expenses',
          {
            ...expense,
            'store_id': storeId,
            'id': (expense['id'] as num?)?.toInt(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Local-first writes. Each one persists locally, then queues the cloud work.
  // ---------------------------------------------------------------------------

  @override
  Future<void> replaceInventory(
    List<InventoryProductItem> items,
    String storeId,
  ) async {
    await super.replaceInventory(items, storeId);
    await _enqueue(
      kind: 'replace',
      resource: 'products',
      payload: items.map((item) => inventoryToMap(item, storeId)).toList(),
    );
  }

  @override
  Future<void> upsertInventoryItem(
    InventoryProductItem item,
    String storeId,
  ) async {
    await super.upsertInventoryItem(item, storeId);
    await _enqueue(
      kind: 'put',
      resource: 'products',
      recordId: item.code,
      payload: inventoryToMap(item, storeId),
    );
  }

  @override
  Future<void> deleteInventoryItem(String code, String storeId) async {
    await super.deleteInventoryItem(code, storeId);
    await _enqueue(
      kind: 'delete',
      resource: 'products',
      recordId: code,
    );
  }

  @override
  Future<void> adjustInventoryStock(
    Map<String, int> deltas,
    String storeId, {
    int lowStockThreshold = 20,
  }) async {
    if (deltas.isEmpty) return;
    await super.adjustInventoryStock(
      deltas,
      storeId,
      lowStockThreshold: lowStockThreshold,
    );
    await _enqueue(
      kind: 'stock-delta',
      resource: 'products',
      payload: <String, Object?>{
        'deltas': deltas,
        'low_stock_threshold': lowStockThreshold,
      },
    );
  }

  /// Persists inventory without queueing a cloud replace. Used after a void,
  /// where the server already restores stock from the voided sale.
  Future<void> replaceInventoryLocal(
    List<InventoryProductItem> items,
    String storeId,
  ) =>
      super.replaceInventory(items, storeId);

  @override
  Future<void> replaceCart(List<ProductItem> items, String storeId) async {
    await super.replaceCart(items, storeId);
    await _enqueue(
      kind: 'replace',
      resource: 'cart',
      payload: items.map((item) => productToMap(item, storeId)).toList(),
    );
  }

  @override
  Future<void> clearCart() async {
    await super.clearCart();
    await _enqueue(kind: 'replace', resource: 'cart', payload: const []);
  }

  /// Clears the on-device cart without queueing a cloud write. Used when a
  /// different account signs in, whose server cart starts empty.
  Future<void> clearLocalCart() => super.clearCart();

  @override
  Future<void> saveCheckout({
    required CompletedOrder order,
    required String storeId,
    required List<InventoryProductItem> stockUpdates,
    Map<String, Object?>? creditCustomer,
  }) async {
    await super.saveCheckout(
      order: order,
      storeId: storeId,
      stockUpdates: stockUpdates,
      creditCustomer: creditCustomer,
    );
    await _enqueue(kind: 'checkout', payload: _orderToMap(order));
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    await super.deleteOrder(orderId);
    await _enqueue(kind: 'void', recordId: orderId);
  }

  @override
  Future<void> replaceStaffRoles(
    List<Map<String, Object?>> roles,
    String storeId,
  ) async {
    await super.replaceStaffRoles(roles, storeId);
    await _enqueue(kind: 'replace', resource: 'roles', payload: roles);
  }

  @override
  Future<void> upsertStaffRole(
    Map<String, Object?> role,
    String storeId,
  ) async {
    await super.upsertStaffRole(role, storeId);
    await _enqueue(
      kind: 'put',
      resource: 'roles',
      recordId: '${role['id']}',
      payload: role,
    );
  }

  @override
  Future<void> deleteStaffRoleRecord(String roleId, String storeId) async {
    await super.deleteStaffRoleRecord(roleId, storeId);
    await _enqueue(
      kind: 'delete',
      resource: 'roles',
      recordId: roleId,
    );
  }

  @override
  Future<void> replaceStaffMembers(
    List<Map<String, Object?>> members,
    String storeId,
  ) async {
    await super.replaceStaffMembers(members, storeId);
    await _enqueue(kind: 'replace', resource: 'staff', payload: members);
  }

  @override
  Future<void> saveStaffMember(Map<String, Object?> member) async {
    final row = <String, Object?>{'store_id': storeId, ...member};
    await super.saveStaffMember(row);
    await _enqueue(
      kind: 'put',
      resource: 'staff',
      recordId: '${member['id']}',
      payload: member,
    );
  }

  @override
  Future<void> deleteStaffMember(String id) async {
    await super.deleteStaffMember(id);
    await _enqueue(kind: 'delete', resource: 'staff', recordId: id);
  }

  @override
  Future<void> saveStaffRecord(
    Map<String, Object?> staff,
    String? password,
  ) async {
    final row = <String, Object?>{'store_id': storeId, ...staff};
    await super.saveStaffMember(row);
    if (password != null && password.isNotEmpty) {
      await _enqueue(
        kind: 'staff-account',
        resource: 'staff',
        recordId: '${staff['id']}',
        payload: {'staff': staff, 'password': password},
      );
    } else {
      await _enqueue(
        kind: 'put',
        resource: 'staff',
        recordId: '${staff['id']}',
        payload: staff,
      );
    }
  }

  @override
  Future<void> replaceCustomers(
    List<Map<String, Object?>> customers,
    String storeId,
  ) async {
    await super.replaceCustomers(customers, storeId);
    await _enqueue(
      kind: 'replace',
      resource: 'customers',
      payload: customers,
    );
  }

  @override
  Future<void> upsertCustomer(
    Map<String, Object?> customer,
    String storeId,
  ) async {
    await super.upsertCustomer(customer, storeId);
    await _enqueue(
      kind: 'put',
      resource: 'customers',
      recordId: '${customer['id']}',
      payload: {...customer, 'store_id': storeId},
    );
  }

  @override
  Future<void> deleteCustomerRecord(String customerId, String storeId) async {
    await super.deleteCustomerRecord(customerId, storeId);
    await _enqueue(
      kind: 'delete',
      resource: 'customers',
      recordId: customerId,
    );
  }

  @override
  Future<void> insertDebitEntry(
    Map<String, Object?> entry,
    String storeId,
  ) async {
    await super.insertDebitEntry(entry, storeId);
    await _enqueue(
      kind: 'put',
      resource: 'debit-entries',
      recordId: '${entry['id']}',
      payload: {...entry, 'store_id': storeId},
    );
  }

  @override
  Future<void> replaceDebitEntries(
    List<Map<String, Object?>> entries,
    String storeId,
  ) async {
    await super.replaceDebitEntries(entries, storeId);
    await _enqueue(
      kind: 'replace',
      resource: 'debit-entries',
      payload: entries,
    );
  }

  @override
  Future<void> deleteDebitEntryRecord(String entryId, String storeId) async {
    await super.deleteDebitEntryRecord(entryId, storeId);
    await _enqueue(
      kind: 'delete',
      resource: 'debit-entries',
      recordId: entryId,
    );
  }

  @override
  Future<int> insertRegisterShift(
    Map<String, Object?> shift,
    String storeId,
  ) async {
    final id = await super.insertRegisterShift(shift, storeId);
    await _enqueue(
      kind: 'put',
      resource: 'register-shifts',
      recordId: '$id',
      payload: {...shift, 'id': id, 'store_id': storeId},
    );
    return id;
  }

  @override
  Future<void> updateRegisterShift(int id, Map<String, Object?> shift) async {
    await super.updateRegisterShift(id, shift);
    final rows = await super.loadRegisterShifts(storeId);
    final updated = rows.firstWhere(
      (row) => row['id'] == id,
      orElse: () => <String, Object?>{...shift, 'id': id, 'store_id': storeId},
    );
    await _enqueue(
      kind: 'put',
      resource: 'register-shifts',
      recordId: '$id',
      payload: updated,
    );
  }

  @override
  Future<void> insertCashMovement(
    Map<String, Object?> movement,
    String storeId,
  ) async {
    final db = await database;
    final id = await db.insert('cash_movements', {...movement, 'store_id': storeId});
    await _enqueue(
      kind: 'put',
      resource: 'cash-movements',
      recordId: '$id',
      payload: {...movement, 'id': id, 'store_id': storeId},
    );
  }

  @override
  Future<void> deleteCashMovement(int id) async {
    await super.deleteCashMovement(id);
    await _enqueue(
      kind: 'delete',
      resource: 'cash-movements',
      recordId: '$id',
    );
  }

  @override
  Future<int> insertSupplier(
    Map<String, Object?> supplier,
    String storeId,
  ) async {
    final id = await super.insertSupplier(supplier, storeId);
    await _enqueue(
      kind: 'put',
      resource: 'suppliers',
      recordId: '$id',
      payload: {...supplier, 'id': id, 'store_id': storeId},
    );
    return id;
  }

  @override
  Future<void> updateSupplier(int id, Map<String, Object?> supplier) async {
    await super.updateSupplier(id, supplier);
    await _enqueue(
      kind: 'put',
      resource: 'suppliers',
      recordId: '$id',
      payload: {...supplier, 'id': id, 'store_id': storeId},
    );
  }

  @override
  Future<void> deleteSupplier(int id) async {
    await super.deleteSupplier(id);
    await _enqueue(
      kind: 'delete',
      resource: 'suppliers',
      recordId: '$id',
    );
  }

  @override
  Future<int> insertReceiving(
    Map<String, Object?> receiving,
    String storeId,
  ) async {
    final id = await super.insertReceiving(receiving, storeId);
    await _enqueue(
      kind: 'put',
      resource: 'receivings',
      recordId: '$id',
      payload: {...receiving, 'id': id, 'store_id': storeId},
    );
    return id;
  }

  @override
  Future<void> deleteReceiving(int id) async {
    await super.deleteReceiving(id);
    await _enqueue(
      kind: 'delete',
      resource: 'receivings',
      recordId: '$id',
    );
  }

  @override
  Future<void> insertExpense(
    Map<String, Object?> expense,
    String storeId,
  ) async {
    final row = Map<String, Object?>.from(expense);
    row['id'] ??= DateTime.now().millisecondsSinceEpoch;
    final db = await database;
    await db.insert(
      'expenses',
      {...row, 'store_id': storeId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _enqueue(
      kind: 'put',
      resource: 'expenses',
      recordId: '${row['id']}',
      payload: row,
    );
  }

  @override
  Future<void> updateExpense(int id, Map<String, Object?> expense) async {
    final row = Map<String, Object?>.from(expense)..['id'] = id;
    final db = await database;
    await db.update(
      'expenses',
      row,
      where: 'id = ?',
      whereArgs: <Object?>[id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _enqueue(
      kind: 'put',
      resource: 'expenses',
      recordId: '$id',
      payload: row,
    );
  }

  @override
  Future<void> deleteExpense(int id) async {
    await super.deleteExpense(id);
    await _enqueue(
      kind: 'delete',
      resource: 'expenses',
      recordId: '$id',
    );
  }

  @override
  Future<void> saveAppProfile(Map<String, Object?> profile) async {
    await super.saveAppProfile(profile);
    await _enqueue(
      kind: 'put',
      resource: 'profile',
      recordId: '1',
      payload: profile,
    );
  }

  @override
  Future<void> saveReceiptSettings(ReceiptSettings settings) async {
    await super.saveReceiptSettings(settings);
    await _enqueue(
      kind: 'put',
      resource: 'receipt-settings',
      recordId: '1',
      payload: {
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
    );
  }

  @override
  Future<void> saveTaxSettings(TaxSettings settings) async {
    await super.saveTaxSettings(settings);
    await _enqueue(
      kind: 'put',
      resource: 'tax-settings',
      recordId: '1',
      payload: {
        'enabled': settings.enabled ? 1 : 0,
        'rate_percent': settings.ratePercent,
        'prices_include_tax': settings.pricesIncludeTax ? 1 : 0,
        'tax_id': settings.taxId,
        'tax_label': settings.taxLabel,
        'track_expense_tax': settings.trackExpenseTax ? 1 : 0,
      },
    );
  }

  Future<void> saveLanguagePreference(String languageCode) async {
    await _enqueue(
      kind: 'put',
      resource: 'preferences',
      recordId: '1',
      payload: {'languageCode': languageCode},
    );
  }

  Map<String, Object?> _orderToMap(CompletedOrder order) => {
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
        'customer_name': order.customerName,
        'discount_amount': order.discountAmount,
        'discount_label': order.discountLabel,
        'lines': [
          for (final line in order.lines)
            {
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
        ],
      };
}
