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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(12)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(context.strings.paragraph(table.note!),
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textBody, height: 1.45))),
              ]),
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
              radius: AppRadius.standard,
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
        decoration: BoxDecoration(
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
              onPressed:
                  page == 0 ? null : () => _updateState(() => _page = page - 1),
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

  Widget _buildMissingDataView(String missing) => Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: _reportAppBar(),
        body: Center(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: MarketEmptyState(
            icon: Icons.info_outline_rounded,
            title: context.tr('Report Unavailable'),
            message: context.strings.paragraph(missing),
            actionLabel: context.tr('Back to Reports'),
            actionIcon: Icons.arrow_back_rounded,
            onAction: () => Navigator.of(context).maybePop(),
            showCard: false,
          ),
        )),
      );
}
