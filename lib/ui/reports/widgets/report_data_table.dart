import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';
import '../pos_report_data.dart';

class ReportDataTable extends StatefulWidget {
  const ReportDataTable({
    super.key,
    required this.table,
    required this.pageRows,
    required this.visibleIndexes,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
  });

  final ReportTable table;
  final List<List<Object?>> pageRows;
  final List<int> visibleIndexes;
  final int? sortColumn;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending) onSort;

  @override
  State<ReportDataTable> createState() => _ReportDataTableState();
}

class _ReportDataTableState extends State<ReportDataTable> {
  bool _showTable = false;
  ReportTable get table => widget.table;
  List<List<Object?>> get pageRows => widget.pageRows;
  List<int> get visibleIndexes => widget.visibleIndexes;
  int? get sortColumn => widget.sortColumn;
  bool get sortAscending => widget.sortAscending;
  void Function(int, bool) get onSort => widget.onSort;

  String _formatValue(
      BuildContext context, Object? value, ReportColumn column) {
    if (value is num) {
      final formatted =
          NumberFormat('#,##0.##', context.strings.languageCode).format(value);
      return column.money
          ? context.tr('TSH {p0}', args: {'p0': formatted})
          : formatted;
    }
    return column.displayValue(value, context.strings)?.toString() ?? '—';
  }

  Object? _value(List<Object?> row, int index) =>
      index < row.length ? row[index] : null;

  void _showDetails(List<Object?> row) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => FractionallySizedBox(
          heightFactor: 0.85,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
                child: Row(children: [
                  Expanded(
                      child: Text(context.tr('Record details'),
                          style: AppTypography.h3)),
                  IconButton(
                      tooltip: context.tr('Close'),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded)),
                ])),
            Divider(height: 1, color: AppColors.divider),
            Expanded(
                child: ListView.separated(
              key: const ValueKey('report-record-details'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              itemCount: visibleIndexes.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 28, color: AppColors.divider),
              itemBuilder: (_, position) {
                final index = visibleIndexes[position];
                final value = _value(row, index);
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr(table.columns[index].label),
                          style: AppTypography.label),
                      const SizedBox(height: 6),
                      SelectableText(
                          _formatValue(context, value, table.columns[index]),
                          style: AppTypography.bodyMain.copyWith(
                              color: value is num && value < 0
                                  ? AppColors.dangerDeep
                                  : AppColors.ink)),
                    ]);
              },
            )),
          ])),
    );
  }

  Widget _records(BuildContext context) {
    if (visibleIndexes.isEmpty) return const SizedBox.shrink();
    final names = visibleIndexes
        .where((i) => const {
              'Product',
              'Customer',
              'Supplier',
              'Account',
              'Staff',
              'Store',
            }.contains(table.columns[i].label))
        .toList();
    final first = names.isEmpty ? visibleIndexes.first : names.first;
    final other = visibleIndexes.where((i) => i != first).toList();
    final money = other.where((i) => table.columns[i].money).toList();
    final text = other.where((i) => !table.columns[i].money).toList();
    final stock =
        text.where((i) => table.columns[i].label == 'In stock').toList();
    final preferredMoney = money
        .where((i) => const {
              'Net sales',
              'Total',
              'Amount',
              'Sale price',
              'Balance',
            }.contains(table.columns[i].label))
        .toList();
    final preview = [
      if (text.isNotEmpty) stock.isEmpty ? text.first : stock.first,
      if (money.isNotEmpty)
        preferredMoney.isEmpty ? money.first : preferredMoney.first,
    ];
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.borderLight)),
      child: Column(children: [
        for (var i = 0; i < pageRows.length; i++) ...[
          if (i > 0) Divider(height: 1, indent: 16, color: AppColors.divider),
          Semantics(
              button: true,
              child: InkWell(
                key: ValueKey('report-record-$i'),
                onTap: () => _showDetails(pageRows[i]),
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr(table.columns[first].label),
                              style: AppTypography.label),
                          const SizedBox(height: 4),
                          Row(children: [
                            Expanded(
                                child: Text(
                                    _formatValue(
                                        context,
                                        _value(pageRows[i], first),
                                        table.columns[first]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMain.copyWith(
                                        fontWeight: FontWeight.w700))),
                            const SizedBox(width: 12),
                            Icon(Icons.chevron_right_rounded,
                                size: 21, color: AppColors.textMuted),
                          ]),
                          for (final index in preview) ...[
                            const SizedBox(height: 8),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      child: Text(
                                          context
                                              .tr(table.columns[index].label),
                                          style: AppTypography.label)),
                                  const SizedBox(width: 12),
                                  Flexible(
                                      child: _buildCell(
                                          context,
                                          _value(pageRows[i], index),
                                          table.columns[index])),
                                ]),
                          ],
                        ])),
              )),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 700) return _buildDesktop(context);
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                    child: Text(
                        context.tr(_showTable
                            ? 'Swipe to see all columns'
                            : 'Tap a record for details'),
                        style: AppTypography.label)),
                PopupMenuButton<int>(
                  tooltip: context.tr('Sort records'),
                  icon: const Icon(Icons.sort_rounded, size: 21),
                  onSelected: (index) => onSort(
                      index, sortColumn == index ? !sortAscending : true),
                  itemBuilder: (_) => [
                    for (final index in visibleIndexes)
                      PopupMenuItem(
                          value: index,
                          child: Row(children: [
                            Expanded(
                                child: Text(
                                    context.tr(table.columns[index].label))),
                            if (sortColumn == index)
                              Icon(
                                  sortAscending
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  size: 18),
                          ])),
                  ],
                ),
                IconButton(
                    tooltip:
                        context.tr(_showTable ? 'List view' : 'Table view'),
                    onPressed: () => setState(() => _showTable = !_showTable),
                    icon: Icon(
                        _showTable
                            ? Icons.view_list_outlined
                            : Icons.table_rows_outlined,
                        size: 21)),
              ]),
              _showTable ? _buildDesktop(context) : _records(context),
            ]);
      });

  Widget _buildDesktop(BuildContext context) {
    final sortIndex =
        sortColumn == null ? null : visibleIndexes.indexOf(sortColumn!);

    return WorkspacePanel(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor:
                  WidgetStatePropertyAll(AppColors.surfaceSecondary),
              headingTextStyle:
                  AppTypography.tableHeader.copyWith(color: AppColors.textBody),
              dataTextStyle: AppTypography.bodySmall,
              columnSpacing: 28,
              horizontalMargin: 20,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 72,
              dividerThickness: 0.6,
              showCheckboxColumn: false,
              sortColumnIndex:
                  sortIndex == null || sortIndex < 0 ? null : sortIndex,
              sortAscending: sortAscending,
              columns: [
                for (final index in visibleIndexes)
                  DataColumn(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(context.tr(table.columns[index].label),
                          maxLines: 2),
                    ),
                    numeric: table.columns[index].money,
                    onSort: (_, ascending) => onSort(index, ascending),
                  ),
              ],
              rows: [
                for (var rowIndex = 0; rowIndex < pageRows.length; rowIndex++)
                  DataRow(
                    color: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return AppColors.surfaceHover;
                      }
                      return rowIndex.isOdd
                          ? AppColors.surfaceSecondary.withValues(alpha: 0.45)
                          : AppColors.surface;
                    }),
                    cells: [
                      for (final index in visibleIndexes)
                        DataCell(ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: _buildCell(
                            context,
                            index < pageRows[rowIndex].length
                                ? pageRows[rowIndex][index]
                                : null,
                            table.columns[index],
                          ),
                        )),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, Object? value, ReportColumn column) {
    if (value is num) {
      final formatted =
          NumberFormat('#,##0.##', context.strings.languageCode).format(value);
      return Text(
        column.money
            ? context.tr('TSH {p0}', args: {'p0': formatted})
            : formatted,
        style: AppTypography.bodySmall.copyWith(
          fontWeight: column.money ? FontWeight.w700 : FontWeight.w500,
          color: value < 0 ? AppColors.dangerDeep : AppColors.ink,
        ),
        textAlign: column.money ? TextAlign.right : TextAlign.left,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return Text(
      column.displayValue(value, context.strings)?.toString() ?? '—',
      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
