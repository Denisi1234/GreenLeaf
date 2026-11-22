import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aza_pos/service/barcode_scan_service.dart';
import 'package:aza_pos/service/esc_pos_receipt_builder.dart';
import 'package:aza_pos/service/pos_local_store.dart';
import 'package:aza_pos/service/pos_order_models.dart';
import 'package:aza_pos/service/receipt_settings.dart';
import 'package:aza_pos/service/secure_token_storage.dart';
import 'package:aza_pos/service/store_preferences.dart';
import 'package:aza_pos/service/tax_settings.dart';
import 'package:aza_pos/service/thermal_printer_service.dart';
import 'package:aza_pos/ui/models/customer_data.dart';
import 'package:aza_pos/ui/models/product_item.dart';
import 'package:aza_pos/ui/more/advanced_features_page.dart';
import 'package:aza_pos/ui/more/more_page.dart';
import 'package:aza_pos/ui/products/inventory_product_item.dart';
import 'package:aza_pos/ui/products/product_management_page.dart';
import 'package:aza_pos/ui/receipt/receipt_document.dart';
import 'package:aza_pos/ui/reports/dashboard_page.dart';
import 'package:aza_pos/ui/shell/app_shell.dart';
import 'package:aza_pos/ui/widgets/app_theme.dart';
import 'package:aza_pos/ui/widgets/common/market_notice.dart';
import 'package:aza_pos/ui/widgets/market_bottom_nav.dart';

import 'support/memory_pos_database.dart';
import 'support/test_hybrid_database.dart';
import 'support/ui_test_fonts.dart';

bool _containsBytes(List<int> haystack, List<int> needle) {
  if (needle.isEmpty || haystack.length < needle.length) return false;
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var matched = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        matched = false;
        break;
      }
    }
    if (matched) return true;
  }
  return false;
}

InventoryProductItem _sampleInventory({
  String code = 'P001',
  String name = 'Mineral Water',
  double stockCount = 10,
  Map<String, Object?> categoryData = const <String, Object?>{},
}) {
  return InventoryProductItem(
    code: code,
    name: name,
    category: 'Drinks',
    purchasePrice: 500,
    sellingPrice: 1000,
    stockCount: stockCount,
    stockState: stockCount <= 0
        ? InventoryStockState.outOfStock
        : stockCount <= 20
            ? InventoryStockState.lowStock
            : InventoryStockState.inStock,
    artType: ProductArtType.aquafina,
    categoryData: categoryData,
  );
}

ReceiptDocument _sampleReceipt({
  String storeName = 'GreenLeaf — Arusha • HQ’',
  String itemName = 'Maji — Baridi • 500ml',
}) {
  return ReceiptDocument(
    order: CompletedOrder(
      id: 'ORD-1001',
      dateTime: '2026-11-20T10:15:00',
      date: '2026-11-20',
      time: '10:15',
      total: 2000,
      status: 'Completed',
      cashierName: 'Amina',
      register: 'Till 1',
      paymentMethod: 'Cash',
      cashTendered: 5000,
      changeDue: 3000,
      lines: [
        OrderLine(
          itemCode: 'P001',
          itemCategory: 'Drinks',
          itemName: itemName,
          itemSize: '500 ml',
          quantity: 2,
          unitPrice: '1000',
          unitPriceValue: 1000,
          unitCost: 500,
          artType: ProductArtType.aquafina,
          imagePath: null,
        ),
      ],
    ),
    storeName: storeName,
    storeAddress: 'Clock Tower Road',
    storePhone: '+255700111222',
    storeTaxId: '123-456-789',
    settings: const ReceiptSettings(
      header: 'Welcome • Karibu',
      footer: 'Asante — Come again!',
    ),
  );
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('en');
    await configureUiTestFonts();
  });

  tearDown(() {
    SecureTokenStorage.resetForTests();
    ThermalPrinterService.resetForTests();
    BarcodeScanService.resetForTests();
  });

  group('Keystore bearer token storage', () {
    late MemoryPosLocalDatabase database;

    setUp(() {
      database = MemoryPosLocalDatabase();
    });

    tearDown(() async {
      await database.close();
    });

    test('writes sentinel to SQLite and real bearer token to SecureTokenStorage',
        () async {
      final vault = <String, String>{};
      SecureTokenStorage.useMemoryStoreForTests(vault);

      await database.saveSyncSession(
        endpoint: 'https://pos.example.test/api',
        token: 'secret-bearer-xyz',
        user: const <String, Object?>{'id': 'u1', 'name': 'Owner'},
      );

      final db = await database.database;
      final rawRows = await db.query('sync_session');
      expect(rawRows, hasLength(1));
      expect(rawRows.single['token'], '__keystore_protected__');
      expect(vault['sync_bearer_token'], 'secret-bearer-xyz');

      final loaded = await database.loadSyncSession();
      expect(loaded, isNotNull);
      expect(loaded!['token'], 'secret-bearer-xyz');
      expect(loaded['endpoint'], 'https://pos.example.test/api');
    });

    test('migrates legacy plaintext SQLite token into SecureTokenStorage',
        () async {
      final vault = <String, String>{};
      SecureTokenStorage.useMemoryStoreForTests(vault);

      await database.saveSyncSession(
        endpoint: 'https://pos.example.test/api',
        token: '',
        user: const <String, Object?>{'id': 'u1'},
      );
      final db = await database.database;
      await db.update(
        'sync_session',
        <String, Object?>{'token': 'legacy-plain-token'},
        where: 'id = ?',
        whereArgs: const <Object?>[1],
      );

      final loaded = await database.loadSyncSession();
      expect(loaded?['token'], 'legacy-plain-token');
      expect(vault['sync_bearer_token'], 'legacy-plain-token');

      final migratedRows = await db.query('sync_session');
      expect(migratedRows.single['token'], '__keystore_protected__');
    });

    test('clearSyncSession removes both SQLite row and vault secret', () async {
      final vault = <String, String>{};
      SecureTokenStorage.useMemoryStoreForTests(vault);

      await database.saveSyncSession(
        endpoint: 'https://pos.example.test/api',
        token: 'secret-to-clear',
        user: const <String, Object?>{'id': 'u1'},
      );
      await database.clearSyncSession();

      final db = await database.database;
      expect(await db.query('sync_session'), isEmpty);
      expect(vault, isEmpty);
      expect(await database.loadSyncSession(), isNull);
    });
  });

  group('Bluetooth ESC-POS thermal printing', () {
    test('builds 58mm and 80mm ESC/POS receipts with ASCII sanitization & drawer pulse',
        () {
      final receipt = _sampleReceipt();

      final bytes58 = EscPosReceiptBuilder.buildReceipt(
        receipt,
        paperWidth: ThermalPaperWidth.mm58,
        openCashDrawer: false,
      );
      expect(bytes58.sublist(0, 2), <int>[0x1B, 0x40]);
      final text58 = ascii.decode(bytes58, allowInvalid: true);
      expect(text58, contains('-' * 32));
      expect(text58, isNot(contains('-' * 48)));
      expect(text58, contains("GreenLeaf - Arusha * HQ'"));
      expect(text58, contains('Maji - Baridi * 500ml'));
      expect(_containsBytes(bytes58, const [0x1B, 0x70, 0x00, 0x19, 0xFA]),
          isFalse);

      final bytes80 = EscPosReceiptBuilder.buildReceipt(
        receipt,
        paperWidth: ThermalPaperWidth.mm80,
        openCashDrawer: true,
      );
      expect(bytes80.sublist(0, 2), <int>[0x1B, 0x40]);
      final text80 = ascii.decode(bytes80, allowInvalid: true);
      expect(text80, contains('-' * 48));
      expect(_containsBytes(bytes80, const [0x1B, 0x70, 0x00, 0x19, 0xFA]),
          isTrue);
    });

    test('buildTestTicket produces valid bytes for both widths', () {
      final ticket58 = EscPosReceiptBuilder.buildTestTicket(
        storeName: 'GreenLeaf Duka',
        paperWidth: ThermalPaperWidth.mm58,
      );
      final ticket80 = EscPosReceiptBuilder.buildTestTicket(
        storeName: '',
        paperWidth: ThermalPaperWidth.mm80,
      );

      expect(ticket58.sublist(0, 2), <int>[0x1B, 0x40]);
      expect(ascii.decode(ticket58, allowInvalid: true), contains('32 chars'));
      expect(ticket80.sublist(0, 2), <int>[0x1B, 0x40]);
      expect(ascii.decode(ticket80, allowInvalid: true), contains('48 chars'));
    });

    test('ThermalPrinterService lists paired printers and prints receipt bytes',
        () async {
      String? sentAddress;
      Uint8List? sentBytes;

      ThermalPrinterService.setTestOverrides(
        listPrinters: () async => const [
          BluetoothPrinterDevice(name: 'RPP02N', address: 'AA:BB:CC:DD:EE:01'),
        ],
        printBytes: (address, bytes) async {
          sentAddress = address;
          sentBytes = bytes;
        },
      );

      final printers = await ThermalPrinterService.instance.listPairedPrinters();
      expect(printers, hasLength(1));
      expect(printers.single.name, 'RPP02N');

      await ThermalPrinterService.instance.printReceipt(
        receipt: _sampleReceipt(),
        address: printers.single.address,
        paperWidth: ThermalPaperWidth.mm80,
        openCashDrawer: true,
      );

      expect(sentAddress, 'AA:BB:CC:DD:EE:01');
      expect(sentBytes, isNotNull);
      expect(sentBytes!.sublist(0, 2), <int>[0x1B, 0x40]);
      expect(
        _containsBytes(sentBytes!, const [0x1B, 0x70, 0x00, 0x19, 0xFA]),
        isTrue,
      );
    });

    test('StorePreferences round-trips thermal printer fields via copyWith/json',
        () {
      const base = StorePreferences();
      final updated = base.copyWith(
        thermalPrinterName: 'Xprinter 58',
        thermalPrinterAddress: '00:11:22:33:44:55',
        thermalPaperWidthMm: 80,
        openCashDrawerOnPrint: true,
      );

      final restored = StorePreferences.fromJson(updated.toJson());
      expect(restored.thermalPrinterName, 'Xprinter 58');
      expect(restored.thermalPrinterAddress, '00:11:22:33:44:55');
      expect(restored.thermalPaperWidthMm, 80);
      expect(restored.openCashDrawerOnPrint, isTrue);
    });
  });

  group('Barcode scanning & lookup', () {
    late MemoryPosLocalDatabase database;
    late PosLocalStore store;

    setUp(() {
      database = MemoryPosLocalDatabase();
      store = PosLocalStore(database: database);
    });

    tearDown(() async {
      store.dispose();
      await database.close();
    });

    test('findProductByBarcode matches SKU code & metadata barcode and enforces stock',
        () async {
      await store.addProduct(_sampleInventory(
        code: 'SKU-WATER',
        name: 'Kilimanjaro Water',
        stockCount: 1,
      ));
      await store.addProduct(_sampleInventory(
        code: 'P002',
        name: 'Azam Soda',
        stockCount: 4,
        categoryData: const <String, Object?>{'barcode': '6221000012345'},
      ));

      final bySku = store.findProductByBarcode('  sku-water ');
      expect(bySku, isNotNull);
      expect(bySku!.code, 'SKU-WATER');

      final byBarcode = store.findProductByBarcode('6221000012345');
      expect(byBarcode, isNotNull);
      expect(byBarcode!.code, 'P002');

      expect(store.findProductByBarcode(''), isNull);
      expect(store.findProductByBarcode('   '), isNull);
      expect(store.findProductByBarcode('999999'), isNull);

      expect(store.addToCart(bySku), isTrue);
      expect(store.addToCart(bySku), isFalse);
      expect(store.cartCount, 1);
    });

    testWidgets('BarcodeScanService trims scanned barcode and ignores blank input',
        (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      BarcodeScanService.setTestOverride(() async => '  6221000012345 \n');
      expect(
        await BarcodeScanService.instance.scan(capturedContext),
        '6221000012345',
      );

      BarcodeScanService.setTestOverride(() async => '   ');
      expect(await BarcodeScanService.instance.scan(capturedContext), isNull);
    });
  });

  group('Per-record & stock-delta sync', () {
    late FakePhpApiClient api;
    late TestHybridDatabase hybridDb;
    late PosLocalStore store;

    setUp(() {
      api = FakePhpApiClient()
        ..restoreSession(
          token: 'test-token',
          user: const <String, dynamic>{'role': 'owner'},
        );
      hybridDb = TestHybridDatabase(api)..storeId = 'store-default';
      store = PosLocalStore(database: hybridDb);
    });

    tearDown(() async {
      hybridDb.stopAutoSync();
      store.dispose();
      hybridDb.dispose();
      await hybridDb.close();
    });

    test('product and customer mutations enqueue PUT/DELETE without full-table replace',
        () async {
      await store.addProduct(_sampleInventory(code: 'P010', stockCount: 10));
      hybridDb.stopAutoSync();
      await hybridDb.syncNow();
      expect(api.replaces, isEmpty);
      expect(api.requests.map((r) => '$r'), contains('PUT products/P010'));

      api.requests.clear();
      await store.updateProduct(
        _sampleInventory(code: 'P010', name: 'Updated Water', stockCount: 10),
      );
      hybridDb.stopAutoSync();
      await hybridDb.syncNow();
      expect(api.replaces, isEmpty);
      expect(api.requests.map((r) => '$r'), contains('PUT products/P010'));

      final customer = CustomerData(
        id: 'CUST-1',
        name: 'Juma',
        phone: '0712000111',
        debitBalance: 500,
      );
      api.requests.clear();
      await store.addCustomer(customer);
      hybridDb.stopAutoSync();
      await hybridDb.syncNow();
      expect(api.replaces, isEmpty);
      expect(api.requests.map((r) => '$r'), contains('PUT customers/CUST-1'));

      api.requests.clear();
      await store.updateCustomer(customer.copyWith(phone: '0712999888'));
      hybridDb.stopAutoSync();
      await hybridDb.syncNow();
      expect(api.replaces, isEmpty);
      expect(api.requests.map((r) => '$r'), contains('PUT customers/CUST-1'));

      api.requests.clear();
      await store.recordDebtPayment(customerId: 'CUST-1', amount: 100);
      hybridDb.stopAutoSync();
      await hybridDb.syncNow();
      expect(api.replaces, isEmpty);
      expect(api.requests.map((r) => '$r'), contains('PUT customers/CUST-1'));

      await store.deleteCustomer('CUST-1');
      hybridDb.stopAutoSync();
      await hybridDb.syncNow();
      expect(api.deleted, contains('customers/CUST-1'));
      expect(
        api.replaces.where(
          (r) => r.resource == 'customers' || r.resource == 'products',
        ),
        isEmpty,
      );

      await store.removeProduct('P010');
      hybridDb.stopAutoSync();
      await hybridDb.syncNow();
      expect(
        api.replaces.where(
          (r) => r.resource == 'customers' || r.resource == 'products',
        ),
        isEmpty,
      );
      expect(api.deleted, contains('products/P010'));
    });

    test('applyInventoryAdjustments uses atomic stock-delta and falls back to PUT on 404',
        () async {
      await store.addProduct(_sampleInventory(code: 'P010', stockCount: 10));
      hybridDb.stopAutoSync();
      await hybridDb.clearOutbox();
      api.requests.clear();

      await store.applyInventoryAdjustments(const <String, int>{'P010': -3});
      hybridDb.stopAutoSync();
      await hybridDb.syncNow();

      expect(api.replaces, isEmpty);
      final deltaReq =
          api.requests.singleWhere((r) => r.path == 'products/stock-delta');
      expect(deltaReq.method, 'POST');
      expect(deltaReq.payload['deltas'], <String, int>{'P010': -3});

      // Fallback when server returns 404 for products/stock-delta
      api.requests.clear();
      api.requestFailures = 1;
      api.requestFailStatus = 404;
      api.rowsByResource['products'] = [
        <String, Object?>{
          'code': 'P010',
          'store_id': 'store-default',
          'name': 'Mineral Water',
          'category': 'Drinks',
          'purchase_price': 500,
          'selling_price': 1000,
          'stock_count': 25,
          'stock_state': 'inStock',
          'art_type': 'aquafina',
          'image_path': null,
          'category_data_json': '{}',
        },
      ];

      await store.applyInventoryAdjustments(const <String, int>{'P010': -3});
      hybridDb.stopAutoSync();
      await hybridDb.syncNow();

      final putReq = api.requests.singleWhere((r) => r.path == 'products/P010');
      expect(putReq.method, 'PUT');
      expect(putReq.payload['stock_count'], 22);
      expect(putReq.payload['stock_state'], 'inStock');
    });

    test('syncs full ReceiptSettings, TaxSettings, and per-record StaffRole PUT/DELETE',
        () async {
      await store.updateReceiptSettings(const ReceiptSettings(
        showStoreContact: false,
        showTaxId: false,
        showDiscount: false,
        header: 'Header 123',
        footer: 'Footer 456',
      ));
      await store.updateTaxSettings(const TaxSettings(
        enabled: true,
        ratePercent: 18,
        pricesIncludeTax: false,
        taxId: 'TIN-100',
        taxLabel: 'VAT',
        trackExpenseTax: true,
      ));
      await store.saveStaffRole(const StaffRoleData(
        id: 'role-supervisor',
        title: 'Supervisor',
        subtitle: 'Shift lead',
        permissions: <String>['View Sales', 'Discounts'],
        sortOrder: 3,
      ));
      hybridDb.stopAutoSync();
      await hybridDb.syncNow();

      expect(api.replaces, isEmpty);
      final receiptReq =
          api.requests.singleWhere((r) => r.path == 'receipt-settings/1');
      expect(receiptReq.payload['header'], 'Header 123');
      expect(receiptReq.payload['footer'], 'Footer 456');
      expect(receiptReq.payload['show_tax_id'], 0);
      expect(receiptReq.payload['show_discount'], 0);

      final taxReq =
          api.requests.singleWhere((r) => r.path == 'tax-settings/1');
      expect(taxReq.payload['enabled'], 1);
      expect(taxReq.payload['rate_percent'], 18.0);
      expect(taxReq.payload['tax_id'], 'TIN-100');

      final roleReq = api.requests
          .singleWhere((r) => r.path == 'roles/role-supervisor');
      expect(roleReq.method, 'PUT');

      await store.deleteStaffRole('role-supervisor');
      hybridDb.stopAutoSync();
      await hybridDb.syncNow();
      expect(api.deleted, contains('roles/role-supervisor'));
    });
  });

  group('Store & UI permission enforcement', () {
    late MemoryPosLocalDatabase database;
    late PosLocalStore store;

    setUp(() {
      database = MemoryPosLocalDatabase();
      store = PosLocalStore(database: database);
    });

    tearDown(() async {
      store.dispose();
      await database.close();
    });

    Future<({StaffMemberData owner, StaffMemberData cashier})> seedUsers() async {
      await store.saveStaffRole(const StaffRoleData(
        id: 'owner',
        title: 'Owner',
        subtitle: 'Full access',
        permissions: <String>[
          'View Sales',
          'View Reports',
          'Process Returns',
          'Discounts',
          'Manage Inventory',
          'Manage Staff',
          'Manage Payments',
          'System Settings',
        ],
        sortOrder: 0,
      ));
      await store.saveStaffRole(const StaffRoleData(
        id: 'cashier',
        title: 'Cashier',
        subtitle: 'Sales only',
        permissions: <String>['View Sales'],
        sortOrder: 1,
      ));
      final owner = await store.addStaffMember(
        name: 'Alice',
        email: 'alice@example.test',
        phone: '0700000001',
        roleId: 'owner',
        username: 'alice',
        password: 'password123',
      );
      final cashier = await store.addStaffMember(
        name: 'Bob',
        email: 'bob@example.test',
        phone: '0700000002',
        roleId: 'cashier',
        username: 'bob',
        password: 'password123',
      );
      return (owner: owner, cashier: cashier);
    }

    test('blocks inventory, settings, and staff mutations for cashier but permits language and unchanged self profile',
        () async {
      final product = _sampleInventory(code: 'P100', stockCount: 5);
      await store.addProduct(product);
      final users = await seedUsers();

      expect(await store.login('bob', 'password123'), isTrue);

      await expectLater(
        () => store.addProduct(_sampleInventory(code: 'P101')),
        throwsStateError,
      );
      await expectLater(() => store.updateProduct(product), throwsStateError);
      await expectLater(() => store.removeProduct('P100'), throwsStateError);
      await expectLater(
        () => store.applyInventoryAdjustments(const <String, int>{'P100': 2}),
        throwsStateError,
      );

      await expectLater(
        () => store.updateReceiptSettings(const ReceiptSettings()),
        throwsStateError,
      );
      await expectLater(
        () => store.updateTaxSettings(const TaxSettings()),
        throwsStateError,
      );
      await expectLater(
        () => store.setStorePreferences(const StorePreferences()),
        throwsStateError,
      );
      await expectLater(
        () => store.updateProfile(AppProfileData.empty()),
        throwsStateError,
      );

      await expectLater(
        () => store.saveStaffRole(const StaffRoleData(
          id: 'r2',
          title: 'X',
          subtitle: '',
          permissions: <String>[],
          sortOrder: 2,
        )),
        throwsStateError,
      );
      await expectLater(
        () => store.updateStaffRolePermissions('cashier', const ['Manage Staff']),
        throwsStateError,
      );
      await expectLater(() => store.deleteStaffRole('cashier'), throwsStateError);
      await expectLater(
        () => store.addStaffMember(
          name: 'Evil',
          email: 'evil@example.test',
          phone: '0700000099',
          roleId: 'owner',
          username: 'evil',
          password: 'password123',
        ),
        throwsStateError,
      );
      await expectLater(
        () => store.setStaffStatus(users.owner.id, StaffStatus.inactive),
        throwsStateError,
      );
      await expectLater(
        () => store.updateStaffMemberRole(users.cashier.id, 'owner'),
        throwsStateError,
      );
      await expectLater(
        () => store.deleteStaffMember(users.owner.id),
        throwsStateError,
      );
      await expectLater(
        () => store.saveStaffMember(users.cashier.copyWith(roleId: 'owner')),
        throwsStateError,
      );

      await store.setLanguageCode('en');
      expect(store.languageCode, 'en');

      final selfSaved = await store.saveStaffMember(
        users.cashier.copyWith(phone: '0711111111'),
      );
      expect(selfSaved.phone, '0711111111');
      expect(selfSaved.roleId, 'cashier');
    });

    testWidgets('MorePage hides restricted tools from cashier and shows them to owner',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await seedUsers();
      await tester.runAsync(() => store.setLanguageCode('en'));
      expect(await store.login('bob', 'password123'), isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<PosLocalStore>.value(
          value: store,
          child: MaterialApp(
            theme: buildOsposTheme(ThemeData.light().textTheme),
            home: const MorePage(useSharedShell: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('more-customers')), findsOneWidget);
      for (final hiddenId in [
        'more-debtors',
        'more-expenses',
        'more-reports',
        'more-advanced',
        'more-settings',
      ]) {
        expect(find.byKey(ValueKey(hiddenId)), findsNothing, reason: hiddenId);
      }

      expect(await store.login('alice', 'password123'), isTrue);
      await tester.pumpAndSettle();

      for (final visibleId in [
        'more-customers',
        'more-debtors',
        'more-expenses',
        'more-reports',
        'more-advanced',
        'more-settings',
      ]) {
        expect(find.byKey(ValueKey(visibleId)), findsOneWidget,
            reason: visibleId);
      }

      await tester.tap(find.byKey(const ValueKey('more-advanced')));
      await tester.pumpAndSettle();
      expect(find.byType(AdvancedFeaturesPage), findsOneWidget);
      expect(find.text('Suppliers'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Tax settings'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tax settings'), findsOneWidget);
    });

    testWidgets('ProductManagementPage hides Add item button for cashier',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await seedUsers();
      await tester.runAsync(() => store.setLanguageCode('en'));
      expect(await store.login('bob', 'password123'), isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<PosLocalStore>.value(
          value: store,
          child: MaterialApp(
            theme: buildOsposTheme(ThemeData.light().textTheme),
            home: const ProductManagementPage(useSharedShell: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add item'), findsNothing);
      expect(find.byTooltip('Import CSV'), findsNothing);
      expect(find.byTooltip('Export CSV'), findsOneWidget);
    });

    test('PBKDF2 password hashing and automatic legacy SHA-256 upgrade on login',
        () async {
      await store.saveStaffRole(const StaffRoleData(
        id: 'cashier',
        title: 'Cashier',
        subtitle: 'Sales',
        permissions: <String>['View Sales'],
        sortOrder: 1,
      ));
      final member = await store.addStaffMember(
        name: 'Neema',
        email: 'neema@example.test',
        phone: '0712345678',
        roleId: 'cashier',
        username: 'neema',
        password: 'MySecretPassword',
      );
      expect(member.passwordHash.startsWith('pbkdf2_sha256\$'), isTrue);

      // Simulate legacy SHA-256 hash stored on disk
      const legacySalt = 'legacy-salt-xyz';
      final legacyHash =
          sha256.convert(utf8.encode('$legacySalt:LegacyPass99')).toString();
      final legacyMember = member.copyWith(
        passwordHash: legacyHash,
        passwordSalt: legacySalt,
      );
      await store.saveStaffMember(legacyMember);
      expect(
        store.staffMembers
            .singleWhere((m) => m.id == member.id)
            .passwordHash
            .startsWith('pbkdf2_sha256\$'),
        isFalse,
      );

      expect(await store.login('neema', 'LegacyPass99'), isTrue);
      final upgraded =
          store.staffMembers.singleWhere((m) => m.id == member.id);
      expect(upgraded.passwordHash.startsWith('pbkdf2_sha256\$'), isTrue);
    });

    test('suspendedSales persist across SQLite store reload and requireOpenShiftForSales blocks checkout',
        () async {
      await store.addProduct(_sampleInventory(code: 'P500', stockCount: 10));
      final product = store.products.firstWhere((p) => p.code == 'P500');
      expect(store.addToCart(product), isTrue);

      final held = await store.suspendCurrentSale(customerName: 'Asha');
      expect(held, isNotNull);
      expect(store.cartCount, 0);
      expect(store.suspendedSales, hasLength(1));

      final storedRows = await database.loadSuspendedSales(store.activeStoreId);
      expect(storedRows, hasLength(1));
      expect(storedRows.single['id'], held!.id);

      await store.resumeSuspendedSale(held.id);
      expect(store.cartCount, 1);
      expect(await database.loadSuspendedSales(store.activeStoreId), isEmpty);

      // Test requireOpenShiftForSales guard
      await store.setStorePreferences(
        store.storePreferences.copyWith(requireOpenShiftForSales: true),
      );
      await expectLater(
        () => store.completeCashSale(
          items: [OrderLineItem(product: product, quantity: 1)],
          cashTendered: 2000,
          cashierName: 'Cashier',
          registerName: 'Register 1',
        ),
        throwsStateError,
      );

      await store.startShift(
        register: 'Register 1',
        openedBy: 'Cashier',
        openingFloat: 10000,
      );
      final order = await store.completeCashSale(
        items: [OrderLineItem(product: product, quantity: 1)],
        cashTendered: 2000,
        cashierName: 'Cashier',
        registerName: 'Register 1',
      );
      expect(order.status, 'Completed');
    });

    testWidgets('AppShell defaults to Sales tab, hides Settings gear for cashier, and standardizes showMarketNotice toast',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await seedUsers();
      await tester.runAsync(() => store.setLanguageCode('en'));
      expect(await store.login('bob', 'password123'), isTrue);

      late BuildContext capturedCtx;
      await tester.pumpWidget(
        ChangeNotifierProvider<PosLocalStore>.value(
          value: store,
          child: MaterialApp(
            theme: buildOsposTheme(ThemeData.light().textTheme),
            home: Builder(
              builder: (context) {
                capturedCtx = context;
                return const AppShell();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final shell = tester.widget<AppShell>(find.byType(AppShell));
      expect(shell.initialTab, MarketTab.sales);

      // Standardized app toast renders and auto-dismisses cleanly
      showMarketNotice(
        capturedCtx,
        title: 'Standard Toast',
        message: 'Unified feedback notice across the app',
        type: MarketNoticeType.success,
      );
      await tester.pump();
      expect(find.text('Standard Toast'), findsOneWidget);
      expect(
          find.text('Unified feedback notice across the app'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Standard Toast'), findsNothing);
    });

    testWidgets('DashboardPage shows cashier shift view when View Reports permission is absent',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await seedUsers();
      await tester.runAsync(() => store.setLanguageCode('en'));
      expect(await store.login('bob', 'password123'), isTrue);

      await tester.pumpWidget(
        ChangeNotifierProvider<PosLocalStore>.value(
          value: store,
          child: MaterialApp(
            theme: buildOsposTheme(ThemeData.light().textTheme),
            home: const DashboardPage(useSharedShell: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
