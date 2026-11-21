import 'package:flutter/material.dart';
import 'package:track_mauzo/l10n/app_localization.dart';
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
  final void Function(OrderLineItem line)? onEditDiscount;
  final VoidCallback onAddItem;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Current sale'),
                    style: AppTypography.sectionHeader,
                  ),
                ),
                Text(
                  context.tr('{p0} items • {p1} units', args: {'p0': itemTypes, 'p1': unitCount}),
                  style: AppTypography.label,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          OrderLinesList(
            orderLines: orderLines,
            hasItems: hasItems,
            onIncrease: onIncrease,
            onDecrease: onDecrease,
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
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
            label: Text(context.tr('Add more items')),
          ),
        ),
      ],
    );
  }
}
