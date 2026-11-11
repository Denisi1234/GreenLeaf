import 'package:flutter/material.dart';

import '../models/report_models.dart';
import '../../../ui/widgets/app_design.dart';

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.metrics});

  final List<MetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: constraints.maxWidth > 600 ? 1.45 : 1.15,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _MetricCard(metric: metric);
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final MetricData metric;

  @override
  Widget build(BuildContext context) {
    final deltaColor = metric.deltaIsPositive == false
        ? AppColors.danger
        : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: metric.tint,
        borderRadius: BorderRadius.circular(AppRadius.rounded),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: metric.iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.standard),
            ),
            child: Icon(
              metric.icon,
              color: metric.iconColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            metric.title,
            style: AppTypography.label.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.value,
            style: AppTypography.cardHeader.copyWith(
              color: metric.valueColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (metric.deltaText != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  metric.deltaIsPositive == true
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 12,
                  color: deltaColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${metric.deltaText} ${metric.deltaLabel}',
                  style: AppTypography.helperText.copyWith(
                    color: deltaColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
