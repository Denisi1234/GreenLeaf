import 'package:track_mauzo/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import '../../widgets/workspace_widgets.dart';

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
    return WorkspacePanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarketSearchField(
            controller: searchController,
            hintText: context.tr('Search by name, code or barcode'),
            onChanged: onSearchChanged,
            onClear: onSearchClear,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('category-$selectedCategory'),
                  initialValue: categories.contains(selectedCategory)
                      ? selectedCategory
                      : null,
                  isExpanded: true,
                  decoration:  InputDecoration(
                    labelText: context.tr('Category'),
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                     DropdownMenuItem<String>(
                      value: null,
                      child: Text(context.tr('All categories'),
                          overflow: TextOverflow.ellipsis),
                    ),
                    ...categories.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: onCategoryChanged,
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('stock-$selectedStockFilter'),
                  isExpanded: true,
                  initialValue: selectedStockFilter,
                  decoration:  InputDecoration(
                    labelText: context.tr('Stock status'),
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items:  [
                    DropdownMenuItem(
                      value: 'all',
                      child:
                          Text(context.tr('All stock'), overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'low',
                      child:
                          Text(context.tr('Low stock'), overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: 'out',
                      child: Text(context.tr('Out of stock'),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  onChanged: onStockFilterChanged,
                ),
              ),
              if (hasFilters)
                TextButton.icon(
                  onPressed: onResetFilters,
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.dangerDeep),
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label:  Text(context.tr('Clear filters')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
