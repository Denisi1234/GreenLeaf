import 'package:aza_pos/l10n/app_localization.dart';
import '../../widgets/app_design.dart';
import '../../widgets/common/market_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/report_models.dart';

class StockAlertCard extends StatelessWidget {
  const StockAlertCard({
    super.key,
    required this.items,
    this.onViewAll,
  });

  final List<StockAlertItem> items;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _emptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('Low Stock Alert'),
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  context.tr('View All'),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textBody,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceSecondary),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.surfaceSecondary,
                    indent: 16,
                    endIndent: 16,
                  ),
                _StockAlertRow(item: items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return MarketEmptyState(
      icon: Icons.check_circle_outline_rounded,
      iconColor: AppColors.success,
      iconBackgroundColor: AppColors.kpiSuccessBg,
      title: context.tr('All Stocked Up'),
      message: context.tr('No items are in the low-stock watchlist right now.'),
    );
  }
}

class _StockAlertRow extends StatelessWidget {
  const _StockAlertRow({required this.item});

  final StockAlertItem item;

  @override
  Widget build(BuildContext context) {
    final isHigh = item.severity == StockAlertSeverity.high;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  isHigh ? AppColors.dangerLight : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isHigh ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
              color: isHigh ? AppColors.danger : AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.category} • ${item.statusLabel}',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isHigh ? AppColors.dangerLight : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.statusLabel,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isHigh ? AppColors.danger : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
