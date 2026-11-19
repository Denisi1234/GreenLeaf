import 'package:flutter/material.dart';
import '../../models/product_item.dart';
import '../../widgets/app_design.dart';

class LineDiscountDialog extends StatefulWidget {
  const LineDiscountDialog({
    super.key,
    required this.line,
  });

  final OrderLineItem line;

  static Future<bool?> show(BuildContext context, OrderLineItem line) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => LineDiscountDialog(line: line),
    );
  }

  @override
  State<LineDiscountDialog> createState() => _LineDiscountDialogState();
}

class _LineDiscountDialogState extends State<LineDiscountDialog> {
  late final TextEditingController _priceCtrl;
  late final TextEditingController _discountCtrl;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(
      text: widget.line.unitPrice.toStringAsFixed(0),
    );
    _discountCtrl = TextEditingController(
      text: widget.line.discountPercent > 0
          ? widget.line.discountPercent.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.line.product.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Price Override per Unit (TSh)', style: AppTypography.label),
          const SizedBox(height: 6),
          TextField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: 'TSh ',
              hintText: widget.line.product.priceValue.toStringAsFixed(0),
            ),
          ),
          const SizedBox(height: 16),
          Text('Line Discount (%)', style: AppTypography.label),
          const SizedBox(height: 6),
          TextField(
            controller: _discountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              suffixText: '%',
              hintText: '0',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.line.customPrice = null;
            widget.line.discountPercent = 0.0;
            Navigator.pop(context, true);
          },
          child: const Text('Reset', style: TextStyle(color: AppColors.danger)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final overridePrice = double.tryParse(_priceCtrl.text.trim());
            final discountPct = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
            if (overridePrice != null && overridePrice > 0) {
              widget.line.customPrice = overridePrice;
            }
            widget.line.discountPercent = discountPct.clamp(0.0, 100.0);
            Navigator.pop(context, true);
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.successDeep),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
