import 'package:flutter/material.dart';

import '../widgets/market_shared_widgets.dart';

class ReportsCatalogPage extends StatelessWidget {
  const ReportsCatalogPage({super.key});

  static const Color _ink = Color(0xFF1E2430);
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
      reports: [],
    ),
    _ReportSection(
      categoryTitle: 'Financial Reports',
      accent: Color(0xFF7A57E5),
      soft: Color(0xFFF4F0FF),
      icon: Icons.receipt_long_outlined,
      count: 10,
      reports: [],
    ),
    _ReportSection(
      categoryTitle: 'Staff Reports',
      accent: Color(0xFFE28A0F),
      soft: Color(0xFFFFF6E8),
      icon: Icons.person_outline_rounded,
      count: 6,
      reports: [],
    ),
    _ReportSection(
      categoryTitle: 'Compliance Reports',
      accent: Color(0xFF1296A8),
      soft: Color(0xFFEDF9FB),
      icon: Icons.shield_outlined,
      count: 7,
      reports: [],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFC),
      drawer: const MarketAppDrawer(selectedItem: 'Reports'),
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
                        _SectionShell(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
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

class _ReportsCatalogHeader extends StatelessWidget {
  const _ReportsCatalogHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: Color(0xFF5C677D),
              size: 30,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Reports',
                style: TextStyle(
                  color: ReportsCatalogPage._ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              showMarketNotice(
                context,
                title: 'Filter Reports',
                message:
                    'Date and category filters can be connected here next.',
              );
            },
            icon: const Icon(
              Icons.filter_alt_outlined,
              color: ReportsCatalogPage._muted,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ReportsCatalogPage._border),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: ReportsCatalogPage._ink,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        trailing,
      ],
    );
  }
}

class _ReportSectionTile extends StatelessWidget {
  const _ReportSectionTile({required this.section});

  final _ReportSection section;

  @override
  Widget build(BuildContext context) {
    return Theme(
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            ...section.reports.map((report) => _ReportListItem(report: report)),
          ],
        ],
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
