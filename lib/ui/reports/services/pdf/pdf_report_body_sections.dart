part of '../pdf_report_service.dart';

pw.Widget _pdfSalesTrendSection(
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

pw.Widget _pdfCustomerInsightsSection(
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

pw.TableRow _pdfTableRow(String label, String value) {
  return pw.TableRow(
    children: [
      _pdfTableCell(label),
      _pdfTableCell(value),
    ],
  );
}

pw.Widget _pdfExpenseAnalysisSection(List<Expense> expenses) {
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

pw.Widget _pdfConclusionSection(String conclusion) {
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

pw.Widget _pdfReferencesSection(ReportSnapshot report) {
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
