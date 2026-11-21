import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:track_mauzo/service/pos_local_database.dart';
import 'package:track_mauzo/service/pos_order_models.dart';
import 'package:track_mauzo/ui/models/product_item.dart';
import 'package:track_mauzo/ui/products/inventory_product_item.dart';

import 'support/test_hybrid_database.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late FakePhpApiClient api;
  late TestHybridDatabase database;

  const storeId = 'store-1';

  setUp(() {
    api = FakePhpApiClient()
      ..restoreSession(
        token: 'test-token',
        user: <String, dynamic>{'role': 'owner'},
      );
    database = TestHybridDatabase(api)..storeId = storeId;
  });

  tearDown(() async {
    database.stopAutoSync();
    database.dispose();
    await database.close();
  });

  InventoryProductItem product({
    String code = 'P001',
    int stockCount = 10,
    String? imagePath,
  }) {
    return InventoryProductItem(
      code: code,
      name: 'Water',
      category: 'Drinks',
      purchasePrice: 10,
      sellingPrice: 20,
      stockCount: stockCount,
      stockState: InventoryStockState.inStock,
      artType: ProductArtType.aquafina,
      imagePath: imagePath,
    );
  }

  CompletedOrder order({String id = 'ORD-1', int quantity = 1}) {
    return CompletedOrder(
      id: id,
      dateTime: '2026-01-01T10:00:00',
      date: '2026-01-01',
      time: '10:00',
      total: 20.0 * quantity,
      status: 'Completed',
      cashierName: 'Cashier',
      register: 'Till 1',
      paymentMethod: 'Cash',
      cashTendered: 20.0 * quantity,
      changeDue: 0,
      lines: [
        OrderLine(
          itemCode: 'P001',
          itemCategory: 'Drinks',
          itemName: 'Water',
          itemSize: '1 pc',
          quantity: quantity,
          unitPrice: '20',
          unitPriceValue: 20,
          unitCost: 10,
          artType: ProductArtType.aquafina,
          imagePath: null,
        ),
      ],
    );
  }

  Future<void> enqueueInventory() async {
    await database.replaceInventory([product()], storeId);
    database.stopAutoSync();
  }

  Future<void> enqueueCheckout() async {
    await database.replaceInventory([product()], storeId);
    database.stopAutoSync();
    await database.clearOutbox();
    await database.saveCheckout(
      order: order(),
      storeId: storeId,
      stockUpdates: [product(stockCount: 9)],
    );
    database.stopAutoSync();
  }

  test('starts with empty outbox counters', () async {
    expect(await database.pendingCount(), 0);
    expect(await database.failedCount(), 0);
  });

  test('local writes are queued and pushed by syncNow', () async {
    await enqueueInventory();

    expect(await database.pendingCount(), 1);
    expect(await database.failedCount(), 0);
    expect(api.replaces, isEmpty);

    await database.syncNow();

    expect(await database.pendingCount(), 0);
    expect(await database.failedCount(), 0);
    expect(api.replaces, hasLength(1));
    expect(api.replaces.single.resource, 'products');
    expect(api.replaces.single.items.single['code'], 'P001');
  });

  test('a 422 response marks an event as failed', () async {
    await enqueueInventory();
    api
      ..replaceFailures = 1
      ..replaceFailStatus = 422;

    await database.syncNow();

    expect(await database.pendingCount(), 0);
    expect(await database.failedCount(), 1);

    await database.retryFailed();
    database.stopAutoSync();

    expect(await database.pendingCount(), 1);
    expect(await database.failedCount(), 0);

    await database.syncNow();

    expect(await database.pendingCount(), 0);
    expect(await database.failedCount(), 0);
    expect(api.replaces, hasLength(2));
  });

  test('server errors keep the event pending for a later retry', () async {
    await enqueueInventory();
    api
      ..replaceFailures = 1
      ..replaceFailStatus = 500;

    await database.syncNow();

    expect(await database.pendingCount(), 1);
    expect(await database.failedCount(), 0);
  });

  test('an expired session keeps the event pending', () async {
    await enqueueInventory();
    api
      ..replaceFailures = 1
      ..replaceFailStatus = 401;

    await database.syncNow();

    expect(await database.pendingCount(), 1);
    expect(await database.failedCount(), 0);
  });

  test('a 409 replace conflict recovers by reading the remote rows', () async {
    await enqueueInventory();
    api
      ..replaceFailures = 1
      ..replaceFailStatus = 409
      ..rowsByResource = {
        'products': [],
      };

    await database.syncNow();

    expect(await database.pendingCount(), 0);
    expect(await database.failedCount(), 0);
    expect(api.rowRequests, contains('products'));
    expect(api.replaces, hasLength(2));
  });

  test('checkout events send the order and clear the cart', () async {
    await enqueueCheckout();

    expect(await database.pendingCount(), 1);

    await database.syncNow();

    expect(await database.pendingCount(), 0);
    final request = api.requests.single;
    expect(request.method, 'POST');
    expect(request.path, 'checkout');
    expect(request.body?['id'], 'ORD-1');
    expect(request.body?['lines'], isA<List<dynamic>>());
    expect(await database.loadOrders(storeId), hasLength(1));
  });

  test('void events target the order endpoint', () async {
    await enqueueCheckout();
    await database.syncNow();

    await database.deleteOrder('ORD-1');
    database.stopAutoSync();
    expect(await database.pendingCount(), 1);

    await database.syncNow();

    expect(await database.pendingCount(), 0);
    expect(
      api.requests.map((request) => '${request.method} ${request.path}'),
      contains('POST orders/ORD-1/void'),
    );
  });

  test('staff account changes send their password once', () async {
    await database.saveStaffRecord(
      <String, Object?>{
        'id': 'u1',
        'name': 'Jane',
        'email': 'jane@example.test',
        'phone': '0700000000',
        'role_id': 'cashier',
        'created_at': '2026-01-01',
      },
      'secret123',
    );
    database.stopAutoSync();

    await database.syncNow();

    expect(await database.pendingCount(), 0);
    final request = api.requests.single;
    expect(request.method, 'POST');
    expect(request.path, 'staff/u1/account');
    expect((request.body?['password']), 'secret123');
  });

  test('hydrate retries failures, pushes and then pulls', () async {
    await enqueueInventory();
    api
      ..replaceFailures = 1
      ..replaceFailStatus = 422
      ..rowsByResource = {
        'products': [
          {
            'code': 'P900',
            'store_id': storeId,
            'name': 'Remote',
            'category': 'General',
            'purchase_price': 5,
            'selling_price': 8,
            'stock_count': 3,
            'stock_state': 'inStock',
            'art_type': 'aquafina',
            'image_path': null,
            'category_data_json': '{}',
          },
        ],
      };

    await database.syncNow();
    expect(await database.failedCount(), 1);

    await database.hydrate();
    database.stopAutoSync();

    expect(await database.pendingCount(), 0);
    expect(await database.failedCount(), 0);
    expect(api.replaces.length, greaterThanOrEqualTo(2));
    expect(api.rowRequests, contains('products'));
    final local = await database.loadInventory(storeId);
    expect(local.map((item) => item.code), ['P900']);
  });

  test('syncNow with pull hydrates local data and notifies listeners', () async {
    api.rowsByResource = {
      'products': [
        {
          'code': 'P900',
          'store_id': storeId,
          'name': 'Remote',
          'category': 'General',
          'purchase_price': 5,
          'selling_price': 8,
          'stock_count': 3,
          'stock_state': 'inStock',
          'art_type': 'aquafina',
          'image_path': null,
          'category_data_json': '{}',
        },
      ],
      'customers': [],
      'orders': [],
      'roles': [],
      'staff': [],
      'expenses': [],
      'profile': [],
      'receipt-settings': [],
    };

    var synced = false;
    database.onSynced = () => synced = true;

    await database.syncNow(pull: true);

    expect(synced, isTrue);
    expect(api.rowRequests, containsAll(['products', 'customers', 'profile']));
    final local = await database.loadInventory(storeId);
    expect(local.single.code, 'P900');
    expect(local.single.name, 'Remote');
  });

  test('clearOutbox drops queued work for a different account', () async {
    await enqueueInventory();
    await database.replaceCart(const [], storeId);
    database.stopAutoSync();
    expect(await database.pendingCount(), 2);

    await database.clearOutbox();

    expect(await database.pendingCount(), 0);
    expect(await database.failedCount(), 0);
  });

  test('uploading image fields happens before replace', () async {
    await database.replaceInventory(
      [product(imagePath: 'C:/images/water.png')],
      storeId,
    );
    database.stopAutoSync();

    await database.syncNow();

    expect(api.uploadedImages, ['C:/images/water.png']);
    expect(
      api.replaces.single.items.single['image_path'],
      'http://test.local/uploads/C:/images/water.png',
    );
  });

  test('inventory payloads use the shared map helper', () {
    final row = database.inventoryToMap(product(), storeId);
    expect(row['store_id'], storeId);
    expect(row['stock_state'], 'inStock');
  });
}
