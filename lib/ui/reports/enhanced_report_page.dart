import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'models/report_models.dart';
import '../accounting/accounts_page.dart';
import '../accounting/bank_reconciliation_page.dart';
import '../accounting/fixed_assets_page.dart';
import '../payment/cash_register_page.dart';
import '../settings/tax_settings_page.dart';
import '../suppliers/suppliers_page.dart';
import 'pos_report_catalog.dart';
import 'pos_report_data.dart';
import 'widgets/metric_grid.dart';
import 'widgets/trend_chart.dart';

class EnhancedReportPage extends StatefulWidget {
  const EnhancedReportPage({
    super.key,
    required this.report,
    this.customBuilder,
    this.additionalMetricsBuilder,
    this.additionalSectionsBuilder,
  });

  final PosReport report;
  final Widget Function(
    BuildContext context,
    ReportTable table,
    PosReportData data,
    DateTimeRange? range,
    String? selection,
  )? customBuilder;
  final List<MetricData> Function(
    ReportTable table,
    PosReportData data,
  )? additionalMetricsBuilder;
  final List<Widget> Function(
    BuildContext context,
    ReportTable table,
    PosReportData data,
    DateTimeRange? range,
  )? additionalSectionsBuilder;

  @override
  State<EnhancedReportPage> createState() => _EnhancedReportPageState();
}

class _EnhancedReportPageState extends State<EnhancedReportPage> {
  static const _pageSize = 25;

  DateTimeRange? _range;
  String? _selection;
  int _page = 0;
  bool _exporting = false;
  ExportFormat _exportFormat = ExportFormat.csv;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _sortColumn;
  bool _sortAscending = true;
  final Set<String> _hiddenColumns = <String>{};

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _range = DateTimeRange(
      start: DateTime(today.year, today.month),
      end: today,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<int> _visibleColumnIndexes(ReportTable table) => [
        for (var i = 0; i < table.columns.length; i++)
          if (!_hiddenColumns.contains(table.columns[i].label)) i,
      ];

  bool _isCostProfit(String label) =>
      RegExp(r'cost|profit', caseSensitive: false).hasMatch(label);

  bool _hasCostProfitColumns(ReportTable table) =>
      table.columns.any((column) => _isCostProfit(column.label));

  List<String> _costProfitLabels(ReportTable table) => [
        for (final column in table.columns)
          if (_isCostProfit(column.label)) column.label,
      ];

  bool _costProfitHidden(ReportTable table) {
    final labels = _costProfitLabels(table);
    return labels.isNotEmpty && labels.every(_hiddenColumns.contains);
  }

  List<List<Object?>> _processedRows(ReportTable table) {
    var rows = table.rows;
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      rows = rows
          .where((row) => row.any((cell) =>
              cell?.toString().toLowerCase().contains(query) ?? false))
          .toList();
    }
    final sort = _sortColumn;
    if (sort != null) {
      final sorted = [...rows];
      sorted.sort((a, b) {
        final av = sort < a.length ? a[sort] : null;
        final bv = sort < b.length ? b[sort] : null;
        final int cmp;
        if (av is num && bv is num) {
          cmp = av.compareTo(bv);
        } else if (av == null && bv == null) {
          cmp = 0;
        } else if (av == null) {
          cmp = -1;
        } else if (bv == null) {
          cmp = 1;
        } else {
          cmp = av
              .toString()
              .toLowerCase()
              .compareTo(bv.toString().toLowerCase());
        }
        return _sortAscending ? cmp : -cmp;
      });
      rows = sorted;
    }
    return rows;
  }

  Future<void> _chooseRange() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate:
          today.isAfter(_range?.end ?? today) ? today : (_range?.end ?? today),
      initialDateRange: _range,
    );
    if (!mounted || range == null) return;
    _setRange(range);
  }

  void _setRange(DateTimeRange? range) {
    setState(() {
      _range = range;
      _selection = null;
      _page = 0;
    });
  }

  void _applyPreset(PresetPeriod preset) {
    final today = DateUtils.dateOnly(DateTime.now());
    DateTime start;
    DateTime end = today;
    switch (preset) {
      case PresetPeriod.today:
        start = today;
        break;
      case PresetPeriod.yesterday:
        start = today.subtract(const Duration(days: 1));
        end = start;
        break;
      case PresetPeriod.last7Days:
        start = today.subtract(const Duration(days: 6));
        break;
      case PresetPeriod.last30Days:
        start = today.subtract(const Duration(days: 29));
        break;
      case PresetPeriod.thisMonth:
        start = DateTime(today.year, today.month, 1);
        break;
      case PresetPeriod.lastMonth:
        final firstThisMonth = DateTime(today.year, today.month, 1);
        start = DateTime(firstThisMonth.year, firstThisMonth.month - 1, 1);
        end = DateTime(firstThisMonth.year, firstThisMonth.month, 0);
        break;
      case PresetPeriod.thisQuarter:
        final quarter = ((today.month - 1) ~/ 3) + 1;
        start = DateTime(today.year, (quarter - 1) * 3 + 1, 1);
        break;
      case PresetPeriod.lastQuarter:
        final quarter = ((today.month - 1) ~/ 3) + 1;
        final firstThisQuarter = DateTime(today.year, (quarter - 1) * 3 + 1, 1);
        start = DateTime(firstThisQuarter.year, firstThisQuarter.month - 3, 1);
        end = DateTime(firstThisQuarter.year, firstThisQuarter.month, 0);
        break;
      case PresetPeriod.thisYear:
        start = DateTime(today.year, 1, 1);
        break;
      case PresetPeriod.lastYear:
        start = DateTime(today.year - 1, 1, 1);
        end = DateTime(today.year - 1, 12, 31);
        break;
      case PresetPeriod.allTime:
        start = DateTime(1900);
        break;
    }
    _setRange(DateTimeRange(start: start, end: end));
  }

  Future<void> _exportReport(ReportTable table) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final export = await _buildExport(table, _exportFormat);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(export.bytes, mimeType: export.mimeType)],
          fileNameOverrides: [export.fileName],
        ),
      );
    } catch (e) {
      if (mounted) {
        showMarketNotice(
          context,
          title: 'Export failed',
          message: '$e',
          type: MarketNoticeType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _saveReport(ReportTable table, ExportFormat format) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final export = await _buildExport(table, format);
      final directory = await _downloadDirectory();
      await directory.create(recursive: true);
      final file = File(
        '${directory.path}${Platform.pathSeparator}${export.fileName}',
      );
      await file.writeAsBytes(export.bytes, flush: true);
      if (mounted) {
        showMarketNotice(
          context,
          title: 'Report saved',
          message: 'Downloaded to ${file.path}',
          type: MarketNoticeType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showMarketNotice(
          context,
          title: 'Download failed',
          message: '$e',
          type: MarketNoticeType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<Directory> _downloadDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    } catch (_) {
      // Fall back to the app documents directory below.
    }
    return getApplicationDocumentsDirectory();
  }

  Future<void> _copyCsv(ReportTable table) async {
    try {
      final text = utf8
          .decode(_generateCsv(table), allowMalformed: true)
          .replaceFirst('\uFEFF', '');
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        showMarketNotice(
          context,
          title: 'Copied',
          message: 'The report table was copied to the clipboard.',
          type: MarketNoticeType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showMarketNotice(
          context,
          title: 'Copy failed',
          message: '$e',
          type: MarketNoticeType.error,
        );
      }
    }
  }

  Future<_ExportPayload> _buildExport(
      ReportTable table, ExportFormat format) async {
    switch (format) {
      case ExportFormat.json:
        return _ExportPayload(
          _generateJson(table),
          _exportFileName('json'),
          'application/json',
        );
      case ExportFormat.xml:
        return _ExportPayload(
          _generateXml(table),
          _exportFileName('xml'),
          'application/xml',
        );
      case ExportFormat.csv:
        return _ExportPayload(
          _generateCsv(table),
          _exportFileName('csv'),
          'text/csv',
        );
      case ExportFormat.txt:
        return _ExportPayload(
          _generateTxt(table),
          _exportFileName('txt'),
          'text/plain',
        );
      case ExportFormat.sql:
        return _ExportPayload(
          _generateSql(table),
          _exportFileName('sql'),
          'application/sql',
        );
      case ExportFormat.excel:
        return _ExportPayload(
          _generateExcel(table),
          _exportFileName('xls'),
          'application/vnd.ms-excel',
        );
      case ExportFormat.pdf:
        return _ExportPayload(
          await _generatePdf(table),
          _exportFileName('pdf'),
          'application/pdf',
        );
    }
  }

  Uint8List _generateJson(ReportTable table) {
    final headers = table.columns.map((c) => c.label).toList();
    final rows = table.rows.map((row) {
      final map = <String, Object?>{};
      for (var i = 0; i < headers.length; i++) {
        map[headers[i]] = i < row.length ? row[i] : null;
      }
      return map;
    }).toList();
    final payload = <String, Object?>{
      'report': widget.report.title,
      'generated_at': DateTime.now().toIso8601String(),
      'range': _range == null
          ? 'all'
          : {
              'start': _range!.start.toIso8601String(),
              'end': _range!.end.toIso8601String(),
            },
      'rows': rows,
    };
    const encoder = JsonEncoder.withIndent('  ');
    return Uint8List.fromList(utf8.encode(encoder.convert(payload)));
  }

  Uint8List _generateXml(ReportTable table) {
    final b = StringBuffer();
    b.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    b.writeln('<report>');
    b.writeln('  <title>${_xmlEscape(widget.report.title)}</title>');
    b.writeln(
        '  <generated_at>${_xmlEscape(DateTime.now().toIso8601String())}</generated_at>');
    b.writeln('  <rows>');
    final headers = table.columns.map((c) => c.label).toList();
    for (final row in table.rows) {
      b.writeln('    <row>');
      for (var i = 0; i < headers.length; i++) {
        final tag = _xmlTag(headers[i], i);
        final value =
            i < row.length ? _exportCell(row[i], table.columns[i]) : '';
        b.writeln('      <$tag>${_xmlEscape(value)}</$tag>');
      }
      b.writeln('    </row>');
    }
    b.writeln('  </rows>');
    b.writeln('</report>');
    return Uint8List.fromList(utf8.encode(b.toString()));
  }

  Uint8List _generateCsv(ReportTable table) {
    final content = [
      table.columns.map((c) => _csvCell(c.label)).join(','),
      ...table.rows.map((row) => [
            for (var i = 0; i < table.columns.length; i++)
              _csvCell(
                  i < row.length ? _exportCell(row[i], table.columns[i]) : '')
          ].join(',')),
    ].join('\r\n');
    return Uint8List.fromList(utf8.encode('\uFEFF$content'));
  }

  Uint8List _generateTxt(ReportTable table) {
    final headers = table.columns.map((c) => c.label).toList();
    final lines = <String>[
      widget.report.title,
      if (_range != null)
        '${DateFormat('yyyy-MM-dd').format(_range!.start)} - ${DateFormat('yyyy-MM-dd').format(_range!.end)}'
      else
        'All dates',
      '',
      headers.join('\t'),
      ...table.rows.map((row) => [
            for (var i = 0; i < table.columns.length; i++)
              i < row.length ? _exportCell(row[i], table.columns[i]) : ''
          ].join('\t')),
    ];
    return Uint8List.fromList(utf8.encode(lines.join('\r\n')));
  }

  Uint8List _generateSql(ReportTable table) {
    final tableName =
        _sqlIdentifier(_baseFileName().isEmpty ? 'report' : _baseFileName());
    final cols = [
      for (var i = 0; i < table.columns.length; i++)
        _sqlIdentifier(table.columns[i].label, fallback: 'col_$i')
    ];
    final b = StringBuffer();
    b.writeln('-- ${widget.report.title}');
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

  Uint8List _generateExcel(ReportTable table) {
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
            '    <Cell><Data ss:Type="String">${_xmlEscape(_exportCell(value, table.columns[i]))}</Data></Cell>',
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

  Future<Uint8List> _generatePdf(ReportTable table) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final primary = PdfColor.fromHex('#2C3E50');
    final headerBg = PdfColor.fromHex('#ECF0F1');
    final border = PdfColor.fromHex('#DCE4EC');
    final rangeLabel = _range != null
        ? '${DateFormat('MMM d, yyyy').format(_range!.start)} – ${DateFormat('MMM d, yyyy').format(_range!.end)}'
        : 'All Time';

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
                  pw.Text(widget.report.title,
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 18, color: primary)),
                  pw.SizedBox(height: 2),
                  pw.Text(rangeLabel,
                      style: pw.TextStyle(
                          font: font, fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
              pw.Text(
                  'Generated ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(
                      font: font, fontSize: 9, color: PdfColors.grey600)),
            ],
          ),
        ),
        build: (context) => [
          if (table.rows.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Text('No records available for the selected filters.',
                  style: pw.TextStyle(font: font, fontSize: 11)),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: table.columns.map((c) => c.label).toList(),
              data: table.rows
                  .map((row) => [
                        for (var i = 0; i < table.columns.length; i++)
                          i < row.length
                              ? _exportCell(row[i], table.columns[i])
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
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                  font: font, fontSize: 8, color: PdfColors.grey600)),
        ),
      ),
    );
    return pdf.save();
  }

  String _exportCell(Object? value, ReportColumn column) {
    if (value == null) return '';
    if (value is num) {
      final formatted = NumberFormat('#,##0.##').format(value);
      return column.money ? 'TSH $formatted' : formatted;
    }
    return value.toString();
  }

  String _csvCell(Object? value) {
    if (value == null) return '';
    if (value is num) return value.toString();
    final original = value.toString();
    final text = RegExp(r'^[\s\uFEFF]*[=+@-]|^[\t\r\n]').hasMatch(original)
        ? "'$original"
        : original;
    return '"${text.replaceAll('"', '""')}"';
  }

  String _xmlEscape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  String _xmlTag(String label, int index) {
    var tag = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    tag = tag.replaceAll(RegExp(r'^_+|_+$'), '');
    if (tag.isEmpty) tag = 'col_$index';
    if (RegExp(r'^[0-9]').hasMatch(tag)) tag = 'c_$tag';
    return tag;
  }

  String _sqlIdentifier(String raw, {String? fallback}) {
    var id = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    id = id.replaceAll(RegExp(r'^_+|_+$'), '');
    if (id.isEmpty) id = fallback ?? 'col';
    if (RegExp(r'^[0-9]').hasMatch(id)) id = 'c_$id';
    return id;
  }

  String _sqlValue(Object? value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    final escaped = value.toString().replaceAll("'", "''");
    return "'$escaped'";
  }

  String _baseFileName() => widget.report.title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  String _exportTimestamp() =>
      DateFormat('yyyyMMddHHmm').format(DateTime.now());

  String _exportFileName(String ext) {
    final base = _baseFileName().isEmpty ? 'report' : _baseFileName();
    return '${base}_${_exportTimestamp()}.$ext';
  }

  @override
  Widget build(BuildContext context) {
    final missing = widget.report.missingData;
    if (missing != null) return _buildMissingDataView(missing);

    final store = context.watch<PosLocalStore>();
    final report = widget.report;
    final data = PosReportData(
      orders: store.orders,
      inventory: store.inventory,
      expenses: store.expenses,
      customers: store.customers,
      storeName: store.profile.storeName,
      shifts: store.registerShifts,
      cashUpFor: store.cashUpFor,
      suppliers: store.suppliers,
      receivings: store.receivings,
      tax: store.taxSettings,
      trialBalanceRows: store.trialBalance(),
      fixedAssets: store.fixedAssets,
      bankTransactions: store.bankTransactions,
    );
    final choices = data.filterOptions(report.data, _range?.start, _range?.end);
    final selection = choices.contains(_selection) ? _selection : null;
    final table = data.build(report.data,
        start: _range?.start, end: _range?.end, selection: selection);
    final additionalMetrics =
        widget.additionalMetricsBuilder?.call(table, data) ??
            _buildDefaultMetrics(table);
    final localizations = MaterialLocalizations.of(context);
    final range = _range;
    final rangeLabel = range == null
        ? 'All dates'
        : '${localizations.formatCompactDate(range.start)} – ${localizations.formatCompactDate(range.end)}';
    final processedRows = _processedRows(table);
    final lastPage =
        processedRows.isEmpty ? 0 : (processedRows.length - 1) ~/ _pageSize;
    final page = _page.clamp(0, lastPage);
    final pageRows =
        processedRows.skip(page * _pageSize).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: report.title,
              subtitle: rangeLabel,
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
              actions: [_buildExportMenu(table)],
            ),
            _buildToolbar(table, choices, selection),
            if (table.note != null) _buildNoteBanner(table.note!),
            Expanded(
              child: pageRows.isEmpty
                  ? _buildEmptyState(report)
                  : _buildContent(table, pageRows, additionalMetrics),
            ),
            _buildPagination(
                page, lastPage, processedRows.length, pageRows.length),
          ],
        ),
      ),
    );
  }

  Widget _buildExportMenu(ReportTable table) {
    return Tooltip(
      message: 'Export / Print',
      child: GestureDetector(
        onTap: _exporting ? null : () => _showExportSheet(table),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: AppColors.border),
          ),
          child: _exporting
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                )
              : const Icon(Icons.ios_share_rounded,
                  color: AppColors.ink, size: 22),
        ),
      ),
    );
  }

  Future<void> _showExportSheet(ReportTable table) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Export report',
                    style: AppTypography.sectionHeader
                        .copyWith(fontSize: 18, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(
                  '${widget.report.title} • ${table.rows.length} rows',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                _sheetSectionLabel('Download to device'),
                _sheetAction(
                  icon: Icons.table_view_rounded,
                  title: 'CSV spreadsheet',
                  subtitle: 'Comma separated values',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _saveReport(table, ExportFormat.csv);
                  },
                ),
                _sheetAction(
                  icon: Icons.grid_on_rounded,
                  title: 'Excel workbook',
                  subtitle: 'Microsoft Excel (.xls)',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _saveReport(table, ExportFormat.excel);
                  },
                ),
                _sheetAction(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'PDF document',
                  subtitle: 'Printable, formatted report',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _saveReport(table, ExportFormat.pdf);
                  },
                ),
                const SizedBox(height: 16),
                _sheetSectionLabel('Share'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final format in ExportFormat.values)
                      _formatChip(format, () {
                        Navigator.of(sheetContext).pop();
                        setState(() => _exportFormat = format);
                        _exportReport(table);
                      }),
                  ],
                ),
                const SizedBox(height: 16),
                _sheetSectionLabel('More'),
                _sheetAction(
                  icon: Icons.copy_all_rounded,
                  title: 'Copy table',
                  subtitle: 'Copy the full table as CSV',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _copyCsv(table);
                  },
                ),
                _sheetAction(
                  icon: Icons.print_outlined,
                  title: 'Print',
                  subtitle: 'Open the system print dialog',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Printing.layoutPdf(onLayout: (_) => _generatePdf(table));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.label.copyWith(
          fontSize: 11,
          letterSpacing: 0.8,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sheetAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.standard),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _formatChip(ExportFormat format, VoidCallback onTap) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(_formatIcon(format), size: 16),
      label: Text(format.label),
      labelStyle: AppTypography.helperText.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      backgroundColor: AppColors.surfaceSecondary,
      side: const BorderSide(color: AppColors.border),
    );
  }

  IconData _formatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return Icons.data_object_rounded;
      case ExportFormat.xml:
        return Icons.code_rounded;
      case ExportFormat.csv:
        return Icons.table_chart_outlined;
      case ExportFormat.txt:
        return Icons.description_outlined;
      case ExportFormat.sql:
        return Icons.storage_rounded;
      case ExportFormat.excel:
        return Icons.grid_on_rounded;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf_outlined;
    }
  }

  Widget _buildToolbar(
      ReportTable table, List<String> choices, String? selection) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.standard),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                      _page = 0;
                    }),
                    textInputAction: TextInputAction.search,
                    style:
                        AppTypography.bodySmall.copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search this report',
                      hintStyle: AppTypography.bodySmall
                          .copyWith(color: AppColors.textLight),
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 19, color: AppColors.textMuted),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _page = 0;
                                });
                              },
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 11, horizontal: 4),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ToolbarButton(
                icon: Icons.view_column_outlined,
                label: 'Columns',
                onTap: () => _showColumnsSheet(table),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ToolbarButton(
                  icon: Icons.date_range_rounded,
                  label: _range == null ? 'Date range' : 'Change dates',
                  onTap: _chooseRange),
              _PresetPeriodMenu(onPresetSelected: _applyPreset),
              if (_range != null)
                _ToolbarButton(
                    icon: Icons.close_rounded,
                    label: 'All dates',
                    onTap: () => _setRange(null)),
              if (_hasCostProfitColumns(table))
                _ToolbarButton(
                    icon: _costProfitHidden(table)
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    label: 'Cost/Profit',
                    onTap: () => setState(() {
                          final labels = _costProfitLabels(table);
                          if (_costProfitHidden(table)) {
                            _hiddenColumns.removeAll(labels);
                          } else {
                            _hiddenColumns.addAll(labels);
                          }
                        })),
              if (choices.isNotEmpty)
                _FilterMenu(
                    choices: choices,
                    selection: selection,
                    onSelected: (value) => setState(() {
                          _selection = value;
                          _page = 0;
                        })),
              if (selection != null)
                _ToolbarButton(
                    icon: Icons.filter_alt_off_rounded,
                    label: 'Clear filter',
                    onTap: () => setState(() {
                          _selection = null;
                          _page = 0;
                        })),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showColumnsSheet(ReportTable table) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Show columns',
                              style: AppTypography.sectionHeader
                                  .copyWith(fontSize: 17, color: AppColors.ink),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() => _hiddenColumns.clear());
                              setState(() {});
                            },
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final column in table.columns)
                            CheckboxListTile(
                              value: !_hiddenColumns.contains(column.label),
                              onChanged: (checked) {
                                setSheetState(() {
                                  if (checked ?? true) {
                                    _hiddenColumns.remove(column.label);
                                  } else if (table.columns.length -
                                          _hiddenColumns.length >
                                      1) {
                                    _hiddenColumns.add(column.label);
                                  }
                                });
                                setState(() {});
                              },
                              title: Text(
                                column.label,
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.ink),
                              ),
                              dense: true,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNoteBanner(String note) => Container(
        width: double.infinity,
        color: AppColors.warningLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
              child: Text(note,
                  style: AppTypography.bodySmall
                      .copyWith(fontSize: 12, color: AppColors.ink))),
        ]),
      );

  Widget _buildEmptyState(PosReport report) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.rounded)),
              child: const Icon(Icons.analytics_outlined,
                  size: 36, color: AppColors.textLight),
            ),
            const SizedBox(height: 16),
            Text('No data available',
                style: AppTypography.cardHeader.copyWith(color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(
                'No records match the current filters for ${report.title.toLowerCase()}.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted)),
            const SizedBox(height: 20),
            if (_setupAction case final setup?)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: MarketButton(
                    label: setup.$2,
                    icon: setup.$3,
                    isFullWidth: false,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => setup.$1(),
                        ),
                      );
                    }),
              ),
            MarketButton(
                label: 'Clear filters',
                icon: Icons.clear_all_rounded,
                isFullWidth: false,
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selection = null;
                    _range = null;
                    _page = 0;
                  });
                }),
          ]),
        ),
      );

  (Widget Function(), String, IconData)? get _setupAction {
    final data = widget.report.data;
    switch (data) {
      case ReportData.cashUp:
      case ReportData.shifts:
        return (
          () => const CashRegisterPage(),
          'Open cash register',
          Icons.point_of_sale_outlined
        );
      case ReportData.suppliers:
      case ReportData.supplierDetail:
      case ReportData.receivings:
        return (
          () => const SuppliersPage(),
          'Add supplier',
          Icons.local_shipping_outlined
        );
      case ReportData.taxes:
      case ReportData.salesTaxes:
      case ReportData.taxCompliance:
        return (
          () => const TaxSettingsPage(),
          'Open tax settings',
          Icons.percent_rounded
        );
      case ReportData.trialBalance:
      case ReportData.balanceSheet:
      case ReportData.cashFlow:
        return (
          () => const AccountsPage(),
          'Open chart of accounts',
          Icons.account_balance_outlined
        );
      case ReportData.assets:
        return (
          () => const FixedAssetsPage(),
          'Add fixed asset',
          Icons.chair_outlined
        );
      case ReportData.bank:
      case ReportData.reconciliation:
        return (
          () => const BankReconciliationPage(),
          'Import statement',
          Icons.account_balance_wallet_outlined
        );
      default:
        return null;
    }
  }

  List<MetricData> _buildDefaultMetrics(ReportTable table) {
    final rows = table.rows;
    final moneyIndexes = <int>[];
    final numericIndexes = <int>[];
    for (var i = 0; i < table.columns.length; i++) {
      final hasNumeric = rows.any((row) => i < row.length && row[i] is num);
      if (!hasNumeric) continue;
      if (table.columns[i].money) {
        moneyIndexes.add(i);
      } else {
        numericIndexes.add(i);
      }
    }
    double totalFor(int index) {
      var total = 0.0;
      for (final row in rows) {
        final value = index < row.length ? row[index] : null;
        if (value is num) total += value.toDouble();
      }
      return total;
    }

    String money(num v) => 'TSH ${NumberFormat('#,##0.##').format(v)}';
    String count(num v) => NumberFormat('#,##0').format(v);
    final metrics = <MetricData>[
      MetricData(
          title: 'Records',
          value: count(rows.length),
          icon: Icons.table_rows_outlined,
          iconColor: AppColors.primary,
          tint: AppColors.surfaceSecondary,
          valueColor: AppColors.primary),
    ];
    if (moneyIndexes.isNotEmpty) {
      final index = moneyIndexes.first;
      final total = totalFor(index);
      metrics.add(MetricData(
          title: 'Total ${table.columns[index].label}',
          value: money(total),
          icon: Icons.payments_outlined,
          iconColor: AppColors.success,
          tint: AppColors.successLight,
          valueColor: AppColors.success));
      if (rows.isNotEmpty) {
        metrics.add(MetricData(
            title: 'Average ${table.columns[index].label}',
            value: money(total / rows.length),
            icon: Icons.functions_rounded,
            iconColor: AppColors.chart4,
            tint: const Color(0xFFF3F4F6),
            valueColor: AppColors.chart4));
      }
    }
    if (moneyIndexes.length > 1) {
      final index = moneyIndexes.last;
      metrics.add(MetricData(
          title: 'Total ${table.columns[index].label}',
          value: money(totalFor(index)),
          icon: Icons.trending_up_rounded,
          iconColor: AppColors.warning,
          tint: AppColors.warningLight,
          valueColor: AppColors.warning));
    } else if (moneyIndexes.isEmpty && numericIndexes.isNotEmpty) {
      final index = numericIndexes.first;
      metrics.add(MetricData(
          title: 'Total ${table.columns[index].label}',
          value: NumberFormat('#,##0.##').format(totalFor(index)),
          icon: Icons.functions_rounded,
          iconColor: AppColors.primary,
          tint: AppColors.surfaceSecondary,
          valueColor: AppColors.primary));
    }
    return metrics;
  }

  Widget _buildContent(ReportTable table, List<List<Object?>> pageRows,
      List<MetricData> additionalMetrics) {
    return CustomScrollView(slivers: [
      if (additionalMetrics.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Key Metrics',
                  style: AppTypography.sectionHeader
                      .copyWith(fontSize: 15, color: AppColors.ink)),
              const SizedBox(height: 12),
              MetricGrid(metrics: additionalMetrics),
            ]),
          ),
        ),
      if (widget.additionalSectionsBuilder != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: widget.additionalSectionsBuilder!(
                      context,
                      table,
                      PosReportData(
                          orders: const [],
                          inventory: const [],
                          expenses: const [],
                          customers: const [],
                          storeName: ''),
                      _range)
                  .map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 16), child: w))
                  .toList(),
            ),
          ),
        ),
      if (widget.customBuilder != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: widget.customBuilder!(
                context,
                table,
                PosReportData(
                    orders: const [],
                    inventory: const [],
                    expenses: const [],
                    customers: const [],
                    storeName: ''),
                _range,
                _selection),
          ),
        ),
      if (table.chartColumn != null &&
          widget.additionalSectionsBuilder == null &&
          widget.customBuilder == null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: MarketSurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildTrendChart(table, pageRows)),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        sliver: SliverToBoxAdapter(child: _buildDataTable(table, pageRows)),
      ),
    ]);
  }

  Widget _buildTrendChart(ReportTable table, List<List<Object?>> pageRows) {
    final index = table.chartColumn!;
    final points = pageRows.map((row) {
      final value = (row[index] as num).toDouble();
      return TrendPoint(
        label: row.first.toString(),
        value: value,
        displayValue: table.columns[index].money
            ? 'TSH ${NumberFormat('#,##0').format(value)}'
            : NumberFormat('#,##0.##').format(value),
      );
    }).toList();
    final maxValue = points.isEmpty
        ? 0.0
        : points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    return TrendChart(
        points: points,
        maxValue: maxValue,
        label: table.columns[index].label,
        color: AppColors.primary);
  }

  Widget _buildDataTable(ReportTable table, List<List<Object?>> pageRows) {
    final visible = _visibleColumnIndexes(table);
    final sortIndex =
        _sortColumn == null ? null : visible.indexOf(_sortColumn!);

    return MarketSurfaceCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor:
                WidgetStateProperty.all(AppColors.surfaceSecondary),
            headingTextStyle: AppTypography.label.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.primaryDeep),
            dataTextStyle: AppTypography.bodySmall.copyWith(fontSize: 12),
            columnSpacing: 16,
            horizontalMargin: 12,
            dividerThickness: 0.6,
            showCheckboxColumn: false,
            sortColumnIndex:
                sortIndex == null || sortIndex < 0 ? null : sortIndex,
            sortAscending: _sortAscending,
            columns: [
              for (final i in visible)
                DataColumn(
                  label: Text(table.columns[i].label),
                  numeric: table.columns[i].money,
                  onSort: (_, ascending) => setState(() {
                    _sortColumn = i;
                    _sortAscending = ascending;
                    _page = 0;
                  }),
                )
            ],
            rows: [
              for (final row in pageRows)
                DataRow(cells: [
                  for (final i in visible)
                    DataCell(ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: _buildCell(
                          i < row.length ? row[i] : null, table.columns[i]),
                    )),
                ])
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(Object? value, ReportColumn column) {
    if (value is num) {
      final formatted = NumberFormat('#,##0.##').format(value);
      return Text(
        column.money ? 'TSH $formatted' : formatted,
        style: AppTypography.bodySmall.copyWith(
            fontWeight: column.money ? FontWeight.w700 : FontWeight.w500,
            color: column.money ? AppColors.primaryDeep : AppColors.ink),
        textAlign: column.money ? TextAlign.right : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Text(value?.toString() ?? '—',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
        maxLines: 2,
        overflow: TextOverflow.ellipsis);
  }

  Widget _buildPagination(
      int page, int lastPage, int totalRows, int pageRowsCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
            totalRows == 0
                ? 'No records'
                : '${page * _pageSize + 1}–${page * _pageSize + pageRowsCount} of $totalRows',
            style: AppTypography.helperText
                .copyWith(fontSize: 13, color: AppColors.textMuted)),
        Row(children: [
          IconButton(
              tooltip: 'Previous page',
              onPressed:
                  page == 0 ? null : () => setState(() => _page = page - 1),
              icon: const Icon(Icons.chevron_left_rounded, size: 22),
              color: AppColors.ink),
          Text('${page + 1} / ${lastPage + 1}',
              style: AppTypography.label.copyWith(color: AppColors.ink)),
          IconButton(
              tooltip: 'Next page',
              onPressed: page == lastPage
                  ? null
                  : () => setState(() => _page = page + 1),
              icon: const Icon(Icons.chevron_right_rounded, size: 22),
              color: AppColors.ink),
        ]),
      ]),
    );
  }

  Widget _buildMissingDataView(String missing) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(children: [
          MarketPageHeader(
              title: widget.report.title,
              transparentBackButton: true,
              onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                        color: AppColors.warningLight, shape: BoxShape.circle),
                    child: const Icon(Icons.construction_outlined,
                        size: 44, color: AppColors.warning),
                  ),
                  const SizedBox(height: 20),
                  Text('Report Unavailable',
                      style: AppTypography.h3.copyWith(fontSize: 20)),
                  const SizedBox(height: 10),
                  Text(missing,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted, height: 1.5)),
                  const SizedBox(height: 20),
                  MarketButton(
                      label: 'Back to Reports',
                      icon: Icons.arrow_back_rounded,
                      isFullWidth: false,
                      onTap: () => Navigator.of(context).pop()),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ExportPayload {
  const _ExportPayload(this.bytes, this.fileName, this.mimeType);
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

enum PresetPeriod {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  thisQuarter,
  lastQuarter,
  thisYear,
  lastYear,
  allTime,
}

extension PresetPeriodLabel on PresetPeriod {
  String get label {
    switch (this) {
      case PresetPeriod.today:
        return 'Today';
      case PresetPeriod.yesterday:
        return 'Yesterday';
      case PresetPeriod.last7Days:
        return 'Last 7 days';
      case PresetPeriod.last30Days:
        return 'Last 30 days';
      case PresetPeriod.thisMonth:
        return 'This month';
      case PresetPeriod.lastMonth:
        return 'Last month';
      case PresetPeriod.thisQuarter:
        return 'This quarter';
      case PresetPeriod.lastQuarter:
        return 'Last quarter';
      case PresetPeriod.thisYear:
        return 'This year';
      case PresetPeriod.lastYear:
        return 'Last year';
      case PresetPeriod.allTime:
        return 'All time';
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textMain,
        side: const BorderSide(color: AppColors.border),
        backgroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: AppTypography.label.copyWith(fontSize: 13),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.standard)),
      ),
    );
  }
}

class _PresetPeriodMenu extends StatelessWidget {
  const _PresetPeriodMenu({required this.onPresetSelected});
  final void Function(PresetPeriod) onPresetSelected;
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PresetPeriod>(
      tooltip: 'Quick date ranges',
      onSelected: onPresetSelected,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard)),
      itemBuilder: (context) => [
        for (final preset in PresetPeriod.values)
          PopupMenuItem(
              value: preset,
              child: Text(preset.label, style: AppTypography.bodySmall)),
      ],
      child: IgnorePointer(
        child: _ToolbarButton(
            icon: Icons.flash_on_rounded, label: 'Quick ranges', onTap: () {}),
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu(
      {required this.choices,
      required this.selection,
      required this.onSelected});
  final List<String> choices;
  final String? selection;
  final void Function(String) onSelected;
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Filter records',
      initialValue: selection,
      onSelected: onSelected,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard)),
      itemBuilder: (context) => [
        for (final value in choices)
          PopupMenuItem(
              value: value, child: Text(value, style: AppTypography.bodySmall)),
      ],
      child: IgnorePointer(
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(
            selection != null
                ? Icons.filter_alt_rounded
                : Icons.filter_list_rounded,
            size: 18,
            color: selection != null ? AppColors.primary : AppColors.textMuted,
          ),
          label: Text(
            selection ?? 'Filter',
            style: AppTypography.label.copyWith(
              fontSize: 13,
              color: selection != null ? AppColors.primary : AppColors.textMain,
              fontWeight: selection != null ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textMain,
            side: BorderSide(
                color:
                    selection != null ? AppColors.primary : AppColors.border),
            backgroundColor: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.standard)),
          ),
        ),
      ),
    );
  }
}
