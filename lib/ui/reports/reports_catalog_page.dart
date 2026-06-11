import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../business_category_config.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class ReportsCatalogPage extends StatelessWidget {
  const ReportsCatalogPage({super.key});

  static const Color _ink = AppColors.ink;
  static const Color _muted = Color(0xFF6C7483);
  static const Color _border = Color(0xFFE7EAF0);
  static const Color _blue = Color(0xFF2D6CEA);

  static const List<_ReportSection> _sections = [
    _ReportSection(
      categoryTitle: 'Sales Reports',
      accent: Color(0xFF2D6CEA),
      soft: Color(0xFFEEF4FF),
      icon: Icons.bar_chart_rounded,
      count: 12,
      reports: [
        _ReportItem(
          title: 'Sales Summary',
          subtitle: 'Summary of sales by date, time or period',
        ),
        _ReportItem(
          title: 'Sales by Product',
          subtitle: 'Detailed sales breakdown by product',
        ),
        _ReportItem(
          title: 'Sales by Category',
          subtitle: 'Sales performance by category',
        ),
      ],
      initiallyExpanded: true,
    ),
    _ReportSection(
      categoryTitle: 'Inventory Reports',
      accent: Color(0xFF46A35F),
      soft: Color(0xFFF0F8F1),
      icon: Icons.inventory_2_outlined,
      count: 9,
      reports: [
        _ReportItem(
          title: 'Stock Status',
          subtitle: 'In stock, low stock, and out of stock items',
        ),
        _ReportItem(
          title: 'Reorder Watchlist',
          subtitle: 'Products that need replenishment attention',
        ),
        _ReportItem(
          title: 'Category Coverage',
          subtitle: 'Inventory balance across product groups',
        ),
      ],
    ),
    _ReportSection(
      categoryTitle: 'Financial Reports',
      accent: Color(0xFF7A57E5),
      soft: Color(0xFFF4F0FF),
      icon: Icons.receipt_long_outlined,
      count: 10,
      reports: [
        _ReportItem(
          title: 'Revenue Trend',
          subtitle: 'How sales move across the selected period',
        ),
        _ReportItem(
          title: 'Profit Snapshot',
          subtitle: 'Revenue, expenses, and margin at a glance',
        ),
        _ReportItem(
          title: 'Expense Breakdown',
          subtitle: 'Spending grouped by category and date',
        ),
      ],
    ),
    _ReportSection(
      categoryTitle: 'Staff Reports',
      accent: Color(0xFFE28A0F),
      soft: Color(0xFFFFF6E8),
      icon: Icons.person_outline_rounded,
      count: 6,
      reports: [
        _ReportItem(
          title: 'Attendance Summary',
          subtitle: 'Shift coverage and roster activity',
        ),
        _ReportItem(
          title: 'Sales by Staff',
          subtitle: 'Performance by cashier or attendant',
        ),
        _ReportItem(
          title: 'Role Access Audit',
          subtitle: 'Staff permissions and access changes',
        ),
      ],
    ),
    _ReportSection(
      categoryTitle: 'Compliance Reports',
      accent: Color(0xFF1296A8),
      soft: Color(0xFFEDF9FB),
      icon: Icons.shield_outlined,
      count: 7,
      reports: [
        _ReportItem(
          title: 'Tax Register',
          subtitle: 'Tax-relevant transactions and totals',
        ),
        _ReportItem(
          title: 'Audit Trail',
          subtitle: 'System changes and sensitive actions',
        ),
        _ReportItem(
          title: 'License Renewals',
          subtitle: 'Upcoming compliance deadlines and notes',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final config = store.businessCategoryConfig;
    final categorySection = _categoryReportSection(config.category);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      drawer: const MarketAppDrawer(selectedItem: 'Home'),
      body: SafeArea(
        child: Column(
          children: [
            const _ReportsCatalogHeader(),
            const Divider(height: 1, thickness: 1, color: _border),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        MarketSurfaceCard(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${config.category.displayName} report pack',
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                  BusinessCategoryBadge(
                                    category: config.category,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                config.dashboardHeadline,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 13.5,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ReportSectionTile(section: categorySection),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        MarketSurfaceCard(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MarketSectionHeader(
                                title: 'All Reports',
                                trailing: IconButton(
                                  onPressed: () {
                                    showMarketNotice(
                                      context,
                                      title: 'Search Reports',
                                      message:
                                          'Report search can be added here next.',
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.search_rounded,
                                    color: _muted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              ..._sections.map(
                                (section) =>
                                    _ReportSectionTile(section: section),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_ReportSection _categoryReportSection(BusinessCategory category) {
  return switch (category) {
    BusinessCategory.pharmacy => const _ReportSection(
        categoryTitle: 'Pharmacy Reports',
        accent: Color(0xFF10B981),
        soft: Color(0xFFF0FDF4),
        icon: Icons.medication_rounded,
        count: 3,
        reports: [
          _ReportItem(
            title: 'Expiry Watchlist',
            subtitle: 'Medicines due for review soon',
          ),
          _ReportItem(
            title: 'Prescription Refill',
            subtitle: 'Refill activity and medicine flow',
          ),
          _ReportItem(
            title: 'Margin Tracker',
            subtitle: 'Profitability across the dispensary',
          ),
        ],
        initiallyExpanded: true,
      ),
    BusinessCategory.electronics => const _ReportSection(
        categoryTitle: 'Electronics Reports',
        accent: Color(0xFF7C3AED),
        soft: Color(0xFFF5F3FF),
        icon: Icons.devices_other_rounded,
        count: 3,
        reports: [
          _ReportItem(
            title: 'Warranty Claims',
            subtitle: 'Service registration and claims flow',
          ),
          _ReportItem(
            title: 'High-Value Sales',
            subtitle: 'Premium items and device turnover',
          ),
          _ReportItem(
            title: 'Brand Performance',
            subtitle: 'Best performing manufacturers',
          ),
        ],
        initiallyExpanded: true,
      ),
    BusinessCategory.retail => const _ReportSection(
        categoryTitle: 'Retail Operations',
        accent: Color(0xFF2563EB),
        soft: Color(0xFFEFF6FF),
        icon: Icons.storefront_outlined,
        count: 4,
        reports: [
          _ReportItem(
            title: 'Fast-Moving Items',
            subtitle: 'Products that are turning fastest on the floor',
          ),
          _ReportItem(
            title: 'Basket Size Trends',
            subtitle: 'Average basket value and add-on patterns',
          ),
          _ReportItem(
            title: 'Markdown Watch',
            subtitle: 'Discounted stock and clearance pressure',
          ),
          _ReportItem(
            title: 'Reorder Pressure',
            subtitle: 'Low stock items and replenishment urgency',
          ),
        ],
        initiallyExpanded: true,
      ),
  };
}

class _ReportsCatalogHeader extends StatelessWidget {
  const _ReportsCatalogHeader();

  @override
  Widget build(BuildContext context) {
    return MarketPageHeader(
      title: 'Reports',
      titleSize: 21,
      actions: [
        IconButton(
          onPressed: () {
            showMarketNotice(
              context,
              title: 'Filter Reports',
              message: 'Date and category filters can be connected here next.',
            );
          },
          icon: const Icon(
            Icons.filter_alt_outlined,
            color: ReportsCatalogPage._muted,
            size: 26,
          ),
        ),
      ],
    );
  }
}

class _ReportSectionTile extends StatelessWidget {
  const _ReportSectionTile({required this.section});

  final _ReportSection section;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      borderColor: ReportsCatalogPage._border,
      radius: 14,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: section.initiallyExpanded,
          tilePadding: EdgeInsets.zero,
          childrenPadding: EdgeInsets.zero,
          iconColor: ReportsCatalogPage._muted,
          collapsedIconColor: ReportsCatalogPage._muted,
          title: Row(
            children: [
              Icon(section.icon, color: section.accent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  section.categoryTitle,
                  style: TextStyle(
                    color: section.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: section.soft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${section.count}',
                  style: TextStyle(
                    color: section.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          children: [
            if (section.reports.isNotEmpty) ...[
              const Divider(height: 1, color: ReportsCatalogPage._border),
              ...section.reports
                  .map((report) => _ReportListItem(report: report)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportListItem extends StatelessWidget {
  const _ReportListItem({required this.report});

  final _ReportItem report;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showMarketNotice(
            context,
            title: report.title,
            message: 'This report detail page can be connected next.',
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 12, right: 16),
                child: Icon(
                  Icons.description_outlined,
                  color: ReportsCatalogPage._blue,
                  size: 28,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                        color: ReportsCatalogPage._ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.subtitle,
                      style: const TextStyle(
                        color: ReportsCatalogPage._muted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ReportsCatalogPage._muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportSection {
  const _ReportSection({
    required this.categoryTitle,
    required this.accent,
    required this.soft,
    required this.icon,
    required this.count,
    required this.reports,
    this.initiallyExpanded = false,
  });

  final String categoryTitle;
  final Color accent;
  final Color soft;
  final IconData icon;
  final int count;
  final List<_ReportItem> reports;
  final bool initiallyExpanded;
}

class _ReportItem {
  const _ReportItem({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}
