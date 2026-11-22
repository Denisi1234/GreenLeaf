import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../../utils/quantity_formatter.dart';

/// Whole-unit editing; measured products retain their measurement sale sheet.
class CartQuantityDialog extends StatefulWidget {
  const CartQuantityDialog(
      {super.key,
      required this.productName,
      required this.quantity,
      required this.available});

  final String productName;
  final double quantity;
  final double available;

  static Future<double?> show(
    BuildContext context, {
    required String productName,
    required double quantity,
    required double available,
  }) =>
      showDialog<double>(
          context: context,
          builder: (_) => CartQuantityDialog(
              productName: productName,
              quantity: quantity,
              available: available));

  @override
  State<CartQuantityDialog> createState() => _CartQuantityDialogState();
}

class _CartQuantityDialogState extends State<CartQuantityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller =
      TextEditingController(text: formatQuantity(widget.quantity));

  @override
  void initState() {
    super.initState();
    _controller.selection = TextSelection(
        baseOffset: 0, extentOffset: _controller.text.length);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(double.parse(_controller.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        title: Text(context.tr('Edit quantity')),
        content: SizedBox(
            width: 340,
            child: Form(
              key: _formKey,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.productName),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _save(),
                      decoration: InputDecoration(
                        labelText: context.tr('Quantity'),
                        helperText: context.tr('Available: {p0}',
                            args: {'p0': formatQuantity(widget.available)}),
                        errorMaxLines: 3,
                      ),
                      validator: (text) {
                        final value = double.tryParse(text?.trim() ?? '');
                        if (value == null ||
                            !value.isFinite ||
                            value <= 0 ||
                            value != value.roundToDouble()) {
                          return context
                              .tr('Enter a whole quantity greater than zero.');
                        }
                        if (value > widget.available + 0.0001) {
                          return context
                              .tr('Quantity exceeds available stock.');
                        }
                        return null;
                      },
                    ),
                  ]),
            )),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr('Cancel'))),
          FilledButton(
              onPressed: _save, child: Text(context.tr('Update quantity'))),
        ],
      );
}
