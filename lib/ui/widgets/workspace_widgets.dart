import 'package:flutter/material.dart';

import 'app_design.dart';

/// Shared surfaces for operational screens. Color is reserved for status and
/// actions; content stays neutral so dense records remain easy to scan.
class WorkspacePanel extends StatelessWidget {
  const WorkspacePanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
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
      this.color = AppColors.ink});

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => WorkspacePanel(
        padding: const EdgeInsets.all(16),
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
