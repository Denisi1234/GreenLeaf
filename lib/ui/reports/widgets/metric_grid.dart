import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../widgets/app_design.dart';
import '../models/report_models.dart';

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.metrics});
  final List<MetricData> metrics;

  static const _palette = [
    (AppColors.kpiSkyBg, AppColors.kpiSky), // Sky
    (AppColors.kpiSuccessBg, AppColors.kpiSuccess), // Emerald
    (AppColors.kpiAmberBg, AppColors.kpiAmber), // Amber
    (AppColors.kpiVioletBg, AppColors.kpiViolet), // Purple
    (AppColors.kpiRoseBg, AppColors.kpiRose), // Rose
    (AppColors.kpiAmberBg, AppColors.kpiAmber), // Orange
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final columns = (constraints.maxWidth / 220).floor().clamp(1, 4);
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (var i = 0; i < metrics.length; i++)
            _buildMetricCard(context, metrics[i], width, i),
        ]);
      });

  Widget _buildMetricCard(BuildContext context, MetricData metric, double width, int index) {
    final colors = _palette[index % _palette.length];
    final bg = metric.tint != Colors.transparent && metric.tint != Colors.white
        ? metric.tint
        : colors.$1;
    final primaryColor = metric.iconColor != AppColors.ink && metric.iconColor != Colors.transparent
        ? metric.iconColor
        : colors.$2;

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(metric.title),
                    style: AppTypography.label.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Icon(metric.icon, size: 18, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                metric.value,
                style: AppTypography.h3.copyWith(
                  color: metric.valueColor != Colors.transparent && metric.valueColor != AppColors.ink
                      ? metric.valueColor
                      : AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (metric.deltaText != null) ...[
              const SizedBox(height: 8),
              Text(
                '${metric.deltaText} ${context.tr(metric.deltaLabel)}',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: metric.deltaIsPositive == false
                      ? AppColors.dangerDeep
                      : AppColors.successDeep,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
