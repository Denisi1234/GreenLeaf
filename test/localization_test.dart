import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:aza_pos/l10n/app_strings.dart';
import 'package:aza_pos/l10n/generated/en_catalog.g.dart';
import 'package:aza_pos/l10n/generated/sw_catalog.g.dart';
import 'package:aza_pos/service/pos_local_store.dart';
import 'package:aza_pos/service/pos_order_models.dart';
import 'package:aza_pos/service/receipt_settings.dart';
import 'package:aza_pos/ui/home/sales_page.dart';
import 'package:aza_pos/ui/models/product_item.dart';
import 'package:aza_pos/ui/more/more_page.dart';
import 'package:aza_pos/ui/payment/payment_page.dart';
import 'package:aza_pos/ui/receipt/receipt_document.dart';
import 'package:aza_pos/ui/receipt/receipt_pdf_service.dart';
import 'package:aza_pos/ui/receipt/receipt_preview_page.dart';
import 'package:aza_pos/ui/receipt/receipt_success_page.dart';
import 'package:aza_pos/ui/reports/pos_report_catalog.dart';
import 'package:aza_pos/ui/reports/pos_report_data.dart';
import 'package:aza_pos/ui/reports/reports_catalog_page.dart';
import 'package:aza_pos/ui/reports/widgets/preset_period_menu.dart';
import 'package:aza_pos/ui/reports/widgets/report_export_service.dart';
import 'package:aza_pos/ui/widgets/app_theme.dart';
import 'support/ui_test_fonts.dart';

class _LanguageStore extends PosLocalStore {
  @override
  bool get isInitialized => true;
}

CompletedOrder _sale() => const CompletedOrder(
  id: 'R-001', dateTime: '2026-11-20T10:30:00', date: '2026-11-20',
  time: '10:30', total: 4000, status: 'Completed', cashierName: 'Jane Cashier',
  register: 'Register 1', paymentMethod: 'Cash', cashTendered: 5000,
  changeDue: 1000, customerName: 'Amina Trading', lines: [
    OrderLine(itemCode: 'P-001', itemCategory: 'General', itemName: 'Cash',
      itemSize: 'Each', quantity: 2, unitPrice: '2000', unitPriceValue: 2000,
      unitCost: 1000, artType: ProductArtType.aquafina, imagePath: null),
  ],
);

Widget _app(_LanguageStore store, Widget page) => ChangeNotifierProvider<PosLocalStore>.value(
  value: store, child: Consumer<PosLocalStore>(builder: (context, store, _) => MaterialApp(
    locale: Locale(store.languageCode),
    supportedLocales: const [Locale('en'), Locale('sw')],
    localizationsDelegates: const [GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
    theme: buildOsposTheme(ThemeData.light().textTheme), home: page,
  )),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await initializeDateFormatting();
    await configureUiTestFonts();
  });

  test('normalizes supported regional language codes', () {
    expect(AppStrings.normalize('en-US'), 'en');
    expect(AppStrings.normalize(' EN_gb '), 'en');
    expect(AppStrings.normalize('sw-TZ'), 'sw');
    expect(AppStrings.normalize('SW_ke'), 'sw');
    expect(AppStrings.normalize('fr'), 'en');
  });

  test('catalog has matching keys and preserves interpolation arguments', () {
    expect(swUiCatalog.keys.toSet(), enUiCatalog.keys.toSet());
    final tokens = RegExp(r'\{p\d+\}');
    for (final key in enUiCatalog.keys) {
      final en = tokens.allMatches(enUiCatalog[key]!).map((m) => m[0]).toSet();
      final sw = tokens.allMatches(swUiCatalog[key]!).map((m) => m[0]).toSet();
      expect(en.containsAll(sw), isTrue, reason: key);
    }
  });

  test('all 79 report titles, groups, and quick periods are translated', () {
    final strings = AppStrings.of('sw');
    expect(posReports.length, 79);
    for (final report in posReports) {
      expect(strings.text(report.title), isNot(report.title), reason: report.title);
      expect(strings.text(report.group.label), isNot(report.group.label));
    }
    for (final period in PresetPeriod.values) {
      expect(strings.text(period.label), isNot(period.label), reason: period.label);
    }
  });

  test('report display and CSV translate system labels without changing names', () async {
    const table = ReportTable([
      ReportColumn('Customer'), ReportColumn('Payment method'),
      ReportColumn('Status'), ReportColumn('Amount', money: true),
    ], [['Cash', 'Cash', 'Completed', 4000]]);
    final display = table.localized(AppStrings.of('sw'));
    expect(display.rows.single, ['Cash', 'Taslimu', 'Imekamilika', 4000]);
    expect(table.rows.single, ['Cash', 'Cash', 'Completed', 4000]);
    final csv = await ReportExportService.buildExport(table: table,
      title: 'Sales Summary', format: ExportFormat.csv, languageCode: 'sw');
    final content = utf8.decode(csv.bytes);
    expect(content, contains('Mteja'));
    expect(content, contains('Taslimu'));
    expect(content, contains('"Cash"'));
    expect(content, contains('4,000'));
  });

  test('receipts translate generated text and preserve business names and totals', () {
    final en = ReceiptDocument(order: _sale(), storeName: 'Sales', languageCode: 'en');
    final sw = ReceiptDocument(order: _sale(), storeName: 'Sales', languageCode: 'sw');
    expect(en.toText(), contains('Cash received: TSh 5,000.00'));
    expect(sw.toText(), contains('Fedha zilizopokelewa: TSh 5,000.00'));
    expect(sw.toText(), contains('Chenji: TSh 1,000.00'));
    expect(sw.toText(), contains('Malipo: Taslimu'));
    expect(sw.toText(), contains('Amina Trading'));
    expect(sw.toText().split('\n').first, 'Sales');
    expect(sw.toText(), contains('Cash | 2 x'));
    expect(sw.subtotal, en.subtotal);
    final custom = ReceiptDocument(order: _sale(), storeName: 'Shop', languageCode: 'sw',
      settings: const ReceiptSettings(header: 'My custom heading', footer: 'My custom footer'));
    expect(custom.toText(), contains('My custom heading'));
    expect(custom.footer, 'My custom footer');
  });

  test('Swahili PDF receipt builds offline', () async {
    final bytes = await ReceiptPdfService.buildReceiptBytes(
      ReceiptDocument(order: _sale(), storeName: 'Duka', languageCode: 'sw'));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  testWidgets('switching languages updates the open sales page immediately', (tester) async {
    final store = _LanguageStore();
    await tester.runAsync(() => store.setLanguageCode('en'));
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(store, const SalesPage()));
    await tester.pumpAndSettle();
    expect(find.text('Make a sale'), findsOneWidget);
    await tester.runAsync(() => store.setLanguageCode('sw-TZ'));
    await tester.pumpAndSettle();
    expect(find.text('Fanya mauzo'), findsOneWidget);
    expect(find.text('Make a sale'), findsNothing);
    await tester.runAsync(() => store.setLanguageCode('en-US'));
    await tester.pumpAndSettle();
    expect(find.text('Make a sale'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  for (final language in ['en', 'sw']) {
    for (final width in [390.0, 1440.0]) {
      final pages = <String, Widget Function()>{
        'sales': () => const SalesPage(),
        'checkout': () => const PaymentPage(items: []),
        'more': () => const MorePage(),
        'reports': () => const ReportsCatalogPage(),
        'receipt': () => ReceiptPreviewPage(order: _sale()),
        'sale confirmation': () => ReceiptSuccessPage(order: _sale()),
      };
      for (final entry in pages.entries) {
        testWidgets('${entry.key} fits $width in $language', (tester) async {
          final store = _LanguageStore();
          await tester.runAsync(() => store.setLanguageCode(language));
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(_app(store, entry.value()));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          store.dispose();
        });
      }
    }
  }
}
