import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/product_item.dart';
import '../../receipt_brand_data.dart';
import '../widgets/app_design.dart';

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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
              // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        ReceiptBrandData.storeName.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#000000'),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Container(height: 1, width: 40, color: PdfColors.grey400),
                      pw.SizedBox(height: 8),
                      _muted('Tel: ${ReceiptBrandData.phone}'),
                    ],
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 24),
                  child: pw.Divider(color: PdfColors.grey300),
                ),

                // Meta
                _metaLine('Receipt #', receiptNumber),
                _metaLine('Date', '$date $time'),
                if (customerName != null) _metaLine('Customer', customerName!),
                _metaLine('Payment', 'Cash'),
                pw.SizedBox(height: 20),

                // Table
                _tableHeader(),
                ...items.map(_itemRow),

                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 16),
                  child: pw.Divider(thickness: 1.5, color: PdfColor.fromHex('#1F2937')),
                ),

                // Summary
                _summaryLine('Subtotal', _money(subtotal)),
                if (discountAmount != null && discountAmount > 0)
                  _summaryLine(discountLabel ?? 'Discount', '- ${_money(discountAmount)}', color: PdfColor.fromHex('#E11D48')),
                pw.SizedBox(height: 8),
                _summaryLine('Grand Total', _money(total), isBold: true, fontSize: 14),
                
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 12),
                  child: pw.Divider(color: PdfColor.fromHex('#E2E8F0')),
                ),
                
                _summaryLine('Cash Received', _money(cashTendered)),
                _summaryLine('Change Due', _money(changeDue), color: PdfColor.fromHex('#15803D'), isBold: true),

                pw.Spacer(),

                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'THANK YOU FOR YOUR BUSINESS',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'We value your trust. Please visit us again!',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    return _writePdfFile(bytes, receiptNumber);
  }

  static String _money(double value) {
    return 'TSh${value.toStringAsFixed(0)}';
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

  static pw.Widget _metaLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader() {
    return pw.Container(
      color: PdfColor.fromHex('#F0F0F0'),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 5, child: pw.Text('Item', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
          pw.Expanded(flex: 2, child: pw.Text('Qty', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
          pw.Expanded(flex: 3, child: pw.Text('Price', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
          pw.Expanded(flex: 4, child: pw.Text('Total', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  static pw.Widget _itemRow(OrderLineItem line) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200))),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 5, child: pw.Text(line.product.name, style: const pw.TextStyle(fontSize: 12))),
          pw.Expanded(flex: 2, child: pw.Text('${line.quantity}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 12))),
          pw.Expanded(flex: 3, child: pw.Text(_money(line.product.priceValue), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 12))),
          pw.Expanded(flex: 4, child: pw.Text(_money(line.totalPrice), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))),
        ],
      ),
    );
  }

  static pw.Widget _summaryLine(String label, String value, {bool isBold = false, double fontSize = 11, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  static pw.Text _muted(String value) {
    return pw.Text(value, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600));
  }
}
