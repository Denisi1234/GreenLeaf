import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../app_design.dart';

/// Standardized clean result modal matching Aza POS's pill-button design.
Future<void> showMarketResultDialog(
  BuildContext context, {
  required String title,
  required String message,
  bool isSuccess = true,
  String? buttonLabel,
}) {
  final accent = isSuccess ? AppColors.successDeep : AppColors.dangerDeep;
  final icon =
      isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.rounded),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.medium,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 36, color: accent),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.sectionHeader.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textBody,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isSuccess ? AppColors.primary : AppColors.dangerDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                child: Text(
                  buttonLabel ?? dialogContext.tr('OK'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
