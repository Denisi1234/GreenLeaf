import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import 'expense_models.dart';

class ExpenseTaxBanner extends StatelessWidget {
  const ExpenseTaxBanner({super.key, required this.amount, required this.strings});

  final double amount;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.percent_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              expenseDual(strings, 'Tax / VAT collected', 'Kodi / VAT iliyokusanywa'),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            formatExpenseMoney(amount),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseRangeCard extends StatelessWidget {
  const ExpenseRangeCard({
    super.key,
    required this.label,
    required this.sortLabel,
    required this.sortIcon,
    required this.onPickRange,
    required this.onCustomRange,
    required this.onPickSort,
    required this.strings,
  });

  final String label;
  final String sortLabel;
  final IconData sortIcon;
  final VoidCallback onPickRange;
  final VoidCallback onCustomRange;
  final VoidCallback onPickSort;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: AppColors.border,
      radius: 0,
      showShadow: false,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.zero,
            ),
            child: const Icon(Icons.date_range_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expenseDual(strings, 'Period', 'Kipindi'),
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
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
          IconButton(
            tooltip: expenseDual(strings, 'Pick period', 'Chagua kipindi'),
            onPressed: onPickRange,
            icon: const Icon(Icons.tune_rounded,
                color: AppColors.textMuted, size: 20),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: expenseDual(strings, 'Custom range', 'Kipindi maalum'),
            onPressed: onCustomRange,
            icon: const Icon(Icons.event_rounded,
                color: AppColors.textMuted, size: 20),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class ExpensePaymentFilterRow extends StatelessWidget {
  const ExpensePaymentFilterRow({
    super.key,
    required this.payments,
    required this.value,
    required this.onChanged,
    required this.strings,
  });

  final List<String> payments;
  final String value;
  final ValueChanged<String> onChanged;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final current = payments.contains(value) ? value : 'All';
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined,
              size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            expenseDual(strings, 'Payment', 'Malipo'),
            style: AppTypography.helperText.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: current,
                isExpanded: true,
                isDense: true,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w700,
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted, size: 20),
                items: payments
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            p == 'All' ? expenseDual(strings, 'All', 'Zote') : p,
                            style: AppTypography.bodySmall,
                          ),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpensePaymentSummaryCard extends StatelessWidget {
  const ExpensePaymentSummaryCard({
    super.key,
    required this.items,
    required this.strings,
  });

  final List<MapEntry<String, double>> items;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final grand = items.fold<double>(0, (s, e) => s + e.value);
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.border,
      radius: 0,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            expenseDual(strings, 'Payment breakdown', 'Mgawanyo wa malipo'),
            style: AppTypography.cardHeader,
          ),
          const SizedBox(height: 12),
          ...items.map((e) {
            final pct = grand <= 0 ? 0.0 : (e.value / grand);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.key,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        formatExpenseMoney(e.value, compact: true),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(pct * 100).toStringAsFixed(0)}%',
                        style: AppTypography.helperText.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.zero,
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceHover,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
