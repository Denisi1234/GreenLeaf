import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../service/expense_model.dart';
import '../../../service/pos_local_store.dart';
import '../../../service/pos_order_models.dart';
import '../../business_category_config.dart';
import '../models/report_models.dart';
import 'report_data_service.dart';

class PdfReportService {
  static Future<Uint8List> generateSalesReportPdf({
    required PosLocalStore store,
    required ReportSnapshot report,
    required AppProfileData profile,
  }) async {
    final pdf = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final logoImage = await _loadPdfLogoImage(profile);
    final generatedAt = DateTime.now();

    final currentOrders =
        _ordersWithinRange(store.orders, report.startDate, report.endDate);
    final previousRange =
        _previousComparableRange(report.startDate, report.endDate);
    final previousOrders = _ordersWithinRange(
      store.orders,
      previousRange.start,
      previousRange.end,
    );
    final currentExpenses = _expensesWithinRange(
      store.expenses,
      report.startDate,
      report.endDate,
    );
    final previousExpenses = _expensesWithinRange(
      store.expenses,
      previousRange.start,
      previousRange.end,
    );
    final currentStats = ReportDataService.buildPdfStats(
      orders: currentOrders,
      customers: store.customers,
      expenses: currentExpenses,
      startDate: report.startDate,
      endDate: report.endDate,
    );
    final previousStats = ReportDataService.buildPdfStats(
      orders: previousOrders,
      customers: store.customers,
      expenses: previousExpenses,
      startDate: previousRange.start,
      endDate: previousRange.end,
    );
    final reportTitle = _reportTitleFor(report);
    final executiveSummary = _buildPdfExecutiveSummary(
      report: report,
      stats: currentStats,
      previousStats: previousStats,
      profile: profile,
      lowStockCount: lowStockItems(store).length,
    );
    final forecast = _buildForecastSnapshot(
      report: report,
      currentStats: currentStats,
      previousStats: previousStats,
      store: store,
    );
    final conclusion = _buildPdfConclusion(
      report,
      currentStats,
      lowStockItems(store).length,
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(24, 20, 24, 26),
          theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        ),
        header: (context) => context.pageNumber == 1
            ? pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: _pdfReportHeader(
                  reportTitle: reportTitle,
                  report: report,
                  profile: profile,
                  logoImage: logoImage,
                ),
              )
            : pw.SizedBox(height: 0),
        build: (context) => [
          _pdfIntroSection(
            executiveSummary,
            report,
            currentStats,
            previousStats,
          ),
          pw.SizedBox(height: 12),
          _pdfHighlightsSection(report, currentStats, previousStats, store),
          pw.SizedBox(height: 12),
          _pdfSectionDivider(),
          _pdfSectionTitle('1. Key Performance Indicators'),
          pw.SizedBox(height: 8),
          _pdfKpiTable(currentStats, previousStats),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('2. Sales Trends'),
          pw.SizedBox(height: 8),
          _pdfSalesTrendSection(report, currentStats),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('3. Top Selling Products'),
          pw.SizedBox(height: 8),
          _pdfProductTable(report.products),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('4. Customer Insights'),
          pw.SizedBox(height: 8),
          _pdfCustomerInsightsSection(currentOrders, store, currentStats),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('5. Expense Analysis'),
          pw.SizedBox(height: 8),
          _pdfExpenseAnalysisSection(currentExpenses),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('6. Forecast & Planning Outlook'),
          pw.SizedBox(height: 8),
          _pdfForecastSection(forecast),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('7. Conclusion'),
          pw.SizedBox(height: 8),
          _pdfConclusionSection(conclusion),
          pw.SizedBox(height: 14),
          _pdfSectionDivider(),
          _pdfSectionTitle('8. References'),
          pw.SizedBox(height: 8),
          _pdfReferencesSection(report),
        ],
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                _formatPdfDateTime(generatedAt),
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                '${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  static Future<pw.ImageProvider?> _loadPdfLogoImage(AppProfileData profile) async {
    final path = profile.logoPath?.trim();
    if (path == null || path.isEmpty) return null;

    try {
      final file = File(path);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static String _reportTitleFor(ReportSnapshot report) {
    if (report.periodLabel == 'This Month') {
      return '${report.category.displayName} Intelligence Report - ${_monthYearLabel(report.endDate)}';
    }
    if (report.periodLabel == 'Today') {
      return '${report.category.displayName} Intelligence Report - ${_dateLabel(report.endDate)}';
    }
    if (report.periodLabel == 'This Week') {
      return '${report.category.displayName} Intelligence Report - ${_dateLabel(report.startDate)} - ${_dateLabel(report.endDate)}';
    }
    return '${report.category.displayName} Intelligence Report - ${report.dateRangeLabel}';
  }

  static pw.Widget _pdfReportHeader({
    required String reportTitle,
    required ReportSnapshot report,
    required AppProfileData profile,
    required pw.ImageProvider? logoImage,
  }) {
    final storeName =
        profile.storeName.trim().isEmpty ? 'Store report' : profile.storeName;

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor.fromHex('#DDE4EE'),
          width: 0.8,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logoImage != null) ...[
            pw.Container(
              width: 56,
              height: 56,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F3F6FB'),
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColor.fromHex('#DDE4EE')),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 12,
                verticalRadius: 12,
                child: pw.Image(logoImage, fit: pw.BoxFit.cover),
              ),
            ),
            pw.SizedBox(width: 12),
          ] else ...[
            pw.Container(
              width: 56,
              height: 56,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#EAF1FF'),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Center(
                child: pw.Text(
                  storeName.isNotEmpty ? storeName[0].toUpperCase() : 'R',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#1E67E8'),
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
            pw.SizedBox(width: 12),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  storeName,
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#0F172A'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  reportTitle,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1E67E8'),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  report.dateRangeLabel,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Prepared for management review',
                  style: const pw.TextStyle(
                    fontSize: 8.8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColor.fromHex('#DDE4EE')),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  report.periodLabel,
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#334155'),
                    fontSize: 10.2,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '${report.category.displayName} intelligence brief',
                  style: const pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfIntroSection(
    String executiveSummary,
    ReportSnapshot report,
    PdfReportStats currentStats,
    PdfReportStats previousStats,
  ) {
    final revenueDelta =
        _changeLabel(currentStats.revenue, previousStats.revenue);
    final orderDelta =
        _changeLabel(currentStats.orderCount, previousStats.orderCount);
    final margin = currentStats.revenue - currentStats.totalExpenses;
    final marginLabel =
        margin >= 0 ? _moneyLabel(margin) : '-${_moneyLabel(margin.abs())}';
    final marginTone = margin >= 0 ? 'Healthy' : 'Under pressure';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E6EBF2'),
          width: 0.7,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${report.category.displayName} management summary',
            style: pw.TextStyle(
              fontSize: 13.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            executiveSummary,
            style: const pw.TextStyle(
              fontSize: 10.2,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _pdfIntroStat(
                  'Revenue shift',
                  revenueDelta,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _pdfIntroStat(
                  'Orders',
                  orderDelta,
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _pdfIntroStat(
                  'Margin',
                  '$marginTone $marginLabel',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfIntroStat(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2'), width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 7.8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.4,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 13.5,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#0F172A'),
      ),
    );
  }

  static pw.Widget _pdfSectionDivider() {
    return pw.Container(
      height: 1,
      margin: const pw.EdgeInsets.only(top: 2),
      color: PdfColor.fromHex('#EEF3F8'),
    );
  }

  static pw.Widget _pdfKpiTable(
    PdfReportStats currentStats,
    PdfReportStats previousStats,
  ) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        children: [
          _pdfTableCell('Metric', bold: true),
          _pdfTableCell('Value', bold: true),
          _pdfTableCell('Change from Previous', bold: true),
        ],
      ),
      _pdfKpiRow(
        'Total Revenue',
        _moneyLabel(currentStats.revenue),
        _changeLabel(currentStats.revenue, previousStats.revenue),
      ),
      _pdfKpiRow(
        'Total Orders',
        currentStats.orderCount.toString(),
        _changeLabel(currentStats.orderCount, previousStats.orderCount),
      ),
      _pdfKpiRow(
        'Average Order Value',
        _moneyLabel(currentStats.averageOrderValue),
        _changeLabel(
          currentStats.averageOrderValue,
          previousStats.averageOrderValue,
        ),
      ),
      _pdfKpiRow(
        'New Customers',
        currentStats.newCustomers.toString(),
        _changeLabel(currentStats.newCustomers, previousStats.newCustomers),
      ),
      _pdfKpiRow(
        'Returning Customers',
        currentStats.returningCustomers.toString(),
        _changeLabel(
          currentStats.returningCustomers,
          previousStats.returningCustomers,
        ),
      ),
    ];

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromHex('#EDF2F7'),
        width: 0.35,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.5),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2.2),
      },
      children: rows,
    );
  }

  static pw.TableRow _pdfKpiRow(
    String label,
    String value,
    String change,
  ) {
    return pw.TableRow(
      children: [
        _pdfTableCell(label),
        _pdfTableCell(value),
        _pdfTableCell(change),
      ],
    );
  }

  static pw.Widget _pdfSalesTrendSection(
    ReportSnapshot report,
    PdfReportStats stats,
  ) {
    final firstPoint =
        report.trendPoints.isNotEmpty ? report.trendPoints.first : null;
    final lastPoint =
        report.trendPoints.isNotEmpty ? report.trendPoints.last : null;
    final peakPoint = report.trendPoints.isEmpty
        ? null
        : report.trendPoints.reduce(
            (a, b) => a.value >= b.value ? a : b,
          );
    final averageTrend = report.trendPoints.isEmpty
        ? 0.0
        : report.trendPoints.fold<double>(
              0,
              (sum, point) => sum + point.value,
            ) /
            report.trendPoints.length;
    final direction = firstPoint == null || lastPoint == null
        ? 'The period does not have enough sales activity for a directional trend.'
        : lastPoint.value >= firstPoint.value
            ? 'Revenue closed stronger than it started, which suggests sales momentum improved over the selected period.'
            : 'Revenue ended below its starting point, suggesting a softer close to the selected period.';

    final peakText = peakPoint == null
        ? 'No completed sales were recorded in the period.'
        : 'The highest revenue day was ${peakPoint.label} at ${peakPoint.displayValue}.';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E6EBF2'),
          width: 0.7,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Sales revenue showed ${_trendDirectionWord(firstPoint, lastPoint)} across the selected period. $peakText',
            style: const pw.TextStyle(
              fontSize: 10.2,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Average daily revenue: ${_moneyLabel(averageTrend)}',
            style: const pw.TextStyle(
              fontSize: 9.8,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            direction,
            style: const pw.TextStyle(
              fontSize: 10.2,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#EDF2F7'),
              width: 0.35,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.5),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                children: [
                  _pdfTableCell('Date', bold: true),
                  _pdfTableCell('Revenue', bold: true),
                ],
              ),
              ...report.trendPoints.map(
                (point) => pw.TableRow(
                  children: [
                    _pdfTableCell(point.label),
                    _pdfTableCell(point.displayValue),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfCustomerInsightsSection(
    List<CompletedOrder> orders,
    PosLocalStore store,
    PdfReportStats stats,
  ) {
    final activeCustomerNames = orders
        .map((order) => order.customerName?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet();
    final activeCustomers = activeCustomerNames.length;
    final repeatCustomers = orders
        .where((order) => (order.customerName ?? '').trim().isNotEmpty)
        .fold<Map<String, int>>({}, (map, order) {
          final name = order.customerName!.trim();
          map[name] = (map[name] ?? 0) + 1;
          return map;
        })
        .values
        .where((count) => count > 1)
        .length;
    final customerStats = store.customerStats();
    final topCustomerName = customerStats['topName'] as String?;
    final topCustomerValue =
        (customerStats['topValue'] as num?)?.toDouble() ?? 0.0;
    final createdThisPeriod = store.customers
        .where((customer) =>
            !customer.createdAt.isBefore(stats.startDate) &&
            !customer.createdAt
                .isAfter(stats.endDate.add(const Duration(days: 1))))
        .length;

    final insight = topCustomerName == null || topCustomerName.trim().isEmpty
        ? 'Customer records are present, but there is no clear top customer yet.'
        : '$topCustomerName generated ${_moneyLabel(topCustomerValue)} in lifetime sales, which makes them a valuable repeat-buyer to keep engaged.';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E6EBF2'),
          width: 0.7,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Customer activity remained at $activeCustomers active customer${activeCustomers == 1 ? '' : 's'} in this period, with $repeatCustomers repeat buyer${repeatCustomers == 1 ? '' : 's'} and $createdThisPeriod newly registered customer${createdThisPeriod == 1 ? '' : 's'}.',
            style: const pw.TextStyle(
              fontSize: 10.2,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            insight,
            style: const pw.TextStyle(
              fontSize: 10.0,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#EDF2F7'),
              width: 0.35,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.7),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                children: [
                  _pdfTableCell('Customer insight', bold: true),
                  _pdfTableCell('Value', bold: true),
                ],
              ),
              _pdfTableRow(
                  'Registered customers', store.customers.length.toString()),
              _pdfTableRow('Active customers', activeCustomers.toString()),
              _pdfTableRow('Returning customers', repeatCustomers.toString()),
              _pdfTableRow(
                'Top customer',
                topCustomerName == null || topCustomerName.trim().isEmpty
                    ? 'Not available'
                    : '$topCustomerName (${_moneyLabel(topCustomerValue)})',
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Customer loyalty continues to matter because repeat buyers reduce acquisition pressure and usually respond well to small reminders, bundles, or limited-time offers.',
            style: const pw.TextStyle(
              fontSize: 10.0,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  static pw.TableRow _pdfTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        _pdfTableCell(label),
        _pdfTableCell(value),
      ],
    );
  }

  static pw.Widget _pdfExpenseAnalysisSection(List<Expense> expenses) {
    final total =
        expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final categories = <String, double>{};
    for (final expense in expenses) {
      categories[expense.category] =
          (categories[expense.category] ?? 0) + expense.amount;
    }
    final topCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topExpense = topCategories.isEmpty ? null : topCategories.first;

    final expenseSummary = total <= 0
        ? 'No expenses were recorded in the selected period.'
        : 'Total expenses for the selected period were ${_moneyLabel(total)}. Inventory, rent, and utilities should be monitored closely because they usually take the largest share of operating cost.';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E6EBF2'),
          width: 0.7,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            expenseSummary,
            style: const pw.TextStyle(
              fontSize: 10.2,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#E3EAF2'),
              width: 0.45,
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(2.4),
              1: pw.FlexColumnWidth(1.6),
              2: pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                children: [
                  _pdfTableCell('Category', bold: true),
                  _pdfTableCell('Amount', bold: true),
                  _pdfTableCell('% of total', bold: true),
                ],
              ),
              ...topCategories.map(
                (entry) => pw.TableRow(
                  children: [
                    _pdfTableCell(entry.key),
                    _pdfTableCell(_moneyLabel(entry.value)),
                    _pdfTableCell(
                      total <= 0
                          ? '0%'
                          : '${((entry.value / total) * 100).toStringAsFixed(0)}%',
                    ),
                  ],
                ),
              ),
              pw.TableRow(
                children: [
                  _pdfTableCell('Total expenses', bold: true),
                  _pdfTableCell(_moneyLabel(total), bold: true),
                  _pdfTableCell('100%', bold: true),
                ],
              ),
            ],
          ),
          if (topExpense != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(
              'Largest category: ${topExpense.key} at ${_moneyLabel(topExpense.value)}.',
              style: const pw.TextStyle(
                fontSize: 10.0,
                color: PdfColors.grey800,
                lineSpacing: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _pdfConclusionSection(String conclusion) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E6EBF2'),
          width: 0.7,
        ),
      ),
      child: pw.Text(
        conclusion,
        style: const pw.TextStyle(
          fontSize: 10.2,
          color: PdfColors.grey800,
          lineSpacing: 4,
        ),
      ),
    );
  }

  static pw.Widget _pdfReferencesSection(ReportSnapshot report) {
    final reportLabel = report.dateRangeLabel;
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E6EBF2'),
          width: 0.7,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _pdfBullet('Internal POS Sales Data - $reportLabel'),
          pw.SizedBox(height: 4),
          _pdfBullet('Internal Customer Database - $reportLabel'),
          pw.SizedBox(height: 4),
          _pdfBullet('Internal Expense Records - $reportLabel'),
          pw.SizedBox(height: 4),
          _pdfBullet('Store profile and branding settings inside the app'),
        ],
      ),
    );
  }

  static String _trendDirectionWord(
    TrendPoint? firstPoint,
    TrendPoint? lastPoint,
  ) {
    if (firstPoint == null || lastPoint == null) {
      return 'limited movement';
    }
    if (lastPoint.value > firstPoint.value) return 'a positive momentum';
    if (lastPoint.value < firstPoint.value) return 'a softer finish';
    return 'steady movement';
  }

  static String _buildPdfExecutiveSummary({
    required ReportSnapshot report,
    required PdfReportStats stats,
    required PdfReportStats previousStats,
    required AppProfileData profile,
    required int lowStockCount,
  }) {
    final storeName = profile.storeName.trim().isEmpty
        ? 'The store'
        : profile.storeName.trim();
    final focus = _categoryFocusSentence(report.category);
    final revenueChange = _changeLabel(stats.revenue, previousStats.revenue);
    final orderChange =
        _changeLabel(stats.orderCount, previousStats.orderCount);
    final margin = stats.revenue - stats.totalExpenses;
    final expenseRatio =
        stats.revenue <= 0 ? 0.0 : (stats.totalExpenses / stats.revenue) * 100;
    final topProduct = report.products.isNotEmpty
        ? 'The top selling product was ${report.products.first.title}.'
        : 'No completed sales were recorded in the selected period.';
    final lowStockText = lowStockCount == 0
        ? 'No inventory items are currently in the low-stock watchlist.'
        : '$lowStockCount inventory item${lowStockCount == 1 ? '' : 's'} are now in the low-stock watchlist.';
    final marginText = margin >= 0
        ? 'The period closed with a positive margin of ${_moneyLabel(margin)}.'
        : 'The period closed with a negative margin of ${_moneyLabel(margin.abs())}, which means expenses outpaced revenue.';

    return '$storeName recorded ${_moneyLabel(stats.revenue)} across ${stats.orderCount} completed orders during ${report.dateRangeLabel}. '
        '$focus '
        'Revenue changed by $revenueChange while order volume changed by $orderChange compared with the previous comparable period. '
        'Average order value was ${_moneyLabel(stats.averageOrderValue)}, with ${stats.activeCustomers} active customer${stats.activeCustomers == 1 ? '' : 's'} and ${stats.returningCustomers} repeat buyer${stats.returningCustomers == 1 ? '' : 's'}. '
        '$marginText Expenses consumed ${expenseRatio.toStringAsFixed(0)}% of revenue, which puts the business in ${expenseRatio > 70 ? 'a pressure zone' : 'a manageable zone'}. '
        '$lowStockText $topProduct';
  }

  static String _categoryFocusSentence(BusinessCategory category) {
    return switch (category) {
      BusinessCategory.pharmacy =>
        'This report emphasizes expiry control, prescription demand, and margin protection for medicine sales.',
      BusinessCategory.electronics =>
        'This report emphasizes high-value devices, warranty readiness, and brand performance across the catalog.',
      BusinessCategory.retail =>
        'This report emphasizes basket size, fast-moving stock, markdown pressure, and reorder timing for store-floor decisions.',
    };
  }

  static String _buildPdfConclusion(
    ReportSnapshot report,
    PdfReportStats stats,
    int lowStockCount,
  ) {
    final revenue = _moneyLabel(stats.revenue);
    final expenses = _moneyLabel(stats.totalExpenses);
    final margin = stats.revenue - stats.totalExpenses;
    final marginLabel = _moneyLabel(margin.abs());
    final marginText = margin >= 0 ? 'profit cushion' : 'cost pressure';
    final inventoryText = lowStockCount == 0
        ? 'Inventory levels are currently stable across the low-stock watchlist.'
        : '$lowStockCount low-stock item${lowStockCount == 1 ? '' : 's'} deserve immediate restocking attention.';

    return '${report.category.displayName} reporting for ${report.dateRangeLabel} showed a fuller business picture than revenue alone. Revenue closed at $revenue, expenses totaled $expenses, and the net position reflected a $marginText of $marginLabel. '
        '$inventoryText The forecast section below highlights near-term demand momentum, stock pressure, and margin protection opportunities.';
  }

  static ForecastSnapshot _buildForecastSnapshot({
    required ReportSnapshot report,
    required PdfReportStats currentStats,
    required PdfReportStats previousStats,
    required PosLocalStore store,
  }) {
    final periodDays = math.max(
      1,
      report.endDate.difference(report.startDate).inDays + 1,
    );
    final averageDailyRevenue = currentStats.revenue / periodDays;
    final revenueChangeRatio = _safeRatio(
      currentStats.revenue,
      previousStats.revenue,
      positiveFallback: 0.12,
    );
    final orderChangeRatio = _safeRatio(
      currentStats.orderCount.toDouble(),
      previousStats.orderCount.toDouble(),
      positiveFallback: 0.08,
    );
    final trendBias = _trendBias(report.trendPoints);
    final momentum = (1 +
            (revenueChangeRatio * 0.35) +
            (orderChangeRatio * 0.15) +
            (trendBias * 0.25))
        .clamp(0.75, 1.35)
        .toDouble();

    final weekBase = averageDailyRevenue * 7 * momentum;
    final monthBase = averageDailyRevenue * 30 * momentum;
    final volatility = math.min(
      0.22,
      0.12 +
          (report.trendPoints.length < 4 ? 0.06 : 0.0) +
          (revenueChangeRatio.abs() * 0.05),
    );
    final monthVolatility = math.min(0.28, volatility + 0.05);
    final lowStockCount = lowStockItems(store).length;
    final expenseRatio = currentStats.revenue <= 0
        ? 0.0
        : (currentStats.totalExpenses / currentStats.revenue) * 100;

    final directionTone = momentum > 1.08
        ? 'Upward momentum'
        : momentum < 0.94
            ? 'Softening momentum'
            : 'Stable momentum';
    final confidenceLabel = report.trendPoints.length >= 7
        ? 'Moderate confidence'
        : 'Directional estimate';

    final riskParts = <String>[];
    if (lowStockCount > 0) {
      riskParts.add(
        '$lowStockCount low-stock item${lowStockCount == 1 ? '' : 's'} may restrict growth',
      );
    }
    if (expenseRatio > 70) {
      riskParts.add(
        'expenses are taking ${expenseRatio.toStringAsFixed(0)}% of revenue',
      );
    }
    if (riskParts.isEmpty) {
      riskParts.add('operating conditions are relatively balanced');
    }
    riskParts.add(_forecastCategoryHint(report.category));

    return ForecastSnapshot(
      nextWeekBase: weekBase,
      nextWeekLow: weekBase * (1 - volatility),
      nextWeekHigh: weekBase * (1 + volatility),
      nextMonthBase: monthBase,
      nextMonthLow: monthBase * (1 - monthVolatility),
      nextMonthHigh: monthBase * (1 + monthVolatility),
      directionTone: directionTone,
      confidenceLabel: confidenceLabel,
      riskNote: riskParts.join(', '),
    );
  }

  static double _safeRatio(
    double current,
    double previous, {
    required double positiveFallback,
  }) {
    if (previous == 0) {
      if (current <= 0) return 0.0;
      return positiveFallback;
    }
    return (current - previous) / previous;
  }

  static double _trendBias(List<TrendPoint> points) {
    if (points.length < 2) return 0.0;
    final first = points.first.value;
    final last = points.last.value;
    if (first <= 0) {
      return last > 0 ? 0.12 : 0.0;
    }
    return ((last - first) / first).clamp(-0.25, 0.25).toDouble();
  }

  static String _forecastCategoryHint(BusinessCategory category) {
    return switch (category) {
      BusinessCategory.pharmacy =>
        'Expiry and prescription demand are the main near-term forecast risks.',
      BusinessCategory.electronics =>
        'Warranty registration and premium device mix drive the forecast band.',
      BusinessCategory.retail =>
        'Demand should stay anchored around basket size, fast movers, and markdown activity.',
    };
  }

  static List<CompletedOrder> _ordersWithinRange(
    List<CompletedOrder> orders,
    DateTime start,
    DateTime end,
  ) {
    return orders.where((order) {
      final orderDate = DateTime.tryParse(order.dateTime);
      if (orderDate == null) return false;
      final day = DateTime(orderDate.year, orderDate.month, orderDate.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();
  }

  static List<Expense> _expensesWithinRange(
    List<Expense> expenses,
    DateTime start,
    DateTime end,
  ) {
    return expenses.where((expense) {
      final day =
          DateTime(expense.date.year, expense.date.month, expense.date.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();
  }

  static ReportRange _previousComparableRange(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    final previousEnd = start.subtract(const Duration(days: 1));
    final previousStart = previousEnd.subtract(Duration(days: days - 1));
    return ReportRange(
      start: previousStart,
      end: previousEnd,
      label: '${_dateLabel(previousStart)} - ${_dateLabel(previousEnd)}',
    );
  }

  static String _changeLabel(num current, num previous) {
    if (previous == 0) {
      if (current == 0) return '0%';
      return '+100% vs previous';
    }
    final change = ((current - previous) / previous) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.abs().toStringAsFixed(change.abs() >= 10 ? 0 : 1)}% vs previous';
  }

  static String _monthYearLabel(DateTime date) {
    const monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  static String _dateLabel(DateTime date) {
    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String _formatPdfDateTime(DateTime dateTime) {
    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${monthNames[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} '
        '$hour:$minute $amPm';
  }

  static String _moneyLabel(double amount) {
    return 'TSH ${_formatWithCommas(amount)}';
  }

  static String _formatWithCommas(num value) {
    final fixed = value.toStringAsFixed(0);
    return fixed.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  static pw.Widget _pdfBullet(String text) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 5,
          height: 5,
          margin: const pw.EdgeInsets.only(top: 5.5),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#1E67E8'),
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            text,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _pdfHighlightsSection(
    ReportSnapshot report,
    PdfReportStats currentStats,
    PdfReportStats previousStats,
    PosLocalStore store,
  ) {
    final topProduct =
        report.products.isNotEmpty ? report.products.first : null;
    final revenueChange =
        _changeLabel(currentStats.revenue, previousStats.revenue);
    final average = _moneyLabel(currentStats.averageOrderValue);
    final margin = currentStats.revenue - currentStats.totalExpenses;
    final expenseRatio = currentStats.revenue <= 0
        ? 0.0
        : (currentStats.totalExpenses / currentStats.revenue) * 100;
    final lowStockCount = lowStockItems(store).length;
    final topProductText = topProduct == null
        ? 'No completed sales were recorded in this period.'
        : '${topProduct.title} led the period with ${topProduct.orders} and ${topProduct.amount} revenue, which suggests a clear demand concentration.';
    final expenseText = currentStats.totalExpenses <= 0
        ? 'No expenses were recorded during this period.'
        : 'Expenses used ${expenseRatio.toStringAsFixed(0)}% of revenue, leaving a ${margin >= 0 ? 'positive' : 'negative'} margin of ${_moneyLabel(margin.abs())}.';
    final stockText = lowStockCount == 0
        ? 'No items are in the low-stock watchlist right now.'
        : '$lowStockCount item${lowStockCount == 1 ? '' : 's'} need restocking attention before the next sales push.';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2'), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${report.category.displayName} intelligence signals',
            style: pw.TextStyle(
              fontSize: 13.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 8),
          _pdfBullet(
            'Revenue changed by $revenueChange across ${currentStats.orderCount} completed orders, with an average order value of $average.',
          ),
          pw.SizedBox(height: 5),
          _pdfBullet(topProductText),
          pw.SizedBox(height: 5),
          _pdfBullet(
            expenseText,
          ),
          pw.SizedBox(height: 5),
          _pdfBullet(
            stockText,
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfForecastSection(ForecastSnapshot forecast) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2'), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Forecast outlook',
            style: pw.TextStyle(
              fontSize: 13.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Projection assumes the current sales pattern, pricing, and stock availability remain broadly consistent.',
            style: const pw.TextStyle(
              fontSize: 9.8,
              color: PdfColors.grey700,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _pdfForecastCard(
                  title: 'Next 7 days',
                  amount: forecast.nextWeekBase,
                  low: forecast.nextWeekLow,
                  high: forecast.nextWeekHigh,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _pdfForecastCard(
                  title: 'Next 30 days',
                  amount: forecast.nextMonthBase,
                  low: forecast.nextMonthLow,
                  high: forecast.nextMonthHigh,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          _pdfBullet(
            'Direction signal: ${forecast.directionTone}. Confidence: ${forecast.confidenceLabel}.',
          ),
          pw.SizedBox(height: 5),
          _pdfBullet(
            'Risk watch: ${forecast.riskNote}.',
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfForecastCard({
    required String title,
    required double amount,
    required double low,
    required double high,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2'), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            _moneyLabel(amount),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Range: ${_moneyLabel(low)} - ${_moneyLabel(high)}',
            style: const pw.TextStyle(
              fontSize: 9.4,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfProductTable(List<ProductData> products) {
    return pw.Table(
      border: pw.TableBorder.symmetric(
        inside: pw.BorderSide(color: PdfColor.fromHex('#E6EBF2'), width: 0.7),
        outside: pw.BorderSide(color: PdfColor.fromHex('#E6EBF2'), width: 0.7),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8F9FB')),
          children: [
            _pdfTableCell('Product', bold: true),
            _pdfTableCell('Sold', bold: true),
            _pdfTableCell('Revenue', bold: true),
          ],
        ),
        ...products.map(
          (product) => pw.TableRow(
            children: [
              _pdfTableCell(product.title),
              _pdfTableCell(product.orders),
              _pdfTableCell(product.amount),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _pdfTableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
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