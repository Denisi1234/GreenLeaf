part of '../enhanced_report_page.dart';

extension _EnhancedReportContent on _EnhancedReportPageState {
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
            onSort: (index, ascending) => _updateState(() {
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
                    : context.tr('{p0}–{p1} of {p2}', args: {
                        'p0': page * _pageSize + 1,
                        'p1': page * _pageSize + pageRowsCount,
                        'p2': totalRows
                      }),
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
                  onChanged: (value) => _updateState(() {
                    _pageSize = value ?? 25;
                    _page = 0;
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: context.tr('Previous page'),
              onPressed: page == 0
                  ? null
                  : () => _updateState(() => _page = page - 1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text('${page + 1}/${lastPage + 1}', style: AppTypography.label),
            IconButton(
              tooltip: context.tr('Next page'),
              onPressed: page == lastPage
                  ? null
                  : () => _updateState(() => _page = page + 1),
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
