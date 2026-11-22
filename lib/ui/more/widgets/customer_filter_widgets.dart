import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import 'customer_models.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _formatMoney(double value) {
  return 'TSh ${value.toStringAsFixed(2)}';
}

class CustomerCreditBanner extends StatelessWidget {
  const CustomerCreditBanner({
    super.key,
    required this.amount,
    required this.count,
    required this.strings,
    required this.onTap,
  });

  final double amount;
  final int count;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warningLight,
      borderRadius: AppCorners.control,
      child: InkWell(
        borderRadius: AppCorners.control,
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: AppCorners.control,
            border:
                Border.all(color: AppColors.kpiAmber.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: AppColors.kpiAmber, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dual(strings, 'Outstanding customer credit',
                          'Madeni ya wateja'),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.kpiAmber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _dual(
                        strings,
                        '$count customer${count == 1 ? '' : 's'} · tap to open the ledger',
                        'wateja $count · gusa kufungua daftari',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.helperText.copyWith(
                        color: AppColors.kpiAmber,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatMoney(amount),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.kpiAmber,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.kpiAmber, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerFilterRow extends StatelessWidget {
  const CustomerFilterRow({
    super.key,
    required this.value,
    required this.strings,
    required this.onChanged,
  });

  final String value;
  final AppStrings strings;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = CustomerFilterOption.values;
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter.name == value;
          return GestureDetector(
            onTap: () => onChanged(filter.name),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: AppCorners.control,
              ),
              child: Text(
                filter.label(strings),
                style: AppTypography.helperText.copyWith(
                  color: selected ? Colors.white : AppColors.textBody,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CustomerSortCard extends StatelessWidget {
  const CustomerSortCard({
    super.key,
    required this.sort,
    required this.strings,
    required this.onPick,
    required this.activeFilters,
    required this.onClear,
  });

  final CustomerSortMode sort;
  final AppStrings strings;
  final VoidCallback onPick;
  final bool activeFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: false,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: AppCorners.control,
            ),
            child: Icon(sort.icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dual(strings, 'Sort order', 'Mpangilio'),
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sort.label(strings),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (activeFilters)
            IconButton(
              tooltip: _dual(strings, 'Clear filters', 'Ondoa vichujio'),
              onPressed: onClear,
              icon: Icon(Icons.filter_alt_off_rounded,
                  color: AppColors.textMuted, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          IconButton(
            tooltip: _dual(strings, 'Sort', 'Panga'),
            onPressed: onPick,
            icon: Icon(Icons.tune_rounded,
                color: AppColors.textMuted, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
