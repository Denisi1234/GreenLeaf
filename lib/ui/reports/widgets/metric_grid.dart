import 'package:flutter/material.dart';
import '../models/report_models.dart';
import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.metrics});
  final List<MetricData> metrics;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = (constraints.maxWidth / 220).floor().clamp(1, 4);
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(spacing: 12, runSpacing: 12, children: [
          for (final metric in metrics)
            SizedBox(
                width: width,
                child: WorkspacePanel(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(metric.title,
                                    style: AppTypography.label)),
                            const SizedBox(width: 8),
                            Icon(metric.icon,
                                size: 20, color: AppColors.textMuted)
                          ]),
                          const SizedBox(height: 12),
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(metric.value,
                                  style: AppTypography.h3.copyWith(
                                      color: AppColors.ink, fontSize: 22))),
                          if (metric.deltaText != null) ...[
                            const SizedBox(height: 8),
                            Text('${metric.deltaText} ${metric.deltaLabel}',
                                style: AppTypography.bodySmall.copyWith(
                                    color: metric.deltaIsPositive == false
                                        ? AppColors.dangerDeep
                                        : AppColors.successDeep))
                          ],
                        ]))),
        ]);
      });
}
