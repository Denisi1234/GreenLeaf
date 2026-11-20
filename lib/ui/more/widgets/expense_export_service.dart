import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/expense_model.dart';
import '../../widgets/market_shared_widgets.dart';
import 'expense_models.dart';

class ExpenseExportService {
  const ExpenseExportService._();

  static Future<void> exportCsv({
    required BuildContext context,
    required List<Expense> expenses,
    required AppStrings strings,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(
        'Title,Vendor,Category,Payment Method,Date,Amount,Tax,Total,Status,Notes');
    for (final e in expenses) {
      final cells = <String>[
        e.title,
        e.vendor,
        e.category,
        e.paymentMethod,
        DateFormat('yyyy-MM-dd').format(e.date),
        e.amount.toStringAsFixed(2),
        e.taxAmount.toStringAsFixed(2),
        e.totalWithTax.toStringAsFixed(2),
        e.status.label,
        e.notes ?? '',
      ].map(_csvCell).join(',');
      buffer.writeln(cells);
    }
    await _shareBytes(
      context: context,
      strings: strings,
      bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
      name: 'expenses_${_stamp()}.csv',
      mime: 'text/csv',
    );
  }

  static Future<void> exportPdf({
    required BuildContext context,
    required List<Expense> expenses,
    required AppStrings strings,
  }) async {
    final doc = pw.Document();
    final total = expenses.fold<double>(0, (s, e) => s + e.totalWithTax);

    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(24),
        ),
        header: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Expense Report',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(
                  '${expenses.length} records · Total ${formatExpenseMoney(total)}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headers: const [
              'Title',
              'Vendor',
              'Category',
              'Payment',
              'Date',
              'Amount',
              'Tax',
              'Total',
              'Status'
            ],
            data: expenses
                .map((e) => [
                      e.title,
                      e.vendor,
                      e.category,
                      e.paymentMethod,
                      DateFormat('yyyy-MM-dd').format(e.date),
                      formatExpenseMoney(e.amount),
                      formatExpenseMoney(e.taxAmount),
                      formatExpenseMoney(e.totalWithTax),
                      e.status.label,
                    ])
                .toList(),
            headerStyle:
                pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'expenses_${_stamp()}.pdf',
    );
  }

  static Future<void> _shareBytes({
    required BuildContext context,
    required AppStrings strings,
    required Uint8List bytes,
    required String name,
    required String mime,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: mime)]),
      );
    } catch (error) {
      if (!context.mounted) return;
      showMarketNotice(
        context,
        title: expenseDual(strings, 'Export failed', 'Imeshindwa kuhamisha'),
        message: error.toString(),
        type: MarketNoticeType.warning,
      );
    }
  }

  static String _stamp() => DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

  static String _csvCell(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }
}
