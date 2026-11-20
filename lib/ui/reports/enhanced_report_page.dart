import 'package:track_mauzo/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

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
import 'widgets/preset_period_menu.dart';
import 'widgets/report_data_table.dart';
import 'widgets/report_empty_state.dart';
import 'widgets/report_export_service.dart';
import 'widgets/report_toolbar.dart';
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

    for (final order in store.orders) {
      checkDate(DateTime.tryParse(order.dateTime)?.toLocal());
    }
    for (final expense in store.expenses) {
      checkDate(expense.date);
    }
    for (final shift in store.registerShifts) {
      checkDate(shift.openedAt.toLocal());
    }
    for (final customer in store.customers) {
      checkDate(customer.createdAt.toLocal());
    }
    for (final receiving in store.receivings) {
      checkDate(receiving.date);
    }
    for (final tx in store.bankTransactions) {
      checkDate(tx.date);
    }

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
    setState(() {
      _range = DateTimeRange(start: start, end: end);
      _selection = null;
      _page = 0;
    });
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
                  title: context.tr(widget.report.title),
                  subtitle: context.tr('Loading all stores…'),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                 Expanded(
                  child: MarketLoadingView(
                    message: context.tr('Aggregating Store Analytics…'),
                    subMessage:
                        'Retrieving real-time data across all store branches',
                  ),
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
                  title: context.tr(widget.report.title),
                  subtitle: context.tr('Could not load stores'),
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
                            label: context.tr('Retry'),
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
    ).localized(context.strings);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(context.tr(report.title),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sectionHeader),
        toolbarHeight: 72,
        actions: [_buildExportButton(exportTable), const SizedBox(width: 12)],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            ReportToolbar(
              table: table,
              choices: choices,
              selection: selection,
              range: _range,
              selectedPreset: _selectedPreset,
              searchController: _searchController,
              searchQuery: _searchQuery,
              isSnapshot: widget.report.isSnapshot,
              onSearchChanged: (value) => setState(() {
                _searchQuery = value;
                _page = 0;
              }),
              onSearchCleared: () => setState(() {
                _searchController.clear();
                _searchQuery = '';
                _page = 0;
              }),
              onShowColumns: () => _showColumnsSheet(table),
              onChooseRange: _chooseRange,
              onPresetSelected: _applyPreset,
              onClearFilters: _clearFilters,
              onSelectionChanged: (value) => setState(() {
                _selection = value;
                _page = 0;
              }),
            ),
            Expanded(
              child: pageRows.isEmpty
                  ? ReportEmptyState(
                      hasFilters:
                          _searchQuery.isNotEmpty || _selection != null,
                      note: table.note,
                      setupAction: _setupAction,
                      onClearFilters: _clearFilters,
                    )
                  : _buildContent(table, pageRows, additionalMetrics, data,
                      processedRows, visible),
            ),
            _buildPagination(
                page, lastPage, processedRows.length, pageRows.length),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(ReportTable table) => InkWell(
        onTap: _exporting || table.rows.isEmpty
            ? null
            : () => _showExportSheet(table),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: AppColors.surfaceSecondary,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_exporting) ...[
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.ink)),
                const SizedBox(width: 8),
              ] else ...[
                const Icon(Icons.ios_share_outlined,
                    size: 16, color: AppColors.ink),
                const SizedBox(width: 8),
              ],
              Text(
                context.tr('Export'),
                style: AppTypography.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color:
                      table.rows.isEmpty ? AppColors.textLight : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
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
                Text(context.tr('Export report'),
                    style: AppTypography.sectionHeader
                        .copyWith(fontSize: 18, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(
                  '${context.tr(widget.report.title)} • ${table.rows.length} ${context.tr(table.rows.length == 1 ? 'record' : 'records')}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 18),
                _sheetSectionLabel('Download to device'),
                _sheetAction(
                  icon: Icons.table_view_rounded,
                  title: context.tr('CSV spreadsheet'),
                  subtitle: context.tr('Comma separated values'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _triggerExport(table, ExportFormat.csv, save: true);
                  },
                ),
                _sheetAction(
                  icon: Icons.grid_on_rounded,
                  title: context.tr('Excel workbook'),
                  subtitle: context.tr('Microsoft Excel (.xls)'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _triggerExport(table, ExportFormat.excel, save: true);
                  },
                ),
                _sheetAction(
                  icon: Icons.picture_as_pdf_outlined,
                  title: context.tr('PDF document'),
                  subtitle: context.tr('Printable, formatted report'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _triggerExport(table, ExportFormat.pdf, save: true);
                  },
                ),
                const SizedBox(height: 16),
                _sheetSectionLabel(context.tr('Share')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final format in [
                      ExportFormat.csv,
                      ExportFormat.excel,
                      ExportFormat.pdf
                    ])
                      ActionChip(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          _triggerExport(table, format, save: false);
                        },
                        avatar: Icon(_formatIcon(format), size: 16),
                        label: Text(format.label),
                        shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        labelStyle: AppTypography.helperText.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        backgroundColor: AppColors.surfaceSecondary,
                        side: BorderSide.none,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _sheetSectionLabel(context.tr('More')),
                _sheetAction(
                  icon: Icons.copy_all_rounded,
                  title: context.tr('Copy table'),
                  subtitle: context.tr('Copy all matching rows as CSV'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ReportExportService.copyCsv(context, table);
                  },
                ),
                _sheetAction(
                  icon: Icons.print_outlined,
                  title: context.tr('Print'),
                  subtitle: context.tr('Open the system print dialog'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Printing.layoutPdf(
                      onLayout: (_) => ReportExportService.generatePdf(
                        table,
                        context.tr(widget.report.title),
                        _range,
                        widget.report.isSnapshot,
                        languageCode: context.strings.languageCode,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _triggerExport(ReportTable table, ExportFormat format,
      {required bool save}) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      if (save) {
        await ReportExportService.saveReport(
          context: context,
          table: table,
          title: context.tr(widget.report.title),
          format: format,
          range: _range,
          isSnapshot: widget.report.isSnapshot,
        );
      } else {
        await ReportExportService.exportReport(
          context: context,
          table: table,
          title: context.tr(widget.report.title),
          format: format,
          range: _range,
          isSnapshot: widget.report.isSnapshot,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
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
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.zero,
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
                              context.tr('Show columns'),
                              style: AppTypography.sectionHeader
                                  .copyWith(fontSize: 17, color: AppColors.ink),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setSheetState(() => _hiddenColumns.clear());
                              setState(() {});
                            },
                            child:  Text(context.tr('Reset')),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (_hasCostProfitColumns(table))
                      SwitchListTile(
                        title:  Text(context.tr('Show cost and profit')),
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
                                context.tr(column.label),
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

  Widget _buildContent(
    ReportTable table,
    List<List<Object?>> pageRows,
    List<MetricData> additionalMetrics,
    PosReportData data,
    List<List<Object?>> matchingRows,
    List<int> visibleIndexes,
  ) {
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.report.isSnapshot
                      ? context.tr('Current records')
                      : context.tr('Report results'),
                  style: AppTypography.sectionHeader,
                ),
              ),
              Text(
                '${matchingRows.length} ${context.tr(matchingRows.length == 1 ? 'record' : 'records')}',
                style: AppTypography.label,
              ),
            ],
          ),
        ),
      ),
      if (table.note != null)
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            color: AppColors.surfaceSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    table.note!,
                    style: AppTypography.bodySmall
                        .copyWith(fontSize: 12, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (additionalMetrics.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('Key Metrics'),
                    style: AppTypography.sectionHeader
                        .copyWith(fontSize: 15, color: AppColors.ink)),
                const SizedBox(height: 12),
                MetricGrid(metrics: additionalMetrics),
              ],
            ),
          ),
        ),
      if (widget.additionalSectionsBuilder != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: widget.additionalSectionsBuilder!(
                      context, table, data, _range)
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
                context, table, data, _range, _selection),
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
              radius: 0,
              showShadow: false,
              child: _buildTrendChart(table, matchingRows),
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        sliver: SliverToBoxAdapter(
          child: ReportDataTable(
            table: table,
            pageRows: pageRows,
            visibleIndexes: visibleIndexes,
            sortColumn: _sortColumn,
            sortAscending: _sortAscending,
            onSort: (index, ascending) => setState(() {
              _sortColumn = index;
              _sortAscending = ascending;
              _page = 0;
            }),
          ),
        ),
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
      label: context.tr(table.columns[index].label),
      color: AppColors.successDeep,
    );
  }

  Widget _buildPagination(
    int page,
    int lastPage,
    int totalRows,
    int pageRowsCount,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                totalRows == 0
                    ? context.tr('No records')
                    : context.tr('{p0}–{p1} of {p2}', args: {'p0': page * _pageSize + 1, 'p1': page * _pageSize + pageRowsCount, 'p2': totalRows}),
                style: AppTypography.label,
              ),
            ),
            Tooltip(
              message: context.tr('Rows per page'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _pageSize,
                  isDense: true,
                  items: [
                    for (final size in [10, 25, 50, 100])
                      DropdownMenuItem(
                        value: size,
                        child: Text('$size', style: AppTypography.bodySmall),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _pageSize = value ?? 25;
                    _page = 0;
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: context.tr('Previous page'),
              onPressed:
                  page == 0 ? null : () => setState(() => _page = page - 1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text('${page + 1}/${lastPage + 1}', style: AppTypography.label),
            IconButton(
              tooltip: context.tr('Next page'),
              onPressed: page == lastPage
                  ? null
                  : () => setState(() => _page = page + 1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      );

  Widget _buildMissingDataView(String missing) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: context.tr(widget.report.title),
              transparentBackButton: true,
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: AppColors.warningLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.construction_outlined,
                            size: 44, color: AppColors.warning),
                      ),
                      const SizedBox(height: 20),
                      Text(context.tr('Report Unavailable'),
                          style: AppTypography.h3.copyWith(fontSize: 20)),
                      const SizedBox(height: 10),
                      Text(
                        missing,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      MarketButton(
                        label: context.tr('Back to Reports'),
                        icon: Icons.arrow_back_rounded,
                        isFullWidth: false,
                        onTap: () => Navigator.of(context).pop(),
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
