import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:track_mauzo/service/pos_local_store.dart';
import 'package:track_mauzo/service/pos_order_models.dart';
import 'package:track_mauzo/service/store_models.dart';
import 'package:track_mauzo/ui/models/product_item.dart';
import 'package:track_mauzo/ui/products/inventory_product_item.dart';
import 'package:track_mauzo/ui/reports/enhanced_report_page.dart';
import 'package:track_mauzo/ui/reports/models/report_models.dart';
import 'package:track_mauzo/ui/reports/pos_report_catalog.dart';
import 'package:track_mauzo/ui/reports/reports_catalog_page.dart';
import 'package:track_mauzo/ui/reports/widgets/trend_chart.dart';
import 'package:track_mauzo/ui/widgets/app_theme.dart';
import 'support/ui_test_fonts.dart';

class _ReportStore extends PosLocalStore {
  @override
  bool get isInitialized => true;
  @override
  String get languageCode => 'en';
  @override
  List<InventoryProductItem> get inventory => List.generate(
      32,
      (index) => InventoryProductItem(
            code: 'P$index',
            name: 'Product ${index.toString().padLeft(2, '0')}',
            category: 'General',
            purchasePrice: 1200,
            sellingPrice: 2000,
            stockCount: index,
            stockState: InventoryStockState.inStock,
            artType: ProductArtType.aquafina,
          ));
  @override
  List<CompletedOrder> get orders => [
        for (var index = 0; index < 3; index++)
          CompletedOrder(
            id: 'sale-$index',
            dateTime: DateTime.now().toIso8601String(),
            date: 'Today',
            time: '',
            total: 4000,
            status: 'Completed',
            cashierName: 'Cashier',
            register: 'POS-01',
            paymentMethod: 'Cash',
            cashTendered: 4000,
            changeDue: 0,
            lines: [
              const OrderLine(
                  itemCode: 'P1',
                  itemCategory: 'General',
                  itemName: 'Product 01',
                  itemSize: 'Each',
                  quantity: 2,
                  unitPrice: 'TSH 2000',
                  unitPriceValue: 2000,
                  unitCost: 1200,
                  artType: ProductArtType.aquafina,
                  imagePath: null)
            ],
          )
      ];
  @override
  Future<List<StoreSnapshot>> loadAllStoreSnapshots() async => [
        StoreSnapshot(
          store: const Store(
              id: 'main', name: 'Main store', address: '', contact: ''),
          orders: orders,
          inventory: inventory,
          expenses: expenses,
          customers: customers,
          shifts: registerShifts,
          suppliers: suppliers,
          receivings: receivings,
          tax: taxSettings,
          trialBalanceRows: trialBalance(),
          fixedAssets: fixedAssets,
          bankTransactions: bankTransactions,
        )
      ];
}

Future<void> _mount(WidgetTester tester, Widget page, double width) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final store = _ReportStore();
  addTearDown(store.dispose);
  await tester.pumpWidget(ChangeNotifierProvider<PosLocalStore>.value(
      value: store,
      child: MaterialApp(
          theme: buildOsposTheme(ThemeData.light().textTheme),
          home: RepaintBoundary(
              key: const ValueKey('report-preview'), child: page))));
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('UI_REVIEW')) return;
  await tester.runAsync(() => GoogleFonts.pendingFonts());
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('report-preview')));
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

  testWidgets('directory lists all 79 reports once without decorative badges',
      (tester) async {
    await _mount(tester, const ReportsCatalogPage(), 1440);
    expect(posReports, hasLength(79));
    for (final report in posReports) {
      expect(find.byKey(ValueKey('report-${report.title}')), findsOneWidget,
          reason: report.title);
    }
    expect(find.byIcon(Icons.workspace_premium_rounded), findsNothing);
    await _capture(tester, 'reports-directory-desktop');
    await tester.enterText(find.byType(TextField), 'Detailed Sales');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('report-Detailed Sales')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('report-Detailed Sales')));
    await tester.pumpAndSettle();
    expect(find.byType(EnhancedReportPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [360.0, 1440.0]) {
    testWidgets('all 79 reports render at ${width.toInt()}px', (tester) async {
      await _mount(tester, const ReportsCatalogPage(), width);
      await _capture(tester, 'reports-directory-${width.toInt()}');
      for (final report in posReports) {
        await tester.pumpWidget(const SizedBox.shrink());
        final store = _ReportStore();
        await tester.pumpWidget(ChangeNotifierProvider<PosLocalStore>.value(
            value: store,
            child: MaterialApp(
                theme: buildOsposTheme(ThemeData.light().textTheme),
                home: EnhancedReportPage(
                    key: ValueKey(report.title), report: report))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: '${report.title} at $width');
        expect(find.byTooltip('Show columns'), findsOneWidget,
            reason: report.title);
        await tester.pumpWidget(const SizedBox.shrink());
        store.dispose();
      }
    });
  }

  testWidgets(
      'tables search, sort, page and export only visible matching columns',
      (tester) async {
    final report = posReports.firstWhere(
        (report) => report.data == ReportData.inventory && !report.chart);
    await _mount(tester, EnhancedReportPage(report: report), 1440);
    expect(find.byType(TrendChart), findsNothing);
    expect(
        tester.widget<DataTable>(find.byType(DataTable)).rows, hasLength(25));
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();
    expect(tester.widget<DataTable>(find.byType(DataTable)).rows, hasLength(7));
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    expect(find.text('${report.title} • 32 records'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Product 01');
    await tester.pumpAndSettle();
    expect(tester.widget<DataTable>(find.byType(DataTable)).rows, hasLength(1));
    await tester.tap(find.byTooltip('Show columns'));
    await tester.pumpAndSettle();
    final beforeColumns =
        tester.widget<DataTable>(find.byType(DataTable)).columns.length;
    final checkbox = find.byType(CheckboxListTile).first;
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    final columns =
        tester.widget<DataTable>(find.byType(DataTable)).columns.length;
    expect(columns, beforeColumns - 1);
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    expect(find.text('${report.title} • 1 record'), findsOneWidget);
    expect(find.text('JSON'), findsNothing);
    expect(find.text('Other formats'), findsOneWidget);
    await _capture(tester, 'report-export');
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.tap(find.text('Copy table'));
    await tester.pumpAndSettle();
    expect(copied!.split('\r\n'), hasLength(2));
    expect(copied!.split('\r\n').first.split(','), hasLength(columns));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'chart reports retain charts and populated tables use the shared layout',
      (tester) async {
    await _mount(tester, EnhancedReportPage(report: posReports.first), 1440);
    expect(find.byType(TrendChart), findsOneWidget);
    await _capture(tester, 'report-chart-desktop');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'dense charts with negative values keep labels within phone width',
      (tester) async {
    await _mount(
        tester,
        Scaffold(
            body: Center(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TrendChart(
                      points: List.generate(
                          40,
                          (index) => TrendPoint(
                              label: 'Long category $index',
                              value: (index - 20).toDouble(),
                              displayValue: '$index')),
                      maxValue: 19,
                    )))),
        360);
    expect(tester.takeException(), isNull);
    expect(find.byType(Tooltip).evaluate().length, lessThanOrEqualTo(8));
    await _capture(tester, 'report-dense-chart-phone');
  });
}
