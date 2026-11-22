import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../widgets/app_design.dart';
import '../widgets/common/market_page_header.dart';
import '../widgets/common/market_search_field.dart';
import 'advanced_reports_page.dart';
import 'enhanced_report_page.dart';
import 'pos_report_catalog.dart';

/// Full-width, sharp, borderless ERP reports directory showing the most useful
/// daily reports up front, with all 60+ specialized reports organized inside
/// [AdvancedReportsPage].
class ReportsCatalogPage extends StatefulWidget {
  const ReportsCatalogPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<ReportsCatalogPage> createState() => _ReportsCatalogPageState();
}

class _ReportsCatalogPageState extends State<ReportsCatalogPage> {
  final _searchController = TextEditingController();
  final _queryNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchController.dispose();
    _queryNotifier.dispose();
    super.dispose();
  }

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
    final essentialReports = <_EssentialReportItem>[
      _EssentialReportItem(
        Icons.point_of_sale_outlined,
        AppColors.primaryDeep, // Cyan
        AppColors.primaryLight,
        context.tr('Sales Summary'),
        context.tr('Daily revenue, volume and net sales'),
        _findReport(ReportData.sales),
      ),
      _EssentialReportItem(
        Icons.trending_up_rounded,
        AppColors.kpiSuccess, // Teal
        AppColors.kpiSuccessBg,
        context.tr('Profit & Loss'),
        context.tr('Gross profit, expenses and net margin'),
        _findReport(ReportData.profitLoss),
      ),
      _EssentialReportItem(
        Icons.inventory_2_outlined,
        AppColors.kpiSky, // Sky
        AppColors.kpiSkyBg,
        context.tr('Inventory Summary'),
        context.tr('Current stock counts and stock valuation'),
        _findReport(ReportData.inventory),
      ),
      _EssentialReportItem(
        Icons.warning_amber_rounded,
        AppColors.kpiAmber, // Amber
        AppColors.kpiAmberBg,
        context.tr('Low Inventory'),
        context.tr('Items running low and needing restock'),
        _findReport(ReportData.lowInventory),
      ),
      _EssentialReportItem(
        Icons.shopping_bag_outlined,
        AppColors.kpiViolet, // Violet
        AppColors.kpiVioletBg,
        context.tr('Best Selling Items'),
        context.tr('Top-performing products by quantity and value'),
        _findReport(ReportData.items),
      ),
      _EssentialReportItem(
        Icons.receipt_long_outlined,
        AppColors.kpiRose, // Rose
        AppColors.kpiRoseBg,
        context.tr('Expenses Summary'),
        context.tr('Business spending breakdown by category'),
        _findReport(ReportData.expenses),
      ),
      _EssentialReportItem(
        Icons.payments_outlined,
        AppColors.kpiSuccess, // Green
        AppColors.kpiSuccessBg,
        context.tr('Payments Summary'),
        context.tr('Cash, mobile money, card and credit totals'),
        _findReport(ReportData.payments),
      ),
      _EssentialReportItem(
        Icons.people_outline_rounded,
        AppColors.textBody, // Slate
        AppColors.surfaceSecondary,
        context.tr('Customers Summary'),
        context.tr('Top buyers and customer purchase history'),
        _findReport(ReportData.customers),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          MarketPageHeader(
            title: context.tr('Reports'),
            subtitle: context.tr('Sales, stock and financial reports'),
            showBackButton: true,
            centerTitle: false,
            titleSize: 22,
            titleWeight: FontWeight.w800,
            showBorder: true,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
          children: [
            // Consistent sharp search bar matching Items, Sales & More pages
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: MarketSearchField(
                controller: _searchController,
                hintText: context.tr('Find a report'),
                onChanged: (v) => _queryNotifier.value = v,
                onClear: () {
                  _searchController.clear();
                  _queryNotifier.value = '';
                },
                height: 48,
                radius: 0,
                backgroundColor: AppColors.surface,
                borderColor: AppColors.border,
                paddingHorizontal: 14,
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _queryNotifier,
                builder: (context, query, _) {
                  final needle = query.trim().toLowerCase();
                  final filtered = essentialReports.where((item) {
                    if (needle.isEmpty) return true;
                    return item.title.toLowerCase().contains(needle) ||
                        item.subtitle.toLowerCase().contains(needle);
                  }).toList();

                  return ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    children: [
                      // Essential reports section
                      if (filtered.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                          child: Row(
                            children: [
                              Text(
                                context.tr('ESSENTIAL REPORTS').toUpperCase(),
                                style: AppTypography.label.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${filtered.length}',
                                style: AppTypography.label.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppRadius.standard),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              children: [
                                for (var i = 0; i < filtered.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      indent: 66,
                                      color: AppColors.border,
                                    ),
                                  InkWell(
                                    onTap: () {
                                      FocusScope.of(context).unfocus();
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => EnhancedReportPage(
                                            report: filtered[i].report,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: filtered[i].badgeBg,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppRadius.sharp),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              filtered[i].icon,
                                              color: filtered[i].iconColor,
                                              size: 19,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  filtered[i].title,
                                                  style: AppTypography.bodyMain
                                                      .copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.ink,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  filtered[i].subtitle,
                                                  style: AppTypography.label,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.chevron_right_rounded,
                                            size: 20,
                                            color: AppColors.textMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                      // Advanced reports hub section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                        child: Row(
                          children: [
                            Text(
                              context.tr('MORE REPORTS').toUpperCase(),
                              style: AppTypography.label.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${posReports.length}',
                              style: AppTypography.label.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppRadius.standard),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AdvancedReportsPage(),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.kpiVioletBg,
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.sharp),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.analytics_outlined,
                                      color: AppColors.kpiViolet,
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr('Advanced reports'),
                                          style:
                                              AppTypography.bodyMain.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          context.tr(
                                            'Graphical, detailed, accounting, tax & multi-store reports',
                                          ),
                                          style: AppTypography.label,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
          ),
        ],
      ),
    );
  }
}

class _EssentialReportItem {
  const _EssentialReportItem(
    this.icon,
    this.iconColor,
    this.badgeBg,
    this.title,
    this.subtitle,
    this.report,
  );

  final IconData icon;
  final Color iconColor;
  final Color badgeBg;
  final String title;
  final String subtitle;
  final PosReport report;
}
