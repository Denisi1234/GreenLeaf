import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../../service/pos_local_store.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/quantity_formatter.dart';
import '../../models/product_item.dart';
import '../../widgets/app_design.dart';
import '../../widgets/app_image.dart';
import '../../widgets/product_art/product_art.dart';

String productKey(ProductItem product) => product.code?.isNotEmpty == true
    ? product.code!
    : '${product.name}|${product.size}|${product.price}|${product.type.name}';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTapDown,
  });

  final ProductItem product;
  final ValueChanged<TapDownDetails> onTapDown;

  String _money(double value, String? currency) {
    return formatMoney(value, currency);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final currency = store.profile.currency;
    final lowThreshold = store.storePreferences.lowStockThreshold;
    final inCart = store.cartQuantityForProduct(product);
    final remaining = roundQuantity(
      (store.availableStockForProduct(product) - inCart)
          .clamp(0.0, 1e12)
          .toDouble(),
    );
    final isOutOfStock = remaining <= 0 && inCart <= 0;
    final isLowStock = !isOutOfStock && remaining <= lowThreshold;
    final unit = product.unit.trim().isEmpty ? 'Pcs' : product.unit.trim();
    final isUnitMeasured =
        product.allowFractional || unit.toLowerCase() != 'pcs';
    TapDownDetails? tapDetails;

    final Color stockDotColor;
    final Color stockTextColor;
    final String stockLabel;
    if (isOutOfStock) {
      stockDotColor = AppColors.danger;
      stockTextColor = AppColors.danger;
      stockLabel = context.tr('Out of stock');
    } else if (remaining <= 0 && inCart > 0) {
      stockDotColor = AppColors.primaryDeep;
      stockTextColor = AppColors.primaryDeep;
      stockLabel = context.tr('All in cart');
    } else if (isLowStock) {
      stockDotColor = AppColors.warning;
      stockTextColor = AppColors.kpiAmber;
      stockLabel = unit.toLowerCase() != 'pcs'
          ? '${formatQuantity(remaining)} $unit'
          : '${formatQuantity(remaining)} Pcs';
    } else {
      stockDotColor = AppColors.success;
      stockTextColor = AppColors.textMain;
      stockLabel = unit.toLowerCase() != 'pcs'
          ? '${formatQuantity(remaining)} $unit'
          : '${formatQuantity(remaining)} Pcs';
    }

    final categoryText = (product.category?.trim().isNotEmpty ?? false)
        ? product.category!.trim()
        : (product.size.trim().isNotEmpty ? product.size.trim() : '');
    final sku = product.code?.trim() ?? '';
    final hasImage = product.imagePath != null && product.imagePath!.isNotEmpty;

    final cardBody = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Whole top section: Product image / artwork banner
        SizedBox(
          height: 98,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: AppColors.pageBackground,
                child: hasImage
                    ? Image(
                        image: appImageProvider(context, product.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: ProductArt(type: product.type),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: ProductArt(type: product.type),
                        ),
                      ),
              ),
              if (inCart > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUnitMeasured
                          ? '${formatQuantity(inCart)} $unit'
                          : '×${formatQuantity(inCart)}',
                      style: GoogleFonts.manrope(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        // Bottom section: Product details
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (categoryText.isNotEmpty)
                      Flexible(
                        child: Text(
                          categoryText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontSize: 11.5,
                            height: 1.15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    if (categoryText.isNotEmpty && sku.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 3.5,
                        height: 3.5,
                        decoration: const BoxDecoration(
                          color: AppColors.borderInput,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (sku.isNotEmpty)
                      Text(
                        sku,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 11.5,
                          height: 1.15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textLight,
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderLight,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('Selling Price'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 10.5,
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 1),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isUnitMeasured
                                  ? '${_money(product.priceValue, currency)} / $unit'
                                  : _money(product.priceValue, currency),
                              maxLines: 1,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.successDeep,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('In Stock'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontSize: 10.5,
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6.5,
                                height: 6.5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: stockDotColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  stockLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                    fontSize: 11.5,
                                    height: 1.15,
                                    fontWeight: FontWeight.w700,
                                    color: stockTextColor,
                                  ),
                                ),
                              ),
                            ],
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
    );

    return Semantics(
      button: true,
      enabled: remaining > 0,
      label: context.tr(
        '{p0}, {p1}, {p2} available',
        args: {
          'p0': product.name,
          'p1': _money(product.priceValue, currency),
          'p2': formatQuantity(remaining),
        },
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          border: Border.all(
            color: inCart > 0 ? AppColors.primary : AppColors.border,
            width: inCart > 0 ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: remaining > 0 ? (details) => tapDetails = details : null,
            onTap: remaining > 0
                ? () {
                    final box = context.findRenderObject() as RenderBox;
                    onTapDown(
                      tapDetails ??
                          TapDownDetails(
                            globalPosition:
                                box.localToGlobal(box.size.center(Offset.zero)),
                          ),
                    );
                  }
                : null,
            child:
                isOutOfStock ? Opacity(opacity: 0.56, child: cardBody) : cardBody,
          ),
        ),
      ),
    );
  }
}
