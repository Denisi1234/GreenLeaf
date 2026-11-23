import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: MarketEmptyState(
          showCard: false,
          icon: hasFilters
              ? Icons.filter_alt_off_outlined
              : Icons.insights_rounded,
          title: hasFilters
              ? context.tr('No matches found')
              : context.tr('No activity recorded yet'),
          message: hasFilters
              ? context.tr(
                  'We couldn\'t find any records matching your search or date criteria. Try adjusting or clearing your filters.',
                )
              : context.strings.paragraph(
                  note ??
                      'Transactions, entries, or activity for this period will appear here once recorded.',
                ),
          actionLabel: hasFilters
              ? context.tr('Reset all filters')
              : (setupAction != null ? context.tr(setupAction!.$2) : null),
          actionIcon: hasFilters ? Icons.refresh_rounded : setupAction?.$3,
          onAction: hasFilters
              ? onClearFilters
              : (setupAction != null
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => setupAction!.$1(),
                        ),
                      )
                  : null),
        ),
      ),
    );
  }
}
