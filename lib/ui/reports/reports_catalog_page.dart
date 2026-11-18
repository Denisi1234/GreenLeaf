import 'package:flutter/material.dart';

import '../widgets/app_design.dart';
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
                '${report.title} ${report.group.label}'
                    .toLowerCase()
                    .contains(query)))
        .toList();
    final groups = ReportGroup.values
        .where((group) => reports.any((report) => report.group == group))
        .toList();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('Reports')),
      body: SafeArea(
          top: false,
          child: LayoutBuilder(builder: (context, constraints) {
            final padding = constraints.maxWidth >= 900 ? 24.0 : 16.0;
            return CustomScrollView(slivers: [
              SliverPadding(
                  padding: EdgeInsets.all(padding),
                  sliver: SliverList.list(children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Find a report',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => setState(() {
                                      _searchController.clear();
                                      _query = '';
                                    })),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                  label: const Text('All reports'),
                                  selected: _group == null,
                                  onSelected: (_) =>
                                      setState(() => _group = null))),
                          for (final group in ReportGroup.values)
                            Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                    label: Text(_groupTitle(group)),
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
                                Text('No matching reports',
                                    style: AppTypography.h3),
                                const SizedBox(height: 8),
                                const Text(
                                    'Try another search or clear your filters.'),
                                const SizedBox(height: 16),
                                TextButton(
                                    onPressed: () => setState(() {
                                          _searchController.clear();
                                          _query = '';
                                          _group = null;
                                        }),
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppColors.dangerDeep),
                                    child: const Text('Clear filters')),
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

class _ReportGroupCard extends StatelessWidget {
  const _ReportGroupCard({required this.group, required this.reports});
  final ReportGroup group;
  final List<PosReport> reports;

  @override
  Widget build(BuildContext context) => WorkspacePanel(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          color: AppColors.surfaceSecondary,
          child: Row(children: [
            Icon(_groupIcon(group), size: 20, color: AppColors.textBody),
            const SizedBox(width: 10),
            Expanded(
                child: Text(_groupTitle(group),
                    style: AppTypography.sectionHeader))
          ]),
        ),
        for (var index = 0; index < reports.length; index++) ...[
          if (index > 0) const Divider(height: 1, color: AppColors.borderLight),
          Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('report-${reports[index].title}'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) =>
                        EnhancedReportPage(report: reports[index]))),
                child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    child: Row(children: [
                      Expanded(
                          child: Text(reports[index].title,
                              style: AppTypography.bodyMedium)),
                      const SizedBox(width: 12),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.textMuted),
                    ])),
              )),
        ],
      ]));
}
