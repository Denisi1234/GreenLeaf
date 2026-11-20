import 'package:flutter/material.dart';

import '../../../service/supplier_model.dart';
import '../../../utils/currency_formatter.dart';
import '../../widgets/app_design.dart';

class SupplierRow extends StatelessWidget {
  const SupplierRow({
    super.key,
    required this.supplier,
    required this.balance,
    required this.isSwahili,
    required this.onTap,
    required this.onReceive,
  });

  final Supplier supplier;
  final double balance;
  final bool isSwahili;
  final VoidCallback onTap;
  final VoidCallback onReceive;

  static String formatMoney(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    final contact = <String>[
      if (supplier.phone.trim().isNotEmpty) supplier.phone.trim(),
      if (supplier.email.trim().isNotEmpty) supplier.email.trim(),
    ].join(' • ');
    final hasBalance = balance > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 42,
              color: hasBalance ? AppColors.danger : AppColors.success,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    style: AppTypography.bodyMain
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (contact.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                  if (supplier.address.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      supplier.address.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textLight),
                    ),
                  ],
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onReceive,
                    child: Text(
                      isSwahili ? 'Pokea bidhaa' : 'Receive goods',
                      style: AppTypography.helperText.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isSwahili ? 'Deni' : 'Payable',
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  formatMoney(balance),
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: hasBalance ? AppColors.danger : AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
