import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/quantity_formatter.dart';
import '../../models/product_item.dart';
import '../../widgets/app_design.dart';
import '../../widgets/common/product_thumbnail.dart';

String productKey(ProductItem product) => product.code?.isNotEmpty == true
    ? product.code!
    : '${product.name}|${product.size}|${product.price}|${product.type.name}';

enum ProductCardLayout { detailed, compact, list }

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTapDown,
    this.layout = ProductCardLayout.detailed,
  });

  final ProductItem product;
  final ValueChanged<TapDownDetails> onTapDown;
  final ProductCardLayout layout;

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
      stockTextColor = AppColors.dangerDeep;
      stockLabel = context.tr('Out of stock');
    } else if (remaining <= 0 && inCart > 0) {
      stockDotColor = AppColors.primary;
      stockTextColor = AppColors.primaryDeep;
      stockLabel = context.tr('All in cart');
    } else if (isLowStock) {
      stockDotColor = AppColors.warning;
      stockTextColor = AppColors.kpiAmber;
      stockLabel = '${formatQuantity(remaining)} $unit';
    } else {
      stockDotColor = AppColors.success;
      stockTextColor = AppColors.textMuted;
      stockLabel = '${formatQuantity(remaining)} $unit';
    }

    final price = isUnitMeasured
        ? '${_money(product.priceValue, currency)}/$unit'
        : _money(product.priceValue, currency);
    final compact = MediaQuery.sizeOf(context).width < 360;

    final cartBadge = AnimatedSwitcher(
      duration: AppDurations.fast,
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: inCart > 0
          ? Container(
              key: ValueKey('cart-badge-$inCart'),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: AppShadows.primary,
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
            )
          : const SizedBox.shrink(),
    );

    final stockIndicator = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: stockDotColor,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            stockLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 11.5,
              fontWeight:
                  isOutOfStock || isLowStock ? FontWeight.w700 : FontWeight.w600,
              color: stockTextColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );

    final Widget content;
    if (layout == ProductCardLayout.list) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProductThumbnail(
                  name: product.name,
                  imagePath: product.imagePath,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  stockIndicator,
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: GoogleFonts.manrope(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.successDeep,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (inCart > 0) ...[
                  const SizedBox(height: 4),
                  cartBadge,
                ],
              ],
            ),
          ],
        ),
      );
    } else if (layout == ProductCardLayout.compact) {
      content = Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (inCart > 0) ...[
                  const SizedBox(width: 6),
                  cartBadge,
                ],
              ],
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                price,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.successDeep,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 4),
            stockIndicator,
          ],
        ),
      );
    } else {
      // Clean Square / Shopify POS product tile: full-bleed photo, crisp name,
      // bold green price, and quiet stock dot — zero repetitive micro-labels.
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: compact ? 88 : 104,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductThumbnail(
                  name: product.name,
                  imagePath: product.imagePath,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: cartBadge,
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 10 : 12,
                compact ? 8 : 10,
                compact ? 10 : 12,
                compact ? 8 : 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: compact ? 13 : 14,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 6),
                  if (compact) ...[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        price,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.successDeep,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    stockIndicator,
                  ] else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              price,
                              maxLines: 1,
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.successDeep,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(child: stockIndicator),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

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
      child: AnimatedContainer(
        duration: AppDurations.fast,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          border: Border.all(
            color: inCart > 0 ? AppColors.primary : AppColors.border,
            width: inCart > 0 ? 1.8 : 1,
          ),
          boxShadow: inCart > 0
              ? AppShadows.primary
              : const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
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
                isOutOfStock ? Opacity(opacity: 0.56, child: content) : content,
          ),
        ),
      ),
    );
  }
}
