import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';
import '../../widgets/app_design.dart';

class PaymentCustomerSelector extends StatelessWidget {
  const PaymentCustomerSelector({
    super.key,
    required this.selectedCustomer,
    required this.savingSale,
    required this.onSelectCustomer,
    required this.onClearCustomer,
  });

  final String? selectedCustomer;
  final bool savingSale;
  final VoidCallback onSelectCustomer;
  final VoidCallback onClearCustomer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.kpiSkyBg,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.kpiSky,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('Customer'), style: AppTypography.label),
                  const SizedBox(height: 2),
                  Text(
                    selectedCustomer ?? context.tr('Walk-in customer'),
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (selectedCustomer != null)
              IconButton(
                tooltip: context.tr('Remove customer'),
                onPressed: savingSale ? null : onClearCustomer,
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            TextButton(
              onPressed: savingSale ? null : onSelectCustomer,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.kpiSkyBg,
                foregroundColor: AppColors.kpiSky,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                selectedCustomer == null
                    ? context.tr('Select')
                    : context.tr('Change'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
