import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';
import '../../models/product_item.dart';
import '../../widgets/app_design.dart';
import 'order_lines_list.dart';

class PaymentCartPanel extends StatelessWidget {
  const PaymentCartPanel({
    super.key,
    required this.orderLines,
    required this.hasItems,
    required this.itemTypes,
    required this.unitCount,
    required this.savingSale,
    required this.onIncrease,
    required this.onDecrease,
    this.onEditQuantity,
    this.onEditDiscount,
    required this.onAddItem,
  });

  final List<OrderLineItem> orderLines;
  final bool hasItems;
  final int itemTypes;
  final int unitCount;
  final bool savingSale;
  final void Function(OrderLineItem line) onIncrease;
  final void Function(OrderLineItem line) onDecrease;
  final void Function(OrderLineItem line)? onEditQuantity;
  final void Function(OrderLineItem line)? onEditDiscount;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Current sale'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sectionHeader,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    context.tr('{p0} items • {p1} units',
                        args: {'p0': itemTypes, 'p1': unitCount}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTypography.label,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          OrderLinesList(
            orderLines: orderLines,
            hasItems: hasItems,
            onIncrease: onIncrease,
            onDecrease: onDecrease,
            onEditQuantity: onEditQuantity,
            onEditDiscount: onEditDiscount,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: CounterActionRow(onAddItem: onAddItem),
          ),
        ],
      ),
    );
  }
}

class CounterActionRow extends StatelessWidget {
  const CounterActionRow({
    super.key,
    required this.onAddItem,
  });

  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onAddItem,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.kpiSkyBg,
              foregroundColor: AppColors.kpiSky,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.all(Radius.circular(AppRadius.button)),
              ),
            ),
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
            label: Text(
              context.tr('Add more items'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
