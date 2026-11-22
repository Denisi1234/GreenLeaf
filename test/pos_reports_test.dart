import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:aza_pos/service/pos_local_store.dart';
import 'package:aza_pos/service/pos_order_models.dart';
import 'package:aza_pos/ui/models/product_item.dart';
import 'package:aza_pos/ui/reports/pos_report_catalog.dart';
import 'package:aza_pos/ui/reports/pos_report_data.dart';
import 'package:aza_pos/ui/reports/advanced_reports_page.dart';

void main() {
  final data = PosReportData(
    orders: [
      _order('cash', '2026-11-09T23:59:00', 'Cash', unitCost: 30),
      _order('credit', '2026-11-10T00:00:00', 'Credit'),
    ],
    inventory: const [],
    expenses: const [],
    customers: const [],
  );

  test('all data-backed catalog entries return consistent table columns', () {
    expect(posReports.length, greaterThanOrEqualTo(50));
    expect(posReports.map((report) => report.title).toSet(),
        hasLength(posReports.length));
    for (final report
        in posReports.where((report) => report.missingData == null)) {
      final table = data.build(report.data);
      for (final row in table.rows) {
        expect(row, hasLength(table.columns.length), reason: report.title);
      }
      if (report.chart) {
        expect(table.chartColumn, isNotNull, reason: report.title);
      }
    }
  });

  test('inclusive dates, net item sales, and historical costs agree', () {
    final date = DateTime(2026, 11, 9);
    final items = data.build(ReportData.items, start: date, end: date);
    expect(items.rows.single, ['Tea', 'T1', 2, 150, 60, 90]);

    final combined = data.build(ReportData.items);
    expect(combined.rows.single, ['Tea', 'T1', 4, 300, null, null]);

    final discounts = data.build(ReportData.discounts);
    expect(discounts.rows.single, ['Unlabelled discount', 2, 100, 300]);
  });

  test('credit sales are separated from cash collected', () {
    final payments = data.build(ReportData.payments);
    expect(payments.rows, [
      ['Cash', 1, 150, 0],
      ['Credit', 1, 0, 150],
    ]);
  });

  test('store profit reports one default store', () {
    final report = data.build(ReportData.location);
    expect(report.rows.single, ['Default Store', 2, 4, 300, null, null]);
  });

  testWidgets('catalog search opens live reports and empty-state guidance',
      (tester) async {
    final store = PosLocalStore();
    await tester.runAsync(() => store.setLanguageCode('en'));
    addTearDown(store.dispose);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: store,
      child: const MaterialApp(home: AdvancedReportsPage()),
    ));

    await tester.enterText(find.byType(TextField), 'Detailed Sales');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'Detailed Sales').last);
    await tester.pumpAndSettle();
    expect(find.text('No activity recorded yet'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Detailed Receivings');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(InkWell, 'Detailed Receivings').last);
    await tester.pumpAndSettle();
    expect(
        find.text(
            'No goods received yet. Record deliveries to build purchase history.'),
        findsOneWidget);
  });
}

CompletedOrder _order(String id, String date, String payment,
    {double? unitCost}) {
  return CompletedOrder(
    id: id,
    dateTime: date,
    date: date,
    time: '',
    total: 150,
    status: 'Completed',
    cashierName: 'Cashier',
    register: 'POS-01',
    paymentMethod: payment,
    cashTendered: payment == 'Cash' ? 150 : 0,
    changeDue: 0,
    lines: [
      OrderLine(
        itemCode: 'T1',
        itemCategory: 'Drinks',
        itemName: 'Tea',
        itemSize: '1 pack',
        quantity: 2,
        unitPrice: 'TSH 100',
        unitPriceValue: 100,
        unitCost: unitCost,
        artType: ProductArtType.aquafina,
        imagePath: null,
      ),
    ],
  );
}
