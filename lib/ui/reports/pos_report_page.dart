import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'pos_report_catalog.dart';
import 'pos_report_data.dart';

class PosReportPage extends StatefulWidget {
  const PosReportPage({super.key, required this.report});
  final PosReport report;

  @override
  State<PosReportPage> createState() => _PosReportPageState();
}

class _PosReportPageState extends State<PosReportPage> {
  static const _pageSize = 25;

  DateTimeRange? _range;
  String? _selection;
  int _page = 0;
  bool _sharing = false;

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

  Future<void> _share(BuildContext buttonContext, ReportTable table) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _sharing = true);
    try {
      final name =
          '${widget.report.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceFirst(RegExp(r'_$'), '')}.csv';
      final content = [
        table.columns.map((column) => _csvCell(column.label)).join(','),
        ...table.rows.map((row) => row.map(_csvCell).join(',')),
      ].join('\r\n');
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(utf8.encode('\uFEFF$content'), mimeType: 'text/csv'),
          ],
          fileNameOverrides: [name],
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (mounted) {
        showMarketNotice(
          context,
          title: 'Share failed',
          message: 'Could not share this report.',
          type: MarketNoticeType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final missing = widget.report.missingData;
    if (missing != null) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              MarketPageHeader(
                title: widget.report.title,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: MarketSurfaceCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.construction_outlined,
                              color: AppColors.warning, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            missing,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
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
    final table = data.build(
      report.data,
      start: _range?.start,
      end: _range?.end,
      selection: selection,
    );
    final lastPage =
        table.rows.isEmpty ? 0 : (table.rows.length - 1) ~/ _pageSize;
    final page = _page.clamp(0, lastPage);
    final pageRows = table.rows.skip(page * _pageSize).take(_pageSize).toList();
    final localizations = MaterialLocalizations.of(context);
    final range = _range;
    final rangeLabel = range == null
        ? 'All dates'
        : '${localizations.formatCompactDate(range.start)} – ${localizations.formatCompactDate(range.end)}';

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: report.title,
              subtitle: rangeLabel,
              onBack: () => Navigator.of(context).pop(),
              actions: [
                Builder(
                  builder: (buttonContext) => InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.standard),
                    onTap: table.rows.isEmpty || _sharing
                        ? null
                        : () => _share(buttonContext, table),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.standard),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: _sharing
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primary),
                            )
                          : const Icon(Icons.ios_share_rounded,
                              size: 18, color: AppColors.ink),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (report.isSnapshot)
                    Text('Current store snapshot',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _chooseRange,
                          icon: const Icon(Icons.date_range_rounded, size: 18),
                          label: Text(rangeLabel),
                          style: _toolbarStyle(),
                        ),
                        if (range != null)
                          OutlinedButton.icon(
                            onPressed: () => _setRange(null),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('All dates'),
                            style: _toolbarStyle(),
                          ),
                        if (choices.isNotEmpty)
                          PopupMenuButton<String>(
                            tooltip: 'Filter records',
                            initialValue: selection,
                            onSelected: (value) => setState(() {
                              _selection = value;
                              _page = 0;
                            }),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.standard)),
                            itemBuilder: (context) => [
                              for (final value in choices)
                                PopupMenuItem(
                                    value: value,
                                    child: Text(value,
                                        style: AppTypography.bodySmall)),
                            ],
                            child: IgnorePointer(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.filter_list_rounded,
                                    size: 18),
                                label: Text(selection ?? 'Filter'),
                                style: _toolbarStyle(),
                              ),
                            ),
                          ),
                        if (selection != null)
                          OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _selection = null;
                              _page = 0;
                            }),
                            icon: const Icon(Icons.filter_alt_off_rounded,
                                size: 18),
                            label: const Text('Clear filter'),
                            style: _toolbarStyle(),
                          ),
                      ],
                    ),
                  if (table.note case final note?)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius:
                            BorderRadius.circular(AppRadius.standard),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(note,
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.ink)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (pageRows.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.analytics_outlined,
                              size: 40, color: AppColors.textLight),
                          const SizedBox(height: 12),
                          Text('No records for this report.',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                    )
                  else ...[
                    if (report.chart && table.chartColumn != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MarketSurfaceCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: _ReportChart(table: table, rows: pageRows),
                        ),
                      ),
                    MarketSurfaceCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppRadius.standard),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                                AppColors.primaryLight),
                            headingTextStyle: AppTypography.label.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: AppColors.primaryDeep),
                            dataTextStyle:
                                AppTypography.bodySmall.copyWith(fontSize: 12),
                            dividerThickness: 0.6,
                            columns: [
                              for (final column in table.columns)
                                DataColumn(
                                  label: Text(column.label),
                                  numeric: column.money,
                                ),
                            ],
                            rows: [
                              for (final row in pageRows)
                                DataRow(
                                  cells: [
                                    for (var i = 0; i < row.length; i++)
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: 220),
                                          child: Text(
                                            _cell(row[i], table.columns[i]),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              fontWeight: table.columns[i].money
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: table.columns[i].money
                                                  ? AppColors.primaryDeep
                                                  : AppColors.ink,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${page * _pageSize + 1}–${page * _pageSize + pageRows.length} of ${table.rows.length}',
                          style: AppTypography.helperText
                              .copyWith(color: AppColors.textMuted),
                        ),
                        IconButton(
                          tooltip: 'Previous page',
                          onPressed: page == 0
                              ? null
                              : () => setState(() => _page = page - 1),
                          icon: const Icon(Icons.chevron_left_rounded),
                          color: AppColors.ink,
                        ),
                        IconButton(
                          tooltip: 'Next page',
                          onPressed: page == lastPage
                              ? null
                              : () => setState(() => _page = page + 1),
                          icon: const Icon(Icons.chevron_right_rounded),
                          color: AppColors.ink,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _toolbarStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.textMain,
        side: const BorderSide(color: AppColors.border),
        backgroundColor: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: AppTypography.label.copyWith(fontSize: 13),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.standard)),
      );
}

final _number = NumberFormat('#,##0.##', 'en');

String _cell(Object? value, ReportColumn column) {
  if (value is num) {
    final formatted = _number.format(value);
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

class _ReportChart extends StatelessWidget {
  const _ReportChart({required this.table, required this.rows});
  final ReportTable table;
  final List<List<Object?>> rows;

  @override
  Widget build(BuildContext context) {
    final index = table.chartColumn!;
    final max = table.rows.fold<double>(0, (peak, row) {
      final magnitude = (row[index] as num).abs().toDouble();
      return magnitude > peak ? magnitude : peak;
    });
    final column = table.columns[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(column.label,
            style: AppTypography.sectionHeader
                .copyWith(fontSize: 15, color: AppColors.ink)),
        const SizedBox(height: 8),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(row.first.toString(),
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall),
                    ),
                    const SizedBox(width: 8),
                    Text(_cell(row[index], column),
                        style: AppTypography.label
                            .copyWith(color: AppColors.primaryDeep)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: max == 0 ? 0 : (row[index] as num).abs() / max,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceSecondary,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
