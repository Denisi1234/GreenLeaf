import 'package:flutter/material.dart';
import '../../../utils/currency_formatter.dart';
import '../../business_category_config.dart';
import '../../widgets/app_design.dart';

class PaymentCashReceivedSheet extends StatefulWidget {
  const PaymentCashReceivedSheet({
    super.key,
    required this.grandTotal,
    required this.category,
    this.currentAmount,
  });

  final double grandTotal;
  final BusinessCategory category;
  final double? currentAmount;

  static Future<double?> show(
    BuildContext context, {
    required double grandTotal,
    required BusinessCategory category,
    double? currentAmount,
  }) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentCashReceivedSheet(
        grandTotal: grandTotal,
        category: category,
        currentAmount: currentAmount,
      ),
    );
  }

  @override
  State<PaymentCashReceivedSheet> createState() =>
      _PaymentCashReceivedSheetState();
}

class _PaymentCashReceivedSheetState extends State<PaymentCashReceivedSheet> {
  late final TextEditingController _controller;
  double _currentInput = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentAmount != null
          ? widget.currentAmount!.round().toString()
          : '',
    );
    _currentInput = widget.currentAmount ?? 0;
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
    final remaining =
        (widget.grandTotal - _currentInput).clamp(0.0, double.infinity);
    final change =
        (_currentInput - widget.grandTotal).clamp(0.0, double.infinity);
    final suggestions = <double>{
      widget.grandTotal,
      (widget.grandTotal / 1000).ceil() * 1000.0,
      (widget.grandTotal / 5000).ceil() * 5000.0,
      (widget.grandTotal / 10000).ceil() * 10000.0
    }.toList()
      ..sort();

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
                Text('Cash received', style: AppTypography.h2),
                const SizedBox(height: 6),
                Text('Enter the amount handed to you by the customer.',
                    style: AppTypography.bodySmall),
                const SizedBox(height: 24),
                TextField(
                  key: const ValueKey('cash-amount'),
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  onChanged: (value) =>
                      setState(() => _currentInput = _parseAmount(value)),
                  style: AppTypography.h2,
                  decoration: const InputDecoration(
                    labelText: 'Amount received',
                    prefixText: 'TSh ',
                    hintText: '0',
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final amount in suggestions)
                      ActionChip(
                        label: Text(amount == widget.grandTotal
                            ? 'Exact amount'
                            : 'TSh ${_format(amount)}'),
                        onPressed: () => setState(() {
                          _currentInput = amount;
                          _controller.text = amount.toStringAsFixed(0);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _CashSummaryRow(
                  label: 'Total due',
                  value: 'TSh ${_format(widget.grandTotal)}',
                  valueColor: AppColors.ink,
                ),
                const SizedBox(height: 16),
                _CashSummaryRow(
                  label: remaining > 0 ? 'Still to receive' : 'Change due',
                  value: 'TSh ${_format(remaining > 0 ? remaining : change)}',
                  valueColor: remaining > 0
                      ? AppColors.dangerDeep
                      : AppColors.successDeep,
                  isBold: true,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('confirm-cash'),
                  onPressed: _currentInput >= widget.grandTotal
                      ? () => Navigator.pop(context, _currentInput)
                      : null,
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.successDeep),
                  child: const Text('Confirm cash amount'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CashSummaryRow extends StatelessWidget {
  const _CashSummaryRow({
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
