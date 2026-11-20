import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../service/pos_order_models.dart';
import '../../service/receipt_settings.dart';
import '../models/product_item.dart';
import 'receipt_document.dart';

class ReceiptPdfService {
  /// Bundled fonts keep receipt generation available without an internet connection.
  static Future<Uint8List> buildReceiptBytes(ReceiptDocument receipt) async {
    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    final ink = PdfColor.fromHex('#111827');
    final muted = PdfColor.fromHex('#64748B');
    final border = PdfColor.fromHex('#E2E8F0');
    pw.MemoryImage? logo;
    final logoPath = receipt.storeLogoPath;
    if (logoPath != null &&
        logoPath.isNotEmpty &&
        !logoPath.startsWith('http')) {
      try {
        final file = File(logoPath);
        if (await file.exists())
          logo = pw.MemoryImage(await file.readAsBytes());
      } catch (_) {/* The business name remains available without a logo. */}
    }
    final pdf = pw.Document(
        title: '${receipt.label('Receipt')} ${receipt.order.receiptNo}',
        author: receipt.businessName,
        creator: 'TrackMauzo');
    pdf.addPage(pw.MultiPage(
      pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(base: regular, bold: bold)),
      header: (_) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 16),
        decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: border))),
        child:
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          if (logo != null) ...[
            pw.Image(logo, width: 48, height: 48, fit: pw.BoxFit.contain),
            pw.SizedBox(width: 14)
          ],
          pw.Expanded(
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                pw.Text(receipt.businessName,
                    style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: ink)),
                if (receipt.settings.showStoreContact &&
                    receipt.storeAddress.trim().isNotEmpty)
                  pw.Text(receipt.storeAddress,
                      style: pw.TextStyle(fontSize: 10, color: muted)),
                if (receipt.settings.showStoreContact &&
                    receipt.storePhone.trim().isNotEmpty)
                  pw.Text(receipt.storePhone,
                      style: pw.TextStyle(fontSize: 10, color: muted)),
                if (receipt.settings.showTaxId &&
                    receipt.storeTaxId.trim().isNotEmpty)
                  pw.Text('TIN: ${receipt.storeTaxId}',
                      style: pw.TextStyle(fontSize: 10, color: muted)),
              ])),
          pw.SizedBox(width: 12),
          pw.Text(receipt.label(receipt.isVoided ? 'VOID' : 'RECEIPT'),
              style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: receipt.isVoided ? PdfColors.red800 : ink)),
        ]),
      ),
      footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                    child: pw.Text(receipt.footer,
                        style: pw.TextStyle(fontSize: 9, color: muted))),
                pw.Text('${context.pageNumber} / ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 9, color: muted)),
              ])),
      build: (_) => [
        pw.SizedBox(height: 16),
        if (receipt.settings.header.trim().isNotEmpty) ...[
          pw.Text(receipt.settings.header),
          pw.SizedBox(height: 12)
        ],
        pw.Wrap(spacing: 24, runSpacing: 8, children: [
          for (final item in receipt.metadata)
            pw.SizedBox(
                width: 220,
                child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item.key,
                          style: pw.TextStyle(fontSize: 9, color: muted)),
                      pw.SizedBox(height: 2),
                      pw.Text(item.value,
                          style: pw.TextStyle(fontSize: 10, color: ink)),
                    ])),
        ]),
        pw.SizedBox(height: 24),
        pw.TableHelper.fromTextArray(
          headers: ['Item', 'Quantity', 'Unit price', 'Amount'].map(receipt.label).toList(),
          data: [
            for (final line in receipt.order.lines)
              [
                line.itemName,
                '${line.quantity}',
                receipt.money(line.unitPriceValue),
                receipt.money(line.lineTotal)
              ]
          ],
          border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: border, width: 0.5)),
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2)
          },
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight
          },
          cellPadding:
              const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          headerDecoration:
              pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
          headerStyle: pw.TextStyle(font: bold, fontSize: 10, color: ink),
          cellStyle: pw.TextStyle(font: regular, fontSize: 10, color: ink),
        ),
        pw.SizedBox(height: 20),
        for (final total in receipt.totals)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6),
            child: pw.Row(children: [
              pw.Spacer(),
              pw.SizedBox(
                  width: 260,
                  child: pw.Row(children: [
                    pw.Expanded(
                        child: pw.Text(total.key,
                            style: pw.TextStyle(fontSize: 11, color: muted))),
                    pw.Text(total.value,
                        style: pw.TextStyle(
                            fontSize: total.key == receipt.label('Total') ? 16 : 11,
                            fontWeight: total.key == receipt.label('Total')
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                            color: ink)),
                  ]))
            ]),
          ),
      ],
    ));
    return pdf.save();
  }

  static Future<File> writeReceiptPdf(ReceiptDocument receipt) async {
    final bytes = await buildReceiptBytes(receipt);
    final directory = await getTemporaryDirectory();
    final safe =
        receipt.order.receiptNo.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final file =
        File('${directory.path}${Platform.pathSeparator}receipt_$safe.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Compatibility entry point for callers that supply cart lines.
  static Future<File> createReceiptPdf(
          {required List<OrderLineItem> items,
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
          required String paymentMethod,
          String storeTaxId = '',
          String? storeLogoPath,
          String header = '',
          String footer = '',
          String? customerName,
          double? discountAmount,
          String? discountLabel,
          bool showTaxId = true,
          bool showOrderNumber = true,
          bool showDateTime = true,
          bool showCashier = true,
          bool showCustomer = true,
          bool showPaymentMethod = true,
          bool showItemCount = true,
          bool showDiscount = true,
          String currency = 'TSh',
          String languageCode = 'en'}) =>
      writeReceiptPdf(ReceiptDocument(
        languageCode: languageCode,
        order: CompletedOrder(
          id: receiptNumber,
          dateTime: '$date $time',
          date: date,
          time: time,
          total: total,
          status: 'Completed',
          cashierName: cashier,
          register: register,
          paymentMethod: paymentMethod,
          cashTendered: cashTendered,
          changeDue: changeDue,
          customerName: customerName,
          discountAmount: discountAmount,
          discountLabel: discountLabel,
          lines: [
            for (final line in items)
              OrderLine(
                  itemCode: line.product.code,
                  itemCategory: line.product.category,
                  itemName: line.product.name,
                  itemSize: line.product.size,
                  quantity: line.quantity,
                  unitPrice: line.product.price,
                  unitPriceValue: line.product.priceValue,
                  artType: line.product.type,
                  imagePath: line.product.imagePath)
          ],
        ),
        storeName: storeName,
        storeAddress: storeAddress,
        storePhone: storePhone,
        storeTaxId: storeTaxId,
        storeLogoPath: storeLogoPath,
        currency: currency,
        settings: ReceiptSettings(
            header: header,
            footer: footer,
            showTaxId: showTaxId,
            showOrderNumber: showOrderNumber,
            showDateTime: showDateTime,
            showCashier: showCashier,
            showCustomer: showCustomer,
            showPaymentMethod: showPaymentMethod,
            showItemCount: showItemCount,
            showDiscount: showDiscount),
      ));
}
