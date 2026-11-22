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
    return MarketSearchField(
      controller: searchController,
      hintText: context.tr('Search by name, code or barcode'),
      onChanged: onSearchChanged,
      onClear: onSearchClear,
      height: 48,
      radius: 0,
      backgroundColor: AppColors.surface,
      borderColor: AppColors.border,
      paddingHorizontal: 14,
    );
  }
}
