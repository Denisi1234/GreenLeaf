import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _money(double value) => 'TSh ${NumberFormat('#,##0.00').format(value)}';

/// Confirms that the running sale is taken on credit for [customerName].
class RecordDebitBottomSheet extends StatelessWidget {
  const RecordDebitBottomSheet({
    super.key,
    required this.customerName,
    required this.total,
    required this.currentBalance,
  });

  final String customerName;
  final double total;
  final double currentBalance;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context.watch<PosLocalStore>().languageCode);
    final newBalance = currentBalance + total;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.zero,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.zero,
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.ink, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dual(strings, 'Record debit sale',
                          'Rekodi mauzo ya mkopo'),
                      style: AppTypography.cardHeader,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RowLine(
                  label: _dual(strings, 'Sale total', 'Jumla ya mauzo'),
                  value: _money(total),
                  strong: true,
                ),
                _RowLine(
                  label: _dual(strings, 'Current balance', 'Deni la sasa'),
                  value: _money(currentBalance),
                ),
                const Divider(
                    height: 14, thickness: 1, color: AppColors.divider),
                _RowLine(
                  label: _dual(
                      strings, 'Balance after sale', 'Deni baada ya mauzo'),
                  value: _money(newBalance),
                  strong: true,
                  color: AppColors.ink,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _dual(
              strings,
              'This amount is added to the customer debit ledger and can be settled from Customers, Debit & Credit.',
              'Kiasi hiki kinaongezwa kwenye daftari la deni la mteja na linaweza kulipwa kupitia Wateja, Madeni na Malipo.',
            ),
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.zero,
            child: InkWell(
              borderRadius: BorderRadius.zero,
              highlightColor: Colors.transparent,
              splashColor: AppColors.primaryDeep.withValues(alpha: 0.4),
              onTap: () => Navigator.of(context).pop(true),
              child: SizedBox(
                height: 50,
                child: Center(
                  child: Text(
                    _dual(strings, 'Confirm debit sale',
                        'Thibitisha mauzo ya mkopo'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                strings.cancel,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowLine extends StatelessWidget {
  const _RowLine({
    required this.label,
    required this.value,
    this.strong = false,
    this.color,
  });

  final String label;
  final String value;
  final bool strong;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? AppColors.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.helperText.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: resolved,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
