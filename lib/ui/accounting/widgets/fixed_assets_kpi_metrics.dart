import 'package:flutter/material.dart';

import '../../../utils/currency_formatter.dart';
import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';

/// Clean operational KPI metrics for the Fixed Assets Register.
class FixedAssetsKpiMetrics extends StatelessWidget {
  const FixedAssetsKpiMetrics({
    super.key,
    required this.totalNbv,
    required this.totalCost,
    required this.totalDepreciation,
    required this.assetCount,
    required this.isSwahili,
  });

  final double totalNbv;
  final double totalCost;
  final double totalDepreciation;
  final int assetCount;
  final bool isSwahili;

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String sw) => isSwahili ? sw : en;

    return LayoutBuilder(
      builder: (context, metricConstraints) {
        final columns = metricConstraints.maxWidth >= 760 ? 4 : 2;
        final width =
            (metricConstraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Net book value', 'Thamani halisi (NBV)'),
                value: _money(totalNbv),
                icon: Icons.account_balance_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: AppColors.kpiSuccessBg,
                color: AppColors.kpiSuccess,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Total purchase cost', 'Gharama ya ununuzi'),
                value: _money(totalCost),
                icon: Icons.payments_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: AppColors.kpiSkyBg,
                color: AppColors.kpiSky,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Accumulated dep.', 'Uchakavu uliokusanywa'),
                value: _money(totalDepreciation),
                icon: Icons.trending_down_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: AppColors.kpiAmberBg,
                color: AppColors.kpiAmber,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Registered assets', 'Mali zilizosajiliwa'),
                value: '$assetCount',
                icon: Icons.domain_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: AppColors.kpiVioletBg,
                color: AppColors.kpiViolet,
              ),
            ),
          ],
        );
      },
    );
  }
}
