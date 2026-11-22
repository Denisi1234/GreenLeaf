import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../widgets/app_design.dart';
import '../widgets/common/market_page_header.dart';
import 'advanced_reports_page.dart';
import 'enhanced_report_page.dart';
import 'pos_report_catalog.dart';

/// Clean, restrained reports hub showing essential daily reports up front,
/// with all 60+ specialized reports accessible in [AdvancedReportsPage].
class ReportsCatalogPage extends StatelessWidget {
  const ReportsCatalogPage({super.key, this.embedded = false});
  final bool embedded;

  PosReport _findReport(ReportData data, {bool preferChart = false}) {
    return posReports.firstWhere(
      (r) => r.data == data && r.chart == preferChart,
      orElse: () => posReports.firstWhere(
        (r) => r.data == data,
        orElse: () => posReports.first,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final essentialReports = <_ReportRowItem>[
      _ReportRowItem(
        icon: Icons.point_of_sale_outlined,
        title: context.tr('Sales Summary'),
        report: _findReport(ReportData.sales),
      ),
      _ReportRowItem(
        icon: Icons.trending_up_rounded,
        title: context.tr('Profit & Loss'),
        report: _findReport(ReportData.profitLoss),
      ),
      _ReportRowItem(
        icon: Icons.inventory_2_outlined,
        title: context.tr('Inventory Summary'),
        report: _findReport(ReportData.inventory),
      ),
      _ReportRowItem(
        icon: Icons.warning_amber_rounded,
        title: context.tr('Low Inventory'),
        report: _findReport(ReportData.lowInventory),
      ),
      _ReportRowItem(
        icon: Icons.shopping_bag_outlined,
        title: context.tr('Best Selling Items'),
        report: _findReport(ReportData.items),
      ),
      _ReportRowItem(
        icon: Icons.receipt_long_outlined,
        title: context.tr('Expenses Summary'),
        report: _findReport(ReportData.expenses),
      ),
      _ReportRowItem(
        icon: Icons.payments_outlined,
        title: context.tr('Payments Summary'),
        report: _findReport(ReportData.payments),
      ),
      _ReportRowItem(
        icon: Icons.people_outline_rounded,
        title: context.tr('Customers Summary'),
        report: _findReport(ReportData.customers),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          MarketPageHeader(
            title: context.tr('Reports'),
            showBackButton: true,
            centerTitle: false,
            titleSize: 20,
            titleWeight: FontWeight.w800,
            showBorder: true,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                        child: Text(
                          context.tr('ESSENTIAL REPORTS').toUpperCase(),
                          style: AppTypography.label.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.standard),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < essentialReports.length;
                                  i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    indent: 52,
                                    color: AppColors.divider,
                                  ),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => EnhancedReportPage(
                                          report: essentialReports[i].report,
                                        ),
                                      ),
                                    );
                                  },
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(minHeight: 54),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            essentialReports[i].icon,
                                            size: 22,
                                            color: AppColors.textMain,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Text(
                                              essentialReports[i].title,
                                              style: AppTypography.bodyMain
                                                  .copyWith(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right_rounded,
                                            size: 20,
                                            color: AppColors.textLight,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                        child: Text(
                          context.tr('MORE REPORTS').toUpperCase(),
                          style: AppTypography.label.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.standard),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppShadows.soft,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AdvancedReportsPage(),
                                ),
                              );
                            },
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 54),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.analytics_outlined,
                                      size: 22,
                                      color: AppColors.textMain,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        context.tr('Advanced reports'),
                                        style: AppTypography.bodyMain.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${posReports.length}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textMuted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                      color: AppColors.textLight,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportRowItem {
  const _ReportRowItem({
    required this.icon,
    required this.title,
    required this.report,
  });

  final IconData icon;
  final String title;
  final PosReport report;
}
