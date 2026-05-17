import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/product_item.dart';
import 'package:possystem/receipt_brand_data.dart';

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
  }) async {
    final pdf = pw.Document();
    final baseFont = await PdfGoogleFonts.notoSansRegular();
    final boldFont = await PdfGoogleFonts.notoSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(
          base: baseFont,
          bold: boldFont,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Receipt Preview',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(18),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(14),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      ReceiptBrandData.storeName,
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    _muted(ReceiptBrandData.address),
                    _muted(ReceiptBrandData.cityStateZip),
                    _muted(ReceiptBrandData.phone),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 10),
                    _metaRow('Receipt #:', receiptNumber),
                    _metaRow('Date:', date),
                    _metaRow('Time:', time),
                    _metaRow('Cashier:', cashier),
                    _metaRow('Register:', register),
                    pw.SizedBox(height: 16),
                    _tableHeader(),
                    ...items.map(_itemRow),
                    pw.SizedBox(height: 14),
                    _amountRow('Subtotal', total),
                    _amountRow('Cash Tendered', cashTendered),
                    _amountRow('Change Due', changeDue),
                    pw.SizedBox(height: 10),
                    pw.Divider(color: PdfColors.grey400),
                    pw.SizedBox(height: 10),
                    _amountRow('Total', total, isLarge: true),
                    pw.SizedBox(height: 18),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F3FAF5'),
                        border: pw.Border.all(color: PdfColor.fromHex('#DDECDD')),
                        borderRadius: pw.BorderRadius.circular(10),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Payment Method',
                                  style: pw.TextStyle(
                                    color: PdfColor.fromHex('#2A7A46'),
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  'Cash',
                                  style: pw.TextStyle(
                                    fontSize: 14,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.Text(
                          'TSH ${total.toStringAsFixed(0)}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 22),
                    pw.Center(
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Thank you for your purchase!',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#2A7A46'),
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          _muted('We appreciate your business.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    return _writePdfFile(bytes, receiptNumber);
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

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 11.5),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8F9FB'),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(flex: 6, child: _headerText('Item')),
          pw.Expanded(flex: 2, child: pw.Center(child: _headerText('Qty'))),
          pw.Expanded(flex: 3, child: pw.Align(alignment: pw.Alignment.centerRight, child: _headerText('Price'))),
          pw.Expanded(flex: 3, child: pw.Align(alignment: pw.Alignment.centerRight, child: _headerText('Subtotal'))),
        ],
      ),
    );
  }

  static pw.Widget _itemRow(OrderLineItem line) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 9),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey200),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  line.product.name,
                  style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  line.product.size,
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Center(
              child: pw.Text('${line.quantity}', style: const pw.TextStyle(fontSize: 11.5)),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'TSH ${line.product.priceValue.toStringAsFixed(0)}',
                style: const pw.TextStyle(fontSize: 11.5),
              ),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'TSH ${line.totalPrice.toStringAsFixed(0)}',
                style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _amountRow(String label, double value, {bool isLarge = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: isLarge ? 15 : 12.5,
                fontWeight: isLarge ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
          pw.Text(
            'TSH ${value.toStringAsFixed(0)}',
            style: pw.TextStyle(
              fontSize: isLarge ? 15 : 12.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Text _headerText(String value) {
    return pw.Text(
      value,
      style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold),
    );
  }

  static pw.Text _muted(String value) {
    return pw.Text(
      value,
      style: const pw.TextStyle(fontSize: 11.5, color: PdfColors.grey700),
    );
  }
}
