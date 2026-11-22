import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aza_pos/service/pos_local_store.dart';
import 'package:aza_pos/service/pos_order_models.dart';
import 'package:aza_pos/service/supplier_model.dart';
import 'package:aza_pos/ui/home/sales_page.dart';
import 'package:aza_pos/ui/home/widgets/measurement_sale_sheet.dart';
import 'package:aza_pos/ui/models/product_item.dart';
import 'package:aza_pos/ui/products/inventory_product_item.dart';
import 'package:aza_pos/ui/receipt/receipt_document.dart';
import 'package:aza_pos/ui/widgets/app_theme.dart';
import 'package:aza_pos/utils/quantity_formatter.dart';

import 'support/memory_pos_database.dart';
import 'support/ui_test_fonts.dart';

class _TestSalesStore extends PosLocalStore {
  _TestSalesStore({required super.database});

  @override
  bool get isInitialized => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    return configureUiTestFonts();
  });

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

  Future<InventoryProductItem> addSukari({
    double stockCount = 100,
    double purchasePrice = 2800,
    double sellingPrice = 3200,
  }) {
    return store.addProduct(
      InventoryProductItem(
        code: 'SUK01',
        name: 'Sukari',
        category: 'Groceries',
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        stockCount: stockCount,
        stockState: stockCount <= 0
            ? InventoryStockState.outOfStock
            : stockCount <= 20
                ? InventoryStockState.lowStock
                : InventoryStockState.inStock,
        artType: ProductArtType.aquafina,
        unit: 'kg',
        allowFractional: true,
        packName: 'Mfuko',
        packSize: 100,
      ),
    );
  }

  Future<InventoryProductItem> addLaptop({double stockCount = 5}) {
    return store.addProduct(
      InventoryProductItem(
        code: 'LAP01',
        name: 'Laptop',
        category: 'Electronics',
        purchasePrice: 800000,
        sellingPrice: 1000000,
        stockCount: stockCount,
        stockState: stockCount <= 0
            ? InventoryStockState.outOfStock
            : stockCount <= 5
                ? InventoryStockState.lowStock
                : InventoryStockState.inStock,
        artType: ProductArtType.aquafina,
        unit: 'Pcs',
        allowFractional: false,
      ),
    );
  }

  test('persists measured unit, bulk pack metadata, decimal stock and cart',
      () async {
    await addSukari(stockCount: 99.75);
    await addLaptop(stockCount: 5);

    final sukariProduct =
        store.products.firstWhere((item) => item.code == 'SUK01');
    final added = store.addToCartQuantity(
      sukariProduct,
      0.313,
      customPrice: 1000 / 0.313,
    );
    expect(added, isTrue);

    // Wait briefly so async cart persistence completes on the in-memory DB.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final storedInventory = await database.loadInventory(store.activeStoreId);
    final sukariRow =
        storedInventory.firstWhere((item) => item.code == 'SUK01');
    final laptopRow =
        storedInventory.firstWhere((item) => item.code == 'LAP01');

    expect(sukariRow.unit, 'kg');
    expect(sukariRow.allowFractional, isTrue);
    expect(sukariRow.packName, 'Mfuko');
    expect(sukariRow.packSize, 100);
    expect(sukariRow.stockCount, closeTo(99.75, 0.0001));
    expect(formatPackEquivalent(150, sukariRow.unit,
        packName: sukariRow.packName, packSize: sukariRow.packSize), '1.5 Mfuko');

    expect(laptopRow.unit, 'Pcs');
    expect(laptopRow.allowFractional, isFalse);
    expect(laptopRow.hasBulkPack, isFalse);
    expect(laptopRow.stockCount, 5);

    final storedCart = await database.loadCart(store.activeStoreId);
    expect(storedCart, hasLength(1));
    expect(storedCart.single.code, 'SUK01');
    expect(storedCart.single.quantity, closeTo(0.313, 0.0001));
    expect(storedCart.single.unit, 'kg');
    expect(storedCart.single.allowFractional, isTrue);
    expect(storedCart.single.lineTotal, closeTo(1000, 1));
  });

  test('handles robo, nusu, amount-based sales and void stock restoration',
      () async {
    await addSukari(stockCount: 100, sellingPrice: 3200);
    final sukari = store.products.firstWhere((item) => item.code == 'SUK01');

    // 1. Robo (0.25 kg) at 3,200 / kg = TSh 800
    final roboOrder = await store.completeCashSale(
      items: [OrderLineItem(product: sukari, quantity: 0.25)],
      cashTendered: 800,
      cashierName: 'Owner',
      registerName: 'Till 1',
    );
    expect(roboOrder.total, 800);
    expect(
      store.inventory.firstWhere((i) => i.code == 'SUK01').stockCount,
      closeTo(99.75, 0.0001),
    );

    // 2. Nusu (0.5 kg) at 3,200 / kg = TSh 1,600
    final nusuOrder = await store.completeCashSale(
      items: [OrderLineItem(product: sukari, quantity: 0.5)],
      cashTendered: 1600,
      cashierName: 'Owner',
      registerName: 'Till 1',
    );
    expect(nusuOrder.total, 1600);
    expect(
      store.inventory.firstWhere((i) => i.code == 'SUK01').stockCount,
      closeTo(99.25, 0.0001),
    );

    // 3. By amount: Sukari ya TSh 1,000 (~0.313 kg)
    final amountOrder = await store.completeCashSale(
      items: [
        OrderLineItem(
          product: sukari,
          quantity: 0.313,
          customPrice: 1000 / 0.313,
        ),
      ],
      cashTendered: 1000,
      cashierName: 'Owner',
      registerName: 'Till 1',
    );
    expect(amountOrder.total, 1000);
    expect(
      store.inventory.firstWhere((i) => i.code == 'SUK01').stockCount,
      closeTo(98.937, 0.0001),
    );

    // 4. Void the nusu order -> restores +0.5 kg back to 99.437 kg
    await store.voidOrder(nusuOrder.id);
    expect(
      store.inventory.firstWhere((i) => i.code == 'SUK01').stockCount,
      closeTo(99.437, 0.0001),
    );
  });

  test('receiving bulk pack updates base stock and weighted average cost',
      () async {
    await addSukari(
      stockCount: 100,
      purchasePrice: 2800,
      sellingPrice: 3200,
    );
    final supplier = await store.saveSupplier(
      Supplier(name: 'Jumla Traders', phone: '0712000111'),
    );

    await store.saveReceiving(
      Receiving(
        supplierId: supplier.id,
        supplierName: supplier.name,
        date: DateTime(2026, 11, 21),
        invoiceNo: 'INV-100KG',
        total: 290000,
        receivedBy: 'Owner',
        lines: const [
          ReceivingLine(
            productName: 'Sukari',
            quantity: 100,
            unitCost: 2900,
            sellingPrice: 3200,
          ),
        ],
      ),
    );

    final updated = store.inventory.firstWhere((item) => item.code == 'SUK01');
    expect(updated.stockCount, closeTo(200, 0.0001));
    expect(updated.purchasePrice, closeTo(2850, 0.01));
  });

  test('receipt formats whole Pcs cleanly and includes units for weighed goods',
      () {
    const doc = ReceiptDocument(
      storeName: 'Duka Letu',
      order: CompletedOrder(
        id: 'ORD-101',
        dateTime: '2026-11-21T10:00:00',
        date: '2026-11-21',
        time: '10:00',
        total: 100800,
        status: 'Completed',
        cashierName: 'Asha',
        register: 'POS-01',
        paymentMethod: 'Cash',
        cashTendered: 101000,
        changeDue: 200,
        lines: [
          OrderLine(
            itemCode: 'LAP01',
            itemCategory: 'Electronics',
            itemName: 'Laptop Bag',
            itemSize: 'Pcs',
            quantity: 2,
            unitPrice: '50000',
            unitPriceValue: 50000,
            artType: ProductArtType.aquafina,
            imagePath: null,
            unit: 'Pcs',
          ),
          OrderLine(
            itemCode: 'SUK01',
            itemCategory: 'Groceries',
            itemName: 'Sukari',
            itemSize: 'kg',
            quantity: 0.25,
            unitPrice: '3200',
            unitPriceValue: 3200,
            artType: ProductArtType.aquafina,
            imagePath: null,
            unit: 'kg',
          ),
        ],
      ),
    );

    final text = doc.toText();
    expect(text, contains('Laptop Bag | 2 x TSh 50,000.00 | TSh 100,000.00'));
    expect(text, contains('Sukari | 0.25 kg x TSh 3,200.00 | TSh 800.00'));
    expect(text, contains('Items: 2.25 units'));
  });

  testWidgets(
      'SalesPage keeps single-tap for Pcs and opens MeasurementSaleSheet for measured items',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final testDb = MemoryPosLocalDatabase();
    final testStore = _TestSalesStore(database: testDb);
    addTearDown(() async {
      testStore.dispose();
      await testDb.close();
    });

    await testStore.addProduct(
      const InventoryProductItem(
        code: 'LAP01',
        name: 'Laptop',
        category: 'Electronics',
        purchasePrice: 800000,
        sellingPrice: 1000000,
        stockCount: 5,
        stockState: InventoryStockState.inStock,
        artType: ProductArtType.aquafina,
        unit: 'Pcs',
        allowFractional: false,
      ),
    );
    await testStore.addProduct(
      const InventoryProductItem(
        code: 'SUK01',
        name: 'Sukari',
        category: 'Groceries',
        purchasePrice: 2800,
        sellingPrice: 3200,
        stockCount: 100,
        stockState: InventoryStockState.inStock,
        artType: ProductArtType.aquafina,
        unit: 'kg',
        allowFractional: true,
        packName: 'Mfuko',
        packSize: 100,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<PosLocalStore>.value(
        value: testStore,
        child: MaterialApp(
          theme: buildOsposTheme(ThemeData.light().textTheme),
          home: const SalesPage(useSharedShell: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tapping a standard Pcs item adds 1 directly with no sheet popup.
    await tester.tap(find.text('Laptop'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(MeasurementSaleSheet), findsNothing);
    final laptop = testStore.products.firstWhere((item) => item.code == 'LAP01');
    expect(testStore.cartQuantityForProduct(laptop), 1);

    // Tapping a fractional item opens MeasurementSaleSheet and lets us pick Robo (0.25 kg).
    await tester.tap(find.text('Sukari'));
    await tester.pumpAndSettle();
    expect(find.byType(MeasurementSaleSheet), findsOneWidget);

    await tester.tap(find.text('Robo (¼ kg)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('measurement-add-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(MeasurementSaleSheet), findsNothing);
    final sukari = testStore.products.firstWhere((item) => item.code == 'SUK01');
    expect(testStore.cartQuantityForProduct(sukari), closeTo(0.25, 0.0001));
    expect(tester.takeException(), isNull);
  });
}
