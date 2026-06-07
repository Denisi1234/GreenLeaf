import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/product_item.dart';
import '../../receipt_brand_data.dart';

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
    String? customerName,
    double? discountAmount,
    String? discountLabel,
  }) async {
    final pdf = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    final subtotal = items.fold<double>(0, (sum, line) => sum + line.totalPrice);
    final discount = discountAmount ?? 0;
    final itemCount = items.fold<int>(0, (sum, line) => sum + line.quantity);
    final safeCustomer = customerName == null || customerName.trim().isEmpty
        ? 'Walk-in customer'
        : customerName.trim();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(24, 22, 24, 26),
          theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Watermark.text(
              'OFFICIAL RECEIPT',
              style: pw.TextStyle(
                color: PdfColor.fromHex('#F4F7FB'),
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
              angle: -math.pi / 4,
            ),
          ),
        ),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: _receiptHeader(
            receiptNumber: receiptNumber,
            date: date,
            time: time,
            cashier: cashier,
            register: register,
            customerName: safeCustomer,
          ),
        ),
        build: (context) => [
          _receiptIntro(
            itemCount: itemCount,
            total: total,
            cashTendered: cashTendered,
            changeDue: changeDue,
          ),
          pw.SizedBox(height: 12),
          _sectionTitle('Items Purchased'),
          pw.SizedBox(height: 6),
          _itemsTable(items),
          pw.SizedBox(height: 12),
          _sectionTitle('Payment Summary'),
          pw.SizedBox(height: 6),
          _paymentSummary(
            subtotal: subtotal,
            discount: discount,
            discountLabel: discountLabel,
            total: total,
            cashTendered: cashTendered,
            changeDue: changeDue,
          ),
        ],
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${ReceiptBrandData.storeName} | Official sale receipt',
                style: const pw.TextStyle(
                  fontSize: 8.3,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber}/${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8.3,
                  color: PdfColors.grey600,
                ),
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

  static Future<File> _writePdfFile(Uint8List bytes, String receiptNumber) async {
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
    required String receiptNumber,
    required String date,
    required String time,
    required String cashier,
    required String register,
    required String customerName,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColor.fromHex('#DCE4EE'), width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'OFFICIAL RECEIPT',
                style: pw.TextStyle(
                  fontSize: 8.8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#64748B'),
                  letterSpacing: 0.8,
                ),
              ),
              pw.Text(
                receiptNumber,
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            ReceiptBrandData.storeName,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Official sale receipt',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#334155'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${ReceiptBrandData.address} | ${ReceiptBrandData.cityStateZip}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Tel: ${ReceiptBrandData.phone}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _metaTag('Date', '$date $time'),
              _metaTag('Cashier', cashier),
              _metaTag('Register', register),
              _metaTag('Customer', customerName),
              _metaTag('Receipt', receiptNumber),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaTag(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
              fontSize: 7.6,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
        ],
      ),
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
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2'), width: 0.7),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(child: _miniStat('Items', itemCount.toString())),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _miniStat('Total', _money(total))),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _miniStat('Tendered', _money(cashTendered))),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _miniStat('Change', _money(changeDue))),
        ],
      ),
    );
  }

  static pw.Widget _miniStat(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(3),
        border: pw.Border.all(color: PdfColor.fromHex('#EDF2F7'), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 7.6,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9.2,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 12.5,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#0F172A'),
      ),
    );
  }

  static pw.Widget _itemsTable(List<OrderLineItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromHex('#EDF2F7'),
        width: 0.35,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(3),
        3: pw.FlexColumnWidth(4),
      },
      children: [
        pw.TableRow(
          children: [
            _tableCell('Item', bold: true),
            _tableCell('Qty', bold: true, align: pw.TextAlign.center),
            _tableCell('Price', bold: true, align: pw.TextAlign.right),
            _tableCell('Total', bold: true, align: pw.TextAlign.right),
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
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: PdfColor.fromHex('#E6EBF2'), width: 0.7),
      ),
      child: pw.Column(
        children: [
          _summaryLine('Subtotal', _money(subtotal)),
          if (discount > 0)
            _summaryLine(
              discountLabel ?? 'Discount',
              '- ${_money(discount)}',
              color: PdfColor.fromHex('#C81E5B'),
            ),
          pw.Divider(color: PdfColor.fromHex('#E6EBF2'), height: 14),
          _summaryLine('Grand Total', _money(total), isBold: true, fontSize: 14),
          pw.Divider(color: PdfColor.fromHex('#E6EBF2'), height: 14),
          _summaryLine('Cash Received', _money(cashTendered)),
          _summaryLine(
            'Change Due',
            _money(changeDue),
            color: PdfColor.fromHex('#166534'),
            isBold: true,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Thank you for your business',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              letterSpacing: 0.8,
              color: PdfColor.fromHex('#334155'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(
    String value, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9.2,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColor.fromHex('#0F172A'),
        ),
      ),
    );
  }

  static pw.Widget _summaryLine(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 10.5,
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
              color: PdfColor.fromHex('#334155'),
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
