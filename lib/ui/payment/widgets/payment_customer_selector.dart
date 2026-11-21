import 'package:flutter/material.dart';
import 'package:track_mauzo/l10n/app_localization.dart';
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
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
        children: [
          const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('Customer'), style: AppTypography.label),
                const SizedBox(height: 3),
                Text(
                  selectedCustomer ?? context.tr('Walk-in customer'),
                  style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
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
            child: Text(selectedCustomer == null ? context.tr('Select') : context.tr('Change')),
          ),
        ],
      ),
      ),
    );
  }
}
