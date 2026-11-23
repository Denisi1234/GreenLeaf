import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/app_theme_palette.dart';
import '../widgets/market_shared_widgets.dart';
import 'audit_export_service.dart';
import 'widgets/audit_event_detail_sheet.dart';

enum _AuditDateRange { all, today, week, month, custom }

/// Tamper-evident Audit & Trail console for store owners and supervisors.
class AuditTrailPage extends StatefulWidget {
  const AuditTrailPage({super.key});

  @override
  State<AuditTrailPage> createState() => _AuditTrailPageState();
}

class _AuditTrailPageState extends State<AuditTrailPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  AuditModule? _selectedModule;
  AuditSeverity? _selectedSeverity;
  String? _selectedActor;
  _AuditDateRange _dateRange = _AuditDateRange.all;
  DateTimeRange? _customRange;
  bool _exporting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  (DateTime?, DateTime?) _resolvedDates() {
    final now = DateTime.now();
    return switch (_dateRange) {
      _AuditDateRange.all => (null, null),
      _AuditDateRange.today => (now, now),
      _AuditDateRange.week => (now.subtract(const Duration(days: 6)), now),
      _AuditDateRange.month => (now.subtract(const Duration(days: 29)), now),
      _AuditDateRange.custom => (_customRange?.start, _customRange?.end),
    };
  }

  bool get _hasFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedModule != null ||
      _selectedSeverity != null ||
      (_selectedActor != null && _selectedActor!.isNotEmpty) ||
      _dateRange != _AuditDateRange.all;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedModule = null;
      _selectedSeverity = null;
      _selectedActor = null;
      _dateRange = _AuditDateRange.all;
      _customRange = null;
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customRange = picked;
      _dateRange = _AuditDateRange.custom;
    });
  }

  String _filterSummary(bool sw) {
    final parts = <String>[];
    if (_selectedModule != null) parts.add(_selectedModule!.label(sw));
    if (_selectedSeverity != null) parts.add(_selectedSeverity!.label(sw));
    if (_selectedActor != null && _selectedActor!.isNotEmpty) {
      parts.add(_selectedActor!);
    }
    if (_searchQuery.trim().isNotEmpty) {
      parts.add('"${_searchQuery.trim()}"');
    }
    if (parts.isEmpty) {
      return sw ? 'Kumbukumbu zote' : 'All recorded events';
    }
    return parts.join(' · ');
  }

  Future<void> _export({
    required bool pdf,
    required List<AuditLogEntry> entries,
    required AuditIntegrityReport integrity,
    required AppStrings strings,
  }) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      if (pdf) {
        await AuditExportService.exportPdf(
          context: context,
          entries: entries,
          integrity: integrity,
          strings: strings,
          filterSummary: _filterSummary(strings.isSwahili),
        );
      } else {
        await AuditExportService.exportCsv(
          context: context,
          entries: entries,
          strings: strings,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showIntegrityDialog(
    BuildContext context,
    AuditIntegrityReport report,
    bool sw,
  ) {
    final palette = AppThemePalette.of(context);
    final shortHead = report.headHash.length > 24
        ? '${report.headHash.substring(0, 24)}...'
        : report.headHash;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
          side: BorderSide(color: palette.border),
        ),
        title: Row(
          children: [
            Icon(
              report.isValid
                  ? Icons.verified_user_rounded
                  : Icons.gpp_bad_rounded,
              color:
                  report.isValid ? AppColors.successDeep : AppColors.dangerDeep,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                report.isValid
                    ? (sw ? 'Mnyororo ni Salama' : 'Audit Chain Verified')
                    : (sw ? 'Tahadhari ya Usalama' : 'Tampering Detected'),
                style: AppTypography.h3.copyWith(color: palette.ink),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.isValid
                  ? (sw
                      ? 'Rekodi zote ${report.totalChecked} zimekaguliwa kwa SHA-256 na hakuna mabadiliko haramu yaliyogunduliwa.'
                      : 'All ${report.totalChecked} audit records passed SHA-256 hash-chain verification with zero broken links.')
                  : (sw
                      ? 'Rekodi ${report.brokenEntryIds.length} zinaonekana kubadilishwa au zina pengo kwenye mfuatano.'
                      : '${report.brokenEntryIds.length} record(s) failed SHA-256 chain verification or have sequence gaps.'),
              style: AppTypography.bodySmall.copyWith(
                color: palette.textBody,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            _DialogStat(
              palette: palette,
              label: sw ? 'Rekodi zilizokaguliwa' : 'Records checked',
              value: '${report.totalChecked}',
            ),
            _DialogStat(
              palette: palette,
              label: sw ? 'Mfuatano wa mwisho' : 'Latest sequence',
              value: '#${report.lastSequence}',
            ),
            _DialogStat(
              palette: palette,
              label: sw ? 'Alama ya SHA-256' : 'Chain head hash',
              value: shortHead,
              monospace: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(sw ? 'Funga' : 'Close'),
          ),
        ],
      ),
    );
  }

  String _dayHeaderLabel(DateTime date, bool sw) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return sw ? 'Leo' : 'Today';
    if (day == yesterday) return sw ? 'Jana' : 'Yesterday';
    return DateFormat('EEE, MMM d, yyyy', sw ? 'sw' : 'en').format(day);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final palette = AppThemePalette.of(context);
    final strings = AppStrings.of(store.languageCode);
    final sw = strings.isSwahili;
    String t(String en, String swText) => sw ? swText : en;

    final (startDate, endDate) = _resolvedDates();
    final entries = store.queryAuditLogs(
      query: _searchQuery,
      module: _selectedModule,
      severity: _selectedSeverity,
      actorName: _selectedActor,
      startDate: startDate,
      endDate: endDate,
    );
    final integrity = store.verifyAuditIntegrity();
    final criticalCount =
        entries.where((e) => e.severity == AuditSeverity.critical).length;
    final actorSet = entries.map((e) => e.actorName).toSet().length;
    final actors = store.auditActors;

    // Group entries sequentially by calendar day while keeping chronological order
    final groupedDays = <({String label, List<AuditLogEntry> items})>[];
    for (final entry in entries) {
      final label = _dayHeaderLabel(entry.timestamp, sw);
      if (groupedDays.isEmpty || groupedDays.last.label != label) {
        groupedDays.add((label: label, items: [entry]));
      } else {
        groupedDays.last.items.add(entry);
      }
    }

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: Column(
        children: [
          MarketPageHeader(
            title: t('Audit & trail', 'Kumbukumbu za ukaguzi'),
            showBackButton: true,
            centerTitle: false,
            titleSize: 20,
            titleWeight: FontWeight.w800,
            showBorder: true,
            actions: [
              Tooltip(
                message: t('Verify chain integrity', 'Kagua usalama wa mnyororo'),
                child: HeaderActionButton(
                  icon: integrity.isValid
                      ? Icons.verified_user_outlined
                      : Icons.gpp_maybe_outlined,
                  background: palette.surface,
                  foreground: integrity.isValid
                      ? AppColors.successDeep
                      : AppColors.dangerDeep,
                  borderColor: palette.border,
                  onTap: () => _showIntegrityDialog(context, integrity, sw),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                enabled: !_exporting && entries.isNotEmpty,
                tooltip: t('Export audit log', 'Hamisha ripoti'),
                color: palette.surface,
                onSelected: (value) => _export(
                  pdf: value == 'pdf',
                  entries: entries,
                  integrity: integrity,
                  strings: strings,
                ),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined,
                            size: 18, color: palette.ink),
                        const SizedBox(width: 10),
                        Text(t('Export PDF report', 'Pakua PDF')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'csv',
                    child: Row(
                      children: [
                        Icon(Icons.table_chart_outlined,
                            size: 18, color: palette.ink),
                        const SizedBox(width: 10),
                        Text(t('Export CSV spreadsheet', 'Pakua CSV')),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(AppRadius.standard),
                    border: Border.all(color: palette.border),
                  ),
                  alignment: Alignment.center,
                  child: _exporting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.primary,
                          ),
                        )
                      : Icon(
                          Icons.ios_share_rounded,
                          size: 20,
                          color: entries.isEmpty
                              ? palette.textMuted
                              : palette.ink,
                        ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _KpiStrip(
                        palette: palette,
                        totalEvents: entries.length,
                        criticalCount: criticalCount,
                        actorCount: actorSet,
                        integrity: integrity,
                        isSwahili: sw,
                        onVerifyTap: () =>
                            _showIntegrityDialog(context, integrity, sw),
                      ),
                      const SizedBox(height: 14),
                      _FilterPanel(
                        palette: palette,
                        searchController: _searchController,
                        searchHint: t(
                          'Search user, action, product, receipt...',
                          'Tafuta mtumiaji, kitendo, bidhaa, risiti...',
                        ),
                        onSearchChanged: (v) =>
                            setState(() => _searchQuery = v),
                        onSearchClear: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        dateRange: _dateRange,
                        customRange: _customRange,
                        onDateRangeChanged: (next) {
                          if (next == _AuditDateRange.custom) {
                            _pickCustomRange();
                          } else {
                            setState(() => _dateRange = next);
                          }
                        },
                        selectedSeverity: _selectedSeverity,
                        onSeverityChanged: (next) =>
                            setState(() => _selectedSeverity = next),
                        selectedModule: _selectedModule,
                        onModuleChanged: (next) =>
                            setState(() => _selectedModule = next),
                        actors: actors,
                        selectedActor: _selectedActor,
                        onActorChanged: (next) =>
                            setState(() => _selectedActor = next),
                        hasFilters: _hasFilters,
                        onReset: _resetFilters,
                        isSwahili: sw,
                      ),
                      const SizedBox(height: 16),
                      if (entries.isEmpty)
                        _AuditEmptyState(
                          palette: palette,
                          hasAnyLogs: store.auditLogs.isNotEmpty,
                          hasFilters: _hasFilters,
                          onReset: _resetFilters,
                          isSwahili: sw,
                        )
                      else
                        for (final group in groupedDays) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group.label.toUpperCase(),
                                    style: AppTypography.label.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: palette.textMuted,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${group.items.length}',
                                  style: AppTypography.label.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final item in group.items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AuditEventCard(
                                palette: palette,
                                entry: item,
                                isSwahili: sw,
                                onTap: () => showAuditEventDetailSheet(
                                  context,
                                  entry: item,
                                  isSwahili: sw,
                                ),
                              ),
                            ),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({
    required this.palette,
    required this.totalEvents,
    required this.criticalCount,
    required this.actorCount,
    required this.integrity,
    required this.isSwahili,
    required this.onVerifyTap,
  });

  final AppThemePalette palette;
  final int totalEvents;
  final int criticalCount;
  final int actorCount;
  final AuditIntegrityReport integrity;
  final bool isSwahili;
  final VoidCallback onVerifyTap;

  String _t(String en, String sw) => isSwahili ? sw : en;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 700 ? 4 : 2;
        const spacing = 10.0;
        final cardWidth =
            ((constraints.maxWidth - spacing * (cols - 1)) / cols)
                .floorToDouble();

        final cards = [
          _KpiTile(
            width: cardWidth,
            palette: palette,
            label: _t('Events', 'Matukio'),
            value: '$totalEvents',
            icon: Icons.history_rounded,
            accent: palette.primaryDeep,
          ),
          _KpiTile(
            width: cardWidth,
            palette: palette,
            label: _t('Critical alerts', 'Matukio muhimu'),
            value: '$criticalCount',
            icon: Icons.warning_amber_rounded,
            accent: criticalCount > 0 ? AppColors.dangerDeep : palette.textMuted,
          ),
          _KpiTile(
            width: cardWidth,
            palette: palette,
            label: _t('Active staff', 'Wahusika'),
            value: '$actorCount',
            icon: Icons.group_outlined,
            accent: palette.primary,
          ),
          _KpiTile(
            width: cardWidth,
            palette: palette,
            label: _t('Chain status', 'Usalama'),
            value: integrity.isValid
                ? _t('Verified', 'Salama')
                : _t('Broken', 'Kasoro'),
            icon: integrity.isValid
                ? Icons.verified_user_outlined
                : Icons.gpp_bad_outlined,
            accent:
                integrity.isValid ? AppColors.successDeep : AppColors.dangerDeep,
            onTap: onVerifyTap,
          ),
        ];

        return Wrap(spacing: spacing, runSpacing: spacing, children: cards);
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.width,
    required this.palette,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final double width;
  final AppThemePalette palette;
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.standard),
              border: Border.all(color: palette.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: palette.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3.copyWith(
                    color: accent,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.palette,
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.dateRange,
    required this.customRange,
    required this.onDateRangeChanged,
    required this.selectedSeverity,
    required this.onSeverityChanged,
    required this.selectedModule,
    required this.onModuleChanged,
    required this.actors,
    required this.selectedActor,
    required this.onActorChanged,
    required this.hasFilters,
    required this.onReset,
    required this.isSwahili,
  });

  final AppThemePalette palette;
  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final _AuditDateRange dateRange;
  final DateTimeRange? customRange;
  final ValueChanged<_AuditDateRange> onDateRangeChanged;
  final AuditSeverity? selectedSeverity;
  final ValueChanged<AuditSeverity?> onSeverityChanged;
  final AuditModule? selectedModule;
  final ValueChanged<AuditModule?> onModuleChanged;
  final List<String> actors;
  final String? selectedActor;
  final ValueChanged<String?> onActorChanged;
  final bool hasFilters;
  final VoidCallback onReset;
  final bool isSwahili;

  String _t(String en, String sw) => isSwahili ? sw : en;

  @override
  Widget build(BuildContext context) {
    final searchField = MarketSearchField(
      controller: searchController,
      hintText: searchHint,
      onChanged: onSearchChanged,
      onClear: onSearchClear,
      radius: AppRadius.input,
      backgroundColor: palette.isDark ? palette.surfaceSecondary : palette.surface,
      borderColor: palette.border,
      paddingHorizontal: 12,
    );

    final actorDropdown = actors.isEmpty
        ? null
        : DropdownButtonFormField<String?>(
            key: ValueKey('actor-${selectedActor ?? 'all'}-${actors.length}'),
            initialValue: actors.contains(selectedActor) ? selectedActor : null,
            isExpanded: true,
            dropdownColor: palette.surface,
            decoration: InputDecoration(
              filled: true,
              fillColor:
                  palette.isDark ? palette.surfaceSecondary : palette.surface,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: AppCorners.input,
                borderSide: BorderSide(color: palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppCorners.input,
                borderSide: BorderSide(color: palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppCorners.input,
                borderSide: BorderSide(color: palette.primary, width: 1.4),
              ),
            ),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  _t('All staff members', 'Wahusika wote'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (final actor in actors)
                DropdownMenuItem<String?>(
                  value: actor,
                  child: Text(actor, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: onActorChanged,
          );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (actorDropdown != null && constraints.maxWidth >= 620) {
                return Row(
                  children: [
                    Expanded(flex: 3, child: searchField),
                    const SizedBox(width: 10),
                    Expanded(flex: 2, child: actorDropdown),
                  ],
                );
              }
              return Column(
                children: [
                  searchField,
                  if (actorDropdown != null) ...[
                    const SizedBox(height: 10),
                    actorDropdown,
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FilterChipItem(
                palette: palette,
                label: _t('All time', 'Muda wote'),
                selected: dateRange == _AuditDateRange.all,
                onTap: () => onDateRangeChanged(_AuditDateRange.all),
              ),
              _FilterChipItem(
                palette: palette,
                label: _t('Today', 'Leo'),
                selected: dateRange == _AuditDateRange.today,
                onTap: () => onDateRangeChanged(_AuditDateRange.today),
              ),
              _FilterChipItem(
                palette: palette,
                label: _t('7 days', 'Siku 7'),
                selected: dateRange == _AuditDateRange.week,
                onTap: () => onDateRangeChanged(_AuditDateRange.week),
              ),
              _FilterChipItem(
                palette: palette,
                label: _t('30 days', 'Siku 30'),
                selected: dateRange == _AuditDateRange.month,
                onTap: () => onDateRangeChanged(_AuditDateRange.month),
              ),
              _FilterChipItem(
                palette: palette,
                label: dateRange == _AuditDateRange.custom &&
                        customRange != null
                    ? '${DateFormat('MMM d').format(customRange!.start)} – ${DateFormat('MMM d').format(customRange!.end)}'
                    : _t('Custom', 'Chagua tarehe'),
                selected: dateRange == _AuditDateRange.custom,
                onTap: () => onDateRangeChanged(_AuditDateRange.custom),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _FilterChipItem(
                palette: palette,
                label: _t('All levels', 'Viwango vyote'),
                selected: selectedSeverity == null,
                onTap: () => onSeverityChanged(null),
              ),
              for (final sev in AuditSeverity.values)
                _FilterChipItem(
                  palette: palette,
                  label: sev.label(isSwahili),
                  selected: selectedSeverity == sev,
                  accent: switch (sev) {
                    AuditSeverity.critical => AppColors.dangerDeep,
                    AuditSeverity.warning => AppColors.warningDeep,
                    AuditSeverity.info => palette.primaryDeep,
                  },
                  onTap: () => onSeverityChanged(
                    selectedSeverity == sev ? null : sev,
                  ),
                ),
              if (hasFilters)
                TextButton(
                  onPressed: onReset,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    _t('Reset', 'Ondoa vichujio'),
                    style: AppTypography.bodySmall.copyWith(
                      color: palette.primaryDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _FilterChipItem(
                    palette: palette,
                    label: _t('All modules', 'Sehemu zote'),
                    selected: selectedModule == null,
                    onTap: () => onModuleChanged(null),
                  ),
                ),
                for (final module in AuditModule.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _FilterChipItem(
                      palette: palette,
                      icon: module.icon,
                      label: module.label(isSwahili),
                      selected: selectedModule == module,
                      onTap: () => onModuleChanged(
                        selectedModule == module ? null : module,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.palette,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accent,
  });

  final AppThemePalette palette;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final activeColor = accent ?? palette.primaryDeep;
    return Material(
      color: selected ? palette.primaryLight : palette.surfaceSecondary,
      borderRadius: BorderRadius.circular(AppRadius.sharp),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sharp),
            border: Border.all(
              color: selected ? activeColor : palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: selected ? activeColor : palette.textMuted,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: selected ? activeColor : palette.textBody,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditEventCard extends StatelessWidget {
  const _AuditEventCard({
    required this.palette,
    required this.entry,
    required this.isSwahili,
    required this.onTap,
  });

  final AppThemePalette palette;
  final AuditLogEntry entry;
  final bool isSwahili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final severityColor = switch (entry.severity) {
      AuditSeverity.critical => AppColors.danger,
      AuditSeverity.warning => AppColors.warning,
      AuditSeverity.info => palette.primary,
    };
    final diffPreview = entry.changedKeys.take(2).map((k) {
      final b = entry.beforeValues[k];
      final a = entry.afterValues[k];
      if (b != null && a != null) return '$k: $b → $a';
      return '$k: ${a ?? b ?? ''}';
    }).join(' · ');

    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(AppRadius.standard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: palette.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: severityColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: palette.surfaceSecondary,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sharp),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                entry.module.icon,
                                size: 18,
                                color: palette.primaryDeep,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.actionTitle(isSwahili),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.bodyMain
                                              .copyWith(
                                            color: palette.ink,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('HH:mm:ss')
                                            .format(entry.timestamp),
                                        style: AppTypography.caption.copyWith(
                                          color: palette.textMuted,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    entry.module.label(isSwahili) +
                                        (entry.entityLabel.isEmpty
                                            ? ''
                                            : ' · ${entry.entityLabel}'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      color: palette.primaryDeep,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: palette.textBody,
                            height: 1.4,
                          ),
                        ),
                        if (diffPreview.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surfaceSecondary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sharp),
                            ),
                            child: Text(
                              diffPreview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: palette.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: palette.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${entry.actorName} (${entry.actorRole})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: palette.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '#${entry.sequence}',
                              style: AppTypography.caption.copyWith(
                                color: palette.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: palette.textMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuditEmptyState extends StatelessWidget {
  const _AuditEmptyState({
    required this.palette,
    required this.hasAnyLogs,
    required this.hasFilters,
    required this.onReset,
    required this.isSwahili,
  });

  final AppThemePalette palette;
  final bool hasAnyLogs;
  final bool hasFilters;
  final VoidCallback onReset;
  final bool isSwahili;

  @override
  Widget build(BuildContext context) {
    final title = hasAnyLogs
        ? (isSwahili ? 'Hakuna matukio yanayolingana' : 'No matching events')
        : (isSwahili ? 'Hakuna kumbukumbu bado' : 'No audit events yet');
    final body = hasAnyLogs
        ? (isSwahili
            ? 'Jaribu kubadilisha vichujio au neno la kutafuta.'
            : 'Try clearing or adjusting your active filters.')
        : (isSwahili
            ? 'Mauzo, mabadiliko ya stoo, kufutwa kwa risiti, zamu na mipangilio itarekodiwa hapa moja kwa moja.'
            : 'Sales, voids, stock edits, register shifts, staff changes and tax edits are recorded here automatically.');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_user_outlined, size: 42, color: palette.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.h3.copyWith(color: palette.ink),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: palette.textMuted,
              height: 1.45,
            ),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onReset,
              child: Text(isSwahili ? 'Ondoa vichujio' : 'Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DialogStat extends StatelessWidget {
  const _DialogStat({
    required this.palette,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final AppThemePalette palette;
  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: palette.textMuted),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: palette.ink,
              fontWeight: FontWeight.w700,
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}
