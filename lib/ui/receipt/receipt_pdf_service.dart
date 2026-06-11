import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/product_item.dart';

class ReceiptPdfService {
  static Future<File> createReceiptPdf({
    required List<OrderLineItem> items,
    required double total,
    required double cashTendered,
    required double changeDue,
    required String receiptNumber,
    required String cashier,
    required String register,
    required String date,
    required String time,
    required String storeName,
    required String storeAddress,
    required String storePhone,
    String? customerName,
    double? discountAmount,
    String? discountLabel,
  }) async {
    final pdf = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final subtotal =
        items.fold<double>(0, (sum, line) => sum + line.totalPrice);
    final discount = discountAmount ?? 0;
    final itemCount = items.fold<int>(0, (sum, line) => sum + line.quantity);
    final cleanStoreName = _cleanValue(storeName, 'Store receipt');
    final cleanStoreAddress = storeAddress.trim();
    final cleanStorePhone = storePhone.trim();
    final safeCustomer = customerName == null || customerName.trim().isEmpty
        ? 'Walk-in customer'
        : customerName.trim();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        ),
        header: (context) => _receiptHeader(
          storeName: cleanStoreName,
          storeAddress: cleanStoreAddress,
          storePhone: cleanStorePhone,
          receiptNumber: receiptNumber,
          date: date,
          time: time,
          customerName: safeCustomer,
        ),
        build: (context) => [
          pw.SizedBox(height: 16),
          _receiptIntro(
            itemCount: itemCount,
            total: total,
            cashTendered: cashTendered,
            changeDue: changeDue,
          ),
          pw.SizedBox(height: 20),
          _sectionTitle('Transaction Details'),
          pw.SizedBox(height: 8),
          _itemsTable(items),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Notes'),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'This is an official receipt for your purchase. Please keep it for your records.',
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 40),
              pw.Expanded(
                flex: 1,
                child: _paymentSummary(
                  subtotal: subtotal,
                  discount: discount,
                  discountLabel: discountLabel,
                  total: total,
                  cashTendered: cashTendered,
                  changeDue: changeDue,
                ),
              ),
            ],
          ),
        ],
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Thank you for shopping at $cleanStoreName',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
      ),
    );

    final bytes = await pdf.save();
    return _writePdfFile(bytes, receiptNumber);
  }

  static String _money(double value) {
    final whole = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(',');
      }
    }
    return 'TSh ${buffer.toString()}';
  }

  static String _cleanValue(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static Future<File> _writePdfFile(
      Uint8List bytes, String receiptNumber) async {
    final directory = await getTemporaryDirectory();
    final receiptsDir = Directory('${directory.path}/shared_receipts');
    if (!receiptsDir.existsSync()) {
      receiptsDir.createSync(recursive: true);
    }

    final safeName = receiptNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file = File('${receiptsDir.path}/$safeName.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static pw.Widget _receiptHeader({
    required String storeName,
    required String storeAddress,
    required String storePhone,
    required String receiptNumber,
    required String date,
    required String time,
    required String customerName,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  storeName.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1E293B'),
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 4),
                if (storeAddress.isNotEmpty)
                  pw.Text(
                    storeAddress,
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                if (storePhone.isNotEmpty)
                  pw.Text(
                    'Tel: $storePhone',
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'RECEIPT',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#E2E8F0'),
                  ),
                ),
                pw.Text(
                  '#$receiptNumber',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#64748B'),
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          height: 2,
          color: PdfColor.fromHex('#334155'),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _metaLine('Date', date),
            if (customerName != 'Walk-in customer')
              _metaLine('Customer', customerName),
          ],
        ),
      ],
    );
  }

  static pw.Widget _receiptIntro({
    required int itemCount,
    required double total,
    required double cashTendered,
    required double changeDue,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _miniMeta('TOTAL ITEMS', itemCount.toString()),
          _miniMeta('GRAND TOTAL', _money(total), highlight: true),
          _miniMeta('CHANGE DUE', _money(changeDue)),
        ],
      ),
    );
  }

  static pw.Widget _miniMeta(String label, String value, {bool highlight = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#94A3B8'),
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: highlight ? 12 : 10,
            fontWeight: pw.FontWeight.bold,
            color: highlight ? PdfColor.fromHex('#0F172A') : PdfColor.fromHex('#475569'),
          ),
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#475569'),
        letterSpacing: 0.8,
      ),
    );
  }

  static pw.Widget _metaLine(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColor.fromHex('#64748B'),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1E293B'),
          ),
        ),
      ],
    );
  }

  static pw.Widget _itemsTable(List<OrderLineItem> items) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(6),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(3),
        3: pw.FlexColumnWidth(4),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F1F5F9'),
          ),
          children: [
            _tableCell('ITEM DESCRIPTION', bold: true, fontSize: 8),
            _tableCell('QTY', bold: true, fontSize: 8, align: pw.TextAlign.center),
            _tableCell('PRICE', bold: true, fontSize: 8, align: pw.TextAlign.right),
            _tableCell('TOTAL', bold: true, fontSize: 8, align: pw.TextAlign.right),
          ],
        ),
        ...items.map(
          (line) => pw.TableRow(
            children: [
              _tableCell(line.product.name),
              _tableCell('${line.quantity}', align: pw.TextAlign.center),
              _tableCell(_money(line.product.priceValue), align: pw.TextAlign.right),
              _tableCell(_money(line.totalPrice), bold: true, align: pw.TextAlign.right),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _paymentSummary({
    required double subtotal,
    required double discount,
    required String? discountLabel,
    required double total,
    required double cashTendered,
    required double changeDue,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _summaryLine('Subtotal', _money(subtotal)),
        if (discount > 0)
          _summaryLine(
            discountLabel ?? 'Discount',
            '- ${_money(discount)}',
            color: PdfColor.fromHex('#E11D48'),
          ),
        pw.SizedBox(height: 4),
        pw.Container(height: 1, color: PdfColor.fromHex('#E2E8F0')),
        pw.SizedBox(height: 4),
        _summaryLine('Total Amount', _money(total), isBold: true, fontSize: 11),
        pw.SizedBox(height: 8),
        _summaryLine('Cash Tendered', _money(cashTendered), fontSize: 9),
        _summaryLine('Change Due', _money(changeDue), color: PdfColor.fromHex('#059669'), isBold: true, fontSize: 10),
      ],
    );
  }

  static pw.Widget _tableCell(
    String value, {
    bool bold = false,
    double fontSize = 8.5,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColor.fromHex('#1E293B'),
        ),
      ),
    );
  }

  static pw.Widget _summaryLine(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 9,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColor.fromHex('#475569'),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
              color: color ?? PdfColor.fromHex('#0F172A'),
            ),
          ),
        ],
      ),
    );
  }
}
