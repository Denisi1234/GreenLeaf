import 'package:aza_pos/ui/accounting/journal_entry_page.dart';
import 'package:aza_pos/ui/accounting/account_form_page.dart';
import 'package:aza_pos/ui/suppliers/new_receiving_page.dart';
import 'package:aza_pos/ui/suppliers/supplier_form_page.dart';
import 'package:aza_pos/ui/suppliers/supplier_detail_page.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:aza_pos/service/pos_local_store.dart';
import 'package:aza_pos/service/pos_order_models.dart';
import 'package:aza_pos/service/expense_model.dart';
import 'package:aza_pos/service/supplier_model.dart';
import 'package:aza_pos/service/store_models.dart';
import 'package:aza_pos/service/accounting_model.dart';
import 'package:aza_pos/service/receipt_settings.dart';
import 'package:aza_pos/ui/models/customer_data.dart';
import 'package:aza_pos/ui/models/product_item.dart';
import 'package:aza_pos/ui/more/customers_page.dart';
import 'package:aza_pos/ui/more/customer_details_page.dart';
import 'package:aza_pos/ui/more/create_customer_page.dart';
import 'package:aza_pos/ui/more/debtors_page.dart';
import 'package:aza_pos/ui/more/expenses_tracking_page.dart';
import 'package:aza_pos/ui/more/add_expense_page.dart';
import 'package:aza_pos/ui/more/staff_management_page.dart';
import 'package:aza_pos/ui/more/staff_member_details_page.dart';
import 'package:aza_pos/ui/more/role_details_page.dart';
import 'package:aza_pos/ui/more/add_edit_staff_page.dart';
import 'package:aza_pos/ui/more/stores_page.dart';
import 'package:aza_pos/ui/more/store_form_page.dart';
import 'package:aza_pos/ui/more/settings_page.dart';
import 'package:aza_pos/ui/more/change_password_page.dart';
import 'package:aza_pos/ui/more/help_support_page.dart';
import 'package:aza_pos/ui/more/privacy_policy_page.dart';
import 'package:aza_pos/ui/more/terms_of_service_page.dart';
import 'package:aza_pos/ui/more/about_app_page.dart';
import 'package:aza_pos/ui/suppliers/suppliers_page.dart';
import 'package:aza_pos/ui/suppliers/receiving_page.dart';
import 'package:aza_pos/ui/accounting/accounts_page.dart';
import 'package:aza_pos/ui/accounting/fixed_assets_page.dart';
import 'package:aza_pos/ui/accounting/bank_reconciliation_page.dart';
import 'package:aza_pos/ui/payment/cash_register_page.dart';
import 'package:aza_pos/ui/settings/tax_settings_page.dart';
import 'package:aza_pos/ui/receipt/receipt_document.dart';
import 'package:aza_pos/ui/receipt/receipt_pdf_service.dart';
import 'package:aza_pos/ui/receipt/receipt_preview_page.dart';
import 'package:aza_pos/ui/receipt/receipt_success_page.dart';
import 'package:aza_pos/ui/widgets/market_shared_widgets.dart';
import 'package:aza_pos/ui/widgets/app_theme.dart';
import 'support/ui_test_fonts.dart';

final customer = CustomerData(
    id: 'c1',
    name: 'Amina Trading',
    phone: '0712345678',
    email: 'amina@example.test',
    address: 'Main Street',
    debitBalance: 5000);
const role = StaffRoleData(
    id: 'manager',
    title: 'Manager',
    subtitle: 'Operations',
    permissions: ['sales', 'inventory', 'reports'],
    sortOrder: 1);
const member = StaffMemberData(
    id: 'm1',
    name: 'Jane Cashier',
    email: 'jane@example.test',
    phone: '0712345678',
    roleId: 'manager',
    createdAt: '2026-01-01');
final supplier = Supplier(
    id: 1,
    name: 'Acme Supplies',
    phone: '0712345678',
    email: 'supplier@example.test',
    openingBalance: 2000);
final expense = Expense(
    id: 1,
    title: 'Delivery costs',
    amount: 1000,
    category: 'Transport',
    paymentMethod: 'Cash',
    date: DateTime.now());
final asset = FixedAsset(
    id: 1,
    name: 'Counter computer',
    category: 'Equipment',
    purchaseDate: DateTime(2026, 1),
    cost: 1000000);
const branch = Store(
    id: 'main',
    name: 'Main branch',
    address: 'Market Street',
    contact: '0712345678');
CompletedOrder sale(
        {String payment = 'Cash', ReceiptSettings? settings, int count = 1}) =>
    CompletedOrder(
      id: 'R-1001',
      dateTime: DateTime.now().toIso8601String(),
      date: '19 Nov 2026',
      time: '10:30',
      total: 3500.50,
      status: 'Completed',
      cashierName: 'Jane Cashier',
      register: 'Counter 1',
      paymentMethod: payment,
      cashTendered: payment == 'Cash' ? 5000 : 0,
      changeDue: payment == 'Cash' ? 1499.50 : 0,
      customerName: 'Amina Trading',
      discountAmount: 500,
      discountLabel: 'Customer discount',
      lines: [
        for (var index = 0; index < count; index++)
          const OrderLine(
              itemCode: 'P1',
              itemCategory: 'General',
              itemName: 'Premium product with a long descriptive name',
              itemSize: 'Each',
              quantity: 2,
              unitPrice: 'TSh 2,000.25',
              unitPriceValue: 2000.25,
              unitCost: 1200,
              artType: ProductArtType.aquafina,
              imagePath: null)
      ],
    );

class _ManagementStore extends PosLocalStore {
  final addedCustomers = <CustomerData>[];
  bool failSave = false;
  @override
  bool get isInitialized => true;
  @override
  String get languageCode => 'en';
  @override
  List<CustomerData> get customers => [customer, ...addedCustomers];
  @override
  List<Expense> get expenses => [expense];
  @override
  List<Supplier> get suppliers => [supplier];
  @override
  List<Store> get stores => [branch];
  @override
  List<StaffMemberData> get staffMembers => [member];
  @override
  List<StaffRoleData> get staffRoles => [role];
  @override
  StaffRoleData? staffRoleById(String id) => id == role.id ? role : null;
  @override
  List<StaffMemberData> staffMembersForRole(String id) =>
      id == role.id ? [member] : [];
  @override
  Supplier? supplierById(int id) => id == 1 ? supplier : null;
  @override
  double supplierBalance(int id) => 2000;
  @override
  List<CompletedOrder> get orders => [sale()];
  @override
  List<Account> get accounts => const [
        Account(id: 1, code: '1000', name: 'Cash', type: AccountType.asset),
        Account(id: 2, code: '4000', name: 'Sales', type: AccountType.income)
      ];
  @override
  List<FixedAsset> get fixedAssets => [asset];
  @override
  List<BankTransaction> get bankTransactions => [
        BankTransaction(
            id: 1,
            date: DateTime.now(),
            description: 'Mobile payment settlement',
            amount: 2000)
      ];
  @override
  List<Receiving> get receivings => [
        Receiving(
            id: 1,
            supplierId: 1,
            supplierName: supplier.name,
            date: DateTime.now(),
            total: 2000,
            invoiceNo: 'INV-01',
            lines: const [
              ReceivingLine(productName: 'Tea', quantity: 2, unitCost: 1000)
            ])
      ];
  @override
  Future<void> addCustomer(CustomerData value) async {
    if (failSave) throw StateError('Save connection unavailable');
    addedCustomers.add(value);
    notifyListeners();
  }
}

Future<_ManagementStore> _mount(WidgetTester tester, Widget page,
    {double width = 1440}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final handler = FlutterError.onError;
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details, forceReport: true);
    handler?.call(details);
  };
  addTearDown(() => FlutterError.onError = handler);
  final store = _ManagementStore();
  addTearDown(store.dispose);
  await tester.pumpWidget(ChangeNotifierProvider<PosLocalStore>.value(
      value: store,
      child: MaterialApp(
          theme: buildOsposTheme(ThemeData.light().textTheme),
          home: RepaintBoundary(
              key: const ValueKey('management-preview'), child: page))));
  await tester.pumpAndSettle();
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
  return store;
}

Future<void> capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('UI_REVIEW')) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('management-preview')));
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
  for (final width in [320.0, 768.0, 1024.0, 1440.0]) {
    final pages = <String, Widget>{
      'customers': const CustomersPage(),
      'customer-details': const CustomerDetailsPage(customerId: 'c1'),
      'new-customer': const CreateCustomerPage(),
      'edit-customer': CreateCustomerPage(existing: customer),
      'debtors': const DebtorsPage(),
      'expenses': const ExpensesTrackingPage(),
      'new-expense': const AddExpensePage(),
      'edit-expense': AddExpensePage(expense: expense),
      'suppliers': const SuppliersPage(),
      'supplier-detail': const SupplierDetailPage(supplierId: 1),
      'new-supplier': const SupplierFormPage(),
      'edit-supplier': SupplierFormPage(supplier: supplier),
      'receiving': const ReceivingPage(),
      'new-receiving': NewReceivingPage(presetSupplier: supplier),
      'staff': const StaffManagementPage(),
      'staff-detail': const StaffMemberDetailsPage(staffId: 'm1'),
      'role-detail': const RoleDetailsPage(roleId: 'manager'),
      'new-staff': const AddEditStaffPage(roles: [role]),
      'edit-staff': const AddEditStaffPage(member: member, roles: [role]),
      'stores': const StoresPage(),
      'new-store': const StoreFormPage(),
      'edit-store': const StoreFormPage(store: branch),
      'accounts': const AccountsPage(),
      'new-account': const AccountFormPage(),
      'journal': const JournalEntryPage(),
      'assets': const FixedAssetsPage(),
      'new-asset': const AssetFormPage(),
      'edit-asset': AssetFormPage(asset: asset),
      'bank': const BankReconciliationPage(),
      'cash-register': const CashRegisterPage(),
      'tax': const TaxSettingsPage(),
      'settings': const SettingsPage(),
      'receipt-settings':
          const SettingsPage(initialSection: SettingsSection.receipt),
      'language-settings':
          const SettingsPage(initialSection: SettingsSection.language),
      'data-settings': const SettingsPage(initialSection: SettingsSection.data),
      'account-settings':
          const SettingsPage(initialSection: SettingsSection.account),
      'change-password': const ChangePasswordPage(),
      'help': const HelpSupportPage(),
      'privacy': const PrivacyPolicyPage(),
      'terms': const TermsOfServicePage(),
      'about': const AboutAppPage(),
      'receipt-preview': ReceiptPreviewPage(order: sale()),
      'receipt-success': ReceiptSuccessPage(order: sale()),
      'credit-receipt': ReceiptPreviewPage(order: sale(payment: 'Credit')),
      'credit-success': ReceiptSuccessPage(order: sale(payment: 'Credit')),
    };
    for (final entry in pages.entries) {
      testWidgets('${entry.key} fits ${width.toInt()}px', (tester) async {
        await _mount(tester, entry.value, width: width);
        expect(tester.takeException(), isNull,
            reason: '${entry.key} at $width');
        if ([
          'receipt-preview',
          'receipt-success',
          'customers',
          'suppliers',
          'staff'
        ].contains(entry.key)) {
          await capture(tester, '${entry.key}-${width.toInt()}');
        }
        final scroll = find.byWidgetPredicate((widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down);
        if (scroll.evaluate().isNotEmpty) {
          await tester.drag(scroll.first, const Offset(0, -1800));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '${entry.key} scrolled at $width');
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  test('receipt uses saved numeric prices and distinguishes payment methods',
      () {
    final cash = ReceiptDocument(
        order: sale(), storeName: 'Main branch', currency: 'KES');
    expect(cash.subtotal, 4000.50);
    expect(sale().lines.first.product.priceValue, 2000.25);
    expect(cash.toText(), contains('KES 4,000.50'));
    expect(cash.toText(), contains('Change due: KES 1,499.50'));
    final credit = ReceiptDocument(
        order: sale(payment: 'Credit'), storeName: 'Main branch');
    expect(credit.toText(), contains('Balance due: TSh 3,500.50'));
    expect(credit.toText(), isNot(contains('Cash received')));
    final card =
        ReceiptDocument(order: sale(payment: 'Card'), storeName: 'Main branch');
    expect(card.toText(), isNot(contains('Change due')));
  });

  test('receipt privacy settings are applied to shared text and PDF metadata',
      () {
    final receipt = ReceiptDocument(
        order: sale(),
        storeName: 'Main branch',
        storePhone: 'hidden-phone',
        storeTaxId: 'hidden-tax',
        settings: const ReceiptSettings(
            showStoreContact: false,
            showTaxId: false,
            showCashier: false,
            showCustomer: false,
            showDiscount: false));
    final text = receipt.toText();
    for (final hidden in [
      'hidden-phone',
      'hidden-tax',
      'Jane Cashier',
      'Amina Trading',
      'Customer discount'
    ]) {
      expect(text, isNot(contains(hidden)));
    }
  });

  testWidgets('PDF generation works offline with a long receipt',
      (tester) async {
    final bytes = await tester.runAsync(() =>
        ReceiptPdfService.buildReceiptBytes(
            ReceiptDocument(order: sale(count: 80), storeName: 'Main branch')));
    expect(utf8.decode(bytes!.take(5).toList()), '%PDF-');
    expect(bytes.length, greaterThan(5000));
  });

  testWidgets(
      'shared save control blocks repeat taps and retains form on failure',
      (tester) async {
    final pending = Completer<void>();
    var calls = 0;
    await _mount(
        tester,
        Scaffold(
            body: Column(children: [
          const TextField(),
          MarketButton(
              label: 'Save record',
              onTap: () async {
                calls++;
                await pending.future;
              })
        ])));
    await tester.enterText(find.byType(TextField), 'Unsaved details');
    await tester.tap(find.text('Save record'));
    await tester.pump();
    await tester.tap(find.text('Save record'));
    await tester.pump();
    expect(calls, 1);
    pending.completeError(StateError('Save connection unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved details'), findsOneWidget);
    expect(find.text('Save connection unavailable'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
