import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/app_design.dart';

class ComparisonCard extends StatelessWidget {
  const ComparisonCard({
    super.key,
    required this.title,
    required this.currentValue,
    required this.previousValue,
    this.format,
    this.higherIsBetter = true,
    this.icon,
    this.color,
  });

  final String title;
  final num currentValue;
  final num previousValue;
  final String Function(num)? format;
  final bool higherIsBetter;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final change = previousValue == 0
        ? 0.0
        : ((currentValue - previousValue) / previousValue) * 100;
    final isPositive = change >= 0;

    final displayFormat =
        format ?? (num v) => NumberFormat('#,##0.##').format(v);
    final accent = color ?? AppColors.primary;
    final trendGood = isPositive == higherIsBetter;
    final trendColor = trendGood ? AppColors.success : AppColors.textMuted;
    final trendBg =
        trendGood ? AppColors.successLight : AppColors.surfaceSecondary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: accent),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  context.tr(title),
                  style: AppTypography.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 12,
                      color: trendColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${change.abs().toStringAsFixed(1)}%',
                      style: AppTypography.helperText.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ValueColumn(
                  label: context.tr('Current'),
                  value: displayFormat(currentValue),
                  isPrimary: true,
                ),
              ),
              Container(width: 1, height: 32, color: AppColors.borderLight),
              Expanded(
                child: _ValueColumn(
                  label: context.tr('Previous'),
                  value: displayFormat(previousValue),
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValueColumn extends StatelessWidget {
  const _ValueColumn({
    required this.label,
    required this.value,
    required this.isPrimary,
  });

  final String label;
  final String value;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(label),
            style:
                AppTypography.helperText.copyWith(color: AppColors.textLight),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: (isPrimary
                    ? AppTypography.cardHeader
                    : AppTypography.bodyMedium)
                .copyWith(
              fontSize: isPrimary ? 18 : 15,
              fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
              color: isPrimary ? AppColors.ink : AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class PeriodComparison extends StatelessWidget {
  const PeriodComparison({
    super.key,
    required this.currentPeriod,
    required this.previousPeriod,
    required this.metrics,
  });

  final String currentPeriod;
  final String previousPeriod;
  final List<ComparisonMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                context.tr('Period Comparison'),
                style: AppTypography.sectionHeader.copyWith(fontSize: 15),
              ),
              const Spacer(),
              _PeriodTag(
                label: currentPeriod,
                color: AppColors.surfaceSecondary,
                textColor: AppColors.primaryDeep,
              ),
              const SizedBox(width: 4),
              Text(
                context.tr('vs'),
                style: AppTypography.helperText
                    .copyWith(color: AppColors.textLight),
              ),
              const SizedBox(width: 4),
              _PeriodTag(
                label: previousPeriod,
                color: AppColors.surfaceSecondary,
                textColor: AppColors.textMuted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return ComparisonCard(
              title: metric.title,
              currentValue: metric.current,
              previousValue: metric.previous,
              format: metric.format,
              higherIsBetter: metric.higherIsBetter,
              icon: metric.icon,
              color: metric.color,
            );
          },
        ),
      ],
    );
  }
}

class _PeriodTag extends StatelessWidget {
  const _PeriodTag({
    required this.label,
    required this.color,
    required this.textColor,
  });
  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        context.tr(label),
        style: AppTypography.helperText.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class ComparisonMetric {
  const ComparisonMetric({
    required this.title,
    required this.current,
    required this.previous,
    this.format,
    this.higherIsBetter = true,
    this.icon,
    this.color,
  });

  final String title;
  final num current;
  final num previous;
  final String Function(num)? format;
  final bool higherIsBetter;
  final IconData? icon;
  final Color? color;
}
