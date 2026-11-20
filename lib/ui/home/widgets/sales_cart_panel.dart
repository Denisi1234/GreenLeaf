import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_mauzo/l10n/app_localization.dart';

import '../../../service/pos_local_store.dart';
import '../../../utils/currency_formatter.dart';
import '../../models/product_item.dart';
import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';
import 'product_card.dart';

class SalesCartPanel extends StatelessWidget {
  const SalesCartPanel({super.key, required this.checkout});
  final Widget checkout;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lines = <String, OrderLineItem>{};
    for (final item in store.cartItems) {
      final key = productKey(item);
      if (lines.containsKey(key)) {
        lines[key]!.quantity++;
      } else {
        lines[key] = OrderLineItem(product: item, quantity: 1);
      }
    }

    return WorkspacePanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Current sale'),
                    style: AppTypography.sectionHeader,
                  ),
                ),
                WorkspaceStatus(
                  label: context.tr('{p0} units', args: {'p0': store.cartCount}),
                  color: AppColors.textBody,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: lines.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 40,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('Your cart is empty'),
                            style: AppTypography.sectionHeader,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('Select a product to start a sale.'),
                            style: AppTypography.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: lines.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (_, index) {
                      final line = lines.values.elementAt(index);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.product.name,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr(
                              'TSh {p0} each',
                              args: {'p0': formatCurrency(line.product.priceValue)},
                            ),
                            style: AppTypography.label,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                tooltip: context.tr(
                                  'Remove one {p0}',
                                  args: {'p0': line.product.name},
                                ),
                                onPressed: () =>
                                    store.removeSingleFromCart(line.product),
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  size: 22,
                                ),
                              ),
                              Text(
                                '${line.quantity}',
                                style: AppTypography.bodyMedium,
                              ),
                              IconButton(
                                tooltip: context.tr(
                                  'Add one {p0}',
                                  args: {'p0': line.product.name},
                                ),
                                onPressed: line.quantity <
                                        store.availableStockForProduct(line.product)
                                    ? () => store.addToCart(line.product)
                                    : null,
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.tr(
                                    'TSh {p0}',
                                    args: {'p0': formatCurrency(line.totalPrice)},
                                  ),
                                  textAlign: TextAlign.right,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: checkout,
          ),
        ],
      ),
    );
  }
}
