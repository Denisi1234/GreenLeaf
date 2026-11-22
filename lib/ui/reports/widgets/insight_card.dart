import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.lightbulb_outline,
    this.color = AppColors.warning,
    this.actionLabel,
    this.onAction,
    this.severity = InsightSeverity.info,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;
  final InsightSeverity severity;

  @override
  Widget build(BuildContext context) {
    final severityConfig = _severityConfigs[severity]!;

    return Container(
      decoration: BoxDecoration(
        color: severityConfig.backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(
          color: severityConfig.iconColor.withValues(alpha: 0.18),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: severityConfig.iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: severityConfig.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(title),
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: severityConfig.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: severityConfig.iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        context.tr(severity.label),
                        style: AppTypography.helperText.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: severityConfig.iconColor,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 13,
                    color: severityConfig.textColor.withValues(alpha: 0.85),
                    height: 1.45,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: severityConfig.iconColor,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel!,
                          style: AppTypography.label.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: severityConfig.iconColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: severityConfig.iconColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum InsightSeverity { info, warning, critical, success }

extension InsightSeverityLabel on InsightSeverity {
  String get label {
    switch (this) {
      case InsightSeverity.info:
        return 'INFO';
      case InsightSeverity.warning:
        return 'ATTENTION';
      case InsightSeverity.critical:
        return 'CRITICAL';
      case InsightSeverity.success:
        return 'POSITIVE';
    }
  }
}

class _SeverityConfig {
  const _SeverityConfig({
    required this.backgroundColor,
    required this.iconColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color iconColor;
  final Color textColor;
}

Map<InsightSeverity, _SeverityConfig> get _severityConfigs => {
  InsightSeverity.info: _SeverityConfig(
    backgroundColor: AppColors.surfaceSecondary,
    iconColor: AppColors.primary,
    textColor: AppColors.ink,
  ),
  InsightSeverity.warning: _SeverityConfig(
    backgroundColor: AppColors.warningLight,
    iconColor: AppColors.warning,
    textColor: AppColors.ink,
  ),
  InsightSeverity.critical: _SeverityConfig(
    backgroundColor: AppColors.dangerLight,
    iconColor: AppColors.danger,
    textColor: AppColors.ink,
  ),
  InsightSeverity.success: _SeverityConfig(
    backgroundColor: AppColors.successLight,
    iconColor: AppColors.success,
    textColor: AppColors.ink,
  ),
};

class InsightList extends StatelessWidget {
  const InsightList({
    super.key,
    required this.insights,
    this.title = 'Key Insights',
  });

  final List<InsightCard> insights;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            context.tr(title),
            style: AppTypography.sectionHeader.copyWith(fontSize: 15),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: insights.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) => insights[index],
        ),
      ],
    );
  }
}

class KPICard extends StatelessWidget {
  const KPICard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.trend,
    this.icon,
    this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final String? trend;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: effectiveColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: effectiveColor),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      context.tr(label),
                      style: AppTypography.label.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: AppTypography.h2.copyWith(
                  fontSize: 26,
                  color: AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: AppTypography.helperText.copyWith(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
              if (trend != null) ...[
                const SizedBox(height: 8),
                _TrendPill(trend: trend!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.trend});
  final String trend;

  @override
  Widget build(BuildContext context) {
    final positive = trend.startsWith('+');
    final negative = trend.startsWith('-');
    final color = positive
        ? AppColors.success
        : negative
            ? AppColors.textMuted
            : AppColors.textMuted;
    final bg = positive
        ? AppColors.successLight
        : negative
            ? AppColors.surfaceSecondary
            : AppColors.surfaceSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive
                ? Icons.trending_up_rounded
                : negative
                    ? Icons.trending_down_rounded
                    : Icons.remove_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            trend,
            style: AppTypography.helperText.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
