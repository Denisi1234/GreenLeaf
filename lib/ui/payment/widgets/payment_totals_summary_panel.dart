import 'package:flutter/material.dart';
import '../../../service/pos_suspended_sale_model.dart';
import '../../../utils/currency_formatter.dart';
import '../../business_category_config.dart';
import '../../models/product_item.dart';
import '../../widgets/app_design.dart';
import 'payment_split_section.dart';

class PaymentTotalsSummaryPanel extends StatelessWidget {
  const PaymentTotalsSummaryPanel({
    super.key,
    required this.category,
    required this.subtotal,
    required this.tax,
    this.discount,
    required this.grandTotal,
    this.cashReceived,
    this.changeDue,
    required this.itemTypes,
    required this.unitCount,
    required this.onEnterCash,
    required this.onAddDiscount,
    required this.onRecordDebit,
    required this.paymentMethod,
    required this.onMethodChanged,
    required this.onExactCash,
    required this.onRemoveDiscount,
    required this.splitPayments,
    required this.remainingDue,
    required this.onAddSplit,
    required this.onRemoveSplit,
  });

  final BusinessCategory category;
  final String subtotal;
  final String tax;
  final String? discount;
  final String grandTotal;
  final String? cashReceived;
  final String? changeDue;
  final int itemTypes;
  final int unitCount;
  final VoidCallback onEnterCash;
  final VoidCallback onAddDiscount;
  final VoidCallback onRecordDebit;
  final String paymentMethod;
  final ValueChanged<String> onMethodChanged;
  final VoidCallback onExactCash;
  final VoidCallback onRemoveDiscount;
  final List<SplitPaymentEntry> splitPayments;
  final double remainingDue;
  final void Function(String method, double amount) onAddSplit;
  final void Function(int index) onRemoveSplit;

  static String summaryLabel(
    BusinessCategory category,
    int itemTypes,
    int unitCount,
  ) {
    return '$itemTypes Items | $unitCount Units';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sale summary', style: AppTypography.sectionHeader),
          const SizedBox(height: 4),
          Text(summaryLabel(category, itemTypes, unitCount),
              style: AppTypography.label),
          const SizedBox(height: 20),
          _PaymentSummaryRow(
              label: 'Subtotal',
              value: 'TSh $subtotal',
              valueColor: AppColors.ink),
          const SizedBox(height: 10),
          _PaymentSummaryRow(
              label: 'Tax', value: 'TSh $tax', valueColor: AppColors.textBody),
          if (discount != null) ...[
            const SizedBox(height: 10),
            _PaymentSummaryRow(
                label: 'Discount',
                value: '− TSh $discount',
                valueColor: AppColors.successDeep),
          ],
          const Divider(height: 32, color: AppColors.border),
          Text('Total due', style: AppTypography.label),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'TSh $grandTotal',
                style: AppTypography.h1.copyWith(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onAddDiscount,
                icon: const Icon(Icons.discount_outlined, size: 18),
                label:
                    Text(discount == null ? 'Add discount' : 'Edit discount'),
              ),
              if (discount != null)
                IconButton(
                  tooltip: 'Remove discount',
                  onPressed: onRemoveDiscount,
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.dangerDeep),
                ),
            ],
          ),
          const Divider(height: 32, color: AppColors.border),
          Text('Payment method', style: AppTypography.sectionHeader),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final method in ['Cash', 'Card', 'Mobile Money'])
                ChoiceChip(
                  label: Text(method),
                  avatar: Icon(
                    switch (method) {
                      'Cash' => Icons.payments_outlined,
                      'Card' => Icons.credit_card_outlined,
                      _ => Icons.phone_android_rounded
                    },
                    size: 17,
                  ),
                  selected: paymentMethod == method,
                  onSelected: (_) => onMethodChanged(method),
                  selectedColor: AppColors.successLight,
                  side: BorderSide(
                    color: paymentMethod == method
                        ? AppColors.successDeep
                        : AppColors.border,
                  ),
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: paymentMethod == method
                        ? AppColors.successDeep
                        : AppColors.textBody,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (paymentMethod == 'Cash') ...[
            OutlinedButton.icon(
              onPressed: onEnterCash,
              icon: const Icon(Icons.payments_outlined, size: 19),
              label: Text(cashReceived == null
                  ? 'Enter cash received'
                  : 'Cash received: TSh $cashReceived'),
            ),
            TextButton(
              onPressed: onExactCash,
              child: const Text('Use exact amount'),
            ),
            if (cashReceived != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successLight.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _PaymentSummaryRow(
                  label: 'Change due',
                  value: 'TSh ${changeDue ?? '0'}',
                  valueColor: AppColors.successDeep,
                  isBold: true,
                ),
              ),
          ] else
            Text(
              'Confirm the $paymentMethod payment on your terminal or phone before completing this sale.',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted, height: 1.5),
            ),
          const Divider(height: 32, color: AppColors.border),
          // Split payments component
          PaymentSplitSection(
            splitPayments: splitPayments,
            remainingDue: remainingDue,
            currentMethod: paymentMethod,
            onAddSplit: onAddSplit,
            onRemoveSplit: onRemoveSplit,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRecordDebit,
            icon: const Icon(Icons.person_outline_rounded, size: 19),
            label: const Text('Record as customer credit'),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryRow extends StatelessWidget {
  const _PaymentSummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }
}
