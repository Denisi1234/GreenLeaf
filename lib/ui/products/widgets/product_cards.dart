import 'package:track_mauzo/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../utils/currency_formatter.dart';
import '../../notifications/notifications_page.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import '../inventory_product_item.dart';

String formatProductPrice(double value) {
  return 'Sh ${formatCurrency(value)}';
}

class ProductItemRowCard extends StatelessWidget {
  const ProductItemRowCard({
    super.key,
    required this.product,
    this.onTap,
    this.onDelete,
  });

  final InventoryProductItem product;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stockCount <= 5 && product.stockCount > 0;
    final isOutOfStock = product.stockCount <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    if (onTap != null || onDelete != null)
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'edit') onTap?.call();
                          if (val == 'delete') onDelete?.call();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        itemBuilder: (context) => [
                          if (onTap != null)
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined,
                                      size: 18, color: AppColors.primaryDeep),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.tr('Edit Item'),
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
                                  const Icon(Icons.delete_outline_rounded,
                                      size: 18, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 8),
                                  Text(
                                    context.tr('Delete'),
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFEF4444),
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
                    Text(
                      product.category,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.tr('Code: {p0}', args: {'p0': product.code}),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Selling Price'),
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatProductPrice(product.sellingPrice),
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          context.tr('In Stock'),
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
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
                                    ? const Color(0xFFEF4444)
                                    : isLowStock
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isOutOfStock
                                  ? context.tr('Out of stock')
                                  : '${product.stockCount} ${product.unit}',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isOutOfStock
                                    ? const Color(0xFFEF4444)
                                    : isLowStock
                                        ? const Color(0xFFB45309)
                                        : AppColors.textMain,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
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
    required this.onAddTap,
    required this.onClearFilter,
  });

  final String query;
  final VoidCallback onAddTap;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    final hasFilter = query.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.zero,
              color: const Color(0xFFE2E8F0),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 32,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter
                ? context.tr('No items match your search')
                : context.tr('No items found in stock'),
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasFilter
                ? context.tr('Try searching with a different name or item code.')
                : context.tr('Use Add item to register your first product.'),
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          if (hasFilter)
            OutlinedButton(
              onPressed: onClearFilter,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.dangerDeep,
                side: const BorderSide(color: AppColors.dangerBorder),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                context.tr('Clear Search'),
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
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
          notificationBackground: const Color(0xFFF8FAFC),
          notificationBorderColor: const Color(0xFFE5EAF0),
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
