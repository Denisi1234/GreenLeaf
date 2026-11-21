import 'dart:math' as math;
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../service/expense_model.dart';
import '../../../service/pos_local_store.dart';
import '../../../service/pos_order_models.dart';
import '../../../service/report_pdf/report_pdf_layout.dart';
import '../../business_category_config.dart';
import '../models/report_models.dart';
import '../pos_report_data.dart';
import 'report_data_service.dart';

part 'pdf/pdf_report_analytics.dart';

/// Analytical sections use the same paper, header and tables as catalog exports.
class PdfReportService {
  static Future<Uint8List> generateSalesReportPdf({
    required PosLocalStore store,
    required ReportSnapshot report,
    required AppProfileData profile,
  }) async {
    final context = ReportPdfContext.fromStore(store,
        period:
            '${DateFormat('yyyy-MM-dd').format(report.startDate)} - ${DateFormat('yyyy-MM-dd').format(report.endDate)}');
    final sw = context.strings.isSwahili;
    String t(String en, String swahili) => sw ? swahili : en;
    String money(num amount) =>
        '${context.currency} ${NumberFormat('#,##0.00', context.languageCode).format(amount)}';
    final orders =
        _ordersWithinRange(store.orders, report.startDate, report.endDate);
    final previous = _previousComparableRange(report.startDate, report.endDate);
    final spending =
        _expensesWithinRange(store.expenses, report.startDate, report.endDate);
    final stats = ReportDataService.buildPdfStats(
        orders: orders,
        customers: store.customers,
        expenses: spending,
        startDate: report.startDate,
        endDate: report.endDate);
    final previousStats = ReportDataService.buildPdfStats(
        orders: _ordersWithinRange(store.orders, previous.start, previous.end),
        customers: store.customers,
        expenses:
            _expensesWithinRange(store.expenses, previous.start, previous.end),
        startDate: previous.start,
        endDate: previous.end);
    final forecast = _buildForecastSnapshot(
        report: report,
        currentStats: stats,
        previousStats: previousStats,
        store: store);
    final lowStock = lowStockItems(store).length;
    final expensesByCategory = <String, double>{};
    for (final expense in spending) {
      expensesByCategory.update(expense.category, (n) => n + expense.amount,
          ifAbsent: () => expense.amount);
    }
    final summary = sw
        ? '${context.businessName} limerekodi mauzo ya ${money(stats.revenue)} katika oda ${stats.orderCount}. '
            'Wastani wa oda ni ${money(stats.averageOrderValue)}; wateja hai ni ${stats.activeCustomers}, '
            'na waliorejea ni ${stats.returningCustomers}. Matumizi ni ${money(stats.totalExpenses)}. '
            'Bidhaa zinazohitaji ufuatiliaji wa idadi dukani ni $lowStock.'
        : _buildPdfExecutiveSummary(
            report: report,
            stats: stats,
            previousStats: previousStats,
            profile: profile,
            lowStockCount: lowStock);
    final conclusion = sw
        ? 'Mauzo ni ${money(stats.revenue)}, matumizi ni ${money(stats.totalExpenses)}, '
            'na salio la mauzo baada ya matumizi ni ${money(stats.revenue - stats.totalExpenses)}. '
            'Fuatilia bidhaa $lowStock zilizopungua na linganisha makadirio na mwenendo halisi wa mauzo.'
        : _buildPdfConclusion(report, stats, lowStock);
    List<pw.Widget> section(
            int index, String en, String swahili, ReportTable table) =>
        [
          pw.SizedBox(height: 16),
          ReportPdfLayout.sectionTitle('$index. ${t(en, swahili)}'),
          pw.SizedBox(height: 7),
          ReportPdfLayout.tableWidget(table: table, context: context),
        ];
    return ReportPdfLayout.buildDocument(
      title: t('Sales intelligence report', 'Ripoti ya uchambuzi wa mauzo'),
      context: context,
      subtitle: context.strings.text(report.periodLabel),
      body: (_) => [
        ReportPdfLayout.sectionTitle(
            t('Executive summary', 'Muhtasari wa utendaji')),
        pw.SizedBox(height: 6),
        pw.Paragraph(text: summary),
        ...section(
            1,
            'Key Performance Indicators',
            'Viashiria muhimu vya utendaji',
            ReportTable([
              ReportColumn(t('Metric', 'Kiashiria')),
              ReportColumn(t('Value', 'Thamani')),
              ReportColumn(t('Change from previous period',
                  'Mabadiliko kutoka kipindi kilichopita')),
            ], [
              [
                t('Total revenue', 'Jumla ya mapato'),
                money(stats.revenue),
                _changeLabel(stats.revenue, previousStats.revenue)
              ],
              [
                t('Completed orders', 'Oda zilizokamilika'),
                stats.orderCount,
                _changeLabel(stats.orderCount, previousStats.orderCount)
              ],
              [
                t('Average order value', 'Wastani wa thamani ya oda'),
                money(stats.averageOrderValue),
                _changeLabel(
                    stats.averageOrderValue, previousStats.averageOrderValue)
              ],
              [
                t('New customers', 'Wateja wapya'),
                stats.newCustomers,
                _changeLabel(stats.newCustomers, previousStats.newCustomers)
              ],
              [
                t('Returning customers', 'Wateja waliorudi'),
                stats.returningCustomers,
                _changeLabel(
                    stats.returningCustomers, previousStats.returningCustomers)
              ],
            ])),
        ...section(
            2,
            'Sales Trends',
            'Mwenendo wa mauzo',
            ReportTable([
              const ReportColumn('Date'),
              const ReportColumn('Revenue', money: true),
            ], [
              for (final point in report.trendPoints) [point.label, point.value]
            ])),
        ...section(
            3,
            'Top Selling Products',
            'Bidhaa zinazouzwa zaidi',
            ReportTable([
              ReportColumn(t('Product', 'Bidhaa')),
              ReportColumn(t('Sold', 'Zilizouzwa')),
              ReportColumn(t('Revenue', 'Mapato')),
            ], [
              for (final product in report.products)
                [
                  product.title,
                  context.strings.message(product.orders),
                  product.amount
                ]
            ])),
        ...section(
            4,
            'Customer Insights',
            'Tathmini ya wateja',
            ReportTable([
              ReportColumn(t('Metric', 'Kiashiria')),
              ReportColumn(t('Value', 'Thamani')),
            ], [
              [t('Active customers', 'Wateja hai'), stats.activeCustomers],
              [
                t('Returning customers', 'Wateja waliorudi'),
                stats.returningCustomers
              ],
              [t('New customers', 'Wateja wapya'), stats.newCustomers],
              [
                t('Top customer', 'Mteja anayeongoza'),
                stats.topCustomerName ?? '-'
              ],
              [
                t('Top customer sales', 'Mauzo ya mteja anayeongoza'),
                money(stats.topCustomerValue)
              ],
            ])),
        ...section(
            5,
            'Expense Analysis',
            'Uchambuzi wa matumizi',
            ReportTable([
              const ReportColumn('Category'),
              const ReportColumn('Amount', money: true),
            ], [
              for (final entry in expensesByCategory.entries)
                [entry.key, entry.value]
            ],
                note:
                    '${context.label('Total expenses')}: ${money(stats.totalExpenses)}')),
        ReportPdfLayout.metadata([
          MapEntry(context.label('Total expenses'), money(stats.totalExpenses))
        ]),
        ...section(
            6,
            'Forecast & Planning Outlook',
            'Makadirio na mipango',
            ReportTable([
              ReportColumn(t('Period', 'Kipindi')),
              ReportColumn(t('Low', 'Chini'), money: true),
              ReportColumn(t('Base', 'Msingi'), money: true),
              ReportColumn(t('High', 'Juu'), money: true),
            ], [
              [
                t('Next 7 days', 'Siku 7 zijazo'),
                forecast.nextWeekLow,
                forecast.nextWeekBase,
                forecast.nextWeekHigh
              ],
              [
                t('Next 30 days', 'Siku 30 zijazo'),
                forecast.nextMonthLow,
                forecast.nextMonthBase,
                forecast.nextMonthHigh
              ],
            ])),
        pw.SizedBox(height: 6),
        pw.Paragraph(
            text: t(
                'Projection assumes the current sales pattern, pricing, and stock availability remain broadly consistent.',
                'Makadirio yanategemea mwenendo wa sasa wa mauzo, bei na upatikanaji wa bidhaa kuendelea kwa kiasi kikubwa.')),
        pw.Paragraph(
            text: sw
                ? 'Fuatilia bidhaa zilizopungua na uwiano wa matumizi kwa mapato. Makadirio si dhamana ya mauzo yajayo.'
                : '${forecast.directionTone}. ${forecast.confidenceLabel}. ${forecast.riskNote}.'),
        pw.SizedBox(height: 16),
        ReportPdfLayout.sectionTitle(t('7. Conclusion', '7. Hitimisho')),
        pw.SizedBox(height: 6),
        pw.Paragraph(text: conclusion),
        pw.SizedBox(height: 16),
        ReportPdfLayout.sectionTitle(t('8. References', '8. Vyanzo')),
        pw.SizedBox(height: 6),
        pw.Paragraph(
            text: t(
                'Internal POS sales data, customer database, expense records, and store profile settings.',
                'Taarifa za mauzo za mfumo, rekodi za wateja, matumizi na mipangilio ya duka.')),
      ],
    );
  }

  static List<StockAlertItem> lowStockItems(PosLocalStore store) {
    final items = store.inventory
        .where((item) => item.stockCount <= 20)
        .map(
          (item) => StockAlertItem(
            name: item.name,
            category: item.category,
            stockCount: item.stockCount,
            statusLabel: item.stockCount <= 0
                ? 'Out of stock'
                : '${item.stockCount} left',
            severity: item.stockCount <= 5
                ? StockAlertSeverity.high
                : StockAlertSeverity.medium,
          ),
        )
        .toList()
      ..sort((left, right) => left.stockCount.compareTo(right.stockCount));

    return items.take(4).toList();
  }
}
