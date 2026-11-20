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
import '../../models/customer_data.dart';
import '../../widgets/market_shared_widgets.dart';
import 'customer_models.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _formatMoney(double value) {
  final formatted = NumberFormat('#,##0.00').format(value);
  return 'TSh $formatted';
}

class CustomerExportService {
  static String _stamp() => DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

  static String _csvCell(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  static int _loyaltyPoints(double spent) => (spent / 1000).round();

  static Future<void> exportCsv(
    BuildContext context, {
    required List<CustomerData> rows,
    required Map<String, CustomerStats> stats,
    required AppStrings strings,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln(
        'Name,Phone,Email,Address,Orders,Total Spent,Points,Outstanding Debit,Joined,Tags');
    for (final c in rows) {
      final info = stats[c.name] ?? CustomerStats.empty;
      final cells = <String>[
        c.name,
        c.phone,
        c.email,
        c.address,
        '${info.orders + c.totalOrders}',
        (info.spent + c.totalSpent).toStringAsFixed(2),
        '${_loyaltyPoints(info.spent + c.totalSpent)}',
        c.debitBalance.toStringAsFixed(2),
        DateFormat('yyyy-MM-dd').format(c.createdAt),
        c.tags.join(' | '),
      ].map(_csvCell).join(',');
      buffer.writeln(cells);
    }
    await _shareBytes(
      context,
      Uint8List.fromList(utf8.encode(buffer.toString())),
      'customers_${_stamp()}.csv',
      'text/csv',
      strings,
    );
  }

  static Future<void> exportPdf(
    BuildContext context, {
    required List<CustomerData> rows,
    required Map<String, CustomerStats> stats,
    required AppStrings strings,
  }) async {
    final totalSpent = rows.fold<double>(
        0, (sum, c) => sum + (stats[c.name]?.spent ?? c.totalSpent));
    final outstanding = rows.fold<double>(0, (sum, c) => sum + c.debitBalance);
    final doc = pw.Document();

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
              pw.Text('Customer Report',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(
                  '${rows.length} customers · Lifetime sales ${_formatMoney(totalSpent)} · Outstanding ${_formatMoney(outstanding)}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
            ],
          ),
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headers: const [
              'Name',
              'Phone',
              'Orders',
              'Total Spent',
              'Points',
              'Debit',
              'Joined'
            ],
            data: rows.map((c) {
              final info = stats[c.name] ?? CustomerStats.empty;
              final spent = info.spent + c.totalSpent;
              return [
                c.name,
                c.phone,
                '${info.orders + c.totalOrders}',
                _formatMoney(spent),
                '${_loyaltyPoints(spent)}',
                c.debitBalance > 0 ? _formatMoney(c.debitBalance) : '—',
                DateFormat('yyyy-MM-dd').format(c.createdAt),
              ];
            }).toList(),
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
        bytes: await doc.save(), filename: 'customers_${_stamp()}.pdf');
  }

  static Future<void> _shareBytes(
    BuildContext context,
    Uint8List bytes,
    String name,
    String mime,
    AppStrings strings,
  ) async {
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
        title: _dual(strings, 'Export failed', 'Imeshindwa kuhamisha'),
        message: error.toString(),
        type: MarketNoticeType.warning,
      );
    }
  }
}
