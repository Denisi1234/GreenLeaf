import 'package:flutter/material.dart';

import '../app_design.dart';

enum MarketNoticeType {
  info,
  success,
  warning,
  error,
}

void showMarketNotice(
  BuildContext context, {
  required String title,
  required String message,
  MarketNoticeType type = MarketNoticeType.success,
}) {
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  final accent = switch (type) {
    MarketNoticeType.success => AppColors.success,
    MarketNoticeType.warning || MarketNoticeType.info => AppColors.textBody,
    MarketNoticeType.error => AppColors.danger,
  };

  final iconBg = switch (type) {
    MarketNoticeType.success => AppColors.successLight,
    MarketNoticeType.warning || MarketNoticeType.info => AppColors.surfaceHover,
    MarketNoticeType.error => AppColors.dangerLight,
  };

  final icon = switch (type) {
    MarketNoticeType.success => Icons.check_circle_rounded,
    MarketNoticeType.warning => Icons.error_outline_rounded,
    MarketNoticeType.info => Icons.info_outline_rounded,
    MarketNoticeType.error => Icons.cancel_rounded,
  };

  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      top: MediaQuery.of(context).padding.top + AppSpacing.md,
      child: _MarketNoticeCard(
        title: title,
        message: message,
        accent: accent,
        iconBg: iconBg,
        icon: icon,
      ),
    ),
  );

  overlay.insert(entry);
  Future<void>.delayed(const Duration(milliseconds: 2500)).then((_) {
    entry.remove();
  });
}

class _MarketNoticeCard extends StatelessWidget {
  const _MarketNoticeCard({
    required this.title,
    required this.message,
    required this.accent,
    required this.iconBg,
    required this.icon,
  });

  final String title;
  final String message;
  final Color accent;
  final Color iconBg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.medium,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.sharp),
              ),
              child: Icon(icon, color: accent, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: AppTypography.helperText.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
