import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import '../../../utils/currency_formatter.dart';
import '../../business_category_config.dart';
import '../../widgets/app_design.dart';

class PaymentDiscountSheet extends StatefulWidget {
  const PaymentDiscountSheet({
    super.key,
    required this.subtotal,
    required this.currentAmount,
    required this.category,
  });

  final double subtotal;
  final double currentAmount;
  final BusinessCategory category;

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required double subtotal,
    required double currentAmount,
    required BusinessCategory category,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentDiscountSheet(
        subtotal: subtotal,
        currentAmount: currentAmount,
        category: category,
      ),
    );
  }

  @override
  State<PaymentDiscountSheet> createState() => _PaymentDiscountSheetState();
}

class _PaymentDiscountSheetState extends State<PaymentDiscountSheet> {
  late final TextEditingController _controller;
  bool _isPercentage = false;
  double _currentInput = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentAmount > 0
          ? widget.currentAmount.round().toString()
          : '',
    );
    _currentInput = widget.currentAmount;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double value) => formatCurrency(value);

  double _parseAmount(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    return parsed != null && parsed.isFinite && parsed >= 0 ? parsed : 0;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = _currentInput.clamp(0.0, 100.0);
    final discount =
        (_isPercentage ? widget.subtotal * percentage / 100 : _currentInput)
            .clamp(0.0, widget.subtotal);

    return ConstrainedBox(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
      child: Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(context.tr('Sale discount'), style: AppTypography.h2),
                const SizedBox(height: 6),
                Text(context.tr('Apply a fixed amount or a percentage to this sale.'),
                    style: AppTypography.bodySmall),
                const SizedBox(height: 20),
                SegmentedButton<bool>(
                  segments:  [
                    ButtonSegment(value: false, label: Text(context.tr('Amount (TSh)'))),
                    ButtonSegment(value: true, label: Text(context.tr('Percentage')))
                  ],
                  selected: {_isPercentage},
                  onSelectionChanged: (value) =>
                      setState(() => _isPercentage = value.first),
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const ValueKey('discount-amount'),
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  onChanged: (value) =>
                      setState(() => _currentInput = _parseAmount(value)),
                  style: AppTypography.h2,
                  decoration: InputDecoration(
                    labelText: _isPercentage
                        ? context.tr('Discount percentage')
                        : context.tr('Discount amount'),
                    prefixText: _isPercentage ? null : 'TSh ',
                    suffixText: _isPercentage ? '%' : null,
                  ),
                ),
                const SizedBox(height: 24),
                _DiscountSummaryRow(
                  label: context.tr('Discount'),
                  value: 'TSh ${_format(discount)}',
                  valueColor: AppColors.successDeep,
                ),
                const SizedBox(height: 16),
                _DiscountSummaryRow(
                  label: context.tr('New total'),
                  value: 'TSh ${_format(widget.subtotal - discount)}',
                  valueColor: AppColors.ink,
                  isBold: true,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('apply-discount'),
                  onPressed: () => Navigator.pop(context, {
                    'amount': discount,
                    'label': _isPercentage
                        ? '${percentage.toStringAsFixed(0)}% Discount'
                        : 'Discount'
                  }),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppCorners.control,
                    ),
                  ),
                  child: Text(
                    context.tr('Apply discount'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscountSummaryRow extends StatelessWidget {
  const _DiscountSummaryRow({
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
