import 'package:flutter/material.dart';
import 'package:track_mauzo/l10n/app_localization.dart';
import '../../widgets/workspace_widgets.dart';
import 'product_cards.dart';

class InventoryKpiMetrics extends StatelessWidget {
  const InventoryKpiMetrics({
    super.key,
    required this.totalItems,
    required this.stockValue,
    required this.lowCount,
    required this.outCount,
  });

  final int totalItems;
  final double stockValue;
  final int lowCount;
  final int outCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, metricConstraints) {
        final columns = metricConstraints.maxWidth >= 760 ? 4 : 2;
        final width = (metricConstraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: context.tr('Total items'),
                value: '',
                icon: Icons.inventory_2_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFFCE7F3),
                color: const Color(0xFFBE185D),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: context.tr('Stock value'),
                value: formatProductPrice(stockValue),
                icon: Icons.account_balance_wallet_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFE0F2FE),
                color: const Color(0xFF0369A1),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: context.tr('Low stock'),
                value: '',
                icon: Icons.trending_down_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFFEF3C7),
                color: const Color(0xFFB45309),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: context.tr('Out of stock'),
                value: '',
                icon: Icons.inventory_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFFEE2E2),
                color: const Color(0xFFB91C1C),
              ),
            ),
          ],
        );
      },
    );
  }
}
