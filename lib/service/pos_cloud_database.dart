import 'dart:convert';

import 'php_api_client.dart';
import 'pos_local_database.dart';
import 'pos_order_models.dart';
import 'receipt_settings.dart';
import '../ui/models/product_item.dart';
import '../ui/products/inventory_product_item.dart';

class PosCloudDatabase extends PosLocalDatabase {
  PosCloudDatabase(this.api);

  final PhpApiClient api;
  Map<String, Object?>? _pendingCheckout;
  String? _pendingFingerprint;
  CompletedOrder? savedCheckout;
  List<InventoryProductItem>? inventoryAfterCheckout;
  List<Map<String, Object?>>? customersAfterCheckout;

  Future<Map<String, Object?>> _images(Map<String, Object?> row) async {
    final result = Map<String, Object?>.from(row);
    for (final key in ['image_path', 'logo_path', 'avatar_path']) {
      if (result[key] is String) {
        result[key] = await api.uploadImage(result[key] as String);
      }
    }
    return result;
  }

  Future<List<Map<String, Object?>>> _imageRows(
      List<Map<String, Object?>> rows) async {
    final result = <Map<String, Object?>>[];
    for (final row in rows) {
      result.add(await _images(row));
    }
    return result;
  }

  Future<List<Map<String, Object?>>> _readAllowedRows(String resource) {
    if (resource == 'expenses' && api.can('View Reports')) {
      return api.rows(resource);
    }
    final permission = resource == 'staff' || resource == 'roles'
        ? 'Manage Staff'
        : (resource == 'expenses' ? 'Manage Payments' : 'View Reports');
    return api.can(permission) ? api.rows(resource) : Future.value([]);
  }

  @override
  Future<List<InventoryProductItem>> loadInventory(String storeId) async =>
      (await api.rows('products')).map(inventoryFromMap).toList();

  @override
  Future<void> replaceInventory(
          List<InventoryProductItem> items, String storeId) async =>
      api.replace(
          'products',
          await _imageRows(
              items.map((item) => inventoryToMap(item, storeId)).toList()));

  @override
  Future<List<ProductItem>> loadCart(String storeId) async =>
      (await api.rows('cart')).map(productFromMap).toList();

  @override
  Future<void> replaceCart(List<ProductItem> items, String storeId) =>
      api.replace(
          'cart', items.map((item) => productToMap(item, storeId)).toList());

  @override
  Future<void> clearCart() => api.replace('cart', []);

  @override
  Future<ReceiptSettings> loadReceiptSettings() async {
    final rows = await api.rows('receipt-settings');
    if (rows.isEmpty) return const ReceiptSettings();
    return ReceiptSettings(
      showStoreContact: rows.first['show_store_contact'] != 0,
      footer: rows.first['footer'] as String? ?? '',
    );
  }

  @override
  Future<void> saveReceiptSettings(ReceiptSettings settings) =>
      api.put('receipt-settings', '1', {
        'show_store_contact': settings.showStoreContact ? 1 : 0,
        'footer': settings.footer,
      });

  @override
  Future<Map<String, Object?>?> loadAppProfile() async {
    final rows = await api.rows('profile');
    return rows.isEmpty ? null : rows.first;
  }

  @override
  Future<void> saveAppProfile(Map<String, Object?> profile) async =>
      api.put('profile', '1', await _images(profile));

  @override
  Future<List<Map<String, Object?>>> loadStaffRoles(String storeId) =>
      _readAllowedRows('roles');

  @override
  Future<void> replaceStaffRoles(
          List<Map<String, Object?>> roles, String storeId) =>
      api.replace('roles', roles);

  @override
  Future<List<Map<String, Object?>>> loadStaffMembers(String storeId) =>
      _readAllowedRows('staff');

  @override
  Future<void> replaceStaffMembers(
          List<Map<String, Object?>> members, String storeId) async =>
      api.replace('staff', await _imageRows(members));

  @override
  Future<void> saveStaffMember(Map<String, Object?> member) =>
      api.put('staff', member['id'] as String, member);

  @override
  Future<void> deleteStaffMember(String id) => api.delete('staff', id);

  @override
  Future<void> saveStaffRecord(
      Map<String, Object?> staff, String? password) async {
    final row = await _images(staff);
    final id = Uri.encodeComponent(staff['id'] as String);
    if (password != null && password.isNotEmpty) {
      await api.request('POST', 'staff/$id/account',
          body: {'staff': row, 'password': password});
    } else {
      await api.put('staff', staff['id'] as String, row);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadCustomers(String storeId) async =>
      (await api.rows('customers'))
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

  @override
  Future<void> replaceCustomers(
          List<Map<String, Object?>> customers, String storeId) =>
      api.replace('customers', customers);

  @override
  Future<List<Map<String, Object?>>> loadExpenses(String storeId) =>
      _readAllowedRows('expenses');

  @override
  Future<void> insertExpense(
      Map<String, Object?> expense, String storeId) async {
    await api.request('POST', 'expenses', body: expense);
  }

  @override
  Future<void> updateExpense(int id, Map<String, Object?> expense) async {
    await api.request('PUT', 'expenses/$id', body: expense);
  }

  @override
  Future<void> deleteExpense(int id) => api.delete('expenses', '$id');

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

  @override
  Future<List<CompletedOrder>> loadOrders(String storeId) async {
    if (!api.can('View Sales') && !api.can('View Reports')) return [];
    final rows = await api.rows('orders');
    if (_pendingCheckout != null &&
        rows.any((row) => row['id'] == _pendingCheckout!['id'])) {
      _pendingCheckout = null;
      _pendingFingerprint = null;
    }
    return rows.map(_orderFromMap).toList();
  }

  CompletedOrder _orderFromMap(Map<String, Object?> row) => CompletedOrder(
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
        lines: (row['lines'] as List)
            .map((line) =>
                orderLineFromMap(Map<String, Object?>.from(line as Map)))
            .toList(),
      );

  @override
  Future<void> saveCheckout({
    required CompletedOrder order,
    required String storeId,
    required List<InventoryProductItem> stockUpdates,
    Map<String, Object?>? creditCustomer,
  }) async {
    final body = _orderToMap(order);
    final fingerprint = Map<String, Object?>.from(body)
      ..remove('id')
      ..remove('date_time')
      ..remove('date_label')
      ..remove('time_label');
    final signature = jsonEncode(fingerprint);
    if (_pendingCheckout != null && signature != _pendingFingerprint) {
      throw const ApiException(
          'Retry the previous sale to confirm its result before starting another.',
          409);
    }
    if (_pendingCheckout == null || signature != _pendingFingerprint) {
      _pendingCheckout = body;
      _pendingFingerprint = signature;
    }
    Map<String, dynamic> result;
    try {
      result = await api.request('POST', 'checkout', body: _pendingCheckout);
    } on ApiException catch (error) {
      if (error.status >= 400 && error.status < 500) {
        _pendingCheckout = null;
        _pendingFingerprint = null;
      }
      rethrow;
    }
    savedCheckout =
        _orderFromMap(Map<String, Object?>.from(result['data'] as Map));
    inventoryAfterCheckout = (result['products'] as List)
        .map((row) => inventoryFromMap(Map<String, Object?>.from(row as Map)))
        .toList();
    customersAfterCheckout = (result['customers'] as List)
        .map((row) => Map<String, Object?>.from(row as Map))
        .toList();
    _pendingCheckout = null;
    _pendingFingerprint = null;
  }

  @override
  Future<void> deleteOrder(String orderId) async {
    await api.request('POST', 'orders/${Uri.encodeComponent(orderId)}/void');
  }
}
