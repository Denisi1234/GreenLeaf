import 'package:flutter/material.dart';

import '../../../service/pos_local_store.dart';
import '../../../service/register_shift_model.dart';
import '../../widgets/app_design.dart';
import 'register_models.dart';

class ShiftRowTile extends StatelessWidget {
  const ShiftRowTile({
    super.key,
    required this.shift,
    required this.summary,
    required this.isSwahili,
    required this.onTap,
  });

  final RegisterShift shift;
  final CashUpSummary summary;
  final bool isSwahili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final opened = shift.openedAt.toLocal();
    final stamp = formatRegisterDateTime(opened);
    final balanced = summary.variance.abs() < 0.5;
    final status = shift.isOpen
        ? (isSwahili ? 'Wazi' : 'Open')
        : (balanced
            ? (isSwahili ? 'Sawa' : 'Balanced')
            : '${isSwahili ? 'Tofauti' : 'Variance'} ${formatRegisterMoney(summary.variance)}');
    final statusColor = shift.isOpen
        ? AppColors.success
        : (balanced ? AppColors.textMuted : AppColors.danger);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.register,
                    style: AppTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$stamp • ${shift.openedBy.isEmpty ? '—' : shift.openedBy}',
                    style: AppTypography.helperText
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!shift.isOpen)
                  Text(
                    formatRegisterMoney(summary.counted),
                    style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                Text(
                  status,
                  style: AppTypography.helperText.copyWith(
                      color: statusColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}

class MovementRowTile extends StatelessWidget {
  const MovementRowTile({
    super.key,
    required this.movement,
    required this.isSwahili,
    required this.onDelete,
  });

  final CashMovement movement;
  final bool isSwahili;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final outflow = movement.type.isOutflow;
    final color = outflow ? AppColors.danger : AppColors.success;
    final at = movement.at.toLocal();
    final time =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    final subtitle = [
      if (movement.reason.trim().isNotEmpty) movement.reason.trim(),
      if (movement.recordedBy.trim().isNotEmpty) movement.recordedBy.trim(),
      time,
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.type.localized(isSwahili),
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${outflow ? '-' : '+'}${formatRegisterMoney(movement.amount)}',
                style: AppTypography.bodySmall
                    .copyWith(color: color, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onDelete,
                child: Text(
                  isSwahili ? 'Ondoa' : 'Remove',
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
