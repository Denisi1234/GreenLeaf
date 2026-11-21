import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';

/// Operational KPI cards for the Staff Management module.
class StaffKpiMetrics extends StatelessWidget {
  const StaffKpiMetrics({
    super.key,
    required this.totalStaff,
    required this.activeStaff,
    required this.onLeaveStaff,
    required this.rolesCount,
    required this.isSwahili,
  });

  final int totalStaff;
  final int activeStaff;
  final int onLeaveStaff;
  final int rolesCount;
  final bool isSwahili;

  @override
  Widget build(BuildContext context) {
    String t(String en, String sw) => isSwahili ? sw : en;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Total Staff', 'Jumla ya Wafanyakazi'),
                value: '$totalStaff',
                icon: Icons.groups_2_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: AppColors.kpiSkyBg,
                color: AppColors.kpiSky,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Active', 'Hai kazini'),
                value: '$activeStaff',
                icon: Icons.check_circle_outline_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: AppColors.kpiSuccessBg,
                color: AppColors.kpiSuccess,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('On Leave', 'Wenye Likizo'),
                value: '$onLeaveStaff',
                icon: Icons.event_busy_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: AppColors.kpiAmberBg,
                color: AppColors.kpiAmber,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Roles & Access', 'Nafasi na Ruhusa'),
                value: '$rolesCount',
                icon: Icons.admin_panel_settings_outlined,
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
