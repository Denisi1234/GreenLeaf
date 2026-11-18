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
import '../../service/store_models.dart';
import '../widgets/app_design.dart';
import '../widgets/workspace_widgets.dart';
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
  int _pageSize = 25;

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

  List<StoreSnapshot>? _multiStoreSnapshots;
  bool _loadingSnapshots = false;
  String? _snapshotsError;

  PresetPeriod _selectedPreset = PresetPeriod.thisMonth;

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _range = DateTimeRange(
      start: DateTime(today.year, today.month, 1),
      end: today,
    );
    if (widget.report.isSnapshot) {
      _range = null;
      _selectedPreset = PresetPeriod.allTime;
    }
    if (widget.report.isMultiStore) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSnapshots());
    }
  }

  Future<void> _loadSnapshots() async {
    if (!mounted) return;
    setState(() {
      _loadingSnapshots = true;
      _snapshotsError = null;
    });
    try {
      final store = context.read<PosLocalStore>();
      final snaps = await store.loadAllStoreSnapshots();
      if (!mounted) return;
      setState(() {
        _multiStoreSnapshots = snaps;
        _loadingSnapshots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _snapshotsError = e.toString();
        _loadingSnapshots = false;
      });
    }
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

  DateTime _earliestActivityDate() {
    final store = context.read<PosLocalStore>();
    DateTime? earliest;

    void checkDate(DateTime? d) {
      if (d == null) return;
      final day = DateTime(d.year, d.month, d.day);
      if (earliest == null || day.isBefore(earliest!)) {
        earliest = day;
      }
    }

    // Orders
    for (final order in store.orders) {
      checkDate(DateTime.tryParse(order.dateTime)?.toLocal());
    }

    // Expenses
    for (final expense in store.expenses) {
      checkDate(expense.date);
    }

    // Shifts
    for (final shift in store.registerShifts) {
      checkDate(shift.openedAt.toLocal());
    }

    // Customers
    for (final customer in store.customers) {
      checkDate(customer.createdAt.toLocal());
    }

    // Receivings
    for (final receiving in store.receivings) {
      checkDate(receiving.date);
    }

    // Bank Transactions
    for (final tx in store.bankTransactions) {
      checkDate(tx.date);
    }

    // Default fallback: Start of current year, or today if no historical records exist
    final now = DateTime.now();
    return earliest ?? DateTime(now.year, 1, 1);
  }

  Future<void> _chooseRange() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final earliest = _earliestActivityDate();
    final firstDate = earliest.isBefore(today)
        ? earliest
        : today.subtract(const Duration(days: 365));

    final range = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate:
          today.isAfter(_range?.end ?? today) ? today : (_range?.end ?? today),
      initialDateRange: _range,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.surface,
                onSurface: AppColors.ink,
              ),
        ),
        child: child!,
      ),
    );
    if (!mounted || range == null) return;
    setState(() {
      _range = range;
      _selection = null;
      _page = 0;
    });
  }

  void _setRange(DateTimeRange? range) {
    setState(() {
      _range = range;
      _selection = null;
      _page = 0;
    });
  }

  void _applyPreset(PresetPeriod preset) {
    setState(() => _selectedPreset = preset);
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
        start = _earliestActivityDate();
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
      if (widget.report.isSnapshot)
        'Current snapshot'
      else if (_range != null)
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
    final rangeLabel = widget.report.isSnapshot
        ? 'Current snapshot'
        : _range != null
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

    if (widget.report.isMultiStore) {
      if (_loadingSnapshots) {
        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: widget.report.title,
                  subtitle: 'Loading all stores…',
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
          ),
        );
      }
      if (_snapshotsError != null) {
        return Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: widget.report.title,
                  subtitle: 'Could not load stores',
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_snapshotsError!,
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.danger)),
                          const SizedBox(height: 16),
                          MarketButton(
                            label: 'Retry',
                            icon: Icons.refresh_rounded,
                            isFullWidth: false,
                            onTap: _loadSnapshots,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    final store = context.watch<PosLocalStore>();
    final report = widget.report;
    final data = PosReportData(
      orders: store.orders,
      inventory: store.inventory,
      expenses: store.expenses,
      customers: store.customers,
      storeName: store.activeStoreName,
      shifts: store.registerShifts,
      cashUpFor: store.cashUpFor,
      suppliers: store.suppliers,
      receivings: store.receivings,
      tax: store.taxSettings,
      trialBalanceRows: store.trialBalance(),
      fixedAssets: store.fixedAssets,
      bankTransactions: store.bankTransactions,
      storeSnapshots: _multiStoreSnapshots ?? const <StoreSnapshot>[],
    );
    final choices = data.filterOptions(report.data, _range?.start, _range?.end);
    final selection = choices.contains(_selection) ? _selection : null;
    final table = data.build(report.data,
        start: _range?.start, end: _range?.end, selection: selection);
    final additionalMetrics =
        widget.additionalMetricsBuilder?.call(table, data) ??
            const <MetricData>[];
    final processedRows = _processedRows(table);
    final lastPage =
        processedRows.isEmpty ? 0 : (processedRows.length - 1) ~/ _pageSize;
    final page = _page.clamp(0, lastPage);
    final pageRows =
        processedRows.skip(page * _pageSize).take(_pageSize).toList();

    final visible = _visibleColumnIndexes(table);
    final exportTable = ReportTable(
      [for (final index in visible) table.columns[index]],
      [
        for (final row in processedRows)
          [for (final index in visible) index < row.length ? row[index] : null]
      ],
      note: table.note,
    );
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(report.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sectionHeader),
        toolbarHeight: 72,
        actions: [_buildExportMenu(exportTable), const SizedBox(width: 12)],
      ),
      body: SafeArea(
          top: false,
          child: Column(children: [
            _buildToolbar(table, choices, selection),
            Expanded(
                child: pageRows.isEmpty
                    ? _buildEmptyState(report, table.note)
                    : _buildContent(table, pageRows, additionalMetrics, data,
                        processedRows)),
            _buildPagination(
                page, lastPage, processedRows.length, pageRows.length),
          ])),
    );
  }

  Widget _buildExportMenu(ReportTable table) => OutlinedButton.icon(
        onPressed: _exporting || table.rows.isEmpty
            ? null
            : () => _showExportSheet(table),
        icon: _exporting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.ios_share_outlined, size: 18),
        label: const Text('Export'),
      );

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
                  '${widget.report.title} • ${table.rows.length} ${table.rows.length == 1 ? 'record' : 'records'}',
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
                    for (final format in [
                      ExportFormat.csv,
                      ExportFormat.excel,
                      ExportFormat.pdf
                    ])
                      _formatChip(format, () {
                        Navigator.of(sheetContext).pop();
                        setState(() => _exportFormat = format);
                        _exportReport(table);
                      }),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Other formats', style: AppTypography.bodySmall),
                  children: [
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final format in [
                        ExportFormat.json,
                        ExportFormat.xml,
                        ExportFormat.txt,
                        ExportFormat.sql
                      ])
                        _formatChip(format, () {
                          Navigator.of(sheetContext).pop();
                          setState(() => _exportFormat = format);
                          _exportReport(table);
                        }),
                    ])
                  ],
                ),
                const SizedBox(height: 16),
                _sheetSectionLabel('More'),
                _sheetAction(
                  icon: Icons.copy_all_rounded,
                  title: 'Copy table',
                  subtitle: 'Copy all matching rows as CSV',
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
      borderRadius: BorderRadius.circular(10),
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

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selection = null;
      _range = null;
      _selectedPreset = PresetPeriod.allTime;
      _page = 0;
    });
  }

  Widget _buildToolbar(
      ReportTable table, List<String> choices, String? selection) {
    final localization = MaterialLocalizations.of(context);
    final range = _range;
    final dateLabel = range == null
        ? 'All dates'
        : '${localization.formatCompactDate(range.start)} – ${localization.formatCompactDate(range.end)}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
              child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {
              _searchQuery = value;
              _page = 0;
            }),
            decoration: InputDecoration(
                hintText: 'Search this report',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _page = 0;
                            }))),
          )),
          const SizedBox(width: 12),
          IconButton.outlined(
              tooltip: 'Show columns',
              onPressed: () => _showColumnsSheet(table),
              icon: const Icon(Icons.view_column_outlined, size: 22)),
        ]),
        const SizedBox(height: 12),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!widget.report.isSnapshot) ...[
                OutlinedButton.icon(
                    onPressed: _chooseRange,
                    icon: const Icon(Icons.calendar_today_outlined, size: 17),
                    label: Text(dateLabel)),
                _PresetPeriodMenu(
                    selectedPreset: _selectedPreset,
                    onPresetSelected: _applyPreset),
              ] else
                const WorkspaceStatus(
                    label: 'Current snapshot', color: AppColors.textBody),
              if (choices.isNotEmpty)
                SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(selection),
                      initialValue: selection,
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Filter records'),
                      items: [
                        const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All records',
                                overflow: TextOverflow.ellipsis)),
                        ...choices.map((value) => DropdownMenuItem(
                            value: value,
                            child:
                                Text(value, overflow: TextOverflow.ellipsis)))
                      ],
                      onChanged: (value) => setState(() {
                        _selection = value;
                        _page = 0;
                      }),
                    )),
              if (_searchQuery.isNotEmpty ||
                  selection != null ||
                  (!widget.report.isSnapshot && _range != null))
                TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.dangerDeep),
                    child: const Text('Clear filters')),
            ]),
      ]),
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
                    if (_hasCostProfitColumns(table))
                      SwitchListTile(
                        title: const Text('Show cost and profit'),
                        value: !_costProfitHidden(table),
                        onChanged: (show) {
                          setSheetState(() {
                            if (show) {
                              _hiddenColumns
                                  .removeAll(_costProfitLabels(table));
                            } else {
                              _hiddenColumns.addAll(_costProfitLabels(table));
                            }
                          });
                          setState(() {});
                        },
                      ),
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
        color: AppColors.surfaceSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
              child: Text(note,
                  style: AppTypography.bodySmall
                      .copyWith(fontSize: 12, color: AppColors.ink))),
        ]),
      );

  Widget _buildEmptyState(PosReport report, String? note) => Center(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: WorkspacePanel(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.table_chart_outlined,
                  size: 36, color: AppColors.textMuted),
              const SizedBox(height: 16),
              Text('No data available', style: AppTypography.h3),
              const SizedBox(height: 8),
              Text('No records match the selected dates and filters.',
                  textAlign: TextAlign.center, style: AppTypography.bodySmall),
              if (note != null) ...[
                const SizedBox(height: 12),
                Text(note,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted))
              ],
              const SizedBox(height: 16),
              if (_searchQuery.isEmpty &&
                  _selection == null &&
                  _setupAction != null)
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => _setupAction!.$1())),
                  icon: Icon(_setupAction!.$3, size: 18),
                  label: Text(_setupAction!.$2),
                ),
              if (_searchQuery.isNotEmpty ||
                  _selection != null ||
                  (!report.isSnapshot && _range != null))
                TextButton(
                    onPressed: _clearFilters,
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.dangerDeep),
                    child: const Text('Clear filters')),
            ]))),
      ));

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

  Widget _buildContent(
      ReportTable table,
      List<List<Object?>> pageRows,
      List<MetricData> additionalMetrics,
      PosReportData data,
      List<List<Object?>> matchingRows) {
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(children: [
                Expanded(
                    child: Text(
                        widget.report.isSnapshot
                            ? 'Current records'
                            : 'Report results',
                        style: AppTypography.sectionHeader)),
                Text(
                    '${matchingRows.length} ${matchingRows.length == 1 ? 'record' : 'records'}',
                    style: AppTypography.label),
              ]))),
      if (table.note != null)
        SliverToBoxAdapter(child: _buildNoteBanner(table.note!)),
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
              children: widget.additionalSectionsBuilder!
                      (context, table, data, _range)
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
            child:
                widget.customBuilder!(context, table, data, _range, _selection),
          ),
        ),
      if (widget.report.chart &&
          table.chartColumn != null &&
          widget.additionalSectionsBuilder == null &&
          widget.customBuilder == null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: MarketSurfaceCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _buildTrendChart(table, matchingRows)),
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
    final points = pageRows.where((row) => row[index] is num).map((row) {
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
        color: AppColors.successDeep);
  }

  Widget _buildDataTable(ReportTable table, List<List<Object?>> pageRows) {
    final visible = _visibleColumnIndexes(table);
    final sortIndex =
        _sortColumn == null ? null : visible.indexOf(_sortColumn!);
    return WorkspacePanel(
        padding: EdgeInsets.zero,
        child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingRowColor: const WidgetStatePropertyAll(
                            AppColors.surfaceSecondary),
                        headingTextStyle: AppTypography.tableHeader
                            .copyWith(color: AppColors.textBody),
                        dataTextStyle: AppTypography.bodySmall,
                        columnSpacing: 28,
                        horizontalMargin: 20,
                        dataRowMinHeight: 52,
                        dataRowMaxHeight: 72,
                        dividerThickness: 0.6,
                        showCheckboxColumn: false,
                        sortColumnIndex: sortIndex == null || sortIndex < 0
                            ? null
                            : sortIndex,
                        sortAscending: _sortAscending,
                        columns: [
                          for (final index in visible)
                            DataColumn(
                              label: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 180),
                                  child: Text(table.columns[index].label,
                                      maxLines: 2)),
                              numeric: table.columns[index].money,
                              onSort: (_, ascending) => setState(() {
                                _sortColumn = index;
                                _sortAscending = ascending;
                                _page = 0;
                              }),
                            )
                        ],
                        rows: [
                          for (var rowIndex = 0;
                              rowIndex < pageRows.length;
                              rowIndex++)
                            DataRow(
                              color: WidgetStatePropertyAll(rowIndex.isOdd
                                  ? AppColors.surfaceSecondary
                                      .withValues(alpha: 0.45)
                                  : AppColors.surface),
                              cells: [
                                for (final index in visible)
                                  DataCell(ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 260),
                                      child: _buildCell(
                                          index < pageRows[rowIndex].length
                                              ? pageRows[rowIndex][index]
                                              : null,
                                          table.columns[index])))
                              ],
                            )
                        ],
                      )),
                )));
  }

  Widget _buildCell(Object? value, ReportColumn column) {
    if (value is num) {
      final formatted = NumberFormat('#,##0.##').format(value);
      return Text(
        column.money ? 'TSH $formatted' : formatted,
        style: AppTypography.bodySmall.copyWith(
            fontWeight: column.money ? FontWeight.w700 : FontWeight.w500,
            color: value < 0 ? AppColors.dangerDeep : AppColors.ink),
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
          int page, int lastPage, int totalRows, int pageRowsCount) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border))),
        child: Row(children: [
          Expanded(
              child: Text(
                  totalRows == 0
                      ? 'No records'
                      : '${page * _pageSize + 1}–${page * _pageSize + pageRowsCount} of $totalRows',
                  style: AppTypography.label)),
          Tooltip(
              message: 'Rows per page',
              child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                value: _pageSize,
                isDense: true,
                items: [
                  for (final size in [10, 25, 50, 100])
                    DropdownMenuItem(
                        value: size,
                        child: Text('$size', style: AppTypography.bodySmall))
                ],
                onChanged: (value) => setState(() {
                  _pageSize = value ?? 25;
                  _page = 0;
                }),
              ))),
          const SizedBox(width: 8),
          IconButton(
              tooltip: 'Previous page',
              onPressed:
                  page == 0 ? null : () => setState(() => _page = page - 1),
              icon: const Icon(Icons.chevron_left_rounded)),
          Text('${page + 1}/${lastPage + 1}', style: AppTypography.label),
          IconButton(
              tooltip: 'Next page',
              onPressed: page == lastPage
                  ? null
                  : () => setState(() => _page = page + 1),
              icon: const Icon(Icons.chevron_right_rounded)),
        ]),
      );

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

class _PresetPeriodMenu extends StatelessWidget {
  const _PresetPeriodMenu({
    required this.onPresetSelected,
    this.selectedPreset,
  });
  final void Function(PresetPeriod) onPresetSelected;
  final PresetPeriod? selectedPreset;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PresetPeriod>(
      tooltip: 'Quick date ranges',
      onSelected: onPresetSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      itemBuilder: (context) => [
        for (final preset in PresetPeriod.values)
          PopupMenuItem(
            value: preset,
            child: Row(
              children: [
                if (selectedPreset == preset)
                  const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(
                  preset.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: selectedPreset == preset
                        ? AppColors.primary
                        : AppColors.ink,
                    fontWeight: selectedPreset == preset
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bolt_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              selectedPreset?.label ?? 'Quick',
              style: AppTypography.label.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
