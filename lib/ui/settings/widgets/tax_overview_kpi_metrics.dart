import 'package:flutter/material.dart';

import '../../../utils/currency_formatter.dart';
import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';

/// Clean operational KPI metrics for the Tax Settings & Overview screen.
class TaxOverviewKpiMetrics extends StatelessWidget {
  const TaxOverviewKpiMetrics({
    super.key,
    required this.taxableSales,
    required this.taxCollected,
    required this.taxRatePercent,
    required this.taxLabel,
    required this.isEnabled,
    required this.isSwahili,
  });

  final double taxableSales;
  final double taxCollected;
  final double taxRatePercent;
  final String taxLabel;
  final bool isEnabled;
  final bool isSwahili;

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String sw) => isSwahili ? sw : en;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 3 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Taxable sales', 'Mauzo yenye kodi'),
                value: _money(taxableSales),
                icon: Icons.receipt_long_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFE0F2FE),
                color: const Color(0xFF0369A1),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Tax collected', 'Kodi iliyokusanywa'),
                value: _money(taxCollected),
                icon: Icons.account_balance_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFD1FAE5),
                color: const Color(0xFF047857),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Active tax rate', 'Kiwango cha sasa cha kodi'),
                value: isEnabled
                    ? '$taxLabel ${taxRatePercent.toStringAsFixed(1)}%'
                    : t('Tax disabled', 'Kodi imezimwa'),
                icon: isEnabled ? Icons.percent_rounded : Icons.block_flipped,
                sharp: true,
                borderless: true,
                backgroundColor: isEnabled ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6),
                color: isEnabled ? const Color(0xFFB45309) : const Color(0xFF6B7280),
              ),
            ),
          ],
        );
      },
    );
  }
}
