import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';
import '../../../utils/quantity_formatter.dart';
import '../inventory_product_item.dart';
import '../../widgets/app_design.dart';
import '../../widgets/common/product_thumbnail.dart';
import '../../widgets/workspace_widgets.dart';
import 'product_cards.dart';

class InventoryDataTable extends StatelessWidget {
  const InventoryDataTable({
    super.key,
    required this.items,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSort,
    this.onEdit,
    this.onAdjustStock,
    this.onDelete,
  });

  final List<InventoryProductItem> items;
  final int sortColumn;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending) onSort;
  final void Function(InventoryProductItem item)? onEdit;
  final void Function(InventoryProductItem item)? onAdjustStock;
  final void Function(InventoryProductItem item)? onDelete;

  @override
  Widget build(BuildContext context) {
    final hasActions =
        onEdit != null || onAdjustStock != null || onDelete != null;
    return WorkspacePanel(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, tableConstraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: tableConstraints.maxWidth,
            ),
            child: DataTable(
              headingRowColor:
                  WidgetStatePropertyAll(AppColors.surfaceSecondary),
              headingTextStyle: AppTypography.tableHeader,
              dataTextStyle: AppTypography.bodySmall,
              horizontalMargin: 20,
              columnSpacing: 24,
              dataRowMinHeight: 64,
              dataRowMaxHeight: 72,
              sortColumnIndex: sortColumn,
              sortAscending: sortAscending,
              columns: [
                for (final entry in [
                  'Item',
                  'Category',
                  'Cost price',
                  'Sale price',
                  'Quantity'
                ].asMap().entries)
                  DataColumn(
                    label: Text(context.tr(entry.value)),
                    numeric: entry.key >= 2,
                    onSort: onSort,
                  ),
                DataColumn(label: Text(context.tr('Status'))),
                if (hasActions) DataColumn(label: Text(context.tr('Actions'))),
              ],
              rows: items
                  .map(
                    (item) => DataRow(
                      cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.pageBackground,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sharp),
                                    border: Border.all(
                                        color: AppColors.border, width: 1),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: ProductThumbnail(
                                      name: item.name,
                                      imagePath: item.imagePath),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (item.code.isNotEmpty)
                                        Text(
                                          item.code,
                                          style: AppTypography.caption,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(Text(item.category)),
                        DataCell(Text(formatProductPrice(item.purchasePrice))),
                        DataCell(Text(
                          (item.allowFractional ||
                                  item.unit.toLowerCase() != 'pcs')
                              ? '${formatProductPrice(item.sellingPrice)} / ${item.unit}'
                              : formatProductPrice(item.sellingPrice),
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.successDeep,
                          ),
                        )),
                        DataCell(
                          Builder(
                            builder: (_) {
                              final packEquiv = formatPackEquivalent(
                                item.stockCount,
                                item.unit,
                                packName: item.packName,
                                packSize: item.packSize,
                              );
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatStockWithUnit(
                                        item.stockCount, item.unit),
                                  ),
                                  if (packEquiv != null)
                                    Text(
                                      '≈ $packEquiv',
                                      style: AppTypography.caption,
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        DataCell(
                          WorkspaceStatus(
                            label: item.stockCount <= 0
                                ? context.tr('Out of stock')
                                : item.stockCount <= 5
                                    ? context.tr('Low stock')
                                    : formatQuantity(item.stockCount),
                            color: item.stockCount <= 0
                                ? AppColors.dangerDeep
                                : item.stockCount <= 5
                                    ? AppColors.warningDeep
                                    : AppColors.successDeep,
                          ),
                        ),
                        if (hasActions)
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (onEdit != null)
                                  IconButton(
                                    tooltip: context.tr('Edit item'),
                                    onPressed: () => onEdit!(item),
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 19),
                                  ),
                                if (onAdjustStock != null)
                                  IconButton(
                                    tooltip: context.strings.isSwahili
                                        ? 'Rekebisha stoo'
                                        : 'Adjust stock',
                                    onPressed: () => onAdjustStock!(item),
                                    icon: const Icon(Icons.tune_rounded,
                                        size: 19),
                                  ),
                                if (onDelete != null)
                                  IconButton(
                                    tooltip: context.tr('Delete item'),
                                    onPressed: () => onDelete!(item),
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: AppColors.dangerDeep,
                                      size: 19,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
