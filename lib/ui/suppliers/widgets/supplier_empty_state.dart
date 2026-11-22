import 'package:flutter/material.dart';

import '../../widgets/market_shared_widgets.dart';

/// Clean, professional centered empty state for supplier and receiving screens.
/// Features a centered layout with an icon, informative headline, contextual helper text,
/// and primary action button, styled according to the sharp flat design system (radius: 0).
class SupplierEmptyState extends StatelessWidget {
  const SupplierEmptyState({
    super.key,
    required this.isSwahili,
    this.isFiltered = false,
    required this.onAddSupplier,
    this.onClearFilter,
  });

  final bool isSwahili;
  final bool isFiltered;
  final VoidCallback onAddSupplier;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    String t(String en, String sw) => isSwahili ? sw : en;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: MarketEmptyState(
          icon: isFiltered
              ? Icons.search_off_rounded
              : Icons.local_shipping_outlined,
          title: isFiltered
              ? t('No suppliers match your search',
                  'Hakuna msambazaji aliyepatikana')
              : t('No suppliers yet', 'Hakuna wasambazaji bado'),
          message: isFiltered
              ? t(
                  'Check the spelling or try searching by phone number, email address, or city.',
                  'Kagua tahajia au jaribu kutafuta kwa namba ya simu, barua pepe, au eneo.',
                )
              : t(
                  'Add suppliers to purchase stock on cash or credit, track outstanding payables, and manage deliveries.',
                  'Ongeza wasambazaji kurekodi ununuzi wa pesa taslimu au mikopo, kusimamia madeni, na kufuatilia bidhaa zinazoingia.',
                ),
          actionLabel: isFiltered
              ? t('Clear search', 'Ondoa utafutaji')
              : t('Add supplier', 'Ongeza msambazaji'),
          actionIcon:
              isFiltered ? Icons.filter_alt_off_rounded : Icons.add_rounded,
          onAction: isFiltered ? onClearFilter : onAddSupplier,
        ),
      ),
    );
  }
}
