import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../../service/pos_local_store.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/quantity_formatter.dart';
import '../../models/product_item.dart';
import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';
import '../../widgets/common/market_confirm_dialog.dart';
import '../../widgets/common/market_notice.dart';
import 'cart_quantity_dialog.dart';
import 'measurement_sale_sheet.dart';
import 'product_card.dart';

class SalesCartPanel extends StatefulWidget {
  const SalesCartPanel({super.key, required this.checkout});
  final Widget checkout;

  @override
  State<SalesCartPanel> createState() => _SalesCartPanelState();
}

class _SalesCartPanelState extends State<SalesCartPanel> {
  bool _clearing = false;
  bool _editing = false;

  Future<void> _clearSale() async {
    if (_clearing) return;
    final store = context.read<PosLocalStore>();
    if (store.cartItems.isEmpty) return;
    setState(() => _clearing = true);
    try {
      final confirmed = await showMarketConfirmDialog(context,
          title: context.tr('Clear current sale?'),
          message: context.tr('Remove every item from the current sale?'),
          confirmLabel: context.tr('Clear sale'),
          cancelLabel: context.tr('Keep sale'),
          isDestructive: true,
          icon: Icons.remove_shopping_cart_outlined);
      if (!confirmed || !mounted) return;
      await store.clearCart();
    } catch (_) {
      if (mounted) {
        showMarketNotice(context,
            title: context.tr('Could not clear sale'),
            message: context.tr('Please try again.'),
            type: MarketNoticeType.error);
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _editQuantity(OrderLineItem line) async {
    if (_editing || _clearing) return;
    _editing = true;
    try {
      final store = context.read<PosLocalStore>();
      final available = roundQuantity(
          (store.availableStockForProduct(line.product) -
                  (store.cartQuantityForProduct(line.product) - line.quantity))
              .clamp(0.0, 1e12)
              .toDouble());
      if (available <= 0) return;
      double? quantity;
      double? price = line.customPrice;
      if (line.product.allowFractional) {
        final result = await MeasurementSaleSheet.show(context,
            product: line.product,
            availableStock: available,
            initialQuantity: line.quantity,
            initialCustomPrice: line.customPrice);
        quantity = result?.quantity;
        price = result?.customPrice;
      } else {
        quantity = await CartQuantityDialog.show(context,
            productName: line.product.name,
            quantity: line.quantity,
            available: available);
      }
      if (quantity == null || !mounted) return;
      final updated = store.setCartItemQuantity(line.product, quantity,
          customPrice: price, matchCustomPrice: line.customPrice);
      if (!updated && mounted) {
        showMarketNotice(context,
            title: context.tr('Stock changed'),
            message: context.tr('Review the available quantity and try again.'),
            type: MarketNoticeType.warning);
      }
    } finally {
      _editing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final currency = store.profile.currency;
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
                Icon(
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
                if (lines.isNotEmpty)
                  IconButton(
                    tooltip: context.tr('Clear sale'),
                    onPressed: _clearing ? null : _clearSale,
                    color: AppColors.dangerDeep,
                    icon: const Icon(Icons.remove_shopping_cart_outlined,
                        size: 20),
                  ),
                WorkspaceStatus(
                  label:
                      context.tr('{p0} units', args: {'p0': store.cartCount}),
                  color: AppColors.primaryDeep,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Expanded(
            child: lines.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
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
                      final step =
                          stepForUnit(unit, line.product.allowFractional);
                      final totalInCart =
                          store.cartQuantityForProduct(line.product);
                      final available =
                          store.availableStockForProduct(line.product);
                      final canAddStep = roundQuantity(totalInCart + step) <=
                          available + 0.0001;
                      final qtyText = formatQtyForReceipt(line.quantity, unit);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(line.product.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700))),
                            IconButton(
                                tooltip: context.tr('Remove item'),
                                onPressed: _clearing
                                    ? null
                                    : () => store.setCartItemQuantity(
                                        line.product, 0,
                                        matchCustomPrice: line.customPrice),
                                color: AppColors.dangerDeep,
                                icon:
                                    const Icon(Icons.close_rounded, size: 18)),
                          ]),
                          const SizedBox(height: 6),
                          Text(
                            isMeasured
                                ? '${formatMoney(line.unitPrice, currency)} / $unit'
                                : context.tr(
                                    '{p0} each',
                                    args: {
                                      'p0':
                                          formatMoney(line.unitPrice, currency)
                                    },
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
                              Tooltip(
                                message: context.tr('Edit quantity'),
                                child: TextButton(
                                  onPressed: () => _editQuantity(line),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(44, 44),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    backgroundColor: AppColors.surfaceSecondary,
                                  ),
                                  child: Text(qtyText,
                                      style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w700)),
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
                                  formatMoney(line.totalPrice, currency),
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
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (lines.isNotEmpty) ...[
                Row(children: [
                  Expanded(
                      child: Text(context.tr('Subtotal'),
                          style: AppTypography.bodySmall)),
                  Flexible(
                      child: Text(formatMoney(store.cartTotal, currency),
                          textAlign: TextAlign.end,
                          style: AppTypography.bodyMedium
                              .copyWith(fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 12),
              ],
              widget.checkout,
            ]),
          ),
        ],
      ),
    );
  }
}
