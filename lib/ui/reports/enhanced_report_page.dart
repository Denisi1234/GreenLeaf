import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'models/report_models.dart';
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

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _range = DateTimeRange(
      start: DateTime(today.year, today.month),
      end: today,
    );
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
        final firstThisQuarter =
            DateTime(today.year, (quarter - 1) * 3 + 1, 1);
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
      Uint8List bytes;
      String fileName;
      String mimeType;
      switch (_exportFormat) {
        case ExportFormat.csv:
          bytes = _generateCsv(table);
          fileName = _csvFileName();
          mimeType = 'text/csv';
          break;
        case ExportFormat.excel:
          bytes = await _generateExcel(table);
          fileName = _excelFileName();
          mimeType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case ExportFormat.pdf:
          bytes = await _generatePdf(table);
          fileName = _pdfFileName();
          mimeType = 'application/pdf';
          break;
      }
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: mimeType)],
          fileNameOverrides: [fileName],
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

  Uint8List _generateCsv(ReportTable table) {
    final content = [
      table.columns.map((c) => _csvCell(c.label)).join(','),
      ...table.rows.map((row) => row.map(_csvCell).join(',')),
    ].join('\r\n');
    return Uint8List.fromList(utf8.encode('\uFEFF$content'));
  }

  Future<Uint8List> _generateExcel(ReportTable table) async {
    final content = [
      table.columns.map((c) => _csvCell(c.label)).join('\t'),
      ...table.rows.map((row) => row.map(_csvCell).join('\t')),
    ].join('\r\n');
    return Uint8List.fromList(utf8.encode('\uFEFF$content'));
  }

  Future<Uint8List> _generatePdf(ReportTable table) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 16),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(widget.report.title,
                  style: pw.TextStyle(
                      font: fontBold, fontSize: 20, color: PdfColors.blue900)),
              pw.Text(
                _range != null
                    ? '${DateFormat('MMM d, yyyy').format(_range!.start)} – ${DateFormat('MMM d, yyyy').format(_range!.end)}'
                    : 'All Time',
                style: pw.TextStyle(
                    font: font, fontSize: 11, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Table.fromTextArray(
            headers: table.columns.map((c) => c.label).toList(),
            data: table.rows
                .map((row) => [
                      for (var i = 0; i < row.length; i++)
                        _pdfCell(row[i], table.columns[i])
                    ])
                .toList(),
            headerStyle: pw.TextStyle(
                font: fontBold, fontSize: 9, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellStyle: pw.TextStyle(font: font, fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                  font: font, fontSize: 8, color: PdfColors.grey600)),
        ),
      ),
    );
    return pdf.save();
  }

  String _pdfCell(Object? value, ReportColumn column) {
    if (value is num) {
      final formatted = NumberFormat('#,##0.##').format(value);
      return column.money ? 'TSH $formatted' : formatted;
    }
    return value?.toString() ?? '—';
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

  String _baseFileName() => widget.report.title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceFirst(RegExp(r'_$'), '');
  String _csvFileName() =>
      '${_baseFileName()}_${DateTime.now().millisecondsSinceEpoch}.csv';
  String _excelFileName() =>
      '${_baseFileName()}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
  String _pdfFileName() =>
      '${_baseFileName()}_${DateTime.now().millisecondsSinceEpoch}.pdf';

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
    final lastPage =
        table.rows.isEmpty ? 0 : (table.rows.length - 1) ~/ _pageSize;
    final page = _page.clamp(0, lastPage);
    final pageRows =
        table.rows.skip(page * _pageSize).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: report.title,
              subtitle: rangeLabel,
              onBack: () => Navigator.of(context).maybePop(),
              actions: [_buildExportMenu(table)],
            ),
            _buildToolbar(choices, selection),
            if (table.note != null) _buildNoteBanner(table.note!),
            Expanded(
              child: pageRows.isEmpty
                  ? _buildEmptyState(report)
                  : _buildContent(table, pageRows, additionalMetrics),
            ),
            _buildPagination(
                page, lastPage, table.rows.length, pageRows.length),
          ],
        ),
      ),
    );
  }

  Widget _buildExportMenu(ReportTable table) {
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard)),
      onSelected: (value) async {
        if (value == 'print') {
          await Printing.layoutPdf(onLayout: (_) => _generatePdf(table));
          return;
        }
        final format = ExportFormat.values.firstWhere((f) => f.name == value);
        setState(() => _exportFormat = format);
        await _exportReport(table);
      },
      itemBuilder: (context) => [
        _menuItem('csv', Icons.table_chart_outlined, 'Export CSV'),
        _menuItem('excel', Icons.grid_on_rounded, 'Export Excel (TSV)'),
        _menuItem('pdf', Icons.picture_as_pdf_outlined, 'Export PDF'),
        const PopupMenuDivider(),
        _menuItem('print', Icons.print_outlined, 'Print'),
      ],
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
            : const Icon(Icons.more_horiz_rounded,
                color: AppColors.ink, size: 22),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String v, IconData i, String l) =>
      PopupMenuItem<String>(
        value: v,
        child: Row(children: [
          Icon(i, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(l, style: AppTypography.bodySmall),
        ]),
      );

  Widget _buildToolbar(List<String> choices, String? selection) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Wrap(
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
            MarketButton(
                label: 'Clear filters',
                icon: Icons.clear_all_rounded,
                isFullWidth: false,
                onTap: () => _setRange(null)),
          ]),
        ),
      );

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
          tint: AppColors.primaryLight,
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
            tint: const Color(0xFFF5F3FF),
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
          tint: AppColors.primaryLight,
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
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
              children: widget
                  .additionalSectionsBuilder!(
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
    return MarketSurfaceCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.primaryLight),
            headingTextStyle: AppTypography.label.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: AppColors.primaryDeep),
            dataTextStyle: AppTypography.bodySmall.copyWith(fontSize: 12),
            columnSpacing: 16,
            horizontalMargin: 12,
            dividerThickness: 0.6,
            columns: [
              for (final column in table.columns)
                DataColumn(label: Text(column.label), numeric: column.money)
            ],
            rows: [
              for (final row in pageRows)
                DataRow(cells: [
                  for (var i = 0; i < row.length; i++)
                    DataCell(ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 240),
                      child: _buildCell(row[i], table.columns[i]),
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
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted, height: 1.5)),
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

enum ExportFormat { csv, excel, pdf }

extension ExportFormatLabel on ExportFormat {
  String get label {
    switch (this) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.excel:
        return 'Excel (TSV)';
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
              value: value,
              child: Text(value, style: AppTypography.bodySmall)),
      ],
      child: IgnorePointer(
        child: OutlinedButton.icon(
          onPressed: () {},
          icon: Icon(
            selection != null
                ? Icons.filter_alt_rounded
                : Icons.filter_list_rounded,
            size: 18,
            color:
                selection != null ? AppColors.primary : AppColors.textMuted,
          ),
          label: Text(
            selection ?? 'Filter',
            style: AppTypography.label.copyWith(
              fontSize: 13,
              color:
                  selection != null ? AppColors.primary : AppColors.textMain,
              fontWeight:
                  selection != null ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textMain,
            side: BorderSide(
                color: selection != null ? AppColors.primary : AppColors.border),
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
