import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../receipt_brand_data.dart';
import '../../service/pos_order_models.dart';
import '../../service/pos_local_store.dart';
import '../widgets/market_shared_widgets.dart';

enum ReportType {
  salesByDate('Sales by Date'),
  topProducts('Top Selling Products'),
  revenueSummary('Revenue Summary');

  const ReportType(this.label);
  final String label;
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late DateTime _selectedFromDate;
  late DateTime _selectedToDate;
  late DateTime _appliedFromDate;
  late DateTime _appliedToDate;
  ReportType _selectedReportType = ReportType.salesByDate;
  ReportType _appliedReportType = ReportType.salesByDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedFromDate = DateTime(now.year, now.month, 1);
    _selectedToDate = DateTime(now.year, now.month, now.day);
    _appliedFromDate = _selectedFromDate;
    _appliedToDate = _selectedToDate;
  }

  Future<void> _pickDate({
    required bool isFrom,
  }) async {
    final initialDate = isFrom ? _selectedFromDate : _selectedToDate;
    final firstDate = DateTime(2020, 1, 1);
    final lastDate = DateTime.now().add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return;

    setState(() {
      if (isFrom) {
        _selectedFromDate = DateTime(picked.year, picked.month, picked.day);
        if (_selectedFromDate.isAfter(_selectedToDate)) {
          _selectedToDate = _selectedFromDate;
        }
      } else {
        _selectedToDate = DateTime(picked.year, picked.month, picked.day);
        if (_selectedToDate.isBefore(_selectedFromDate)) {
          _selectedFromDate = _selectedToDate;
        }
      }
    });
  }

  Future<void> _selectReportType() async {
    final selected = await showModalBottomSheet<ReportType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ReportType.values
                .map(
                  (type) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      type.label,
                      style: const TextStyle(
                        color: Color(0xFF202938),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: type == _selectedReportType
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2B61C9),
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(type),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (selected == null) return;
    setState(() => _selectedReportType = selected);
  }

  void _applyFilters() {
    setState(() {
      _appliedFromDate = _selectedFromDate;
      _appliedToDate = _selectedToDate;
      _appliedReportType = _selectedReportType;
    });
    showMarketNotice(
      context,
      title: 'Report Updated',
      message:
          '${_appliedReportType.label} from ${_formatDateLong(_appliedFromDate)} to ${_formatDateLong(_appliedToDate)}',
    );
  }

  Future<void> _exportReport(_ReportData reportData) async {
    try {
      final regularFont = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          theme: pw.ThemeData.withFont(base: regularFont, bold: boldFont),
          build: (context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      ReceiptBrandData.storeName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      ReceiptBrandData.address,
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      ReceiptBrandData.phone,
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      _appliedReportType.label,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Period: ${_formatDateLong(_appliedFromDate)} - ${_formatDateLong(_appliedToDate)}',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFD'),
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: PdfColor.fromHex('#DCE2EA')),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: _pdfMetric(
                      'Total Sales',
                      'TSH ${reportData.totalSales.toStringAsFixed(0)}',
                    ),
                  ),
                  pw.Container(
                    width: 1,
                    height: 38,
                    color: PdfColor.fromHex('#E5E7EB'),
                  ),
                  pw.Expanded(
                    child: _pdfMetric(
                      'Orders',
                      '${reportData.orderCount}',
                    ),
                  ),
                  pw.Container(
                    width: 1,
                    height: 38,
                    color: PdfColor.fromHex('#E5E7EB'),
                  ),
                  pw.Expanded(
                    child: _pdfMetric(
                      'Top Product',
                      reportData.topProducts.isEmpty
                          ? 'No sales'
                          : reportData.topProducts.first.name,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Daily Sales Overview',
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E5E7EB')),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(3),
              },
              children: [
                _pdfHeaderRow(['Day', 'Sales']),
                ...reportData.dailySales.map(
                  (entry) => _pdfBodyRow([
                    _formatDateShort(entry.date),
                    'TSH ${entry.amount.toStringAsFixed(0)}',
                  ]),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Top Selling Products',
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E5E7EB')),
              columnWidths: const {
                0: pw.FixedColumnWidth(34),
                1: pw.FlexColumnWidth(4),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(2),
              },
              children: [
                _pdfHeaderRow(['#', 'Product', 'Qty Sold', 'Sales']),
                ...reportData.topProducts.asMap().entries.map(
                  (entry) => _pdfBodyRow([
                    '${entry.key + 1}',
                    entry.value.name,
                    '${entry.value.quantity}',
                    'TSH ${entry.value.amount.toStringAsFixed(0)}',
                  ]),
                ),
                if (reportData.topProducts.isEmpty)
                  _pdfBodyRow(['-', 'No products in this range', '-', '-']),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      if (!mounted) return;
      await Printing.layoutPdf(
        name:
            'report_${_appliedReportType.name}_${_formatDateFile(_appliedFromDate)}_${_formatDateFile(_appliedToDate)}.pdf',
        onLayout: (_) async => bytes,
      );
      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Export Ready',
        message: 'Report PDF opened in the print dialog',
      );
    } catch (_) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Export Failed',
        message: 'Could not generate the report PDF',
        type: MarketNoticeType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<PosLocalStore>().orders;
    final reportData = _ReportData.fromOrders(
      orders: orders,
      fromDate: _appliedFromDate,
      toDate: _appliedToDate,
      reportType: _appliedReportType,
    );

    return SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(child: BackdropGlow()),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Row(
                  children: [
                    const _MenuButtonLite(),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Reports',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF202938),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _exportReport(reportData),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.ios_share_rounded,
                            color: Color(0xFF202938),
                            size: 24,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Export',
                            style: TextStyle(
                              color: Color(0xFF202938),
                              fontSize: 12.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                  child: Column(
                    children: [
                      _ReportFilterCard(
                        selectedReportType: _selectedReportType,
                        fromDate: _selectedFromDate,
                        toDate: _selectedToDate,
                        onReportTypeTap: _selectReportType,
                        onFromTap: () => _pickDate(isFrom: true),
                        onToTap: () => _pickDate(isFrom: false),
                        onGenerate: _applyFilters,
                      ),
                      const SizedBox(height: 16),
                      _ReportSummaryStrip(reportData: reportData),
                      const SizedBox(height: 16),
                      _SalesOverviewCard(
                        reportData: reportData,
                        reportType: _appliedReportType,
                      ),
                      const SizedBox(height: 16),
                      _TopProductsCard(products: reportData.topProducts),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportSummaryStrip extends StatelessWidget {
  const _ReportSummaryStrip({required this.reportData});

  final _ReportData reportData;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            label: 'Orders',
            value: '${reportData.orderCount}',
            tint: const Color(0xFFEFF5FF),
            accent: const Color(0xFF2B61C9),
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            label: 'Days',
            value: '${reportData.dailySales.length}',
            tint: const Color(0xFFF3FAF4),
            accent: const Color(0xFF2F8F5B),
            icon: Icons.calendar_today_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryChip(
            label: 'Top Products',
            value: '${reportData.topProducts.length}',
            tint: const Color(0xFFFFF7E8),
            accent: const Color(0xFFB7791F),
            icon: Icons.workspace_premium_outlined,
          ),
        ),
      ],
    );
  }
}

class _ReportFilterCard extends StatelessWidget {
  const _ReportFilterCard({
    required this.selectedReportType,
    required this.fromDate,
    required this.toDate,
    required this.onReportTypeTap,
    required this.onFromTap,
    required this.onToTap,
    required this.onGenerate,
  });

  final ReportType selectedReportType;
  final DateTime fromDate;
  final DateTime toDate;
  final VoidCallback onReportTypeTap;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      tint: const Color(0xFFF8FBFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Color(0xFF2B61C9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Filters',
                      style: TextStyle(
                        color: Color(0xFF202938),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Select the report type and date range',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PickerField(
            icon: Icons.bar_chart_rounded,
            label: selectedReportType.label,
            onTap: onReportTypeTap,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  title: 'From',
                  value: _formatDateLong(fromDate),
                  onTap: onFromTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateField(
                  title: 'To',
                  value: _formatDateLong(toDate),
                  onTap: onToTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onGenerate,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2F67CF), Color(0xFF2558BE)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F2B61C9),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Generate Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
}

class _SalesOverviewCard extends StatelessWidget {
  const _SalesOverviewCard({
    required this.reportData,
    required this.reportType,
  });

  final _ReportData reportData;
  final ReportType reportType;

  @override
  Widget build(BuildContext context) {
    final heading = switch (reportType) {
      ReportType.salesByDate => 'Sales Overview',
      ReportType.topProducts => 'Sales Behind Top Products',
      ReportType.revenueSummary => 'Revenue Summary',
    };

    return _ReportPanel(
      tint: const Color(0xFFFFFCF7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  heading,
                  style: const TextStyle(
                    color: Color(0xFF202938),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Sales',
                    style: TextStyle(
                      color: Color(0xFF636B78),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TSH ${reportData.totalSales.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF202938),
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reportData.comparisonText,
                    style: TextStyle(
                      color: reportData.comparisonColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (reportData.dailySales.isEmpty)
            Container(
              height: 210,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Text(
                'No sales found in this date range',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0E7D8)),
              ),
              child: SizedBox(
                height: 210,
                child: _SalesBarChart(values: reportData.dailySales),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.products});

  final List<_TopProductStat> products;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      padding: EdgeInsets.zero,
      tint: const Color(0xFFFCFCFD),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Top Selling Products',
                style: TextStyle(
                  color: Color(0xFF202938),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(
                top: BorderSide(color: Color(0xFFE8EBEF)),
                bottom: BorderSide(color: Color(0xFFE8EBEF)),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(width: 24, child: Text('#', style: _tableHeaderStyle)),
                Expanded(
                  flex: 4,
                  child: Text('PRODUCT', style: _tableHeaderStyle),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'QTY SOLD',
                    textAlign: TextAlign.center,
                    style: _tableHeaderStyle,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'SALES',
                    textAlign: TextAlign.right,
                    style: _tableHeaderStyle,
                  ),
                ),
              ],
            ),
          ),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No products sold in this date range',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            ...products.asMap().entries.map(
                  (entry) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEFF2F5)),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Color(0xFF202938),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            entry.value.name,
                            style: const TextStyle(
                              color: Color(0xFF202938),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${entry.value.quantity}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF202938),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'TSH ${entry.value.amount.toStringAsFixed(0)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Color(0xFF202938),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
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
}

class _ReportPanel extends StatelessWidget {
  const _ReportPanel({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.tint,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint ?? Colors.white,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDCE2EA)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF2B61C9), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF202938),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF636B78),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDCE2EA)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF202938),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SalesBarChart extends StatelessWidget {
  const _SalesBarChart({required this.values});

  final List<_DailySalesPoint> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isEmpty
        ? 1.0
        : values.map((point) => point.amount).reduce(math.max);
    final labels = _buildAxisLabels(values);

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4, right: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Peak', style: _axisLabelStyle),
                    Text('Mid', style: _axisLabelStyle),
                    Text('Low', style: _axisLabelStyle),
                    Text('0', style: _axisLabelStyle),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              4,
                              (_) => const Divider(
                                height: 1,
                                color: Color(0xFFE9EDF3),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: values
                                .map(
                                  (point) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          height: constraints.maxHeight *
                                              (point.amount / maxValue),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Color(0xFF5A86DE),
                                                Color(0xFF2B61C9),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (label) => Text(label, style: _axisLabelStyle),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  List<String> _buildAxisLabels(List<_DailySalesPoint> points) {
    if (points.isEmpty) return const ['-', '-', '-', '-', '-'];
    final indexes = <int>{0, points.length ~/ 4, points.length ~/ 2, (points.length * 3) ~/ 4, points.length - 1}
      ..removeWhere((index) => index < 0 || index >= points.length);
    return indexes
        .map((index) => _formatDateShort(points[index].date))
        .toList();
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.tint,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color tint;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF202938),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
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

class _MenuButtonLite extends StatelessWidget {
  const _MenuButtonLite();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Icon(
        Icons.menu_rounded,
        color: Color(0xFF202938),
        size: 26,
      ),
    );
  }
}

class _ReportData {
  const _ReportData({
    required this.totalSales,
    required this.orderCount,
    required this.dailySales,
    required this.topProducts,
    required this.comparisonText,
    required this.comparisonColor,
  });

  final double totalSales;
  final int orderCount;
  final List<_DailySalesPoint> dailySales;
  final List<_TopProductStat> topProducts;
  final String comparisonText;
  final Color comparisonColor;

  factory _ReportData.fromOrders({
    required List<CompletedOrder> orders,
    required DateTime fromDate,
    required DateTime toDate,
    required ReportType reportType,
  }) {
    final start = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final end = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);

    final filteredOrders = orders.where((order) {
      final orderDate = DateTime.tryParse(order.dateTime);
      if (orderDate == null) return false;
      return !orderDate.isBefore(start) && !orderDate.isAfter(end);
    }).toList();

    final totalSales =
        filteredOrders.fold<double>(0, (sum, order) => sum + order.total);
    final productStats = <String, _TopProductStat>{};
    final dailyMap = <DateTime, double>{};

    for (var date = start;
        !date.isAfter(DateTime(toDate.year, toDate.month, toDate.day));
        date = date.add(const Duration(days: 1))) {
      dailyMap[DateTime(date.year, date.month, date.day)] = 0;
    }

    for (final order in filteredOrders) {
      final orderDate = DateTime.parse(order.dateTime);
      final orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
      dailyMap.update(
        orderDay,
        (value) => value + order.total,
        ifAbsent: () => order.total,
      );

      for (final line in order.lines) {
        final existing = productStats[line.itemName];
        if (existing == null) {
          productStats[line.itemName] = _TopProductStat(
            name: line.itemName,
            quantity: line.quantity,
            amount: line.lineTotal,
          );
        } else {
          productStats[line.itemName] = _TopProductStat(
            name: existing.name,
            quantity: existing.quantity + line.quantity,
            amount: existing.amount + line.lineTotal,
          );
        }
      }
    }

    final periodLength = toDate.difference(fromDate).inDays + 1;
    final previousStart = fromDate.subtract(Duration(days: periodLength));
    final previousEnd = fromDate.subtract(const Duration(seconds: 1));
    final previousTotal = orders.where((order) {
      final orderDate = DateTime.tryParse(order.dateTime);
      if (orderDate == null) return false;
      return !orderDate.isBefore(previousStart) && !orderDate.isAfter(previousEnd);
    }).fold<double>(0, (sum, order) => sum + order.total);

    final comparison = _buildComparison(totalSales, previousTotal);
    final tops = productStats.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return _ReportData(
      totalSales: totalSales,
      orderCount: filteredOrders.length,
      dailySales: dailyMap.entries
          .map((entry) => _DailySalesPoint(entry.key, entry.value))
          .toList(),
      topProducts: tops.take(reportType == ReportType.topProducts ? 10 : 5).toList(),
      comparisonText: comparison.$1,
      comparisonColor: comparison.$2,
    );
  }

  static (String, Color) _buildComparison(double current, double previous) {
    if (previous <= 0 && current <= 0) {
      return ('No sales in this period', const Color(0xFF6B7280));
    }
    if (previous <= 0) {
      return ('New sales in selected period', const Color(0xFF3FA66B));
    }
    final delta = ((current - previous) / previous) * 100;
    if (delta >= 0) {
      return ('Up ${delta.toStringAsFixed(1)}% vs previous period', const Color(0xFF3FA66B));
    }
    return ('Down ${delta.abs().toStringAsFixed(1)}% vs previous period', const Color(0xFFB45309));
  }
}

class _DailySalesPoint {
  const _DailySalesPoint(this.date, this.amount);

  final DateTime date;
  final double amount;
}

class _TopProductStat {
  const _TopProductStat({
    required this.name,
    required this.quantity,
    required this.amount,
  });

  final String name;
  final int quantity;
  final double amount;
}

const _axisLabelStyle = TextStyle(
  color: Color(0xFF6B7280),
  fontSize: 11.5,
  fontWeight: FontWeight.w500,
);

const _tableHeaderStyle = TextStyle(
  color: Color(0xFF7A8393),
  fontSize: 11.5,
  fontWeight: FontWeight.w700,
);

String _formatDateLong(DateTime date) {
  const monthNames = [
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
  return '${monthNames[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
}

String _formatDateShort(DateTime date) {
  const monthNames = [
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
  return '${monthNames[date.month - 1]} ${date.day.toString().padLeft(2, '0')}';
}

String _formatDateFile(DateTime date) {
  return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
}

pw.Widget _pdfMetric(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10.5,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

pw.TableRow _pdfHeaderRow(List<String> values) {
  return pw.TableRow(
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#F6F8FB'),
    ),
    children: values
        .map(
          (value) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        )
        .toList(),
  );
}

pw.TableRow _pdfBodyRow(List<String> values) {
  return pw.TableRow(
    children: values
        .map(
          (value) => pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10.5),
            ),
          ),
        )
        .toList(),
  );
}
