import '../../../l10n/app_strings.dart';
import 'package:track_mauzo/l10n/app_localization.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import '../models/report_models.dart';
import '../pos_report_data.dart';

class ExportPayload {
  const ExportPayload(this.bytes, this.fileName, this.mimeType);
  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

enum ExportFormat { json, xml, csv, txt, sql, excel, pdf }

extension ExportFormatLabel on ExportFormat {
  String get label {
    switch (this) {
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.xml:
        return 'XML';
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.txt:
        return 'TXT';
      case ExportFormat.sql:
        return 'SQL';
      case ExportFormat.excel:
        return 'Excel';
      case ExportFormat.pdf:
        return 'PDF';
    }
  }
}

class ReportExportService {
  static Future<void> exportReport({
    required BuildContext context,
    required ReportTable table,
    required String title,
    required ExportFormat format,
    DateTimeRange? range,
    bool isSnapshot = false,
  }) async {
    try {
      final export = await buildExport(
        table: table,
        title: title,
        format: format,
        range: range,
        isSnapshot: isSnapshot,
        languageCode: context.strings.languageCode,
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(export.bytes, mimeType: export.mimeType)],
          fileNameOverrides: [export.fileName],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        showMarketNotice(
          context,
          title: context.tr('Export failed'),
          message: '$e',
          type: MarketNoticeType.error,
        );
      }
    }
  }

  static Future<void> saveReport({
    required BuildContext context,
    required ReportTable table,
    required String title,
    required ExportFormat format,
    DateTimeRange? range,
    bool isSnapshot = false,
  }) async {
    try {
      final export = await buildExport(
        table: table,
        title: title,
        format: format,
        range: range,
        isSnapshot: isSnapshot,
        languageCode: context.strings.languageCode,
      );
      final directory = await _downloadDirectory();
      await directory.create(recursive: true);
      final file = File(
        '${directory.path}${Platform.pathSeparator}${export.fileName}',
      );
      await file.writeAsBytes(export.bytes, flush: true);
      if (context.mounted) {
        showMarketNotice(
          context,
          title: context.tr('Report saved'),
          message: context.tr('Downloaded to {p0}', args: {'p0': file.path}),
          type: MarketNoticeType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showMarketNotice(
          context,
          title: context.tr('Download failed'),
          message: '$e',
          type: MarketNoticeType.error,
        );
      }
    }
  }

  static Future<void> copyCsv(BuildContext context, ReportTable table) async {
    try {
      final text = utf8
          .decode(generateCsv(table), allowMalformed: true)
          .replaceFirst('\uFEFF', '');
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        showMarketNotice(
          context,
          title: context.tr('Copied'),
          message: context.tr('The report table was copied to the clipboard.'),
          type: MarketNoticeType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showMarketNotice(
          context,
          title: context.tr('Copy failed'),
          message: '$e',
          type: MarketNoticeType.error,
        );
      }
    }
  }

  static Future<Directory> _downloadDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    } catch (_) {}
    return getApplicationDocumentsDirectory();
  }

  static Future<ExportPayload> buildExport({
    required ReportTable table,
    required String title,
    required ExportFormat format,
    DateTimeRange? range,
    bool isSnapshot = false,
    String languageCode = 'en',
  }) async {
    final strings = AppStrings.of(languageCode);
    table = table.localized(strings);
    title = strings.text(title);
    switch (format) {
      case ExportFormat.json:
        return ExportPayload(
          generateJson(table, title, range),
          exportFileName(title, 'json'),
          'application/json',
        );
      case ExportFormat.xml:
        return ExportPayload(
          generateXml(table, title),
          exportFileName(title, 'xml'),
          'application/xml',
        );
      case ExportFormat.csv:
        return ExportPayload(
          generateCsv(table),
          exportFileName(title, 'csv'),
          'text/csv',
        );
      case ExportFormat.txt:
        return ExportPayload(
          generateTxt(table, title, range, isSnapshot, languageCode: languageCode),
          exportFileName(title, 'txt'),
          'text/plain',
        );
      case ExportFormat.sql:
        return ExportPayload(
          generateSql(table, title),
          exportFileName(title, 'sql'),
          'application/sql',
        );
      case ExportFormat.excel:
        return ExportPayload(
          generateExcel(table),
          exportFileName(title, 'xls'),
          'application/vnd.ms-excel',
        );
      case ExportFormat.pdf:
        return ExportPayload(
          await generatePdf(table, title, range, isSnapshot, languageCode: languageCode),
          exportFileName(title, 'pdf'),
          'application/pdf',
        );
    }
  }

  static Uint8List generateJson(
      ReportTable table, String title, DateTimeRange? range) {
    final headers = table.columns.map((c) => c.label).toList();
    final rows = table.rows.map((row) {
      final map = <String, Object?>{};
      for (var i = 0; i < headers.length; i++) {
        map[headers[i]] = i < row.length ? row[i] : null;
      }
      return map;
    }).toList();
    final payload = <String, Object?>{
      'report': title,
      'generated_at': DateTime.now().toIso8601String(),
      'range': range == null
          ? 'all'
          : {
              'start': range.start.toIso8601String(),
              'end': range.end.toIso8601String(),
            },
      'rows': rows,
    };
    const encoder = JsonEncoder.withIndent('  ');
    return Uint8List.fromList(utf8.encode(encoder.convert(payload)));
  }

  static Uint8List generateXml(ReportTable table, String title) {
    final b = StringBuffer();
    b.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    b.writeln('<report>');
    b.writeln('  <title>${_xmlEscape(title)}</title>');
    b.writeln(
        '  <generated_at>${_xmlEscape(DateTime.now().toIso8601String())}</generated_at>');
    b.writeln('  <rows>');
    final headers = table.columns.map((c) => c.label).toList();
    for (final row in table.rows) {
      b.writeln('    <row>');
      for (var i = 0; i < headers.length; i++) {
        final tag = _xmlTag(headers[i], i);
        final value =
            i < row.length ? exportCell(row[i], table.columns[i]) : '';
        b.writeln('      <$tag>${_xmlEscape(value)}</$tag>');
      }
      b.writeln('    </row>');
    }
    b.writeln('  </rows>');
    b.writeln('</report>');
    return Uint8List.fromList(utf8.encode(b.toString()));
  }

  static Uint8List generateCsv(ReportTable table) {
    final content = [
      table.columns.map((c) => _csvCell(c.label)).join(','),
      ...table.rows.map((row) => [
            for (var i = 0; i < table.columns.length; i++)
              _csvCell(
                  i < row.length ? exportCell(row[i], table.columns[i]) : '')
          ].join(',')),
    ].join('\r\n');
    return Uint8List.fromList(utf8.encode('\uFEFF$content'));
  }

  static Uint8List generateTxt(ReportTable table, String title,
      DateTimeRange? range, bool isSnapshot, {String languageCode = 'en'}) {
    final strings = AppStrings.of(languageCode);
    final headers = table.columns.map((c) => c.label).toList();
    final lines = <String>[
      title,
      if (isSnapshot)
        strings.text('Current snapshot')
      else if (range != null)
        '${DateFormat('yyyy-MM-dd').format(range.start)} - ${DateFormat('yyyy-MM-dd').format(range.end)}'
      else
        strings.text('All dates'),
      '',
      headers.join('\t'),
      ...table.rows.map((row) => [
            for (var i = 0; i < table.columns.length; i++)
              i < row.length ? exportCell(row[i], table.columns[i]) : ''
          ].join('\t')),
    ];
    return Uint8List.fromList(utf8.encode(lines.join('\r\n')));
  }

  static Uint8List generateSql(ReportTable table, String title) {
    final tableName =
        _sqlIdentifier(baseFileName(title).isEmpty ? 'report' : baseFileName(title));
    final cols = [
      for (var i = 0; i < table.columns.length; i++)
        _sqlIdentifier(table.columns[i].label, fallback: 'col_$i')
    ];
    final b = StringBuffer();
    b.writeln('-- $title');
    b.writeln('-- Generated ${DateTime.now().toIso8601String()}');
    b.writeln('CREATE TABLE IF NOT EXISTS $tableName (');
    b.writeln(cols.map((c) => '  $c TEXT').join(',\n'));
    b.writeln(');');
    for (final row in table.rows) {
      final values = [
        for (var i = 0; i < table.columns.length; i++)
          _sqlValue(i < row.length ? row[i] : null)
      ].join(', ');
      b.writeln(
          'INSERT INTO $tableName (${cols.join(', ')}) VALUES ($values);');
    }
    return Uint8List.fromList(utf8.encode(b.toString()));
  }

  static Uint8List generateExcel(ReportTable table) {
    final b = StringBuffer();
    b.writeln('<?xml version="1.0"?>');
    b.writeln('<?mso-application progid="Excel.Sheet"?>');
    b.writeln('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"');
    b.writeln(' xmlns:o="urn:schemas-microsoft-com:office:office"');
    b.writeln(' xmlns:x="urn:schemas-microsoft-com:office:excel"');
    b.writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">');
    b.writeln(' <Worksheet ss:Name="Report">');
    b.writeln('  <Table>');
    b.writeln('   <Row>');
    for (final column in table.columns) {
      b.writeln(
        '    <Cell><Data ss:Type="String">${_xmlEscape(column.label)}</Data></Cell>',
      );
    }
    b.writeln('   </Row>');
    for (final row in table.rows) {
      b.writeln('   <Row>');
      for (var i = 0; i < table.columns.length; i++) {
        final value = i < row.length ? row[i] : null;
        if (value is num && !table.columns[i].money) {
          b.writeln('    <Cell><Data ss:Type="Number">$value</Data></Cell>');
        } else {
          b.writeln(
            '    <Cell><Data ss:Type="String">${_xmlEscape(exportCell(value, table.columns[i]))}</Data></Cell>',
          );
        }
      }
      b.writeln('   </Row>');
    }
    b.writeln('  </Table>');
    b.writeln(' </Worksheet>');
    b.writeln('</Workbook>');
    return Uint8List.fromList(utf8.encode(b.toString()));
  }

  static Future<Uint8List> generatePdf(
    ReportTable table,
    String title,
    DateTimeRange? range,
    bool isSnapshot, {
    String languageCode = 'en',
  }) async {
    final strings = AppStrings.of(languageCode);
    table = table.localized(strings);
    title = strings.text(title);
    final pdf = pw.Document();
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final fontBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    final primary = PdfColor.fromHex('#2C3E50');
    final headerBg = PdfColor.fromHex('#ECF0F1');
    final border = PdfColor.fromHex('#DCE4EC');
    final rangeLabel = isSnapshot
        ? strings.text('Current snapshot')
        : range != null
            ? '${DateFormat('MMM d, yyyy', strings.languageCode).format(range.start)} – ${DateFormat('MMM d, yyyy', strings.languageCode).format(range.end)}'
            : strings.text('All Time');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 1, color: border)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(title,
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 18, color: primary)),
                  pw.SizedBox(height: 2),
                  pw.Text(rangeLabel,
                      style: pw.TextStyle(
                          font: font, fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
              pw.Text(
                  '${strings.text('Generated')} ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(
                      font: font, fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ),
        build: (context) => [
          if (table.rows.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Text(strings.text('No records available for the selected filters.'),
                  style: pw.TextStyle(font: font, fontSize: 11)),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: table.columns.map((c) => c.label).toList(),
              data: table.rows
                  .map((row) => [
                        for (var i = 0; i < table.columns.length; i++)
                          i < row.length
                              ? exportCell(row[i], table.columns[i])
                              : ''
                      ])
                  .toList(),
              headerStyle:
                  pw.TextStyle(font: fontBold, fontSize: 9, color: primary),
              headerDecoration: pw.BoxDecoration(color: headerBg),
              cellStyle: pw.TextStyle(font: font, fontSize: 8),
              cellAlignments: {
                for (var i = 0; i < table.columns.length; i++)
                  i: table.columns[i].money
                      ? pw.Alignment.centerRight
                      : pw.Alignment.centerLeft,
              },
              headerAlignments: {
                for (var i = 0; i < table.columns.length; i++)
                  i: table.columns[i].money
                      ? pw.Alignment.centerRight
                      : pw.Alignment.centerLeft,
              },
              border: pw.TableBorder.all(color: border, width: 0.5),
              headerPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
              '${strings.text('Page')} ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(
                  font: font, fontSize: 8, color: PdfColors.grey600)),
        ),
      ),
    );
    return pdf.save();
  }

  static String exportCell(Object? value, ReportColumn column) {
    if (value == null) return '';
    if (value is num) {
      final formatted = NumberFormat('#,##0.##').format(value);
      return column.money ? 'TSH $formatted' : formatted;
    }
    return value.toString();
  }

  static String _csvCell(Object? value) {
    if (value == null) return '';
    if (value is num) return value.toString();
    final original = value.toString();
    final text = RegExp(r'^[\s\uFEFF]*[=+@-]|^[\t\r\n]').hasMatch(original)
        ? "'$original"
        : original;
    return '"${text.replaceAll('"', '""')}"';
  }

  static String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static String _xmlTag(String label, int index) {
    var tag = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    tag = tag.replaceAll(RegExp(r'^_+|_+$'), '');
    if (tag.isEmpty) tag = 'col_$index';
    if (RegExp(r'^[0-9]').hasMatch(tag)) tag = 'c_$tag';
    return tag;
  }

  static String _sqlIdentifier(String raw, {String? fallback}) {
    var id = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    id = id.replaceAll(RegExp(r'^_+|_+$'), '');
    if (id.isEmpty) id = fallback ?? 'col';
    if (RegExp(r'^[0-9]').hasMatch(id)) id = 'c_$id';
    return id;
  }

  static String _sqlValue(Object? value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    final escaped = value.toString().replaceAll("'", "''");
    return "'$escaped'";
  }

  static String baseFileName(String title) => title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  static String exportFileName(String title, String ext) {
    final base = baseFileName(title).isEmpty ? 'report' : baseFileName(title);
    final stamp = DateFormat('yyyyMMddHHmm').format(DateTime.now());
    return '${base}_$stamp.$ext';
  }
}
