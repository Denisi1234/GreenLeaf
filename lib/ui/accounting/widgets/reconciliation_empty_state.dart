import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.zero,
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t('No statement lines yet', 'Hakuna mistari ya taarifa bado'),
                textAlign: TextAlign.center,
                style: AppTypography.h2.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t(
                  'Add bank or mobile money transactions manually, or import CSV/Excel statements to reconcile against your sales and accounting records.',
                  'Ongeza miamala ya benki au mitandao ya simu wewe mwenyewe, au ingiza taarifa ya CSV/Excel ili kupatanisha na mauzo na vitabu vya hesabu.',
                ),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: MarketButton(
                      label: t('Add line', 'Ongeza mstari'),
                      icon: Icons.add_rounded,
                      radius: 0,
                      onTap: onAddLine,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: MarketButton(
                      label: t('Import statement', 'Ingiza taarifa'),
                      icon: Icons.upload_file_outlined,
                      isPrimary: false,
                      radius: 0,
                      onTap: onImport,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
