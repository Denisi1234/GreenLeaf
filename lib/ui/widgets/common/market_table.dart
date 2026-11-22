import 'package:flutter/material.dart';

import '../app_design.dart';

class MarketTable extends StatelessWidget {
  const MarketTable({
    super.key,
    required this.columns,
    required this.rows,
    this.headerColor,
  });

  final List<String> columns;
  final List<List<Widget>> rows;
  final Color? headerColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: headerColor ?? AppColors.surfaceSecondary,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.standard)),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: columns
                .map((col) => Expanded(
                      child: Text(
                        col.toUpperCase(),
                        style: AppTypography.tableHeader,
                      ),
                    ))
                .toList(),
          ),
        ),
        // Rows
        ...rows.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          final isLast = index == rows.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                left: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
                bottom: BorderSide(
                  color: AppColors.border,
                  width: isLast ? 1 : 0.5,
                ),
              ),
              borderRadius: isLast
                  ? const BorderRadius.vertical(
                      bottom: Radius.circular(AppRadius.standard))
                  : null,
            ),
            child: Row(
              children: row.map((cell) => Expanded(child: cell)).toList(),
            ),
          );
        }),
      ],
    );
  }
}
