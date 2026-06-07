import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../service/duka_ai_service.dart';
import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../models/product_item.dart';
import '../widgets/market_shared_widgets.dart';

// ignore_for_file: unused_element

enum _ReportPeriod { today, week, month, allTime }

extension _ReportPeriodLabel on _ReportPeriod {
  String get label {
    switch (this) {
      case _ReportPeriod.today:
        return 'Today';
      case _ReportPeriod.week:
        return 'This Week';
      case _ReportPeriod.month:
        return 'This Month';
      case _ReportPeriod.allTime:
        return 'All Time';
    }
  }

  String get shortLabel {
    switch (this) {
      case _ReportPeriod.today:
        return 'Today';
      case _ReportPeriod.week:
        return 'Week';
      case _ReportPeriod.month:
        return 'Month';
      case _ReportPeriod.allTime:
        return 'All';
    }
  }
}

String _kLabel(num value) {
  if (value <= 0) return '0K';
  final thousands = value.toDouble() / 1000;
  return '${thousands.round()}K';
}

class ReportHubPage extends StatefulWidget {
  const ReportHubPage({super.key});

  static const MethodChannel _shareChannel =
      MethodChannel('possystem/report_share');

  static const Color _bg = Color(0xFFF7FAFC);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF667085);
  static const Color _border = Color(0xFFE6EBF2);
  static const Color _blue = Color(0xFF1E67E8);
  static const Color _green = Color(0xFF169B4A);
  static const Color _purple = Color(0xFF8E3ED8);

  @override
  State<ReportHubPage> createState() => _ReportHubPageState();
}

class _ReportHubPageState extends State<ReportHubPage> {
  bool _isDownloading = false;
  _ReportPeriod _selectedPeriod = _ReportPeriod.week;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final report = _buildReportSnapshot(store.orders, _selectedPeriod);
    final baseTheme = Theme.of(context);
    final theme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: ReportHubPage._bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  onBackTap: () => Navigator.of(context).maybePop(),
                  onDownloadTap: () => _downloadReport(context),
                  isDownloading: _isDownloading,
                ),
                const SizedBox(height: 12),
                _RangeCard(
                  dateRange: report.dateRangeLabel,
                  periodLabel: _selectedPeriod.shortLabel,
                  onPeriodSelected: (period) {
                    setState(() => _selectedPeriod = period);
                  },
                ),
                const SizedBox(height: 12),
                _MetricGrid(metrics: report.metrics),
                const SizedBox(height: 10),
                Expanded(
                  flex: 2,
                  child: _SectionCard(
                    title: 'Sales Trend',
                    trailing: const SizedBox.shrink(),
                    child: Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _SalesTrendChart(
                          points: report.trendPoints,
                          maxValue: report.chartMaxValue,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 1,
                  child: _SectionCard(
                    title: 'Top Selling Products',
                    trailing: const _LinkAction(label: 'View All'),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _TopSellingProductsList(
                        products: report.products,
                        emptyMessage: 'No completed sales in this period.',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadReport(BuildContext context) async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    Uint8List? pdfBytes;
    final fileName = _reportFileName();
    final store = context.read<PosLocalStore>();
    final report = _buildReportSnapshot(store.orders, _selectedPeriod);
    try {
      final aiSummary = await _buildAiExecutiveSummary(store, report);
      pdfBytes = await _buildSalesReportPdfBytes(
        report,
        aiSummary,
        store.profile,
      );
      final shared = await _shareReportPdf(pdfBytes, fileName);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shared
                ? 'Share sheet opened for $fileName'
                : 'Share dialog unavailable on this device.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not share report: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  _ReportSnapshot _buildReportSnapshot(
    List<CompletedOrder> orders,
    _ReportPeriod period,
  ) {
    final range = _resolveReportRange(orders, period);

    final ordersInRange = orders.where((order) {
      final orderDate = DateTime.tryParse(order.dateTime);
      if (orderDate == null) return false;
      final day = DateTime(orderDate.year, orderDate.month, orderDate.day);
      return !day.isBefore(range.start) && !day.isAfter(range.end);
    }).toList();

    final dailyRevenue = <DateTime, double>{};
    final productTally = <String, _ProductTally>{};

    for (final order in ordersInRange) {
      final orderDate = DateTime.tryParse(order.dateTime);
      if (orderDate == null) continue;
      final day = DateTime(orderDate.year, orderDate.month, orderDate.day);
      dailyRevenue[day] = (dailyRevenue[day] ?? 0) + order.total;

      for (final line in order.lines) {
        final key = line.itemCode?.trim().isNotEmpty == true
            ? line.itemCode!.trim()
            : line.itemName.trim();
        final current = productTally.putIfAbsent(
          key,
          () => _ProductTally(
            title: line.itemName,
            quantity: 0,
            revenue: 0,
            icon: _iconForLine(line),
            colors: _colorsForLine(line),
          ),
        );
        current.quantity += line.quantity;
        current.revenue += line.lineTotal;
      }
    }

    final trendPoints = _buildTrendPoints(
      dailyRevenue: dailyRevenue,
      startDate: range.start,
      endDate: range.end,
    );

    final totalRevenue = ordersInRange.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );
    final totalOrders = ordersInRange.length;
    final averageOrderValue =
        totalOrders == 0 ? 0.0 : totalRevenue / totalOrders;
    final topProducts = productTally.values.toList()
      ..sort((left, right) {
        final quantityCompare = right.quantity.compareTo(left.quantity);
        if (quantityCompare != 0) return quantityCompare;
        final revenueCompare = right.revenue.compareTo(left.revenue);
        if (revenueCompare != 0) return revenueCompare;
        return left.title.compareTo(right.title);
      });

    final productData = topProducts
        .take(3)
        .map(
          (product) => _ProductData(
            title: product.title,
            orders: '${product.quantity} sold',
            amount: _moneyLabel(product.revenue),
            icon: product.icon,
            colors: product.colors,
          ),
        )
        .toList();

    return _ReportSnapshot(
      periodLabel: period.label,
      dateRangeLabel: range.label,
      metrics: [
        _MetricData(
          title: 'Total Revenue',
          value: _moneyLabel(totalRevenue),
          icon: Icons.trending_up_rounded,
          iconColor: ReportHubPage._blue,
          tint: const Color(0xFFEAF1FF),
          valueColor: ReportHubPage._blue,
        ),
        _MetricData(
          title: 'Total Orders',
          value: totalOrders.toString(),
          icon: Icons.shopping_bag_rounded,
          iconColor: ReportHubPage._green,
          tint: const Color(0xFFEAF8EF),
          valueColor: ReportHubPage._green,
        ),
        _MetricData(
          title: 'Average Order Value',
          value: _moneyLabel(averageOrderValue),
          icon: Icons.account_balance_wallet_rounded,
          iconColor: ReportHubPage._purple,
          tint: const Color(0xFFF1EAFB),
          valueColor: ReportHubPage._purple,
        ),
      ],
      trendPoints: trendPoints,
      products: productData,
      chartMaxValue: _resolveChartMax(trendPoints),
    );
  }

  Future<Uint8List> _buildSalesReportPdfBytes(
    _ReportSnapshot report,
    String aiSummary,
    AppProfileData profile,
  ) async {
    final pdf = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();
    final logoImage = await _loadPdfLogoImage(profile);
    final generatedAt = DateTime.now();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        build: (context) => [
          _pdfHeader(report, profile, logoImage),
          pw.SizedBox(height: 14),
          _pdfAiSummarySection(aiSummary),
          pw.SizedBox(height: 18),
          _pdfHighlightsSection(report),
          pw.SizedBox(height: 18),
          _pdfStoreDetails(profile),
          pw.SizedBox(height: 18),
          _pdfMetricRow(report.metrics),
          pw.SizedBox(height: 18),
          _pdfSectionHeader('Sales Trend'),
          pw.SizedBox(height: 10),
          _pdfTrendSummaryClean(report.trendPoints),
          pw.SizedBox(height: 18),
          _pdfSectionHeader('Top Selling Products'),
          pw.SizedBox(height: 10),
          _pdfProductTable(report.products),
        ],
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated ${_formatPdfDateTime(generatedAt)}',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                profile.storeName.trim().isEmpty
                    ? 'Sales Report'
                    : profile.storeName.trim(),
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

  Future<pw.ImageProvider?> _loadPdfLogoImage(AppProfileData profile) async {
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

  Future<bool> _shareReportPdf(Uint8List bytes, String fileName) async {
    if (Platform.isAndroid) {
      final result = await ReportHubPage._shareChannel.invokeMethod<bool>(
        'sharePdfFromBytes',
        <String, Object?>{
          'fileName': fileName,
          'bytes': bytes,
          'subject': 'Sales Report',
          'text': 'Sales report attached',
        },
      );
      return result ?? false;
    }

    await Printing.sharePdf(bytes: bytes, filename: fileName);
    return true;
  }

  pw.Widget _pdfHeader(
    _ReportSnapshot report,
    AppProfileData profile,
    pw.ImageProvider? logoImage,
  ) {
    final storeName =
        profile.storeName.trim().isEmpty ? 'Store report' : profile.storeName;
    final ownerName =
        profile.ownerName.trim().isEmpty ? 'Owner not set' : profile.ownerName;
    final contact =
        profile.contactNumber.trim().isEmpty ? 'Contact not set' : profile.contactNumber;
    final email =
        profile.emailAddress.trim().isEmpty ? 'Email not set' : profile.emailAddress;
    final address = profile.physicalAddress.trim().isEmpty
        ? 'Address not set'
        : profile.physicalAddress;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logoImage != null) ...[
          pw.Container(
            width: 52,
            height: 52,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F3F6FB'),
              borderRadius: pw.BorderRadius.circular(14),
              border: pw.Border.all(color: PdfColor.fromHex('#DDE4EE')),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 14,
              verticalRadius: 14,
              child: pw.Image(
                logoImage,
                fit: pw.BoxFit.cover,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
        ] else ...[
          pw.Container(
            width: 52,
            height: 52,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#EAF1FF'),
              borderRadius: pw.BorderRadius.circular(14),
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
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0F172A'),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Sales Report',
                style: pw.TextStyle(
                  fontSize: 11.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                report.dateRangeLabel,
                style: const pw.TextStyle(
                  fontSize: 10.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                '$ownerName | $contact | $email',
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                address,
                style: const pw.TextStyle(
                  fontSize: 9.5,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: PdfColor.fromHex('#DDE4EE')),
          ),
          child: pw.Text(
            report.periodLabel,
            style: pw.TextStyle(
              color: PdfColor.fromHex('#0F172A'),
              fontSize: 10.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfMetricRow(List<_MetricData> metrics) {
    return pw.Row(
      children: metrics
          .map((metric) => pw.Expanded(child: _pdfMetricCard(metric)))
          .toList(),
    );
  }

  pw.Widget _pdfMetricCard(_MetricData metric) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(horizontal: 4),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 28,
            height: 28,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex(_hexForMetric(metric.tint)),
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                _metricGlyph(metric.icon),
                style: pw.TextStyle(
                  color: PdfColor.fromHex(_hexForMetric(metric.iconColor)),
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            metric.title,
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            metric.value,
            style: pw.TextStyle(
              fontSize: 14.5,
              color: PdfColor.fromHex(_hexForMetric(metric.valueColor)),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfStoreDetails(AppProfileData profile) {
    final lines = <pw.Widget>[
      pw.Text(
        'Store information',
        style: pw.TextStyle(
          fontSize: 13.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#0F172A'),
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#F8FAFC'),
          borderRadius: pw.BorderRadius.circular(14),
          border: pw.Border.all(color: PdfColor.fromHex('#DDE4EE')),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pdfInfoLine(
              'Store name',
              profile.storeName.trim().isEmpty ? 'Not set' : profile.storeName,
            ),
            pw.SizedBox(height: 6),
            _pdfInfoLine(
              'Owner',
              profile.ownerName.trim().isEmpty ? 'Not set' : profile.ownerName,
            ),
            pw.SizedBox(height: 6),
            _pdfInfoLine(
              'Contact',
              profile.contactNumber.trim().isEmpty
                  ? 'Not set'
                  : profile.contactNumber,
            ),
            pw.SizedBox(height: 6),
            _pdfInfoLine(
              'Email',
              profile.emailAddress.trim().isEmpty
                  ? 'Not set'
                  : profile.emailAddress,
            ),
            pw.SizedBox(height: 6),
            _pdfInfoLine(
              'Address',
              profile.physicalAddress.trim().isEmpty
                  ? 'Not set'
                  : profile.physicalAddress,
            ),
          ],
        ),
      ),
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines,
    );
  }

  pw.Widget _pdfHighlightsSection(_ReportSnapshot report) {
    final topProduct = report.products.isNotEmpty
        ? report.products.first
        : null;
    final revenue = report.metrics.isNotEmpty ? report.metrics[0].value : 'TSH 0';
    final orders = report.metrics.length > 1 ? report.metrics[1].value : '0';
    final average = report.metrics.length > 2 ? report.metrics[2].value : 'TSH 0';
    final topProductText = topProduct == null
        ? 'No completed sales were recorded in this period.'
        : '${topProduct.title} led the period with ${topProduct.orders} and ${topProduct.amount} revenue.';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FBFCFE'),
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColor.fromHex('#E3E9F2')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Key highlights',
            style: pw.TextStyle(
              fontSize: 13.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 8),
          _pdfBullet(
            'Revenue for this period is $revenue across $orders completed orders, with an average order value of $average.',
          ),
          pw.SizedBox(height: 5),
          _pdfBullet(topProductText),
          pw.SizedBox(height: 5),
          _pdfBullet(
            'The report only includes completed sales stored in the app, so it reflects finalized business activity.',
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfBullet(String text) {
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

  pw.Widget _pdfInfoLine(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 72,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _pdfSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#0F172A'),
        ),
      ),
    );
  }

  pw.Widget _pdfAiSummarySection(String aiSummary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FAFCFF'),
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: PdfColor.fromHex('#DCE6F5')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 24,
                height: 24,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EAF1FF'),
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'AI',
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('#1E67E8'),
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'AI Executive Analysis',
                style: pw.TextStyle(
                  fontSize: 13.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#0F172A'),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            aiSummary,
            style: const pw.TextStyle(
              fontSize: 10.2,
              color: PdfColors.grey800,
              lineSpacing: 4,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated from completed sales, trend data, and top product performance inside the app.',
            style: const pw.TextStyle(
              fontSize: 8.6,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfTrendSummary(List<_TrendPoint> points) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2')),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: points
                  .map(
                    (point) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Text(
                        '${point.label}  •  ${point.displayValue}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfTrendSummaryClean(List<_TrendPoint> points) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FBFCFE'),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2')),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Trend breakdown',
            style: pw.TextStyle(
              fontSize: 11.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 8),
          ...points.map(
            (point) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2')),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      point.label,
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                  pw.Text(
                    point.displayValue,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1E67E8'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfProductTable(List<_ProductData> products) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#E6EBF2')),
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

  pw.Widget _pdfTableCell(String text, {bool bold = false}) {
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

  String _reportFileName() {
    return 'sales_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
  }

  String _formatPdfDateTime(DateTime dateTime) {
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

  String _hexForMetric(Color color) {
    final red = (color.r * 255.0).round().clamp(0, 255).toInt();
    final green = (color.g * 255.0).round().clamp(0, 255).toInt();
    final blue = (color.b * 255.0).round().clamp(0, 255).toInt();
    return '#'
        '${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}';
  }

  String _metricGlyph(IconData icon) {
    if (icon == Icons.trending_up_rounded) return 'R';
    if (icon == Icons.shopping_bag_rounded) return 'O';
    if (icon == Icons.account_balance_wallet_rounded) return 'A';
    return '-';
  }

  String _dateLabel(DateTime date) {
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

  String _trendLabel(DateTime date) {
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
    return '${monthNames[date.month - 1]} ${date.day}';
  }

  String _moneyLabel(double amount) {
    return 'TSH ${_formatWithCommas(amount)}';
  }

  String _compactAmount(double value) {
    return _kLabel(value);
  }

  String _formatWithCommas(num value) {
    final fixed = value.toStringAsFixed(0);
    return fixed.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  double _resolveChartMax(List<_TrendPoint> points) {
    final highestValue = points.fold<double>(
      0,
      (maxValue, point) => math.max(maxValue, point.value),
    );
    if (highestValue <= 0) return 500;
    if (highestValue <= 500) return 500;
    if (highestValue <= 1000) return 1000;
    if (highestValue <= 2500) {
      return (highestValue / 500).ceilToDouble() * 500;
    }
    if (highestValue <= 10000) {
      return (highestValue / 1000).ceilToDouble() * 1000;
    }
    return (highestValue / 5000).ceilToDouble() * 5000;
  }

  IconData _iconForLine(OrderLine line) {
    switch (line.artType) {
      case ProductArtType.aquafina:
        return Icons.water_drop_outlined;
      case ProductArtType.coke:
        return Icons.local_drink_rounded;
      case ProductArtType.lays:
        return Icons.lunch_dining_rounded;
      case ProductArtType.galaxy:
        return Icons.egg_alt_rounded;
      case ProductArtType.kelloggs:
        return Icons.breakfast_dining_rounded;
      case ProductArtType.dove:
        return Icons.spa_outlined;
      case ProductArtType.colgate:
        return Icons.health_and_safety_outlined;
      case ProductArtType.dettol:
        return Icons.cleaning_services_outlined;
      case ProductArtType.tide:
        return Icons.local_laundry_service_outlined;
    }
  }

  List<Color> _colorsForLine(OrderLine line) {
    switch (line.artType) {
      case ProductArtType.aquafina:
        return const [Color(0xFF1E67E8), Color(0xFF69A6FF)];
      case ProductArtType.coke:
        return const [Color(0xFFD12D2D), Color(0xFFFF7A7A)];
      case ProductArtType.lays:
        return const [Color(0xFFD97706), Color(0xFFF7C35F)];
      case ProductArtType.galaxy:
        return const [Color(0xFF8E3ED8), Color(0xFFC58BFF)];
      case ProductArtType.kelloggs:
        return const [Color(0xFFB45309), Color(0xFFF2B46D)];
      case ProductArtType.dove:
        return const [Color(0xFF0F9D8C), Color(0xFF76D6CA)];
      case ProductArtType.colgate:
        return const [Color(0xFF1D4ED8), Color(0xFF6EA8FF)];
      case ProductArtType.dettol:
        return const [Color(0xFF169B4A), Color(0xFF7EDDA2)];
      case ProductArtType.tide:
        return const [Color(0xFF9A3412), Color(0xFFF59E0B)];
    }
  }

  Future<String> _buildAiExecutiveSummary(
    PosLocalStore store,
    _ReportSnapshot report,
  ) async {
    final fallback = _buildLocalExecutiveSummary(store, report);
    final service = DukaAiService(
      geminiApiKey: store.geminiApiKey,
      groqApiKey: store.groqApiKey,
      groqModel: store.groqModel,
      timeout: const Duration(seconds: 18),
    );

    if (!service.isConfigured) {
      return fallback;
    }

    final response = await service
        .sendMessage(
          prompt:
              'Write a professional executive sales analysis for this report.',
          storeContext: _buildReportContext(store, report),
          history: const <DukaAiMessage>[],
          systemPromptOverride: _professionalReportSystemPrompt(),
        )
        .timeout(
          const Duration(seconds: 4),
          onTimeout: () => const DukaAiResult(
            reply: '',
            errorKind: DukaAiErrorKind.timeout,
          ),
        );

    final cleaned = _normalizeAiText(response.reply);
    if (response.errorKind == DukaAiErrorKind.none && cleaned.isNotEmpty) {
      return cleaned;
    }

    return fallback;
  }

  String _buildReportContext(PosLocalStore store, _ReportSnapshot report) {
    final profile = store.profile;
    final revenue =
        report.metrics.isNotEmpty ? report.metrics[0].value : 'TSH 0';
    final orders = report.metrics.length > 1 ? report.metrics[1].value : '0';
    final average =
        report.metrics.length > 2 ? report.metrics[2].value : 'TSH 0';

    final buffer = StringBuffer();
    buffer.writeln('Report title: Sales Report');
    buffer.writeln(
      'Store name: ${profile.storeName.isEmpty ? 'Unnamed store' : profile.storeName}',
    );
    buffer.writeln(
      'Owner: ${profile.ownerName.isEmpty ? 'Not set' : profile.ownerName}',
    );
    buffer.writeln('Period: ${report.dateRangeLabel}');
    buffer.writeln('Period type: ${report.periodLabel}');
    buffer.writeln('Total revenue: $revenue');
    buffer.writeln('Completed orders: $orders');
    buffer.writeln('Average order value: $average');
    buffer.writeln('Top selling products:');
    if (report.products.isEmpty) {
      buffer.writeln('- No completed sales in this period.');
    } else {
      for (final product in report.products) {
        buffer.writeln(
            '- ${product.title} | ${product.orders} | ${product.amount}');
      }
    }
    buffer.writeln('Sales trend:');
    for (final point in report.trendPoints) {
      buffer.writeln('- ${point.label}: ${point.displayValue}');
    }
    return buffer.toString();
  }

  String _buildLocalExecutiveSummary(
    PosLocalStore store,
    _ReportSnapshot report,
  ) {
    final storeName =
        store.profile.storeName.isEmpty ? 'the shop' : store.profile.storeName;
    final revenue =
        report.metrics.isNotEmpty ? report.metrics[0].value : 'TSH 0';
    final orders = report.metrics.length > 1 ? report.metrics[1].value : '0';
    final average =
        report.metrics.length > 2 ? report.metrics[2].value : 'TSH 0';
    final topProduct = report.products.isNotEmpty
        ? 'Top product: ${report.products.first.title} with ${report.products.first.orders}.'
        : 'There were no completed sales in this period.';

    final trendNote = report.trendPoints.isEmpty
        ? 'The trend chart does not have enough completed sales to show a pattern.'
        : 'The trend section summarizes activity across ${report.trendPoints.length} points.';

    return '''
Executive summary
$storeName recorded $revenue across $orders completed orders, with an average order value of $average.

Key observations
- $topProduct
- $trendNote
- This report is based on completed sales stored in the app, so the figures reflect finalized transactions only.

Watch-outs
- Review slower-moving products and tighten stock planning around them.
- Keep an eye on the sales rhythm in the selected period for any soft spots.

Recommended actions
- Protect stock for the best sellers.
- Consider small promos or bundles for slower items.
'''
        .trim();
  }

  String _professionalReportSystemPrompt() {
    return '''
You are a senior retail analyst writing a polished executive sales report.

Write in a formal, concise, businesslike tone.
Use only the numbers and facts in the provided data.
Do not invent data or mention unsupported assumptions.
Use plain text only. No markdown. No greetings. No sign-off.

Structure the response with these short sections:
Executive summary
Key observations
Watch-outs
Recommended actions

Keep each section brief and readable in a PDF.
''';
  }

  String _normalizeAiText(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1')
        .trim();
  }

  _ReportRange _resolveReportRange(
    List<CompletedOrder> orders,
    _ReportPeriod period,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (period) {
      case _ReportPeriod.today:
        return _ReportRange(
          start: todayStart,
          end: todayStart,
          label: _dateLabel(todayStart),
        );
      case _ReportPeriod.week:
        final weekStart =
            todayStart.subtract(Duration(days: todayStart.weekday - 1));
        return _ReportRange(
          start: weekStart,
          end: todayStart,
          label: '${_dateLabel(weekStart)} - ${_dateLabel(todayStart)}',
        );
      case _ReportPeriod.month:
        final monthStart = DateTime(now.year, now.month, 1);
        return _ReportRange(
          start: monthStart,
          end: todayStart,
          label: '${_dateLabel(monthStart)} - ${_dateLabel(todayStart)}',
        );
      case _ReportPeriod.allTime:
        final orderDates = orders
            .map((order) => DateTime.tryParse(order.dateTime))
            .whereType<DateTime>()
            .toList()
          ..sort();
        if (orderDates.isEmpty) {
          return _ReportRange(
            start: todayStart,
            end: todayStart,
            label: 'All Time',
          );
        }
        final start = DateTime(
          orderDates.first.year,
          orderDates.first.month,
          orderDates.first.day,
        );
        final end = DateTime(
          orderDates.last.year,
          orderDates.last.month,
          orderDates.last.day,
        );
        return _ReportRange(start: start, end: end, label: 'All Time');
    }
  }

  List<_TrendPoint> _buildTrendPoints({
    required Map<DateTime, double> dailyRevenue,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final totalDays = endDate.difference(startDate).inDays + 1;
    if (totalDays <= 0) {
      return <_TrendPoint>[
        _TrendPoint(
          label: _trendLabel(startDate),
          value: 0,
          displayValue: _compactAmount(0),
        ),
      ];
    }

    if (totalDays <= 7) {
      return List.generate(totalDays, (index) {
        final day = startDate.add(Duration(days: index));
        final value = dailyRevenue[day] ?? 0;
        return _TrendPoint(
          label: _trendLabel(day),
          value: value,
          displayValue: _compactAmount(value),
        );
      });
    }

    const bucketCount = 6;
    final bucketSize = (totalDays / bucketCount).ceil();
    final points = <_TrendPoint>[];

    for (var index = 0; index < bucketCount; index++) {
      final bucketStart = startDate.add(Duration(days: index * bucketSize));
      if (bucketStart.isAfter(endDate)) break;

      var bucketEnd = bucketStart.add(Duration(days: bucketSize - 1));
      if (bucketEnd.isAfter(endDate)) {
        bucketEnd = endDate;
      }

      final value = _sumRevenueForRange(
        dailyRevenue: dailyRevenue,
        startDate: bucketStart,
        endDate: bucketEnd,
      );

      points.add(
        _TrendPoint(
          label: _trendBucketLabel(bucketStart, bucketEnd),
          value: value,
          displayValue: _compactAmount(value),
        ),
      );
    }

    return points.isEmpty
        ? <_TrendPoint>[
            _TrendPoint(
              label: _trendLabel(startDate),
              value: 0,
              displayValue: _compactAmount(0),
            ),
          ]
        : points;
  }

  double _sumRevenueForRange({
    required Map<DateTime, double> dailyRevenue,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    var total = 0.0;
    var current = startDate;
    while (!current.isAfter(endDate)) {
      total += dailyRevenue[current] ?? 0;
      current = current.add(const Duration(days: 1));
    }
    return total;
  }

  String _trendBucketLabel(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day) {
      return _trendLabel(startDate);
    }
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return '${_monthName(startDate.month)} ${startDate.day}-${endDate.day}';
    }
    return '${_monthName(startDate.month)} ${startDate.day}-${_monthName(endDate.month)} ${endDate.day}';
  }

  String _monthName(int month) {
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
    return monthNames[month - 1];
  }
}

class _ReportSnapshot {
  const _ReportSnapshot({
    required this.periodLabel,
    required this.dateRangeLabel,
    required this.metrics,
    required this.trendPoints,
    required this.products,
    required this.chartMaxValue,
  });

  final String periodLabel;
  final String dateRangeLabel;
  final List<_MetricData> metrics;
  final List<_TrendPoint> trendPoints;
  final List<_ProductData> products;
  final double chartMaxValue;
}

class _ReportRange {
  const _ReportRange({
    required this.start,
    required this.end,
    required this.label,
  });

  final DateTime start;
  final DateTime end;
  final String label;
}

class _ProductTally {
  _ProductTally({
    required this.title,
    required this.quantity,
    required this.revenue,
    required this.icon,
    required this.colors,
  });

  final String title;
  int quantity;
  double revenue;
  final IconData icon;
  final List<Color> colors;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBackTap,
    required this.onDownloadTap,
    required this.isDownloading,
  });

  final VoidCallback onBackTap;
  final VoidCallback onDownloadTap;
  final bool isDownloading;

  @override
  Widget build(BuildContext context) {
    return MarketPageHeader(
      title: 'Sales Report',
      titleSize: 22,
      titleWeight: FontWeight.w800,
      showBorder: false,
      showShadow: true,
      onBack: onBackTap,
      trailing: Material(
        color: const Color(0x1A1E67E8),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isDownloading ? null : onDownloadTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isDownloading
                    ? const SizedBox(
                        key: ValueKey('download-loading'),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation(
                            ReportHubPage._blue,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.share_rounded,
                        key: ValueKey('download-icon'),
                        color: ReportHubPage._blue,
                        size: 22,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeCard extends StatelessWidget {
  const _RangeCard({
    required this.dateRange,
    required this.periodLabel,
    required this.onPeriodSelected,
  });

  final String dateRange;
  final String periodLabel;
  final ValueChanged<_ReportPeriod> onPeriodSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportHubPage._border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            color: ReportHubPage._muted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dateRange,
                    style: const TextStyle(
                      color: ReportHubPage._ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<_ReportPeriod>(
                  onSelected: onPeriodSelected,
                  position: PopupMenuPosition.under,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  offset: const Offset(0, 10),
                  itemBuilder: (context) => _ReportPeriod.values
                      .map(
                        (period) => PopupMenuItem<_ReportPeriod>(
                          value: period,
                          child: Text(period.label),
                        ),
                      )
                      .toList(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ReportHubPage._border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          periodLabel,
                          style: const TextStyle(
                            color: ReportHubPage._ink,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: ReportHubPage._muted,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 420 ? 2 : 3;
        const gap = 6.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _MetricCard(data: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportHubPage._border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: data.tint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              color: data.iconColor,
              size: 15,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ReportHubPage._muted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
          const Spacer(),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              data.value,
              style: TextStyle(
                color: data.valueColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.trailing,
    required this.child,
  });

  final String title;
  final Widget trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportHubPage._border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ReportHubPage._ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _LinkAction extends StatelessWidget {
  const _LinkAction({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ReportHubPage._blue,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.chevron_right_rounded,
          color: ReportHubPage._blue,
          size: 16,
        ),
      ],
    );
  }
}

class _TopSellingProductsList extends StatelessWidget {
  const _TopSellingProductsList({
    required this.products,
    required this.emptyMessage,
  });

  final List<_ProductData> products;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          emptyMessage,
          style: const TextStyle(
            color: ReportHubPage._muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int index = 0; index < products.length; index++) ...[
          _ProductRow(data: products[index]),
          if (index != products.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Divider(
                height: 1,
                thickness: 1,
                color: ReportHubPage._border,
              ),
            ),
        ],
      ],
    );
  }
}

class _SalesTrendChart extends StatelessWidget {
  const _SalesTrendChart({
    required this.points,
    required this.maxValue,
  });

  final List<_TrendPoint> points;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SalesTrendPainter(
        points: points,
        maxValue: maxValue,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SalesTrendPainter extends CustomPainter {
  _SalesTrendPainter({
    required this.points,
    required this.maxValue,
  });

  final List<_TrendPoint> points;
  final double maxValue;

  static const TextStyle _axisStyle = TextStyle(
    color: Color(0xFF5B6270),
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.15,
  );
  static const TextStyle _valueStyle = TextStyle(
    color: Color(0xFF101828),
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 62.0;
    const rightPad = 24.0;
    const topPad = 16.0;
    const topInset = 20.0;
    const bottomPad = 22.0;
    const labelBandHeight = 20.0;
    final chartRect = Rect.fromLTWH(
      leftPad,
      topPad,
      size.width - leftPad - rightPad,
      size.height - topPad - bottomPad - labelBandHeight,
    );
    const lineColor = ReportHubPage._blue;

    final showEveryNth = points.length > 5 ? 2 : 1;
    bool shouldDrawLabel(int i) =>
        i == 0 || i == points.length - 1 || i % showEveryNth == 0;

    final gridPaint = Paint()
      ..color = const Color(0xFFD8DFEA)
      ..strokeWidth = 1;

    final fillPaint = Paint()
      ..color = const Color(0x1A1E67E8)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pointOuterPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final pointInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final chartMaxValue = maxValue <= 0 ? 1.0 : maxValue;
    final gridValues = List<double>.generate(
      6,
      (index) => chartMaxValue * index / 5,
    );

    final stepX =
        points.length == 1 ? 0.0 : chartRect.width / (points.length - 1);
    final offsets = <Offset>[];

    for (var index = 0; index < points.length; index++) {
      final x = chartRect.left + (stepX * index);
      final y = chartRect.bottom -
          (points[index].value / chartMaxValue) *
              (chartRect.height - topInset);
      offsets.add(Offset(x, y));
    }

    for (final gridValue in gridValues) {
      final gridY =
          chartRect.bottom - (gridValue / chartMaxValue) * chartRect.height;
      _drawDashedLine(
        canvas,
        Offset(chartRect.left, gridY),
        Offset(chartRect.right, gridY),
        gridPaint,
      );
      _paintText(
        canvas,
        _gridLabel(gridValue),
        _axisStyle,
        Offset(0, gridY - 8),
        width: 40,
        align: TextAlign.right,
      );
    }

    if (offsets.isEmpty) return;

    final areaPath = Path()
      ..moveTo(offsets.first.dx, chartRect.bottom)
      ..lineTo(offsets.first.dx, offsets.first.dy);
    for (var index = 1; index < offsets.length; index++) {
      areaPath.lineTo(offsets[index].dx, offsets[index].dy);
    }
    areaPath
      ..lineTo(offsets.last.dx, chartRect.bottom)
      ..close();
    canvas.drawPath(areaPath, fillPaint);

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var index = 1; index < offsets.length; index++) {
      linePath.lineTo(offsets[index].dx, offsets[index].dy);
    }
    canvas.drawPath(linePath, strokePaint);

    for (var index = 0; index < offsets.length; index++) {
      final offset = offsets[index];
      canvas.drawCircle(offset, 8, pointOuterPaint);
      canvas.drawCircle(offset, 5.2, pointInnerPaint);

      if (shouldDrawLabel(index)) {
        _paintText(
          canvas,
          points[index].displayValue,
          _valueStyle,
          Offset(offset.dx, offset.dy - 34),
          width: 48,
          align: TextAlign.center,
        );
        _paintText(
          canvas,
          points[index].label,
          _axisStyle,
          Offset(offset.dx, chartRect.bottom + 6),
          width: 48,
          align: TextAlign.center,
        );
      }
    }
  }

  static String _gridLabel(double value) {
    return _kLabel(value);
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashWidth = 4.0;
    const dashGap = 6.0;
    var currentX = start.dx;

    while (currentX < end.dx) {
      final nextX =
          (currentX + dashWidth) > end.dx ? end.dx : currentX + dashWidth;
      canvas.drawLine(
        Offset(currentX, start.dy),
        Offset(nextX, end.dy),
        paint,
      );
      currentX += dashWidth + dashGap;
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset offset, {
    required double width,
    required TextAlign align,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(minWidth: 0, maxWidth: width);

    final dx = switch (align) {
      TextAlign.right => offset.dx + width - painter.width,
      TextAlign.center => offset.dx + (width - painter.width) / 2,
      _ => offset.dx,
    };

    painter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _SalesTrendPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.maxValue != maxValue;
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.data});

  final _ProductData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _ProductThumb(data: data),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: ReportHubPage._ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  data.orders,
                  style: const TextStyle(
                    color: ReportHubPage._muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            data.amount,
            style: const TextStyle(
              color: ReportHubPage._blue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.15,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF8A94A6),
            size: 16,
          ),
        ],
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.data});

  final _ProductData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: data.colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          data.icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.tint,
    required this.valueColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color tint;
  final Color valueColor;
}

class _TrendPoint {
  const _TrendPoint({
    required this.label,
    required this.value,
    required this.displayValue,
  });

  final String label;
  final double value;
  final String displayValue;
}

class _ProductData {
  const _ProductData({
    required this.title,
    required this.orders,
    required this.amount,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String orders;
  final String amount;
  final IconData icon;
  final List<Color> colors;
}
