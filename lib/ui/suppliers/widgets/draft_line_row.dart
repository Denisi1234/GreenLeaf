import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../utils/currency_formatter.dart';
import '../../../utils/quantity_formatter.dart';
import '../../widgets/app_design.dart';
import '../add_receiving_line_page.dart';

String _money(double value) {
  final negative = value < 0;
  return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
}

class DraftLineRow extends StatelessWidget {
  const DraftLineRow({
    super.key,
    required this.index,
    required this.line,
    required this.isSwahili,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final DraftReceivingLine line;
  final bool isSwahili;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  InputDecoration _cellDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quantity = TextFormField(
      initialValue:
          line.quantity <= 0 ? '' : formatQuantity(line.quantity),
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
      ],
      decoration: _cellDecoration(
        line.unit.toLowerCase() == 'pcs' ? '' : line.unit,
      ).copyWith(labelText: isSwahili ? 'Idadi' : 'Quantity'),
      onChanged: (value) {
        line.quantity =
            roundQuantity(double.tryParse(value.trim().replaceAll(',', '')) ?? 0);
        onChanged();
      },
    );
    final cost = TextFormField(
      initialValue: line.unitCost <= 0 ? '' : line.unitCost.toStringAsFixed(0),
      textAlign: TextAlign.right,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _cellDecoration('TSh')
          .copyWith(labelText: isSwahili ? 'Gharama' : 'Unit cost'),
      onChanged: (value) {
        line.unitCost = double.tryParse(value.trim().replaceAll(',', '')) ?? 0;
        onChanged();
      },
    );
    final name = Text('$index. ${line.productName}',
        style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700));
    final remove = IconButton(
      tooltip: isSwahili ? 'Ondoa bidhaa' : 'Remove item',
      onPressed: onDelete,
      icon: const Icon(Icons.delete_outline_rounded,
          color: AppColors.dangerDeep, size: 20),
    );
    final total = Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(isSwahili ? 'Jumla' : 'Line total', style: AppTypography.label),
      const SizedBox(height: 4),
      Text(_money(line.total),
          style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700)),
    ]);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 580) {
          return Row(children: [
            Expanded(flex: 4, child: name),
            const SizedBox(width: 16),
            SizedBox(width: 85, child: quantity),
            const SizedBox(width: 12),
            SizedBox(width: 120, child: cost),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: total),
            const SizedBox(width: 8),
            remove,
          ]);
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: name), remove]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: quantity),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: cost)
          ]),
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: total),
        ]);
      }),
    );
  }
}
