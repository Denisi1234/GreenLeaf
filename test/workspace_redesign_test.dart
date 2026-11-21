import 'package:track_mauzo/ui/suppliers/new_receiving_page.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/ui_test_fonts.dart';
import 'package:provider/provider.dart';
import 'package:track_mauzo/service/pos_local_store.dart';
import 'package:track_mauzo/service/pos_order_models.dart';
import 'package:track_mauzo/service/store_preferences.dart';
import 'package:track_mauzo/ui/models/product_item.dart';
import 'package:track_mauzo/ui/home/sales_page.dart';
import 'package:track_mauzo/ui/home/widgets/product_card.dart';
import 'package:track_mauzo/ui/more/advanced_features_page.dart';
import 'package:track_mauzo/ui/more/settings_page.dart';
import 'package:track_mauzo/ui/more/more_page.dart';
import 'package:track_mauzo/ui/reports/reports_catalog_page.dart';
import 'package:track_mauzo/ui/payment/payment_page.dart';
import 'package:track_mauzo/ui/products/inventory_product_item.dart';
import 'package:track_mauzo/ui/products/product_management_page.dart';
import 'package:track_mauzo/ui/widgets/app_theme.dart';

class _ReviewStore extends PosLocalStore {
  int logoutCalls = 0;
  @override
  Future<void> logout() async {
    logoutCalls++;
  }

  int saves = 0;
  int clears = 0;
  final _cart = <ProductItem>[];
  @override
  List<ProductItem> get products => inventory
      .map((item) => ProductItem(
          item.name, '500 ml', item.sellingPrice.toString(), item.artType,
          code: item.code, category: item.category))
      .toList();
  @override
  List<ProductItem> get cartItems => List.unmodifiable(_cart);
  @override
  int get cartCount => _cart.length;
  @override
  double get cartTotal =>
      _cart.fold(0, (total, item) => total + item.priceValue);
  String? savedMethod;
  double? savedDiscount;
  final pendingSale = Completer<CompletedOrder>();
  @override
  bool get isInitialized => true;
  @override
  String get languageCode => 'en';
  @override
  StorePreferences get storePreferences =>
      const StorePreferences(enableAdvancedAccounting: true);
  @override
  int availableStockForProduct(ProductItem product) =>
      inventory.firstWhere((item) => item.code == product.code).stockCount;
  @override
  bool addToCart(ProductItem product) {
    _cart.add(product);
    notifyListeners();
    return true;
  }

  @override
  bool removeSingleFromCart(ProductItem product) {
    if (_cart.isNotEmpty) _cart.removeLast();
    notifyListeners();
    return true;
  }

  @override
  Future<void> clearCart() async {
    clears++;
  }

  @override
  Future<CompletedOrder> completeCashSale(
      {required List<OrderLineItem> items,
      required double cashTendered,
      required String cashierName,
      required String registerName,
      String? customerName,
      double? discountAmount,
      String? discountLabel,
      String paymentMethod = 'Cash'}) {
    saves++;
    savedMethod = paymentMethod;
    savedDiscount = discountAmount;
    return pendingSale.future;
  }

  @override
  List<InventoryProductItem> get inventory => List.generate(
      26,
      (index) => InventoryProductItem(
            code: 'P${index.toString().padLeft(3, '0')}',
            name: index == 0
                ? 'Mineral Water'
                : 'Product ${index.toString().padLeft(2, '0')}',
            category: index.isEven ? 'Drinks' : 'Groceries',
            purchasePrice: 1500,
            sellingPrice: 2500,
            stockCount: index == 0
                ? 0
                : index == 1
                    ? 3
                    : 24,
            stockState: index == 0
                ? InventoryStockState.outOfStock
                : InventoryStockState.inStock,
            artType: ProductArtType.aquafina,
          ));
}

const _captureKey = ValueKey('review-capture');

Future<_ReviewStore> _mount(WidgetTester tester, Widget page, Size size) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final handler = FlutterError.onError;
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details, forceReport: true);
    handler?.call(details);
  };
  addTearDown(() => FlutterError.onError = handler);
  final store = _ReviewStore();
  addTearDown(store.dispose);
  await tester.pumpWidget(ChangeNotifierProvider<PosLocalStore>.value(
    value: store,
    child: MaterialApp(
      theme: buildOsposTheme(ThemeData.light().textTheme),
      home: RepaintBoundary(key: _captureKey, child: page),
    ),
  ));
  await tester.pumpAndSettle();
  return store;
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('UI_REVIEW')) return;
  await tester.runAsync(() async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_captureKey));
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/ui_review/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(configureUiTestFonts);

  for (final width in [390.0, 768.0, 1440.0]) {
    for (final entry in <String, Widget>{
      'sales': const SalesPage(useSharedShell: true),
      'inventory': const ProductManagementPage(useSharedShell: true),
      'checkout': const PaymentPage(items: [
        ProductItem('Mineral Water', '500 ml', '2500', ProductArtType.aquafina)
      ]),
      'receiving': const NewReceivingPage(),
      'settings': const SettingsPage(),
      'more': const MorePage(useSharedShell: true),
    }.entries) {
      testWidgets('${entry.key} fits ${width.toInt()}px', (tester) async {
        await _mount(tester, entry.value, Size(width, 900));
        expect(tester.takeException(), isNull);
        await _capture(tester, '${entry.key}-${width.toInt()}');
      });
    }
  }

  testWidgets('inventory filters, clears, sorts and pages real rows',
      (tester) async {
    await _mount(tester, const ProductManagementPage(useSharedShell: true),
        const Size(1440, 1000));
    expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 20);
    await tester.scrollUntilVisible(find.byTooltip('Next page'), 600,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 6);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 2500));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Mineral');
    await tester.pumpAndSettle();
    expect(find.text('1–1 of 1'), findsOneWidget);
    expect(find.text('Mineral Water'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(tester.widget<DataTable>(find.byType(DataTable)).rows.length, 20);
    await tester.tap(find.text('Quantity'));
    await tester.pumpAndSettle();
    final table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.sortColumnIndex, 4);
    expect(
        find
            .descendant(
                of: find.byType(DataTable),
                matching: find.text('Mineral Water'))
            .first,
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'desktop settings preserves unsaved receipt edits across sections',
      (tester) async {
    await _mount(tester, const SettingsPage(), const Size(1440, 1000));
    await tester.tap(find.widgetWithText(ListTile, 'Receipts'));
    await tester.pumpAndSettle();
    final toggle = find.byType(Switch).first;
    final original = tester.widget<Switch>(toggle).value;
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Receipts'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch).first).value, !original);
    expect(tester.takeException(), isNull);
  });
  const checkout = PaymentPage(items: [
    ProductItem('Product 01', '500 ml', '2500', ProductArtType.aquafina,
        code: 'P001')
  ]);

  testWidgets('checkout offers existing and new customers', (tester) async {
    await _mount(tester, checkout, const Size(390, 900));
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    expect(find.text('Select existing customer'), findsOneWidget);
    expect(find.text('Create new customer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clear sale requires confirmation and disables empty checkout',
      (tester) async {
    final store = await _mount(tester, checkout, const Size(1440, 1000));
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep sale'));
    await tester.pumpAndSettle();
    expect(store.clears, 0);
    expect(find.text('Product 01'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear sale'));
    await tester.pumpAndSettle();
    expect(store.clears, 1);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('complete-sale')))
            .onPressed,
        isNull);
  });

  testWidgets('card payment saves once and failed save can be retried',
      (tester) async {
    final store = await _mount(tester, checkout, const Size(1440, 1000));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Card'));
    await tester.pumpAndSettle();
    expect(find.text('Enter cash received'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('complete-sale')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('complete-sale')));
    await tester.pump();
    expect(store.saves, 1);
    expect(store.savedMethod, 'Card');
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('complete-sale')))
            .onPressed,
        isNull);
    store.pendingSale.completeError(StateError('Connection interrupted'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('complete-sale')))
            .onPressed,
        isNotNull);
    expect(find.text('Connection interrupted'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('cash amount validates and remains usable above keyboard',
      (tester) async {
    await _mount(tester, checkout, const Size(390, 900));
    await tester.ensureVisible(find.byKey(const ValueKey('complete-sale')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('complete-sale')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byKey(const ValueKey('cash-amount')), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('confirm-cash')))
            .onPressed,
        isNull);
    await tester.enterText(find.byKey(const ValueKey('cash-amount')), '3000');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await _capture(tester, 'checkout-cash-keyboard');
    expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('confirm-cash')))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discount updates the payable amount and can be removed',
      (tester) async {
    await _mount(tester, checkout, const Size(1440, 1000));
    await tester.tap(find.text('Add discount'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('discount-amount')), '500');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('apply-discount')));
    await tester.pumpAndSettle();
    expect(find.text('Complete sale • TSh 2,000'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove discount'));
    await tester.pumpAndSettle();
    expect(find.text('Complete sale • TSh 2,500'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('sales filters by real categories and opens checkout from cart',
      (tester) async {
    final store = await _mount(
        tester, const SalesPage(useSharedShell: true), const Size(1440, 1000));
    await tester.tap(find.text('Groceries').first);
    await tester.pumpAndSettle();
    expect(find.text('13 products'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'P001');
    await tester.pumpAndSettle();
    expect(find.byType(ProductCard), findsOneWidget);
    await tester.tap(find.byType(ProductCard));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(store.cartCount, 1);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.text('Review & checkout'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('More keeps useful tools and removes placeholder content',
      (tester) async {
    await _mount(
        tester, const MorePage(useSharedShell: true), const Size(1440, 1000));
    for (final id in [
      'customers',
      'debtors',
      'expenses',
      'reports',
      'advanced',
      'settings',
    ]) {
      expect(find.byKey(ValueKey('more-$id')), findsOneWidget);
    }
    expect(find.text('Aza POS'), findsNothing);
    expect(find.text('Version 1.0.0'), findsNothing);
    expect(find.text('Rate this app'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('more-advanced')));
    await tester.pumpAndSettle();
    expect(find.byType(AdvancedFeaturesPage), findsOneWidget);
    for (final label in [
      'Suppliers',
      'Goods received',
      'Cash register',
      'Accounts & ledger',
      'Tax settings',
      'Stores',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(label), findsOneWidget);
    }
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Reports');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('more-reports')));
    await tester.pumpAndSettle();
    expect(find.byType(ReportsCatalogPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('More handles unmatched searches and confirms sign out',
      (tester) async {
    final store = await _mount(
        tester, const MorePage(useSharedShell: true), const Size(390, 900));
    await tester.enterText(find.byType(TextField), 'no-match-123');
    await tester.pumpAndSettle();
    expect(find.text('No matching tools'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('more-sign-out')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Are you sure you want to end your session?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.logoutCalls, 0);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('more-customers')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
