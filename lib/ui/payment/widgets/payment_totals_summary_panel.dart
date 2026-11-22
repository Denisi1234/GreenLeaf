import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import '../../../service/pos_suspended_sale_model.dart';
import '../../business_category_config.dart';
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
    this.onAddDiscount,
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
  final VoidCallback? onAddDiscount;
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
          Text(context.tr('Sale summary'), style: AppTypography.sectionHeader),
          const SizedBox(height: 4),
          Text(context.tr('{p0} items • {p1} units', args: {'p0': itemTypes, 'p1': unitCount}),
              style: AppTypography.label),
          const SizedBox(height: 20),
          _PaymentSummaryRow(
              label: context.tr('Subtotal'),
              value: 'TSh $subtotal',
              valueColor: AppColors.ink),
          const SizedBox(height: 10),
          _PaymentSummaryRow(
              label: context.tr('Tax'), value: 'TSh $tax', valueColor: AppColors.textBody),
          if (discount != null) ...[
            const SizedBox(height: 10),
            _PaymentSummaryRow(
                label: context.tr('Discount'),
                value: '− TSh $discount',
                valueColor: AppColors.successDeep),
          ],
          Divider(height: 32, color: AppColors.border),
          Text(context.tr('Total due'), style: AppTypography.label),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr('TSh {p0}', args: {'p0': grandTotal}),
                style: AppTypography.h1.copyWith(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (onAddDiscount != null || discount != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (onAddDiscount != null)
                  OutlinedButton.icon(
                    onPressed: onAddDiscount,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.kpiAmberBg,
                      foregroundColor: AppColors.kpiAmber,
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppCorners.control,
                      ),
                    ),
                    icon: const Icon(Icons.discount_outlined, size: 18),
                    label: Text(
                      discount == null
                          ? context.tr('Add discount')
                          : context.tr('Edit discount'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                if (discount != null)
                  IconButton(
                    tooltip: context.tr('Remove discount'),
                    onPressed: onRemoveDiscount,
                    icon: Icon(Icons.close_rounded,
                        color: AppColors.dangerDeep),
                  ),
              ],
            ),
          Divider(height: 32, color: AppColors.border),
          Text(context.tr('Payment method'), style: AppTypography.sectionHeader),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final method in ['Cash', 'Card', 'Mobile Money'])
                ChoiceChip(
                  label: Text(context.tr(method)),
                  avatar: Icon(
                    switch (method) {
                      'Cash' => Icons.payments_outlined,
                      'Card' => Icons.credit_card_outlined,
                      _ => Icons.phone_android_rounded
                    },
                    size: 17,
                    color: paymentMethod == method
                        ? Colors.white
                        : AppColors.textMuted,
                  ),
                  selected: paymentMethod == method,
                  onSelected: (_) => onMethodChanged(method),
                  showCheckmark: false,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.pageBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  side: BorderSide.none,
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: paymentMethod == method
                        ? Colors.white
                        : AppColors.textBody,
                    fontWeight: paymentMethod == method
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (paymentMethod == 'Cash') ...[
            OutlinedButton.icon(
              onPressed: onEnterCash,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.kpiSkyBg,
                foregroundColor: AppColors.kpiSky,
                side: BorderSide.none,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              icon: const Icon(Icons.payments_outlined, size: 19),
              label: Text(
                cashReceived == null
                    ? context.tr('Enter cash received')
                    : context.tr('Cash received: TSh {p0}',
                        args: {'p0': cashReceived}),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton(
              onPressed: onExactCash,
              child: Text(
                context.tr('Use exact amount'),
                style: TextStyle(
                  color: AppColors.kpiSky,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (cashReceived != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.kpiSuccessBg,
                  borderRadius: BorderRadius.circular(AppRadius.standard),
                ),
                child: _PaymentSummaryRow(
                  label: context.tr('Change due'),
                  value: 'TSh ${changeDue ?? '0'}',
                  valueColor: AppColors.kpiSuccess,
                  isBold: true,
                ),
              ),
          ] else
            Text(
              context.tr(
                  'Confirm the {p0} payment on your terminal or phone before completing this sale.',
                  args: {'p0': paymentMethod}),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted, height: 1.5),
            ),
          Divider(height: 32, color: AppColors.border),
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
            style: TextButton.styleFrom(
              backgroundColor: AppColors.kpiVioletBg,
              foregroundColor: AppColors.kpiViolet,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            icon: const Icon(Icons.person_outline_rounded, size: 19),
            label: Text(
              context.tr('Record as customer credit'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
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
