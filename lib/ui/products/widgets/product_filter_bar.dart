import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../widgets/app_design.dart';
import '../../widgets/common/market_search_field.dart';

class ProductFilterBar extends StatelessWidget {
  const ProductFilterBar({
    super.key,
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.selectedStockFilter,
    required this.hasFilters,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onCategoryChanged,
    required this.onStockFilterChanged,
    required this.onResetFilters,
  });

  final TextEditingController searchController;
  final List<String> categories;
  final String? selectedCategory;
  final String selectedStockFilter;
  final bool hasFilters;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchClear;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onStockFilterChanged;
  final VoidCallback onResetFilters;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: MarketSearchField(
            controller: searchController,
            hintText: context.tr('Search by name, code or barcode'),
            onChanged: onSearchChanged,
            onClear: onSearchClear,
            height: 48,
            radius: AppRadius.input,
            backgroundColor: AppColors.surface,
            borderColor: AppColors.border,
            paddingHorizontal: 14,
          ),
        ),
        if (hasFilters) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onResetFilters,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDeep,
              minimumSize: const Size(44, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(
              context.tr('Reset'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}
