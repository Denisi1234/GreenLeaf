import 'package:provider/provider.dart';
import '../../../service/pos_local_store.dart';
import '../../../service/report_pdf/report_pdf_layout.dart';
import '../../reports/pos_report_data.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../l10n/app_strings.dart';
import '../../models/customer_data.dart';
import '../../widgets/market_shared_widgets.dart';
import 'customer_models.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

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
        'Name,Phone,Email,Address,Orders,Total Spent,Points,Outstanding Debit,Joined,Tags'
            .split(',')
            .map(strings.text)
            .map(_csvCell)
            .join(','));
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
    ReportPdfContext? pdfContext,
  }) async {
    final reportContext = pdfContext ??
        ReportPdfContext.fromStore(context.read<PosLocalStore>(),
            languageCode: strings.languageCode);
    final bytes = await buildPdf(
        rows: rows, stats: stats, strings: strings, pdfContext: reportContext);
    await Printing.sharePdf(
        bytes: bytes, filename: 'customers_${_stamp()}.pdf');
  }

  static Future<Uint8List> buildPdf({
    required List<CustomerData> rows,
    required Map<String, CustomerStats> stats,
    required AppStrings strings,
    ReportPdfContext? pdfContext,
  }) {
    final context =
        pdfContext ?? ReportPdfContext(languageCode: strings.languageCode);
    final totalSpent = rows.fold<double>(
        0, (sum, c) => sum + (stats[c.name]?.spent ?? 0) + c.totalSpent);
    final outstanding = rows.fold<double>(0, (sum, c) => sum + c.debitBalance);
    String money(double amount) =>
        '${context.currency} ${NumberFormat('#,##0.00', context.languageCode).format(amount)}';
    return ReportPdfLayout.tableDocument(
      title: context.label('Customer Report'),
      context: context,
      subtitle: context.label('Current snapshot'),
      table: ReportTable(const [
        ReportColumn('Name'),
        ReportColumn('Phone'),
        ReportColumn('Orders'),
        ReportColumn('Total Spent', money: true),
        ReportColumn('Points'),
        ReportColumn('Debit', money: true),
        ReportColumn('Joined'),
      ], [
        for (final c in rows)
          [
            c.name,
            c.phone,
            (stats[c.name]?.orders ?? 0) + c.totalOrders,
            (stats[c.name]?.spent ?? 0) + c.totalSpent,
            _loyaltyPoints((stats[c.name]?.spent ?? 0) + c.totalSpent),
            c.debitBalance,
            DateFormat('yyyy-MM-dd').format(c.createdAt),
          ]
      ]),
      summary: [
        MapEntry(context.label('Customers'), '${rows.length}'),
        MapEntry(context.label('Total spent'), money(totalSpent)),
        MapEntry(context.label('Outstanding balance'), money(outstanding)),
      ],
    );
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
