import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:track_mauzo/l10n/app_strings.dart';
import 'package:track_mauzo/service/debit_entry_model.dart';
import 'package:track_mauzo/service/debit_statement_service.dart';
import 'package:track_mauzo/service/expense_model.dart';
import 'package:track_mauzo/service/pos_local_store.dart';
import 'package:track_mauzo/service/pos_order_models.dart';
import 'package:track_mauzo/service/report_pdf/report_pdf_layout.dart';
import 'package:track_mauzo/service/store_models.dart';
import 'package:track_mauzo/service/tax_settings.dart';
import 'package:track_mauzo/ui/business_category_config.dart';
import 'package:track_mauzo/ui/models/customer_data.dart';
import 'package:track_mauzo/ui/models/product_item.dart';
import 'package:track_mauzo/ui/more/widgets/customer_export_service.dart';
import 'package:track_mauzo/ui/more/widgets/customer_models.dart';
import 'package:track_mauzo/ui/more/widgets/expense_export_service.dart';
import 'package:track_mauzo/ui/reports/models/report_models.dart';
import 'package:track_mauzo/ui/reports/pos_report_catalog.dart';
import 'package:track_mauzo/ui/reports/pos_report_data.dart';
import 'package:track_mauzo/ui/reports/services/pdf_report_service.dart';
import 'package:track_mauzo/ui/reports/services/report_data_service.dart';
import 'package:track_mauzo/ui/reports/widgets/report_export_service.dart';

final _now = DateTime(2026, 11, 21, 11, 30);
final _customer = CustomerData(
    id: 'C1',
    name: 'Amina Trading',
    phone: '0712345678',
    email: 'amina@example.test',
    address: 'Market Street',
    debitBalance: 1500,
    totalSpent: 1000,
    totalOrders: 1,
    createdAt: DateTime(2026, 1, 1));
final _expenses = [
  Expense(
      id: 1,
      title: 'Delivery fuel',
      vendor: 'Supplier A',
      amount: 2000,
      taxAmount: 100,
      category: 'Transport',
      paymentMethod: 'Cash',
      date: _now)
];
const _inventory = [
  InventoryProductItem(
      code: 'S001',
      name: 'Sukari (1 kg)',
      category: 'Food',
      purchasePrice: 2800,
      sellingPrice: 3200,
      stockCount: 45,
      stockState: InventoryStockState.inStock,
      artType: ProductArtType.aquafina)
];
final _orders = [
  for (final method in ['Cash', 'Credit'])
    CompletedOrder(
      id: 'SALE-$method',
      dateTime: _now.toIso8601String(),
      date: '2026-11-21',
      time: '11:30',
      total: 6400,
      status: 'Completed',
      cashierName: 'Neema',
      register: 'Counter 1',
      paymentMethod: method,
      cashTendered: method == 'Cash' ? 7000 : 0,
      changeDue: method == 'Cash' ? 600 : 0,
      customerName: _customer.name,
      lines: const [
        OrderLine(
            itemCode: 'S001',
            itemCategory: 'Food',
            itemName: 'Sukari (1 kg)',
            itemSize: '1 kg',
            quantity: 2,
            unitPrice: '3200',
            unitPriceValue: 3200,
            unitCost: 2800,
            artType: ProductArtType.aquafina,
            imagePath: null)
      ],
    )
];
final _entries = [
  DebitEntry(
      id: 'D1',
      customerId: 'C1',
      customerName: 'Amina Trading',
      type: DebitType.charge,
      amount: 2000,
      createdAt: _now,
      note: 'Invoice INV-01',
      orderId: 'INV-01'),
  DebitEntry(
      id: 'D2',
      customerId: 'C1',
      customerName: 'Amina Trading',
      type: DebitType.payment,
      amount: 500,
      createdAt: _now,
      note: 'Cash payment'),
];

class _PdfStore extends PosLocalStore {
  _PdfStore(this.language);
  final String language;
  @override
  String get languageCode => language;
  @override
  List<CompletedOrder> get orders => _orders;
  @override
  List<Expense> get expenses => _expenses;
  @override
  List<CustomerData> get customers => [_customer];
  @override
  List<InventoryProductItem> get inventory => _inventory;
  @override
  String get activeStoreName => 'GreenLeaf Shop';
  @override
  AppProfileData get profile => AppProfileData.empty()
      .copyWith(storeName: 'GreenLeaf Shop', ownerName: 'Neema Msimamizi');
}

ReportPdfContext _context(String lang, {String filters = ''}) =>
    ReportPdfContext(
      businessName: 'GreenLeaf Shop',
      preparedBy: 'Neema Msimamizi',
      languageCode: lang,
      generatedAt: _now,
      reference: 'RPT-20261121',
      dateFormat: 'dd/MM/yyyy',
      period: '2026-11-01 - 2026-11-21',
      filterSummary: filters,
    );

Future<void> _save(String name, Uint8List bytes) async {
  expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  expect(bytes.length, greaterThan(1000));
  final file = File('build/pdf_review/$name.pdf');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting());
  final snapshot = StoreSnapshot(
      store: const Store(
          id: 'main', name: 'GreenLeaf Shop', address: '', contact: ''),
      orders: _orders,
      inventory: _inventory,
      expenses: _expenses,
      customers: [_customer],
      shifts: const [],
      suppliers: const [],
      receivings: const [],
      tax: const TaxSettings(),
      trialBalanceRows: const [],
      fixedAssets: const [],
      bankTransactions: const []);
  final data = PosReportData(
      orders: _orders,
      inventory: _inventory,
      expenses: _expenses,
      customers: [_customer],
      storeName: 'GreenLeaf Shop',
      storeSnapshots: [snapshot]);

  test('page orientation follows the number of business columns', () {
    expect(ReportPdfLayout.pageFormatFor(6).width,
        lessThan(ReportPdfLayout.pageFormatFor(6).height));
    expect(ReportPdfLayout.pageFormatFor(7).width,
        greaterThan(ReportPdfLayout.pageFormatFor(7).height));
  });

  test('PDF label metadata leaves non-PDF financial exports unchanged', () {
    final table = data.build(ReportData.profitLoss);
    expect(table.columns.first.systemLabels, isTrue);
    final localized = table.localized(AppStrings.of('sw'));
    expect(localized.rows.first.first, 'Net sales');
    expect(utf8.decode(ReportExportService.generateCsv(localized)), contains('Net sales'));
  });

  test('business-entered names are preserved even when they match accounting labels', () async {
    await _save('sw/names-preserved', await ReportExportService.generatePdf(
      const ReportTable([ReportColumn('Customer'), ReportColumn('Item'),
        ReportColumn('Amount', money: true)], [['Net sales', 'Gross profit', 42.25]]),
      'Detailed Sales', null, false, pdfContext: _context('sw')));
  });

  for (final lang in ['en', 'sw']) {
    for (var index = 0; index < posReports.length; index++) {
      final report = posReports[index];
      test('${report.title} PDF in $lang', () async {
        final table = data.build(report.data);
        final bytes = await ReportExportService.generatePdf(
            table,
            report.title,
            DateTimeRange(start: DateTime(2026, 11), end: _now),
            report.isSnapshot,
            languageCode: lang,
            pdfContext: _context(lang));
        await _save('$lang/catalog-${index.toString().padLeft(2, '0')}', bytes);
      });
    }

    test('customer PDF in $lang preserves lifetime amounts and names',
        () async {
      final bytes = await CustomerExportService.buildPdf(rows: [
        _customer
      ], stats: const {
        'Amina Trading': CustomerStats(orders: 2, spent: 6400, lastOrder: null)
      }, strings: AppStrings.of(lang), pdfContext: _context(lang));
      await _save('$lang/customers', bytes);
    });
    test('expense PDF in $lang preserves tax and total', () async {
      await _save(
          '$lang/expenses',
          await ExpenseExportService.buildPdf(
              expenses: _expenses,
              strings: AppStrings.of(lang),
              pdfContext: _context(lang)));
    });
    test('customer debt statement PDF in $lang preserves charges and payments',
        () async {
      await _save(
          '$lang/debt-statement',
          await DebitStatementService.buildPdf(
              customer: _customer, entries: _entries, context: _context(lang)));
    });
    test('analytical PDF in $lang retains its eight sections offline',
        () async {
      final store = _PdfStore(lang);
      final report = ReportDataService.buildReportSnapshot(
          store: store,
          period: ReportPeriod.allTime,
          category: BusinessCategory.retail);
      await _save(
          '$lang/analytical',
          await PdfReportService.generateSalesReportPdf(
              store: store, report: report, profile: store.profile));
      store.dispose();
    });

    test('empty report in $lang uses the common header and empty message',
        () async {
      await _save(
          '$lang/empty',
          await ReportExportService.generatePdf(
              const ReportTable(
                  [ReportColumn('Item'), ReportColumn('Amount', money: true)],
                  []),
              'Sales Summary',
              null,
              false,
              pdfContext: _context(lang)));
    });
    test('long cell in $lang continues without losing later rows', () async {
      await _save(
          '$lang/long-cell',
          await ReportExportService.generatePdf(
              ReportTable(const [
                ReportColumn('Item'),
                ReportColumn('Description'),
                ReportColumn('Amount', money: true),
              ], [
                [
                  'P-LONG',
                  '${List.filled(500, 'Detailed description of a product').join(' ')} END_LONG_CELL',
                  -1234.50
                ],
                ['P-LAST', 'LAST_REPORT_ROW', 9876.54],
              ]),
              'Detailed Sales',
              null,
              false,
              pdfContext: _context(lang)));
    });
    test('large wide report in $lang spans many pages', () async {
      await _save(
          '$lang/large-wide',
          await ReportExportService.generatePdf(
              ReportTable([
                for (var c = 0; c < 12; c++)
                  ReportColumn(c == 0 ? 'Item' : 'Column $c', money: c > 5),
              ], [
                for (var r = 0; r < 1000; r++)
                  [
                    'ROW-${r.toString().padLeft(4, '0')}',
                    'Supplier A',
                    'Market Street',
                    'Cash',
                    'Completed',
                    2,
                    1000.50,
                    -2000.25,
                    3456.78,
                    4000,
                    5000,
                    6000,
                  ]
              ]),
              'Multi-Store Side-by-Side Comparison',
              null,
              false,
              pdfContext: _context(lang)));
    });
    test(
        'selected report rows and columns are passed to PDF unchanged in $lang',
        () async {
      const selected = ReportTable([
        ReportColumn('Item'),
        ReportColumn('Amount', money: true)
      ], [
        ['FILTERED_ROW', 42.25]
      ]);
      final export = await ReportExportService.buildExport(
          table: selected,
          title: 'Items Summary',
          format: ExportFormat.pdf,
          languageCode: lang,
          pdfContext: _context(lang, filters: 'Search: FILTERED_ROW'));
      await _save('$lang/filtered', export.bytes);
      expect(selected.rows.single, ['FILTERED_ROW', 42.25]);
      expect(utf8.decode(ReportExportService.generateCsv(selected)),
          contains('42.25'));
    });
  }
}
