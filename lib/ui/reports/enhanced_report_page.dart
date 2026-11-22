import '../../service/report_pdf/report_pdf_layout.dart';
import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/store_models.dart';
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
import 'widgets/preset_period_menu.dart';
import 'widgets/report_data_table.dart';
import 'widgets/report_empty_state.dart';
import 'widgets/report_export_service.dart';
import 'widgets/report_toolbar.dart';
import 'widgets/trend_chart.dart';

part 'enhanced/enhanced_report_filters.dart';
part 'enhanced/enhanced_report_sheets.dart';
part 'enhanced/enhanced_report_content.dart';

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

  void _updateState(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) {
    if (!context.watch<PosLocalStore>().hasPermission('View Reports')) {
      return _buildMissingDataView(
        context.tr('You do not have permission to view reports.'),
      );
    }
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
            if (pageRows.isNotEmpty)
              _buildPagination(
                  page, lastPage, processedRows.length, pageRows.length),
          ],
        ),
      ),
    );
  }
}
