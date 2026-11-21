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

part 'pdf/pdf_report_header_sections.dart';
part 'pdf/pdf_report_body_sections.dart';
part 'pdf/pdf_report_analytics.dart';
part 'pdf/pdf_report_widgets.dart';

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
