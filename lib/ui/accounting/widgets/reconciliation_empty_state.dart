import 'package:flutter/material.dart';

import '../../widgets/market_shared_widgets.dart';

/// Clean, professional centered empty state for Bank & Mobile Money Reconciliation.
class ReconciliationEmptyState extends StatelessWidget {
  const ReconciliationEmptyState({
    super.key,
    required this.isSwahili,
    required this.onAddLine,
    required this.onImport,
  });

  final bool isSwahili;
  final VoidCallback onAddLine;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    String t(String en, String sw) => isSwahili ? sw : en;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: MarketEmptyState(
          icon: Icons.account_balance_outlined,
          title: t('No statement lines yet', 'Hakuna mistari ya taarifa bado'),
          message: t(
            'Add bank or mobile money transactions manually, or import CSV/Excel statements to reconcile against your sales and accounting records.',
            'Ongeza miamala ya benki au mitandao ya simu wewe mwenyewe, au ingiza taarifa ya CSV/Excel ili kupatanisha na mauzo na vitabu vya hesabu.',
          ),
          actionLabel: t('Add line', 'Ongeza mstari'),
          actionIcon: Icons.add_rounded,
          onAction: onAddLine,
          secondaryActionLabel: t('Import statement', 'Ingiza taarifa'),
          secondaryActionIcon: Icons.upload_file_outlined,
          onSecondaryAction: onImport,
        ),
      ),
    );
  }
}
