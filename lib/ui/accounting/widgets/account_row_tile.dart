import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';

class AccountRowTile extends StatelessWidget {
  const AccountRowTile({
    super.key,
    required this.code,
    required this.name,
    required this.debit,
    required this.credit,
    required this.formattedAmount,
  });

  final String code;
  final String name;
  final double debit;
  final double credit;
  final String formattedAmount;

  @override
  Widget build(BuildContext context) {
    final balance = debit - credit;
    final color = balance > 0
        ? AppColors.ink
        : balance < 0
            ? AppColors.successDeep
            : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              code,
              style: AppTypography.helperText.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              formattedAmount,
              textAlign: TextAlign.right,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
