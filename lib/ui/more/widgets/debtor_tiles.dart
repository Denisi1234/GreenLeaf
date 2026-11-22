import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/debit_entry_model.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _money(double value, {bool compact = false}) {
  final formatted = compact
      ? NumberFormat.compact().format(value)
      : NumberFormat('#,##0.00').format(value);
  return 'TSh $formatted';
}

class LedgerTile extends StatelessWidget {
  const LedgerTile({super.key, required this.entry, required this.strings});

  final DebitEntry entry;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final isPayment = entry.isPayment;
    final color = isPayment ? AppColors.success : AppColors.ink;
    final background =
        isPayment ? AppColors.successLight : AppColors.surfaceSecondary;

    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderColor: AppColors.border,
      radius: AppRadius.input,
      showShadow: false,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppCorners.control,
            ),
            child: Icon(
              isPayment ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.customerName} · ${entry.type.localized(strings.isSwahili)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    DateFormat('MMM d, yyyy').format(entry.createdAt),
                    if (entry.note.trim().isNotEmpty) entry.note.trim(),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${isPayment ? '-' : '+'}${_money(entry.amount, compact: true)}',
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyDebtors extends StatelessWidget {
  const EmptyDebtors({
    super.key,
    required this.strings,
    required this.filtered,
    required this.onReset,
  });

  final AppStrings strings;
  final bool filtered;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return MarketEmptyState(
      icon: filtered ? Icons.search_off_rounded : Icons.verified_rounded,
      iconColor: filtered ? AppColors.primary : AppColors.success,
      iconBackgroundColor:
          filtered ? AppColors.surfaceSecondary : AppColors.successLight,
      title: filtered
          ? _dual(strings, 'No matching debtors', 'Hakuna wadaiwa')
          : _dual(strings, 'No debts recorded', 'Hakuna madeni'),
      message: filtered
          ? _dual(strings, 'Try another name or phone number.',
              'Jaribu jina au namba nyingine.')
          : _dual(
              strings,
              'Credit sales from the counter appear here with full statements.',
              'Mauzo ya mkopo kutoka kaunta yanaonekana hapa na taarifa kamili.',
            ),
      actionLabel:
          filtered ? _dual(strings, 'Clear search', 'Ondoa utafutaji') : null,
      actionIcon: filtered ? Icons.filter_alt_off_rounded : null,
      onAction: filtered ? onReset : null,
    );
  }
}
