import 'package:track_mauzo/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import '../../../service/pos_suspended_sale_model.dart';
import '../../../utils/currency_formatter.dart';
import '../../widgets/app_design.dart';

class PaymentSplitSection extends StatelessWidget {
  const PaymentSplitSection({
    super.key,
    required this.splitPayments,
    required this.remainingDue,
    required this.currentMethod,
    required this.onAddSplit,
    required this.onRemoveSplit,
  });

  final List<SplitPaymentEntry> splitPayments;
  final double remainingDue;
  final String currentMethod;
  final void Function(String method, double amount) onAddSplit;
  final void Function(int index) onRemoveSplit;

  Future<void> _showAddSplitDialog(BuildContext context) async {
    final controller =
        TextEditingController(text: remainingDue.toStringAsFixed(0));
    String method = currentMethod;

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title:  Text(context.tr('Add Payment Split')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration:  InputDecoration(labelText: context.tr('Payment method')),
                items:  [
                  DropdownMenuItem(value: 'Cash', child: Text(context.tr('Cash'))),
                  DropdownMenuItem(
                      value: 'Mobile Money',
                      child: Text(context.tr('M-Pesa / Mobile Money'))),
                  DropdownMenuItem(value: 'Card', child: Text(context.tr('Card / Bank'))),
                ],
                onChanged: (val) => setDlgState(() => method = val ?? 'Cash'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration:  InputDecoration(
                  labelText: context.tr('Amount (TSh)'),
                  prefixText: 'TSh ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:  Text(context.tr('Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.successDeep),
              child:  Text(context.tr('Add Tender')),
            ),
          ],
        ),
      ),
    );

    if (added == true) {
      final amt = double.tryParse(controller.text.trim()) ?? 0;
      if (amt > 0) onAddSplit(method, amt);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr('Split payments ({p0})', args: {'p0': splitPayments.length}),
                style: AppTypography.sectionHeader,
              ),
            ),
            TextButton.icon(
              onPressed: remainingDue <= 0
                  ? null
                  : () => _showAddSplitDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label:  Text(context.tr('Add Split')),
            ),
          ],
        ),
        if (splitPayments.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: splitPayments.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final p = splitPayments[idx];
                return ListTile(
                  dense: true,
                  title: Text(
                    p.method,
                    style: AppTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('TSh {p0}', args: {'p0': formatCurrency(p.amount)}),
                        style: AppTypography.bodySmall
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.danger),
                        onPressed: () => onRemoveSplit(idx),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(
                context.tr('Remaining balance due'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                context.tr('TSh {p0}', args: {'p0': formatCurrency(remainingDue)}),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: remainingDue > 0
                      ? AppColors.dangerDeep
                      : AppColors.successDeep,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
