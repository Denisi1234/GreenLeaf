import 'package:flutter/material.dart';
import '../../../l10n/app_strings.dart';
import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';
import 'expense_models.dart';

class ExpenseKpiMetrics extends StatelessWidget {
  const ExpenseKpiMetrics({
    super.key,
    required this.total,
    required this.totalRecords,
    required this.taxTotal,
    required this.strings,
  });

  final double total;
  final int totalRecords;
  final double taxTotal;
  final AppStrings strings;

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
                label: expenseDual(strings, 'Total spent', 'Jumla ya matumizi'),
                value: formatExpenseMoney(total, compact: true),
                icon: Icons.payments_outlined,
                sharp: false,
                borderless: true,
                backgroundColor: AppColors.kpiDangerBg,
                color: AppColors.kpiDanger,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: expenseDual(strings, 'Total records', 'Idadi ya kumbukumbu'),
                value: '$totalRecords',
                icon: Icons.receipt_long_outlined,
                sharp: false,
                borderless: true,
                backgroundColor: AppColors.kpiSkyBg,
                color: AppColors.kpiSky,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: expenseDual(strings, 'Average expense', 'Wastani wa matumizi'),
                value: formatExpenseMoney(
                  totalRecords == 0 ? 0 : total / totalRecords,
                  compact: true,
                ),
                icon: Icons.query_stats_rounded,
                sharp: false,
                borderless: true,
                backgroundColor: AppColors.kpiAmberBg,
                color: AppColors.kpiAmber,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: expenseDual(strings, 'Tax included', 'Kodi iliyojumuishwa'),
                value: formatExpenseMoney(taxTotal, compact: true),
                icon: Icons.account_balance_outlined,
                sharp: false,
                borderless: true,
                backgroundColor: taxTotal > 0 ? AppColors.kpiVioletBg : AppColors.kpiNeutralBg,
                color: taxTotal > 0 ? AppColors.kpiViolet : AppColors.kpiNeutral,
              ),
            ),
          ],
        );
      },
    );
  }
}
