import 'package:flutter/material.dart';

import '../../../utils/currency_formatter.dart';
import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';

/// Clean operational KPI metrics for the Bank & Mobile Money Reconciliation module.
class BankReconciliationKpiMetrics extends StatelessWidget {
  const BankReconciliationKpiMetrics({
    super.key,
    required this.inflow,
    required this.outflow,
    required this.net,
    required this.matchedCount,
    required this.totalCount,
    required this.isSwahili,
  });

  final double inflow;
  final double outflow;
  final double net;
  final int matchedCount;
  final int totalCount;
  final bool isSwahili;

  static String _money(double value, {bool signed = false}) {
    final negative = value < 0;
    final abs = formatCurrency(value.abs());
    if (signed) {
      if (value > 0) return '+TSh $abs';
      if (value < 0) return '-TSh $abs';
      return 'TSh $abs';
    }
    return '${negative ? '-' : ''}TSh $abs';
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String sw) => isSwahili ? sw : en;
    final allMatched = totalCount > 0 && matchedCount == totalCount;

    return LayoutBuilder(
      builder: (context, metricConstraints) {
        final columns = metricConstraints.maxWidth >= 760 ? 4 : 2;
        final width =
            (metricConstraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Money in', 'Pesa zilizoingia'),
                value: _money(inflow),
                icon: Icons.arrow_downward_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFD1FAE5),
                color: const Color(0xFF047857),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Money out', 'Pesa zilizotoka'),
                value: _money(outflow),
                icon: Icons.arrow_upward_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFFEE2E2),
                color: const Color(0xFFB91C1C),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Net movement', 'Mabadiliko halisi'),
                value: _money(net, signed: true),
                icon: Icons.swap_vert_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: net >= 0 ? const Color(0xFFE0F2FE) : const Color(0xFFFFEDD5),
                color: net >= 0 ? const Color(0xFF0369A1) : const Color(0xFFC2410C),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Matched / total', 'Zimeoanishwa / jumla'),
                value: '$matchedCount / $totalCount',
                icon: allMatched ? Icons.check_circle_outline : Icons.sync_problem_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: allMatched
                    ? const Color(0xFFDCFCE7)
                    : (matchedCount == 0 && totalCount > 0
                        ? const Color(0xFFF3F4F6)
                        : const Color(0xFFFEF3C7)),
                color: allMatched
                    ? const Color(0xFF15803D)
                    : (matchedCount == 0 && totalCount > 0
                        ? const Color(0xFF4B5563)
                        : const Color(0xFFB45309)),
              ),
            ),
          ],
        );
      },
    );
  }
}
