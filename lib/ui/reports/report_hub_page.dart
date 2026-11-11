import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../business_category_config.dart';
import '../../service/pos_local_store.dart';
import '../../ui/widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart' show MarketSurfaceCard;
import 'models/report_models.dart';
import 'pages/customers_report_page.dart';
import 'reports_catalog_page.dart';
import 'pages/inventory_report_page.dart';
import 'pages/profit_loss_report_page.dart';
import 'pages/sales_report_page.dart';
import 'services/report_data_service.dart';
import 'widgets/executive_summary_card.dart';
import 'widgets/metric_grid.dart';
import 'widgets/top_selling_products_list.dart';
import 'widgets/top_selling_products_sheet.dart';
import 'widgets/trend_chart.dart';

class ReportHubPage extends StatefulWidget {
  const ReportHubPage({super.key});

  @override
  State<ReportHubPage> createState() => _ReportHubPageState();
}

class _ReportHubPageState extends State<ReportHubPage>
    with TickerProviderStateMixin {
  ReportPeriod _selectedPeriod = ReportPeriod.month;
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: AppDurations.normal,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _refreshController.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) _refreshController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final config = store.businessCategoryConfig;
    final report = ReportDataService.buildReportSnapshot(
      store: store,
      period: _selectedPeriod,
      category: config.category,
    );
    final baseTheme = Theme.of(context);
    final theme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: RefreshIndicator(
          color: config.primaryColor,
          backgroundColor: Colors.white,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _PeriodSelector(
                      selected: _selectedPeriod,
                      accent: config.primaryColor,
                      onSelected: (period) {
                        setState(() => _selectedPeriod = period);
                      },
                    ),
                    const SizedBox(height: 20),
                    ExecutiveSummaryCard(
                      title: _reportOverviewTitle(config.category),
                      summary: ReportDataService.buildExecutiveSummary(
                        report: report,
                        profile: store.profile,
                        period: _selectedPeriod,
                      ),
                    ),
                    const SizedBox(height: 20),
                    MetricGrid(metrics: report.metrics),
                    const SizedBox(height: 20),
                    _RevenueTrendSection(
                      config: config,
                      points: report.trendPoints,
                      maxValue: report.chartMaxValue,
                    ),
                    const SizedBox(height: 20),
                    _QuickReports(
                      accent: config.primaryColor,
                      onOpen: (builder) => _openReport(context, builder),
                      onViewAll: () => _openCatalog(context),
                    ),
                    const SizedBox(height: 20),
                    _TopSellingSection(
                      config: config,
                      report: report,
                      onViewAll: () =>
                          _showTopSellingProducts(context, report),
                    ),
                    const SizedBox(height: 20),
                    _StockAlertSection(
                      config: config,
                      items: ReportDataService.lowStockItems(store),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCatalog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const ReportsCatalogPage(),
      ),
    );
  }

  void _openReport(BuildContext context, WidgetBuilder builder) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: builder),
    );
  }

  String _reportOverviewTitle(BusinessCategory category) {
    return switch (category) {
      BusinessCategory.pharmacy => 'Pharmacy Intelligence',
      BusinessCategory.electronics => 'Electronics Intelligence',
      BusinessCategory.retail => 'Retail Operations Intelligence',
    };
  }

  void _showTopSellingProducts(
    BuildContext context,
    ReportSnapshot report,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TopSellingProductsSheet(
          products: report.allProducts,
          emptyMessage: 'No completed sales in this period.',
        );
      },
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.accent,
    required this.onSelected,
  });

  final ReportPeriod selected;
  final Color accent;
  final ValueChanged<ReportPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          for (final period in ReportPeriod.values)
            Expanded(
              child: _PeriodChip(
                label: period.shortLabel,
                selected: period == selected,
                accent: accent,
                onTap: () => onSelected(period),
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RevenueTrendSection extends StatelessWidget {
  const _RevenueTrendSection({
    required this.config,
    required this.points,
    required this.maxValue,
  });

  final BusinessCategoryConfig config;
  final List<TrendPoint> points;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      backgroundColor: Colors.white,
      borderColor: AppColors.border,
      radius: AppRadius.rounded,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Revenue Trend',
                  style: AppTypography.sectionHeader.copyWith(
                    color: AppColors.ink,
                    fontSize: 15,
                  ),
                ),
                _TrendBadge(points: points),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: TrendChart(
              points: points,
              maxValue: maxValue,
              label: 'Revenue',
              color: config.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.points});

  final List<TrendPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox.shrink();
    }
    final change = points.last.value - points.first.value;
    final positive = change >= 0;
    final color = positive ? AppColors.success : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            positive ? 'Trending Up' : 'Trending Down',
            style: GoogleFonts.manrope(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickReports extends StatelessWidget {
  const _QuickReports({
    required this.accent,
    required this.onOpen,
    required this.onViewAll,
  });

  final Color accent;
  final ValueChanged<WidgetBuilder> onOpen;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final items = <_QuickReport>[
      _QuickReport(
        title: 'Sales',
        icon: Icons.receipt_long_rounded,
        color: AppColors.chart1,
        builder: (_) => const SalesReportPage(),
      ),
      _QuickReport(
        title: 'Profit & Loss',
        icon: Icons.trending_up_rounded,
        color: AppColors.chart2,
        builder: (_) => const ProfitLossReportPage(),
      ),
      _QuickReport(
        title: 'Inventory',
        icon: Icons.inventory_2_outlined,
        color: AppColors.chart3,
        builder: (_) => const InventoryReportPage(),
      ),
      _QuickReport(
        title: 'Customers',
        icon: Icons.people_alt_outlined,
        color: AppColors.chart4,
        builder: (_) => const CustomersReportPage(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Quick Reports',
              style: AppTypography.sectionHeader.copyWith(
                color: AppColors.ink,
                fontSize: 15,
              ),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: onViewAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all reports',
                      style: AppTypography.helperText.copyWith(
                        color: accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _QuickReportTile(
                report: items[index],
                onTap: () => onOpen(items[index].builder),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickReport {
  const _QuickReport({
    required this.title,
    required this.icon,
    required this.color,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final Color color;
  final WidgetBuilder builder;
}

class _QuickReportTile extends StatelessWidget {
  const _QuickReportTile({required this.report, required this.onTap});

  final _QuickReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.standard),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.standard),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: report.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(report.icon, color: report.color, size: 18),
                ),
                Text(
                  report.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopSellingSection extends StatelessWidget {
  const _TopSellingSection({
    required this.config,
    required this.report,
    required this.onViewAll,
  });

  final BusinessCategoryConfig config;
  final ReportSnapshot report;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      backgroundColor: Colors.white,
      borderColor: AppColors.border,
      radius: AppRadius.rounded,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Selling Products',
                  style: AppTypography.sectionHeader.copyWith(
                    color: AppColors.ink,
                    fontSize: 15,
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View All',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: config.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TopSellingProductsList(
              products: report.allProducts.take(5).toList(),
              emptyMessage: 'No completed sales in this period.',
            ),
          ),
        ],
      ),
    );
  }
}

class _StockAlertSection extends StatelessWidget {
  const _StockAlertSection({
    required this.config,
    required this.items,
  });

  final BusinessCategoryConfig config;
  final List<StockAlertItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return MarketSurfaceCard(
        backgroundColor: Colors.white,
        borderColor: AppColors.border,
        radius: AppRadius.rounded,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'All Stocked Up',
                    style: AppTypography.cardHeader.copyWith(
                      color: AppColors.ink,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No items are in the low-stock watchlist right now.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return MarketSurfaceCard(
      backgroundColor: Colors.white,
      borderColor: AppColors.border,
      radius: AppRadius.rounded,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.danger,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Low Stock Alert',
                  style: AppTypography.sectionHeader.copyWith(
                    color: AppColors.ink,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          ...items.map(
            (item) => _StockAlertRow(item: item),
          ),
        ],
      ),
    );
  }
}

class _StockAlertRow extends StatelessWidget {
  const _StockAlertRow({required this.item});

  final StockAlertItem item;

  @override
  Widget build(BuildContext context) {
    final isHigh = item.severity == StockAlertSeverity.high;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isHigh ? AppColors.dangerLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isHigh ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
              color: isHigh ? AppColors.danger : AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.category} \u2022 ${item.statusLabel}',
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textLight,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isHigh ? AppColors.dangerLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.statusLabel,
              style: AppTypography.helperText.copyWith(
                color: isHigh ? AppColors.danger : AppColors.warning,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
