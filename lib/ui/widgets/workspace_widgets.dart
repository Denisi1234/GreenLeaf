import 'package:flutter/material.dart';

import 'app_design.dart';

/// Shared surfaces for operational screens. Color is reserved for status and
/// actions; content stays neutral so dense records remain easy to scan.
class WorkspacePanel extends StatelessWidget {
  const WorkspacePanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20),
      this.sharp = false,
      this.borderless = false,
      this.backgroundColor});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool sharp;
  final bool borderless;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.surface,
          border: borderless ? null : Border.all(color: AppColors.border),
          borderRadius: sharp ? BorderRadius.zero : BorderRadius.circular(12),
        ),
        child: Padding(padding: padding, child: child),
      );
}

class WorkspaceHeading extends StatelessWidget {
  const WorkspaceHeading(
      {super.key, required this.title, required this.subtitle, this.action});

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.h2),
            const SizedBox(height: 4),
            Text(subtitle,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted)),
          ],
        );
        if (constraints.maxWidth < 520) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                if (action != null) ...[const SizedBox(height: 14), action!],
              ]);
        }
        return Row(children: [
          Expanded(child: text),
          if (action != null) ...[const SizedBox(width: 20), action!]
        ]);
      });
}

class WorkspaceMetric extends StatelessWidget {
  const WorkspaceMetric(
      {super.key,
      required this.label,
      required this.value,
      required this.icon,
      this.color = AppColors.ink,
      this.sharp = false,
      this.borderless = false,
      this.backgroundColor});

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool sharp;
  final bool borderless;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => WorkspacePanel(
        padding: const EdgeInsets.all(16),
        sharp: sharp,
        borderless: borderless,
        backgroundColor: backgroundColor,
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label, style: AppTypography.label),
                const SizedBox(height: 6),
                Text(value, style: AppTypography.h3.copyWith(color: color)),
              ])),
        ]),
      );
}

class WorkspaceStatus extends StatelessWidget {
  const WorkspaceStatus({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: AppTypography.label.copyWith(color: color)),
      );
}

/// Keeps operational pages and their forms at a comfortable reading width.
class ManagementViewport extends StatelessWidget {
  const ManagementViewport(
      {super.key, required this.child, this.maxWidth = 1280});
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// Shared desktop register; compact screens keep their task-specific cards.
class WorkspaceRegister extends StatefulWidget {
  const WorkspaceRegister(
      {super.key,
      required this.columns,
      required this.rows,
      required this.mobile});
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final Widget mobile;
  @override
  State<WorkspaceRegister> createState() => _WorkspaceRegisterState();
}

class _WorkspaceRegisterState extends State<WorkspaceRegister> {
  int _page = 0;
  static const _pageSize = 25;
  @override
  void didUpdateWidget(covariant WorkspaceRegister oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows.length != widget.rows.length) _page = 0;
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 800) return widget.mobile;
        final last =
            widget.rows.isEmpty ? 0 : (widget.rows.length - 1) ~/ _pageSize;
        final page = _page.clamp(0, last);
        final rows =
            widget.rows.skip(page * _pageSize).take(_pageSize).toList();
        return WorkspacePanel(
            padding: EdgeInsets.zero,
            child: Column(children: [
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columns: widget.columns,
                        rows: rows,
                        showCheckboxColumn: false,
                        headingRowColor: const WidgetStatePropertyAll(
                            AppColors.surfaceSecondary),
                        headingTextStyle: AppTypography.tableHeader,
                        dataTextStyle: AppTypography.bodySmall,
                        horizontalMargin: 20,
                        columnSpacing: 24,
                        dataRowMinHeight: 60,
                        dataRowMaxHeight: 80,
                      ))),
              if (widget.rows.length > _pageSize)
                Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      Expanded(
                          child: Text(
                              '${page * _pageSize + 1}–${page * _pageSize + rows.length} / ${widget.rows.length}',
                              style: AppTypography.label)),
                      IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .previousPageTooltip,
                          onPressed: page == 0
                              ? null
                              : () => setState(() => _page = page - 1),
                          icon: const Icon(Icons.chevron_left_rounded)),
                      IconButton(
                          tooltip:
                              MaterialLocalizations.of(context).nextPageTooltip,
                          onPressed: page == last
                              ? null
                              : () => setState(() => _page = page + 1),
                          icon: const Icon(Icons.chevron_right_rounded)),
                    ])),
            ]));
      });
}
