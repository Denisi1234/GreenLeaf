import 'package:flutter/material.dart';

import '../../../utils/currency_formatter.dart';
import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';

/// KPI operational cards for Trial Balance in the Accounts & Ledger module.
class TrialBalanceKpiMetrics extends StatelessWidget {
  const TrialBalanceKpiMetrics({
    super.key,
    required this.totalDebit,
    required this.totalCredit,
    required this.isSwahili,
  });

  final double totalDebit;
  final double totalCredit;
  final bool isSwahili;

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    String t(String en, String sw) => isSwahili ? sw : en;
    final balanced = (totalDebit - totalCredit).abs() < 0.01;

    return LayoutBuilder(
      builder: (context, metricConstraints) {
        final columns = metricConstraints.maxWidth >= 760 ? 3 : 1;
        final width =
            (metricConstraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Total debit', 'Jumla ya deni'),
                value: _money(totalDebit),
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
                label: t('Total credit', 'Jumla ya mkopo'),
                value: _money(totalCredit),
                icon: Icons.credit_score_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFFEF3C7),
                color: const Color(0xFFB45309),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Trial balance status', 'Hali ya mizania'),
                value: balanced
                    ? t('Balanced', 'Imelingana')
                    : t('Discrepancy', 'Tofauti'),
                icon: balanced
                    ? Icons.check_circle_outline_rounded
                    : Icons.warning_amber_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: balanced
                    ? const Color(0xFFD1FAE5)
                    : const Color(0xFFFEE2E2),
                color: balanced
                    ? const Color(0xFF047857)
                    : const Color(0xFFB91C1C),
              ),
            ),
          ],
        );
      },
    );
  }
}
