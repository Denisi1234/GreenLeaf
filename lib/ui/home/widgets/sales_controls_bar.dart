import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../../utils/currency_formatter.dart';
import '../../widgets/app_design.dart';
import '../../widgets/common/market_search_field.dart';

class CheckoutBar extends StatelessWidget {
  const CheckoutBar({
    super.key,
    required this.cartKey,
    required this.itemCount,
    required this.total,
    required this.onCheckout,
    required this.label,
    this.onViewCart,
    this.currency,
    this.accentColor,
  });

  final GlobalKey cartKey;
  final int itemCount;
  final double total;
  final VoidCallback onCheckout;
  final VoidCallback? onViewCart;
  final String label;
  final String? currency;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final active = itemCount > 0;
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Row(
      children: [
        if (onViewCart != null && active) ...[
          Material(
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              side: BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onViewCart,
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: SizedBox(
                width: compact ? 48 : 56,
                height: compact ? 50 : 56,
                child: Tooltip(
                  message: context.tr('Current sale'),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.primaryDeep,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
        ],
        Expanded(
          child: Semantics(
            button: true,
            enabled: active,
            child: Material(
              color: active ? (accentColor ?? AppColors.primary) : AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
                side: active
                    ? BorderSide.none
                    : BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: active ? onCheckout : null,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 14 : 20,
                    vertical: compact ? 11 : 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        key: cartKey,
                        color: active ? Colors.white : AppColors.textMuted,
                        size: compact ? 20 : 24,
                      ),
                      SizedBox(width: compact ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              active
                                  ? label
                                  : context.tr('Select products to start'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color:
                                    active ? Colors.white : AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${context.tr('{p0} units', args: {
                                    'p0': itemCount
                                  })} • ${formatMoney(total, currency)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall.copyWith(
                                color:
                                    active ? Colors.white : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: active ? Colors.white : AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onSubmitted,
    this.onScanTap,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onScanTap;

  @override
  Widget build(BuildContext context) {
    return MarketSearchField(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onClear: () {
        controller.clear();
        onChanged('');
      },
      onScanTap: onScanTap,
      height: 48,
      radius: AppRadius.input,
      backgroundColor: AppColors.surface,
      borderColor: AppColors.border,
      paddingHorizontal: 14,
    );
  }
}

class SalesCategoryStrip extends StatelessWidget {
  const SalesCategoryStrip({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category == selectedCategory;
          return ChoiceChip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            label: Text(index == 0 ? context.tr('All') : category),
            selected: selected,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
            ),
            labelStyle: AppTypography.bodySmall.copyWith(
              color: selected ? Colors.white : AppColors.textBody,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          );
        },
      ),
    );
  }
}
