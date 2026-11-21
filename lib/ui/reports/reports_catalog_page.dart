import 'package:flutter/material.dart';
import 'package:track_mauzo/l10n/app_localization.dart';

import '../widgets/app_design.dart';
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
  final _searchFocusNode = FocusNode();
  final _queryNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
        AppColors.kpiSky, // Blue
        AppColors.kpiSkyBg,
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
      appBar: AppBar(
        title: Text(
          context.tr('Reports'),
          style: AppTypography.cardHeader.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.headerSurface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Full-width sharp borderless ERP filter bar
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (v) => _queryNotifier.value = v,
                textInputAction: TextInputAction.search,
                style: AppTypography.bodyMain,
                decoration: InputDecoration(
                  hintText: context.tr('Find a report'),
                  hintStyle: AppTypography.label,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: ValueListenableBuilder<String>(
                    valueListenable: _queryNotifier,
                    builder: (_, q, __) => q.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _queryNotifier.value = '';
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                  filled: true,
                  fillColor: AppColors.pageBackground,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.ink, width: 1),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      // Essential reports section
                      if (filtered.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                        Material(
                          color: AppColors.sectionSurface,
                          borderRadius: BorderRadius.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < filtered.length; i++) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    indent: 68,
                                    color: AppColors.divider,
                                  ),
                                InkWell(
                                  onTap: () {
                                    _searchFocusNode.unfocus();
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
                                      horizontal: 16,
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
                                                BorderRadius.circular(8),
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
                        const SizedBox(height: 20),
                      ],
                      // Advanced reports hub section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                      Material(
                        color: AppColors.sectionSurface,
                        borderRadius: BorderRadius.zero,
                        child: InkWell(
                          onTap: () {
                            _searchFocusNode.unfocus();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AdvancedReportsPage(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.kpiSkyBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.analytics_outlined,
                                    color: AppColors.kpiSky,
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
                                        style: AppTypography.bodyMain.copyWith(
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
                    ],
                  );
                },
              ),
            ),
          ],
        ),
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
