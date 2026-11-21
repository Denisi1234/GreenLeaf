part of '../pdf_report_service.dart';

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

pw.Widget _pdfHighlightsSection(
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
  final lowStockCount = PdfReportService.lowStockItems(store).length;
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

pw.Widget _pdfForecastSection(ForecastSnapshot forecast) {
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

pw.Widget _pdfForecastCard({
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

pw.Widget _pdfProductTable(List<ProductData> products) {
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
