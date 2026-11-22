import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/currency_formatter.dart';
import '../../../utils/quantity_formatter.dart';
import '../../notifications/notifications_page.dart';
import '../../widgets/app_design.dart';
import '../../widgets/common/product_thumbnail.dart';
import '../../widgets/market_shared_widgets.dart';
import '../inventory_product_item.dart';

String formatProductPrice(double value) {
  return 'Sh ${formatCurrency(value)}';
}

class ProductItemRowCard extends StatelessWidget {
  const ProductItemRowCard({
    super.key,
    required this.product,
    this.lowStockThreshold = 5,
    this.onTap,
    this.onAdjustStock,
    this.onDelete,
  });

  final InventoryProductItem product;
  final int lowStockThreshold;
  final VoidCallback? onTap;
  final VoidCallback? onAdjustStock;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isLowStock =
        product.stockCount <= lowStockThreshold && product.stockCount > 0;
    final isOutOfStock = product.stockCount <= 0;
    final isSwahili = context.strings.isSwahili;
    final isMeasured =
        product.allowFractional || product.unit.toLowerCase() != 'pcs';
    final packEquiv = formatPackEquivalent(
      product.stockCount,
      product.unit,
      packName: product.packName,
      packSize: product.packSize,
    );
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          child: Padding(
            padding: EdgeInsets.fromLTRB(8, 8, compact ? 10 : 16, 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: compact ? 68 : 88,
                    constraints: const BoxConstraints(minHeight: 82),
                    decoration: BoxDecoration(
                      color: AppColors.pageBackground,
                      borderRadius: BorderRadius.circular(AppRadius.sharp),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ProductThumbnail(
                        name: product.name, imagePath: product.imagePath),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ),
                              if (onTap != null ||
                                  onAdjustStock != null ||
                                  onDelete != null)
                                PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'edit') onTap?.call();
                                    if (val == 'adjust') onAdjustStock?.call();
                                    if (val == 'delete') onDelete?.call();
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    Icons.more_horiz_rounded,
                                    color: AppColors.textLight,
                                    size: 20,
                                  ),
                                  itemBuilder: (context) => [
                                    if (onTap != null)
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined,
                                                size: 18,
                                                color: AppColors.primaryDeep),
                                            const SizedBox(width: 8),
                                            Text(
                                              context.tr('Edit Item'),
                                              style: GoogleFonts.manrope(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (onAdjustStock != null)
                                      PopupMenuItem(
                                        value: 'adjust',
                                        child: Row(
                                          children: [
                                            Icon(Icons.tune_rounded,
                                                size: 18,
                                                color: AppColors.primaryDeep),
                                            const SizedBox(width: 8),
                                            Text(
                                              isSwahili
                                                  ? 'Rekebisha stoo'
                                                  : 'Adjust stock',
                                              style: GoogleFonts.manrope(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (onDelete != null)
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(
                                                Icons.delete_outline_rounded,
                                                size: 18,
                                                color: AppColors.danger),
                                            const SizedBox(width: 8),
                                            Text(
                                              context.tr('Delete'),
                                              style: GoogleFonts.manrope(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.danger,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  product.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.borderInput,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  context.tr('Code: {p0}',
                                      args: {'p0': product.code}),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr('Selling Price'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        isMeasured
                                            ? '${formatProductPrice(product.sellingPrice)} / ${product.unit}'
                                            : formatProductPrice(
                                                product.sellingPrice),
                                        maxLines: 1,
                                        style: GoogleFonts.manrope(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.successDeep,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      context.tr('In Stock'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 7,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isOutOfStock
                                                ? AppColors.danger
                                                : isLowStock
                                                    ? AppColors.warning
                                                    : AppColors.success,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: Text(
                                            isOutOfStock
                                                ? context.tr('Out of stock')
                                                : formatStockWithUnit(
                                                    product.stockCount,
                                                    product.unit),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.manrope(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: isOutOfStock
                                                  ? AppColors.danger
                                                  : isLowStock
                                                      ? AppColors.kpiAmber
                                                      : AppColors.textMain,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (packEquiv != null)
                                      Text(
                                        '≈ $packEquiv',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductEmptyState extends StatelessWidget {
  const ProductEmptyState({
    super.key,
    required this.query,
    this.onAddTap,
    required this.onClearFilter,
  });

  final String query;
  final VoidCallback? onAddTap;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final hasFilter = query.isNotEmpty;
    return MarketEmptyState(
      showCard: false,
      icon: hasFilter ? Icons.search_off_rounded : Icons.inventory_2_outlined,
      title: hasFilter
          ? context.tr('No items match your search')
          : context.tr('No items found in stock'),
      message: hasFilter
          ? context.tr('Try searching with a different name or item code.')
          : context.tr('Use Add item to register your first product.'),
      actionLabel: hasFilter
          ? context.tr('Clear Search')
          : (onAddTap != null ? context.tr('Add item') : null),
      actionIcon: hasFilter
          ? Icons.filter_alt_off_rounded
          : (onAddTap != null ? Icons.add_rounded : null),
      onAction: hasFilter ? onClearFilter : onAddTap,
    );
  }
}

class ProductsHeader extends StatelessWidget {
  const ProductsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketPageHeader(
      title: context.tr('Items'),
      showBackButton: false,
      centerTitle: false,
      showBorder: false,
      titleSize: 22,
      titleWeight: FontWeight.w800,
      actions: [
        MarketHeaderActionButtons(
          notificationBackground: AppColors.pageBackground,
          notificationBorderColor: AppColors.border,
          showNotificationDot: true,
          onNotificationTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const NotificationsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}
