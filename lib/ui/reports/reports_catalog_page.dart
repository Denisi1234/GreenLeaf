import 'package:flutter/material.dart';

import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'pos_report_catalog.dart';
import 'pos_report_page.dart';

const Color _ink = AppColors.ink;
const Color _muted = Color(0xFF6C7483);
const Color _border = Color(0xFFE7EAF0);

class ReportsCatalogPage extends StatefulWidget {
  const ReportsCatalogPage({super.key, this.embedded = false});

  /// When true the page renders only the report directory without its own
  /// scaffold, header or drawer. Used by the Reports tab.
  final bool embedded;

  @override
  State<ReportsCatalogPage> createState() => _ReportsCatalogPageState();
}

class _ReportsCatalogPageState extends State<ReportsCatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<_ReportSection> _sections = _buildSections();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ReportSection> get _visibleSections {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _sections;

    final visible = <_ReportSection>[];
    for (final section in _sections) {
      final matches = section.reports
          .where(
            (report) =>
                report.title.toLowerCase().contains(query) ||
                report.subtitle.toLowerCase().contains(query),
          )
          .toList();
      if (matches.isNotEmpty) {
        visible.add(section.copyWith(reports: matches));
      }
    }
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleSections;
    final isSearching = _query.trim().isNotEmpty;

    final directory = ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ReportSearchField(
          controller: _searchController,
          query: _query,
          onChanged: (value) => setState(() => _query = value),
          onClear: () {
            _searchController.clear();
            setState(() => _query = '');
          },
        ),
        const SizedBox(height: 16),
        if (visible.isEmpty)
          _EmptySearchState(query: _query)
        else
          for (final section in visible) ...[
            _ReportSectionTile(
              key: ValueKey(
                '${section.categoryTitle}-${isSearching ? _query : ''}',
              ),
              section: section,
              forceExpanded: isSearching,
            ),
            const SizedBox(height: 12),
          ],
      ],
    );

    if (widget.embedded) {
      return ColoredBox(
        color: AppColors.pageBackground,
        child: SafeArea(top: false, child: directory),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      drawer: const MarketAppDrawer(selectedItem: 'Home'),
      body: SafeArea(
        child: Column(
          children: [
            const _ReportsCatalogHeader(),
            Expanded(child: directory),
          ],
        ),
      ),
    );
  }
}

class _ReportSearchField extends StatelessWidget {
  const _ReportSearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: _ink,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Search ${posReports.length} reports',
          hintStyle: const TextStyle(
            color: Color(0xFF9AA3B2),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _muted,
            size: 21,
          ),
          suffixIcon: query.isNotEmpty
              ? IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _muted,
                    size: 19,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.textLight,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No reports found',
            style: AppTypography.bodyMain.copyWith(
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nothing matches "$query". Try another keyword.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: _muted),
          ),
        ],
      ),
    );
  }
}

List<_ReportSection> _buildSections() {
  final grouped = <ReportGroup, List<PosReport>>{};
  for (final report in posReports) {
    grouped.putIfAbsent(report.group, () => []).add(report);
  }

  return [
    for (final group in ReportGroup.values)
      if ((grouped[group] ?? const <PosReport>[]).isNotEmpty)
        _ReportSection(
          categoryTitle: group.label,
          accent: _accentFor(group),
          soft: _softFor(group),
          icon: _iconFor(group),
          reports: [
            for (final report in grouped[group]!)
              _ReportItem(
                report: report,
                title: report.title,
                subtitle: _subtitleFor(group),
              ),
          ],
          initiallyExpanded: group == ReportGroup.graphical,
        ),
  ];
}

Color _accentFor(ReportGroup group) {
  return switch (group) {
    ReportGroup.graphical => AppColors.primary,
    ReportGroup.summary => AppColors.ink,
    ReportGroup.detailed => AppColors.danger,
    ReportGroup.inventory => const Color(0xFF111111),
    ReportGroup.accounting => const Color(0xFF111111),
    ReportGroup.operations => AppColors.textMuted,
  };
}

Color _softFor(ReportGroup group) {
  return switch (group) {
    ReportGroup.graphical => const Color(0xFFF3F4F6),
    ReportGroup.summary => const Color(0xFFF3F4F6),
    ReportGroup.detailed => AppColors.dangerLight,
    ReportGroup.inventory => const Color(0xFFF3F4F6),
    ReportGroup.accounting => const Color(0xFFF3F4F6),
    ReportGroup.operations => const Color(0xFFF3F4F6),
  };
}

IconData _iconFor(ReportGroup group) {
  return switch (group) {
    ReportGroup.graphical => Icons.bar_chart_rounded,
    ReportGroup.summary => Icons.list_alt_rounded,
    ReportGroup.detailed => Icons.description_outlined,
    ReportGroup.inventory => Icons.inventory_2_outlined,
    ReportGroup.accounting => Icons.account_balance_outlined,
    ReportGroup.operations => Icons.insights_rounded,
  };
}

String _subtitleFor(ReportGroup group) {
  return switch (group) {
    ReportGroup.graphical => 'Visual chart overview',
    ReportGroup.summary => 'Totals and summary metrics',
    ReportGroup.detailed => 'Row-level transaction detail',
    ReportGroup.inventory => 'Stock levels and valuation',
    ReportGroup.accounting => 'Financial statements and reconciliation',
    ReportGroup.operations => 'TrackMauzo operational insight',
  };
}

class _ReportsCatalogHeader extends StatelessWidget {
  const _ReportsCatalogHeader();

  @override
  Widget build(BuildContext context) {
    return MarketPageHeader(
      title: 'Reports',
      titleSize: 21,
      showBackButton: false,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.ink,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _ReportSectionTile extends StatelessWidget {
  const _ReportSectionTile({
    super.key,
    required this.section,
    required this.forceExpanded,
  });

  final _ReportSection section;
  final bool forceExpanded;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      borderColor: _border,
      radius: 14,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: forceExpanded || section.initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          iconColor: _muted,
          collapsedIconColor: _muted,
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: section.soft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(section.icon, color: section.accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.categoryTitle,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${section.reports.length} reports',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            if (section.reports.isNotEmpty) ...[
              const Divider(height: 1, color: _border),
              for (var index = 0; index < section.reports.length; index++) ...[
                _ReportListItem(
                  report: section.reports[index],
                  accent: section.accent,
                ),
                if (index != section.reports.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFF1F3F7),
                    indent: 60,
                    endIndent: 14,
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportListItem extends StatelessWidget {
  const _ReportListItem({required this.report, required this.accent});

  final _ReportItem report;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => PosReportPage(report: report.report),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            children: [
              Icon(
                Icons.insert_chart_outlined_rounded,
                color: accent,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      report.subtitle,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textLight,
                size: 20,
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
    required this.reports,
    this.initiallyExpanded = false,
  });

  final String categoryTitle;
  final Color accent;
  final Color soft;
  final IconData icon;
  final List<_ReportItem> reports;
  final bool initiallyExpanded;

  _ReportSection copyWith({List<_ReportItem>? reports}) {
    return _ReportSection(
      categoryTitle: categoryTitle,
      accent: accent,
      soft: soft,
      icon: icon,
      reports: reports ?? this.reports,
      initiallyExpanded: initiallyExpanded,
    );
  }
}

class _ReportItem {
  const _ReportItem({
    required this.report,
    required this.title,
    required this.subtitle,
  });

  final PosReport report;
  final String title;
  final String subtitle;
}
