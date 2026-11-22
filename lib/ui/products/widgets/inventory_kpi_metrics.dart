import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';
import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';
import 'product_cards.dart';

class InventoryKpiMetrics extends StatelessWidget {
  const InventoryKpiMetrics({
    super.key,
    required this.totalItems,
    required this.stockValue,
    required this.lowCount,
    required this.outCount,
  });

  final int totalItems;
  final double stockValue;
  final int lowCount;
  final int outCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, metricConstraints) {
        final columns = metricConstraints.maxWidth >= 760 ? 4 : 2;
        final width = (metricConstraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: context.tr('Total items'),
                value: '$totalItems',
                icon: Icons.inventory_2_outlined,
                sharp: false,
                borderless: true,
                backgroundColor: AppColors.kpiRoseBg,
                color: AppColors.kpiRose,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: context.tr('Stock value'),
                value: formatProductPrice(stockValue),
                icon: Icons.account_balance_wallet_outlined,
                sharp: false,
                borderless: true,
                backgroundColor: AppColors.kpiSkyBg,
                color: AppColors.kpiSky,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: context.tr('Low stock'),
                value: '$lowCount',
                icon: Icons.trending_down_rounded,
                sharp: false,
                borderless: true,
                backgroundColor: AppColors.kpiAmberBg,
                color: AppColors.kpiAmber,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: context.tr('Out of stock'),
                value: '$outCount',
                icon: Icons.inventory_outlined,
                sharp: false,
                borderless: true,
                backgroundColor: AppColors.kpiDangerBg,
                color: AppColors.kpiDanger,
              ),
            ),
          ],
        );
      },
    );
  }
}
