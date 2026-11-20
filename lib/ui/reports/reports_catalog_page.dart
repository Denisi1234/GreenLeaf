import 'package:track_mauzo/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'enhanced_report_page.dart';
import 'pos_report_catalog.dart';

/// One directory entry per report, grouped by its declared report type.
class ReportsCatalogPage extends StatefulWidget {
  const ReportsCatalogPage({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<ReportsCatalogPage> createState() => _ReportsCatalogPageState();
}

class _ReportsCatalogPageState extends State<ReportsCatalogPage> {
  final _searchController = TextEditingController();
  String _query = '';
  ReportGroup? _group;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final reports = posReports
        .where((report) =>
            (_group == null || report.group == _group) &&
            (query.isEmpty ||
                '${report.title} ${report.group.label} ${context.tr(report.title)} ${context.tr(report.group.label)}'
                    .toLowerCase()
                    .contains(query)))
        .toList();
    final groups = ReportGroup.values
        .where((group) => reports.any((report) => report.group == group))
        .toList();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title:  Text(context.tr('Reports'))),
      body: SafeArea(
          top: false,
          child: LayoutBuilder(builder: (context, constraints) {
            final padding = constraints.maxWidth >= 900 ? 24.0 : 16.0;
            return CustomScrollView(slivers: [
              SliverPadding(
                  padding: EdgeInsets.all(padding),
                  sliver: SliverList.list(children: [
                    MarketSearchField(
                      controller: _searchController,
                      hintText: context.tr('Find a report'),
                      onChanged: (value) => setState(() => _query = value),
                      onClear: () => setState(() {
                        _searchController.clear();
                        _query = '';
                      }),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                  label:  Text(context.tr('All reports')),
                                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  selected: _group == null,
                                  onSelected: (_) =>
                                      setState(() => _group = null))),
                          for (final group in ReportGroup.values)
                            Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                    label: Text(context.tr(_groupTitle(group))),
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                    selected: _group == group,
                                    onSelected: (_) =>
                                        setState(() => _group = group))),
                        ])),
                    const SizedBox(height: 24),
                    if (reports.isEmpty)
                      WorkspacePanel(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(children: [
                                const Icon(Icons.search_off_rounded,
                                    color: AppColors.textMuted, size: 36),
                                const SizedBox(height: 16),
                                Text(context.tr('No matching reports'),
                                    style: AppTypography.h3),
                                const SizedBox(height: 8),
                                 Text(
                                    context.tr('Try another search or clear your filters.')),
                                const SizedBox(height: 16),
                                TextButton(
                                    onPressed: () => setState(() {
                                          _searchController.clear();
                                          _query = '';
                                          _group = null;
                                        }),
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppColors.dangerDeep),
                                    child:  Text(context.tr('Clear filters'))),
                              ])))
                    else
                      LayoutBuilder(builder: (context, panelConstraints) {
                        final columns = panelConstraints.maxWidth >= 1250
                            ? 3
                            : panelConstraints.maxWidth >= 760
                                ? 2
                                : 1;
                        final width =
                            (panelConstraints.maxWidth - (columns - 1) * 20) /
                                columns;
                        return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var column = 0;
                                  column < columns;
                                  column++) ...[
                                if (column > 0) const SizedBox(width: 20),
                                SizedBox(
                                    width: width,
                                    child: Column(children: [
                                      for (var index = column;
                                          index < groups.length;
                                          index += columns)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 20),
                                          child: _ReportGroupCard(
                                              group: groups[index],
                                              reports: reports
                                                  .where((report) =>
                                                      report.group ==
                                                      groups[index])
                                                  .toList()),
                                        ),
                                    ])),
                              ],
                            ]);
                      }),
                  ])),
            ]);
          })),
    );
  }
}

String _groupTitle(ReportGroup group) => switch (group) {
      ReportGroup.graphical => 'Charts',
      ReportGroup.summary => 'Summary',
      ReportGroup.detailed => 'Detailed',
      ReportGroup.inventory => 'Inventory',
      ReportGroup.accounting => 'Accounting & register',
      ReportGroup.operations => 'Operations',
      ReportGroup.multiStore => 'Multi-store',
    };

IconData _groupIcon(ReportGroup group) => switch (group) {
      ReportGroup.graphical => Icons.bar_chart_rounded,
      ReportGroup.summary => Icons.summarize_outlined,
      ReportGroup.detailed => Icons.table_rows_outlined,
      ReportGroup.inventory => Icons.inventory_2_outlined,
      ReportGroup.accounting => Icons.account_balance_outlined,
      ReportGroup.operations => Icons.insights_outlined,
      ReportGroup.multiStore => Icons.storefront_outlined,
    };

Color _groupColor(ReportGroup group) => switch (group) {
      ReportGroup.graphical => const Color(0xFF0369A1), // Sky
      ReportGroup.summary => const Color(0xFF047857), // Emerald
      ReportGroup.detailed => const Color(0xFF7E22CE), // Purple
      ReportGroup.inventory => const Color(0xFFB45309), // Amber
      ReportGroup.accounting => const Color(0xFF0D9488), // Teal
      ReportGroup.operations => const Color(0xFFC2410C), // Orange
      ReportGroup.multiStore => const Color(0xFFBE185D), // Rose
    };

Color _groupBackground(ReportGroup group) => switch (group) {
      ReportGroup.graphical => const Color(0xFFE0F2FE),
      ReportGroup.summary => const Color(0xFFD1FAE5),
      ReportGroup.detailed => const Color(0xFFF3E8FF),
      ReportGroup.inventory => const Color(0xFFFEF3C7),
      ReportGroup.accounting => const Color(0xFFCCFBF1),
      ReportGroup.operations => const Color(0xFFFFEDD5),
      ReportGroup.multiStore => const Color(0xFFFCE7F3),
    };

class _ReportGroupCard extends StatelessWidget {
  const _ReportGroupCard({required this.group, required this.reports});
  final ReportGroup group;
  final List<PosReport> reports;

  @override
  Widget build(BuildContext context) {
    final groupColor = _groupColor(group);
    final groupBg = _groupBackground(group);

    return WorkspacePanel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: groupBg,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.zero,
                  ),
                  alignment: Alignment.center,
                  child: Icon(_groupIcon(group), size: 18, color: groupColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(_groupTitle(group)),
                    style: AppTypography.sectionHeader.copyWith(
                      color: groupColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var index = 0; index < reports.length; index++) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.borderLight),
            Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('report-${reports[index].title}'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EnhancedReportPage(report: reports[index]),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr(reports[index].title),
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
