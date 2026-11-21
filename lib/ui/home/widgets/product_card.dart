import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:track_mauzo/l10n/app_localization.dart';

import '../../../service/pos_local_store.dart';
import '../../../utils/currency_formatter.dart';
import '../../models/product_item.dart';
import '../../widgets/app_design.dart';
import '../../widgets/app_image.dart';
import '../../widgets/workspace_widgets.dart';

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

  String _money(double value) {
    return 'TSh ${formatCurrency(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final inCart = store.cartItems
        .where((item) => productKey(item) == productKey(product))
        .length;
    final remaining =
        (store.availableStockForProduct(product) - inCart).clamp(0, 1 << 31);
    TapDownDetails? tapDetails;

    return Semantics(
      button: true,
      enabled: remaining > 0,
      label: context.tr(
        '{p0}, {p1}, {p2} available',
        args: {'p0': product.name, 'p1': _money(product.priceValue), 'p2': remaining},
      ),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.tile),
          side: BorderSide(
            color: inCart > 0 ? AppColors.primary : AppColors.border,
            width: inCart > 0 ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTapDown: remaining > 0 ? (details) => tapDetails = details : null,
          onTap: remaining > 0
              ? () {
                  final box = context.findRenderObject() as RenderBox;
                  onTapDown(
                    tapDetails ??
                        TapDownDetails(
                          globalPosition: box.localToGlobal(box.size.center(Offset.zero)),
                        ),
                  );
                }
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 104,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.headerSurface,
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: DashboardTileArt(product: product)),
                      if (remaining <= 5)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: remaining == 0 && inCart == 0
                                  ? AppColors.kpiDangerBg
                                  : AppColors.kpiAmberBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: remaining == 0 && inCart == 0
                                    ? AppColors.kpiDanger.withValues(alpha: 0.35)
                                    : AppColors.kpiAmber.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              remaining == 0
                                  ? (inCart > 0 ? context.tr('All in cart') : context.tr('Out of stock'))
                                  : context.tr('{p0} left', args: {'p0': remaining}),
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: remaining == 0 && inCart == 0
                                    ? AppColors.kpiDanger
                                    : AppColors.kpiAmber,
                              ),
                            ),
                          ),
                        ),
                      if (inCart > 0)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              context.tr('{p0} in cart', args: {'p0': inCart}),
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (product.size.isNotEmpty)
                        Text(
                          product.size,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label,
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _money(product.priceValue),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primaryDeep,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: remaining > 0 ? AppColors.primary : AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.circular(AppRadius.standard),
                            ),
                            child: Icon(
                              remaining > 0 ? Icons.add_rounded : Icons.remove_rounded,
                              color: remaining > 0 ? Colors.white : AppColors.textMuted,
                              size: 20,
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
    );
  }
}

class DashboardTileArt extends StatelessWidget {
  const DashboardTileArt({super.key, required this.product});
  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      return Image(
        image: appImageProvider(context, product.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => DashboardFallbackArt(label: product.name),
      );
    }
    return DashboardFallbackArt(label: product.name);
  }
}

class DashboardFallbackArt extends StatelessWidget {
  const DashboardFallbackArt({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final initials = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();

    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.borderLight),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: GoogleFonts.manrope(
            color: AppColors.textMuted,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
