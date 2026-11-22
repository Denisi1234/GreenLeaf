import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../app_design.dart';

/// Standardized, Android-ready confirmation dialog used across the entire app.
///
/// Returns `true` when the user confirms, or `false` when cancelled/dismissed.
Future<bool> showMarketConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = false,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppColors.dangerLight
                    : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(AppRadius.standard),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive ? AppColors.danger : AppColors.ink,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.cardHeader.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textMuted,
          height: 1.45,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(
            backgroundColor: AppColors.surfaceSecondary,
            foregroundColor: AppColors.textBody,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          child: Text(
            cancelLabel ?? dialogContext.tr('Cancel'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor:
                isDestructive ? AppColors.danger : AppColors.primary,
            foregroundColor: Colors.white,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          child: Text(
            confirmLabel ??
                (isDestructive
                    ? dialogContext.tr('Delete')
                    : dialogContext.tr('Confirm')),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return result == true;
}
