import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(
                  isFiltered
                      ? Icons.search_off_rounded
                      : Icons.local_shipping_outlined,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isFiltered
                    ? t('No suppliers match your search', 'Hakuna msambazaji aliyepatikana')
                    : t('No suppliers yet', 'Hakuna wasambazaji bado'),
                textAlign: TextAlign.center,
                style: AppTypography.cardHeader.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFiltered
                    ? t(
                        'Check the spelling or try searching by phone number, email address, or city.',
                        'Kagua tahajia au jaribu kutafuta kwa namba ya simu, barua pepe, au eneo.',
                      )
                    : t(
                        'Add suppliers to purchase stock on cash or credit, track outstanding payables, and manage deliveries.',
                        'Ongeza wasambazaji kurekodi ununuzi wa pesa taslimu au mikopo, kusimamia madeni, na kufuatilia bidhaa zinazoingia.',
                      ),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (isFiltered)
                MarketButton(
                  label: t('Clear search', 'Ondoa utafutaji'),
                  icon: Icons.filter_alt_off_rounded,
                  isFullWidth: false,
                  isPrimary: false,
                  onTap: onClearFilter,
                )
              else
                MarketButton(
                  label: t('Add supplier', 'Ongeza msambazaji'),
                  icon: Icons.add_rounded,
                  isFullWidth: false,
                  onTap: onAddSupplier,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
