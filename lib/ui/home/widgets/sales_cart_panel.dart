import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../../service/pos_local_store.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/quantity_formatter.dart';
import '../../models/product_item.dart';
import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';
import 'measurement_sale_sheet.dart';
import 'product_card.dart';

class SalesCartPanel extends StatelessWidget {
  const SalesCartPanel({super.key, required this.checkout});
  final Widget checkout;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lines = <String, OrderLineItem>{};
    for (final item in store.cartItems) {
      final key =
          '${productKey(item)}|${item.customPrice?.toStringAsFixed(4) ?? ''}';
      if (lines.containsKey(key)) {
        lines[key]!.quantity =
            roundQuantity(lines[key]!.quantity + item.quantity);
      } else {
        lines[key] = OrderLineItem(
          product: item,
          quantity: item.quantity,
          customPrice: item.customPrice,
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border, width: 1),
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
                const Icon(
                  Icons.shopping_bag_outlined,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr('Current sale'),
                    style: AppTypography.sectionHeader,
                  ),
                ),
                WorkspaceStatus(
                  label: context.tr('{p0} units', args: {'p0': store.cartCount}),
                  color: AppColors.primaryDeep,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
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
                            size: 32,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.tr('Your cart is empty'),
                            style: AppTypography.sectionHeader,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr('Select a product to start a sale.'),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
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
                      final unit = line.product.unit.trim().isEmpty
                          ? 'Pcs'
                          : line.product.unit.trim();
                      final isMeasured = line.product.allowFractional ||
                          unit.toLowerCase() != 'pcs';
                      final step = stepForUnit(unit, line.product.allowFractional);
                      final totalInCart =
                          store.cartQuantityForProduct(line.product);
                      final available =
                          store.availableStockForProduct(line.product);
                      final canAddStep =
                          roundQuantity(totalInCart + step) <=
                              available + 0.0001;
                      final qtyText = formatQtyForReceipt(line.quantity, unit);
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
                            isMeasured
                                ? 'TSh ${formatCurrency(line.unitPrice)} / $unit'
                                : context.tr(
                                    'TSh {p0} each',
                                    args: {'p0': formatCurrency(line.unitPrice)},
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
                                onPressed: () => store.removeQuantityFromCart(
                                  line.product,
                                  step,
                                  customPrice: line.customPrice,
                                ),
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  size: 22,
                                ),
                              ),
                              InkWell(
                                onTap: line.product.allowFractional
                                    ? () async {
                                        final maxForLine = roundQuantity(
                                          (available -
                                                  (totalInCart - line.quantity))
                                              .clamp(0.0, 1e12)
                                              .toDouble(),
                                        );
                                        if (maxForLine <= 0) return;
                                        final updated =
                                            await MeasurementSaleSheet.show(
                                          context,
                                          product: line.product,
                                          availableStock: maxForLine,
                                          initialQuantity: line.quantity,
                                          initialCustomPrice: line.customPrice,
                                        );
                                        if (updated == null) return;
                                        store.setCartItemQuantity(
                                          line.product,
                                          updated.quantity,
                                          customPrice: updated.customPrice,
                                          matchCustomPrice: line.customPrice,
                                        );
                                      }
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    qtyText,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      decoration: line.product.allowFractional
                                          ? TextDecoration.underline
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: context.tr(
                                  'Add one {p0}',
                                  args: {'p0': line.product.name},
                                ),
                                onPressed: canAddStep
                                    ? () => store.addToCartQuantity(
                                          line.product,
                                          step,
                                          customPrice: line.customPrice,
                                        )
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
