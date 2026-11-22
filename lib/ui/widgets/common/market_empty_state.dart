import 'package:flutter/material.dart';

import '../app_design.dart';
import 'market_button.dart';
import 'market_surface_card.dart';

/// Unified empty state card shared across all list, ledger, report, and catalog
/// pages (modeled on the Customer empty state design).
class MarketEmptyState extends StatelessWidget {
  const MarketEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.isPrimaryAction = true,
    this.secondaryActionLabel,
    this.secondaryActionIcon,
    this.onSecondaryAction,
    this.iconColor = AppColors.primary,
    this.iconBackgroundColor = AppColors.surfaceSecondary,
    this.showCard = true,
    this.maxWidth = 460,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool isPrimaryAction;
  final String? secondaryActionLabel;
  final IconData? secondaryActionIcon;
  final VoidCallback? onSecondaryAction;
  final Color iconColor;
  final Color iconBackgroundColor;
  final bool showCard;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: iconBackgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.tile),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 34,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.cardHeader,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
            height: 1.45,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 18),
          if (secondaryActionLabel != null && onSecondaryAction != null)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                MarketButton(
                  label: actionLabel!,
                  icon: actionIcon,
                  isFullWidth: false,
                  isPrimary: isPrimaryAction,
                  onTap: onAction,
                ),
                MarketButton(
                  label: secondaryActionLabel!,
                  icon: secondaryActionIcon,
                  color: AppColors.kpiVioletBg,
                  foregroundColor: AppColors.kpiViolet,
                  isFullWidth: false,
                  onTap: onSecondaryAction,
                ),
              ],
            )
          else
            MarketButton(
              label: actionLabel!,
              icon: actionIcon,
              isFullWidth: false,
              isPrimary: isPrimaryAction,
              onTap: onAction,
            ),
        ],
      ],
    );

    if (!showCard) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          child: content,
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          width: double.infinity,
          child: MarketSurfaceCard(
            padding: const EdgeInsets.all(28),
            borderColor: AppColors.border,
            radius: AppRadius.standard,
            showShadow: false,
            child: content,
          ),
        ),
      ),
    );
  }
}
