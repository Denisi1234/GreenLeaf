import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_strings.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

enum LedgerSortMode { balance, oldest, recent, overdue }

extension LedgerSortModeExt on LedgerSortMode {
  String label(AppStrings strings) => switch (this) {
        LedgerSortMode.balance =>
          _dual(strings, 'Highest balance', 'Deni kubwa'),
        LedgerSortMode.oldest =>
          _dual(strings, 'Oldest debt', 'Deni la zamani'),
        LedgerSortMode.recent =>
          _dual(strings, 'Recent activity', 'Shughuli mpya'),
        LedgerSortMode.overdue =>
          _dual(strings, 'Overdue (>30 days)', 'Yaliyochelewa (>30d)'),
      };

  IconData get icon => switch (this) {
        LedgerSortMode.balance => Icons.trending_down_rounded,
        LedgerSortMode.oldest => Icons.history_rounded,
        LedgerSortMode.recent => Icons.schedule_rounded,
        LedgerSortMode.overdue => Icons.warning_amber_rounded,
      };
}

class DebtorSortRow extends StatelessWidget {
  const DebtorSortRow({
    super.key,
    required this.sort,
    required this.strings,
    required this.oldestDebt,
    required this.onPick,
  });

  final LedgerSortMode sort;
  final AppStrings strings;
  final DateTime? oldestDebt;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderColor: AppColors.border,
      radius: AppRadius.input,
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
            child:
                Icon(Icons.rule_rounded, color: AppColors.ink, size: 18),
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
                if (oldestDebt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_dual(strings, 'Oldest unpaid charge', 'Deni la zamani halijalipwa')}: ${DateFormat('MMM d, yyyy').format(oldestDebt!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.helperText.copyWith(
                      color: AppColors.textLight,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ],
            ),
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
