import 'package:track_mauzo/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';
import '../models/report_models.dart';
import '../pos_report_data.dart';

class ReportDataTable extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                  const WidgetStatePropertyAll(AppColors.surfaceSecondary),
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
                      child:
                          Text(context.tr(table.columns[index].label), maxLines: 2),
                    ),
                    numeric: table.columns[index].money,
                    onSort: (_, ascending) => onSort(index, ascending),
                  ),
              ],
              rows: [
                for (var rowIndex = 0; rowIndex < pageRows.length; rowIndex++)
                  DataRow(
                    color: WidgetStatePropertyAll(rowIndex.isOdd
                        ? AppColors.surfaceSecondary.withValues(alpha: 0.45)
                        : AppColors.surface),
                    cells: [
                      for (final index in visibleIndexes)
                        DataCell(ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: _buildCell(context,
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
      final formatted = NumberFormat('#,##0.##', context.strings.languageCode).format(value);
      return Text(
        column.money ? context.tr('TSH {p0}', args: {'p0': formatted}) : formatted,
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
