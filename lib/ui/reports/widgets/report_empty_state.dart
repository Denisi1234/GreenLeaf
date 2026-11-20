import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

class ReportEmptyState extends StatelessWidget {
  const ReportEmptyState({
    super.key,
    required this.hasFilters,
    this.note,
    this.setupAction,
    required this.onClearFilters,
  });

  final bool hasFilters;
  final String? note;
  final (Widget Function(), String, IconData)? setupAction;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.zero,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Center(
                    child: Icon(
                      hasFilters
                          ? Icons.filter_alt_off_outlined
                          : Icons.insights_rounded,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  hasFilters
                      ? 'No matches found'
                      : 'No activity recorded yet',
                  style: AppTypography.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasFilters
                      ? 'We couldn\'t find any records matching your search or date criteria. Try adjusting or clearing your filters.'
                      : (note ??
                          'Transactions, entries, or activity for this period will appear here once recorded.'),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (hasFilters) ...[
                  MarketButton.secondary(
                    label: 'Reset all filters',
                    icon: Icons.refresh_rounded,
                    isFullWidth: false,
                    onTap: onClearFilters,
                    height: 42,
                  ),
                ] else if (setupAction != null) ...[
                  MarketButton.primary(
                    label: setupAction!.$2,
                    icon: setupAction!.$3,
                    isFullWidth: false,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => setupAction!.$1(),
                      ),
                    ),
                    height: 44,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
