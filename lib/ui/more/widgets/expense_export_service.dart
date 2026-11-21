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
        'Title,Vendor,Category,Payment Method,Date,Amount,Tax,Total,Status,Notes'
            .split(',')
            .map(strings.text)
            .map(_csvCell)
            .join(','));
    for (final e in expenses) {
      final cells = <String>[
        e.title,
        e.vendor,
        e.category,
        strings.text(e.paymentMethod),
        DateFormat('yyyy-MM-dd').format(e.date),
        e.amount.toStringAsFixed(2),
        e.taxAmount.toStringAsFixed(2),
        e.totalWithTax.toStringAsFixed(2),
        strings.text(e.status.label),
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
    ReportPdfContext? pdfContext,
  }) async {
    final reportContext = pdfContext ??
        ReportPdfContext.fromStore(context.read<PosLocalStore>(),
            languageCode: strings.languageCode);
    final bytes = await buildPdf(
        expenses: expenses, strings: strings, pdfContext: reportContext);
    await Printing.sharePdf(bytes: bytes, filename: 'expenses_${_stamp()}.pdf');
  }

  static Future<Uint8List> buildPdf({
    required List<Expense> expenses,
    required AppStrings strings,
    ReportPdfContext? pdfContext,
  }) {
    final context =
        pdfContext ?? ReportPdfContext(languageCode: strings.languageCode);
    final total = expenses.fold<double>(0, (sum, e) => sum + e.totalWithTax);
    return ReportPdfLayout.tableDocument(
      title: context.label('Expense Report'),
      context: context,
      subtitle: context.label('Report results'),
      table: ReportTable(const [
        ReportColumn('Title'),
        ReportColumn('Vendor'),
        ReportColumn('Category'),
        ReportColumn('Payment'),
        ReportColumn('Date'),
        ReportColumn('Amount', money: true),
        ReportColumn('Tax', money: true),
        ReportColumn('Total', money: true),
        ReportColumn('Status'),
      ], [
        for (final e in expenses)
          [
            e.title,
            e.vendor,
            e.category,
            e.paymentMethod,
            DateFormat('yyyy-MM-dd').format(e.date),
            e.amount,
            e.taxAmount,
            e.totalWithTax,
            e.status.localized(context.strings.isSwahili),
          ]
      ]),
      summary: [
        MapEntry(context.label('Records'), '${expenses.length}'),
        MapEntry(context.label('Total expenses'),
            '${context.currency} ${NumberFormat('#,##0.00', context.languageCode).format(total)}'),
      ],
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
