import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../ui/reports/pos_report_data.dart';
import 'report_pdf_context.dart';

export 'report_pdf_context.dart';

/// Shared print design based on the shop stock-list reference document.
class ReportPdfLayout {
  static const teal = PdfColor.fromInt(0xff0f766e);
  static const ink = PdfColor.fromInt(0xff1e293b);
  static const muted = PdfColor.fromInt(0xff475569);
  static const grid = PdfColor.fromInt(0xffcbd5e1);
  static const pale = PdfColor.fromInt(0xfff8fafc);
  static const portraitMargin = 51.0;
  static const landscapeMargin = 36.0;

  static PdfPageFormat pageFormatFor(int dataColumns) =>
      dataColumns > 6 ? PdfPageFormat.a4.landscape : PdfPageFormat.a4;

  static Future<Uint8List> tableDocument({
    required String title,
    required ReportTable table,
    required ReportPdfContext context,
    String? subtitle,
    List<MapEntry<String, String>> details = const [],
    List<MapEntry<String, String>> summary = const [],
  }) =>
      buildDocument(
        title: context.strings.text(title),
        context: context,
        subtitle: subtitle,
        dataColumns: table.columns.length,
        body: (_) => [
          if (details.isNotEmpty) ...[
            metadata(details),
            pw.SizedBox(height: 14),
          ],
          tableWidget(table: table, context: context),
          if (summary.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            sectionTitle(context.label('Summary')),
            pw.SizedBox(height: 6),
            metadata(summary),
          ],
          if (table.note?.trim().isNotEmpty == true) ...[
            pw.SizedBox(height: 16),
            ...noteWidgets(context.paragraph(table.note!), context),
          ],
        ],
      );

  /// Also hosts the analytical report's existing narrative and chart sections.
  static Future<Uint8List> buildDocument({
    required String title,
    required ReportPdfContext context,
    required List<pw.Widget> Function(pw.Context) body,
    String? subtitle,
    int dataColumns = 0,
  }) async {
    await initializeDateFormatting(context.strings.languageCode);
    final regular =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    final format = pageFormatFor(dataColumns);
    final margin = dataColumns > 6 ? landscapeMargin : portraitMargin;
    final document = pw.Document(
        title: title,
        author: context.businessName,
        creator: 'TrackMauzo',
        compress: true);
    document.addPage(pw.MultiPage(
      maxPages: 10000,
      pageTheme: pw.PageTheme(
          pageFormat: format,
          margin: pw.EdgeInsets.fromLTRB(margin, 42, margin, 36),
          theme: pw.ThemeData.withFont(base: regular, bold: bold).copyWith(
            defaultTextStyle: const pw.TextStyle(fontSize: 10, color: ink),
          )),
      header: (page) => _header(title, subtitle, context, page.pageNumber == 1),
      footer: (page) => _footer(title, context, page),
      build: body,
    ));
    return document.save();
  }

  static pw.Widget _header(String title, String? subtitle,
          ReportPdfContext context, bool firstPage) =>
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(firstPage ? title.toUpperCase() : title,
              style: pw.TextStyle(
                  fontSize: firstPage ? 20 : 12,
                  fontWeight: pw.FontWeight.bold,
                  color: teal)),
          if (firstPage && subtitle?.isNotEmpty == true) ...[
            pw.SizedBox(height: 6),
            pw.Text(subtitle!,
                style: const pw.TextStyle(fontSize: 10.5, color: muted)),
          ],
          pw.SizedBox(height: firstPage ? 12 : 6),
          pw.Container(height: 1.5, color: teal),
          if (firstPage) ...[
            pw.SizedBox(height: 14),
            _identity(context),
            if (context.period.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              pw.Text('${context.label('Period')}: ${context.period}',
                  style: const pw.TextStyle(fontSize: 9, color: muted)),
            ],
            if (context.filterSummary.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text('${context.label('Filters')}: ${context.filterSummary}',
                  style: const pw.TextStyle(fontSize: 9, color: muted)),
            ],
          ] else ...[
            pw.SizedBox(height: 5),
            pw.Text(
                [context.businessName, context.reportReference]
                    .where((s) => s.isNotEmpty)
                    .join(' | '),
                style: const pw.TextStyle(fontSize: 8, color: muted)),
          ],
          pw.SizedBox(height: firstPage ? 16 : 10),
        ],
      );

  static pw.Widget _identity(ReportPdfContext context) => pw.Table(
        border: pw.TableBorder.all(color: grid, width: .7),
        columnWidths: const {
          0: pw.FlexColumnWidth(1.1),
          1: pw.FlexColumnWidth(2),
          2: pw.FlexColumnWidth(1.1),
          3: pw.FlexColumnWidth(2)
        },
        children: [
          pw.TableRow(
              decoration: const pw.BoxDecoration(color: pale),
              children: [
                cell(context.label('Store name'), bold: true),
                cell(_value(context.businessName)),
                cell(context.label('Date'), bold: true),
                cell(context.dateLabel),
              ]),
          pw.TableRow(
              decoration: const pw.BoxDecoration(color: pale),
              children: [
                cell(context.label('Prepared by'), bold: true),
                cell(_value(context.preparedBy)),
                cell(context.label('Reference'), bold: true),
                cell(context.reportReference),
              ]),
        ],
      );

  static pw.Widget _footer(
          String title, ReportPdfContext context, pw.Context page) =>
      pw.Container(
          margin: const pw.EdgeInsets.only(top: 14),
          padding: const pw.EdgeInsets.only(top: 9),
          decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: grid, width: .5))),
          child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                    child: pw.Text(title,
                        style: const pw.TextStyle(fontSize: 8, color: muted))),
                pw.SizedBox(width: 16),
                pw.Text(
                    '${context.label('Page')} ${page.pageNumber} ${context.label('of')} ${page.pagesCount}',
                    style: const pw.TextStyle(fontSize: 8, color: muted)),
              ]));

  static pw.Widget sectionTitle(String title) => pw.Text(title,
      style: pw.TextStyle(
          fontSize: 12, fontWeight: pw.FontWeight.bold, color: teal));

  static pw.Widget metadata(List<MapEntry<String, String>> values) => pw.Table(
        border: pw.TableBorder.all(color: grid, width: .6),
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(3)
        },
        children: [
          for (final value in values)
            pw.TableRow(
                decoration: const pw.BoxDecoration(color: pale),
                children: [
                  cell(value.key, bold: true),
                  cell(_value(value.value)),
                ])
        ],
      );

  static pw.Widget cell(String text,
          {bool bold = false,
          bool header = false,
          pw.TextAlign align = pw.TextAlign.left,
          double fontSize = 9.5}) =>
      pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          child: pw.Text(text,
              textAlign: align,
              softWrap: true,
              style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: bold || header
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  color: header ? PdfColors.white : ink)));

  static pw.Widget tableWidget(
      {required ReportTable table, required ReportPdfContext context}) {
    final localized = table.localized(context.strings);
    final columns = localized.columns;
    if (columns.isEmpty) {
      return pw.Text(
          context.label('No records available for the selected filters.'));
    }
    final wide = columns.length > 6;
    final size = wide ? 9.0 : 9.5;
    final width = pageFormatFor(columns.length).width -
        2 * (wide ? landscapeMargin : portraitMargin);
    final numeric = [
      for (var i = 0; i < columns.length; i++)
        columns[i].money ||
            (localized.rows.any((r) => i < r.length && r[i] is num) &&
                localized.rows
                    .every((r) => i >= r.length || r[i] == null || r[i] is num))
    ];
    // Compact codes and quantities leave room for descriptions and prices.
    final weights = [
      for (var i = 0; i < columns.length; i++)
        _columnWidth(columns[i], localized.rows, i, numeric[i], size, context)
    ];
    final sumWeights = weights.fold<double>(0, (a, b) => a + b);
    const indexWidth = 36.0;
    final expanded = <(String, List<String>)>[];
    for (var r = 0; r < localized.rows.length; r++) {
      final row = localized.rows[r];
      final chunks = [
        for (var c = 0; c < columns.length; c++)
          _splitCell(
              _format(c < row.length ? row[c] : null, columns[c], context),
              math.max(
                  4,
                  (((width - indexWidth) * weights[c] / sumWeights - 16) /
                          (size * .95))
                      .floor()))
      ];
      final count =
          chunks.fold<int>(1, (n, parts) => math.max(n, parts.length));
      for (var part = 0; part < count; part++) {
        expanded.add((
          '${r + 1}${part == 0 ? '' : '\n${context.label('(cont.)')}'}',
          [
            for (final segments in chunks)
              part < segments.length ? segments[part] : ''
          ]
        ));
      }
    }
    final rendered = pw.Table(
        border: pw.TableBorder.all(color: grid, width: .6),
        columnWidths: {
          0: const pw.FixedColumnWidth(indexWidth),
          for (var i = 0; i < weights.length; i++)
            i + 1: pw.FlexColumnWidth(weights[i])
        },
        children: [
          pw.TableRow(
              repeat: true,
              decoration: const pw.BoxDecoration(color: teal),
              children: [
                cell(context.label('No.'), header: true, fontSize: size),
                for (var c = 0; c < columns.length; c++)
                  cell(
                      columns[c].money
                          ? '${columns[c].label}\n(${context.currency})'
                          : columns[c].label,
                      header: true,
                      fontSize: size,
                      align:
                          numeric[c] ? pw.TextAlign.right : pw.TextAlign.left),
              ]),
          for (final row in expanded)
            pw.TableRow(children: [
              cell(row.$1, align: pw.TextAlign.center, fontSize: 8),
              for (var c = 0; c < columns.length; c++)
                cell(row.$2[c],
                    fontSize: size,
                    align: numeric[c] ? pw.TextAlign.right : pw.TextAlign.left),
            ]),
        ]);
    if (expanded.isEmpty) {
      return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.stretch, children: [
        rendered,
        pw.Container(padding: const pw.EdgeInsets.all(16),
          decoration: const pw.BoxDecoration(border: pw.Border(
            left: pw.BorderSide(color: grid, width: .6), right: pw.BorderSide(color: grid, width: .6),
            bottom: pw.BorderSide(color: grid, width: .6))),
          child: pw.Text(context.label('No records available for the selected filters.'),
            textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9.5, color: muted))),
      ]);
    }
    return rendered;
  }

  static String _format(
      Object? value, ReportColumn column, ReportPdfContext context) {
    if (value == null) return '-';
    if (value is num) {
      final number = NumberFormat(column.money ? '#,##0.00' : '#,##0.##',
              context.strings.languageCode)
          .format(value);
      return number;
    }
    return column.systemLabels
        ? context.label(value.toString())
        : value.toString();
  }

  static double _columnWidth(ReportColumn column, List<List<Object?>> rows,
      int index, bool numeric, double size, ReportPdfContext context) {
    final words = column.label.split(RegExp(r'\s+'));
    final longestWord =
        words.fold<int>(0, (n, word) => math.max(n, word.runes.length));
    final labelWidth = longestWord * size * .58 + 18;
    var contentWidth = numeric ? (column.money ? 64.0 : 40.0) : 50.0;
    for (final row in rows.take(100)) {
      final text =
          _format(index < row.length ? row[index] : null, column, context);
      contentWidth =
          math.max(contentWidth, text.runes.length * size * .52 + 18);
    }
    return math.max(
        labelWidth, math.min(contentWidth, numeric ? 115.0 : 135.0));
  }

  // Table rows cannot span pages. Split exceptionally long cells into bounded
  // continuation rows; short numeric cells appear only on the first row.
  static List<String> _splitCell(String text, int lineWidth) {
    final lines = text.split('\n');
    final count = lines.fold<int>(0,
        (n, line) => n + math.max(1, (line.runes.length / lineWidth).ceil()));
    if (count <= 10) return [text];
    final wrapped = <String>[];
    for (final line in lines) {
      final chars = line.runes.toList();
      if (chars.isEmpty) wrapped.add('');
      for (var start = 0; start < chars.length;) {
        var end = math.min(start + lineWidth, chars.length);
        if (end < chars.length) {
          for (var at = end - 1; at > start; at--) {
            if (chars[at] == 32) {
              end = at + 1;
              break;
            }
          }
        }
        wrapped.add(String.fromCharCodes(chars.sublist(start, end)));
        start = end;
      }
    }
    return [
      for (var i = 0; i < wrapped.length; i += 10)
        wrapped.sublist(i, math.min(i + 10, wrapped.length)).join('\n')
    ];
  }

  static List<pw.Widget> noteWidgets(String note, ReportPdfContext context) => [
        sectionTitle(context.label('Notes')),
        pw.SizedBox(height: 5),
        for (final part in _splitCell(note, 75))
          pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.only(left: 9),
              decoration: const pw.BoxDecoration(
                  border:
                      pw.Border(left: pw.BorderSide(color: teal, width: 2))),
              child: pw.Text(part,
                  style: const pw.TextStyle(
                      fontSize: 9, color: muted, lineSpacing: 2))),
      ];

  static String _value(String value) => value.trim().isEmpty ? '-' : value;
}
