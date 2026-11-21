import 'package:flutter/material.dart';
import 'package:track_mauzo/l10n/app_localization.dart';

import '../app_design.dart';

/// Standardized Android-ready success or failure result modal shared across the app.
Future<void> showMarketResultDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool isSuccess = true,
  String? buttonLabel,
}) {
  final accent = isSuccess ? AppColors.success : AppColors.danger;
  final badgeBg = isSuccess ? AppColors.successLight : AppColors.dangerLight;
  final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.modal),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: badgeBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.cardHeader.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: isSuccess ? AppColors.ink : AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.standard),
                ),
              ),
              child: Text(buttonLabel ?? dialogContext.tr('OK')),
            ),
          ),
        ],
      ),
    ),
  );
}
