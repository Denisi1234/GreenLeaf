part of '../pdf_report_service.dart';

Future<pw.ImageProvider?> _loadPdfLogoImage(
    AppProfileData profile) async {
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

String _reportTitleFor(ReportSnapshot report) {
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

pw.Widget _pdfReportHeader({
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

pw.Widget _pdfIntroSection(
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

pw.Widget _pdfIntroStat(String label, String value) {
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

pw.Widget _pdfSectionTitle(String title) {
  return pw.Text(
    title,
    style: pw.TextStyle(
      fontSize: 13.5,
      fontWeight: pw.FontWeight.bold,
      color: PdfColor.fromHex('#0F172A'),
    ),
  );
}

pw.Widget _pdfSectionDivider() {
  return pw.Container(
    height: 1,
    margin: const pw.EdgeInsets.only(top: 2),
    color: PdfColor.fromHex('#EEF3F8'),
  );
}

pw.Widget _pdfKpiTable(
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

pw.TableRow _pdfKpiRow(
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
