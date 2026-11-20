import 'package:flutter/material.dart';
import 'package:track_mauzo/l10n/app_localization.dart';

import '../../../utils/currency_formatter.dart';
import '../../widgets/app_design.dart';

class CheckoutBar extends StatelessWidget {
  const CheckoutBar({
    super.key,
    required this.cartKey,
    required this.itemCount,
    required this.total,
    required this.onCheckout,
    required this.label,
    this.accentColor = const Color(0xFF0F172A),
  });

  final GlobalKey cartKey;
  final int itemCount;
  final double total;
  final VoidCallback onCheckout;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: itemCount > 0,
        child: Material(
          color: itemCount > 0 ? accentColor : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: itemCount > 0 ? onCheckout : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    key: cartKey,
                    color: itemCount > 0 ? Colors.white : AppColors.textMuted,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemCount > 0
                              ? label
                              : context.tr('Select products to start'),
                          style: AppTypography.bodySmall.copyWith(
                            color: itemCount > 0
                                ? Colors.white
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr(
                            '{p0} units • TSh {p1}',
                            args: {
                              'p0': itemCount,
                              'p1': formatCurrency(total),
                            },
                          ),
                          style: AppTypography.bodySmall.copyWith(
                            color: itemCount > 0
                                ? Colors.white
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: itemCount > 0 ? Colors.white : AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onScanTap,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onScanTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : onScanTap != null
                ? IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                    onPressed: onScanTap,
                  )
                : null,
      ),
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
      height: 44,
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
            label: Text(index == 0 ? context.tr('All') : category),
            selected: selected,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            selectedColor: AppColors.ink,
            backgroundColor: AppColors.surfaceSecondary,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            side: BorderSide.none,
            labelStyle: AppTypography.bodySmall.copyWith(
              color: selected ? Colors.white : AppColors.textBody,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          );
        },
      ),
    );
  }
}
