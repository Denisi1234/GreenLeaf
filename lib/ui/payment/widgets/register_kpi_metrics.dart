import 'package:flutter/material.dart';

import '../../../service/register_shift_model.dart';
import '../../../utils/currency_formatter.dart';
import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';

/// KPI metric grid for the open register shift.
/// Presents vital cash metrics in sharp, borderless operational cards.
class RegisterKpiMetrics extends StatelessWidget {
  const RegisterKpiMetrics({
    super.key,
    required this.summary,
    required this.salesCount,
    required this.isSwahili,
  });

  final CashUpSummary summary;
  final int salesCount;
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
        final columns = constraints.maxWidth >= 760 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Expected in drawer', 'Inayotarajiwa kazini'),
                value: _money(summary.expected),
                icon: Icons.account_balance_wallet_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: summary.expected >= 0
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFFEE2E2),
                color: summary.expected >= 0
                    ? const Color(0xFF047857)
                    : const Color(0xFFB91C1C),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Opening float', 'Pesa ya kuanzia'),
                value: _money(summary.openingFloat),
                icon: Icons.payments_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFE0F2FE),
                color: const Color(0xFF0369A1),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Cash sales', 'Mauzo ya taslimu'),
                value: _money(summary.cashSales),
                icon: Icons.point_of_sale_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFFEF3C7),
                color: const Color(0xFFB45309),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Shift transactions', 'Miamala ya zamu'),
                value: '$salesCount',
                icon: Icons.receipt_long_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFF3E8FF),
                color: const Color(0xFF7E22CE),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// KPI metric grid when the register shift is currently closed.
/// Shows lifetime / recent shift statistics.
class RegisterClosedKpiMetrics extends StatelessWidget {
  const RegisterClosedKpiMetrics({
    super.key,
    required this.shifts,
    required this.isSwahili,
    this.totalVariance = 0,
  });

  final List<RegisterShift> shifts;
  final bool isSwahili;
  final double totalVariance;

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String sw) => isSwahili ? sw : en;

    final closedShifts = shifts.where((s) => s.closedAt != null).toList();

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
                label: t('Status', 'Hali ya Kasha'),
                value: t('Closed', 'Limefungwa'),
                icon: Icons.lock_outline_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFF1F5F9),
                color: AppColors.ink,
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Completed shifts', 'Zamu zilizofungwa'),
                value: '${closedShifts.length}',
                icon: Icons.history_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFE0F2FE),
                color: const Color(0xFF0369A1),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Net cash discrepancy', 'Tofauti ya jumla'),
                value: _money(totalVariance),
                icon: Icons.balance_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: totalVariance == 0
                    ? const Color(0xFFD1FAE5)
                    : (totalVariance > 0
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFFEE2E2)),
                color: totalVariance == 0
                    ? const Color(0xFF047857)
                    : (totalVariance > 0
                        ? const Color(0xFFB45309)
                        : const Color(0xFFB91C1C)),
              ),
            ),
          ],
        );
      },
    );
  }
}
