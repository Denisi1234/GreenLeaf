import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../../utils/currency_formatter.dart';
import '../../../utils/quantity_formatter.dart';
import '../../models/product_item.dart';
import '../../widgets/app_design.dart';

class MeasurementSaleSheet extends StatefulWidget {
  const MeasurementSaleSheet({
    super.key,
    required this.product,
    required this.availableStock,
    this.initialQuantity,
    this.initialCustomPrice,
  });

  final ProductItem product;
  final double availableStock;
  final double? initialQuantity;
  final double? initialCustomPrice;

  static Future<({double quantity, double? customPrice})?> show(
    BuildContext context, {
    required ProductItem product,
    required double availableStock,
    double? initialQuantity,
    double? initialCustomPrice,
  }) {
    return showModalBottomSheet<({double quantity, double? customPrice})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => MeasurementSaleSheet(
        product: product,
        availableStock: availableStock,
        initialQuantity: initialQuantity,
        initialCustomPrice: initialCustomPrice,
      ),
    );
  }

  @override
  State<MeasurementSaleSheet> createState() => _MeasurementSaleSheetState();
}

class _MeasurementSaleSheetState extends State<MeasurementSaleSheet> {
  static const List<double> _amountPresets = [500, 1000, 1500, 2000, 5000];

  late final TextEditingController _qtyController;
  late final TextEditingController _amountController;
  late final TextEditingController _customTotalController;
  bool _byAmountMode = false;
  bool _adjustTotalPrice = false;

  @override
  void initState() {
    super.initState();
    final defaultQty = widget.initialQuantity ??
        stepForUnit(widget.product.unit, true).clamp(0.001, widget.availableStock);
    final initQty = roundQuantity(defaultQty);
    _qtyController = TextEditingController(
      text: initQty > 0 ? formatQuantity(initQty) : '',
    );
    final initTotal = initQty * (widget.initialCustomPrice ?? widget.product.priceValue);
    _amountController = TextEditingController(
      text: initTotal > 0 ? initTotal.round().toString() : '',
    );
    _adjustTotalPrice = widget.initialCustomPrice != null;
    _customTotalController = TextEditingController(
      text: widget.initialCustomPrice != null && initQty > 0
          ? (initQty * widget.initialCustomPrice!).round().toString()
          : '',
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _amountController.dispose();
    _customTotalController.dispose();
    super.dispose();
  }

  double get _parsedQty {
    final raw = double.tryParse(_qtyController.text.trim().replaceAll(',', '')) ?? 0;
    return roundQuantity(raw);
  }

  double get _parsedAmount {
    return double.tryParse(_amountController.text.trim().replaceAll(',', '')) ?? 0;
  }

  double get _parsedCustomTotal {
    return double.tryParse(_customTotalController.text.trim().replaceAll(',', '')) ?? 0;
  }

  double get _effectiveQuantity {
    if (_byAmountMode) {
      final unitPrice = widget.product.priceValue;
      if (unitPrice <= 0 || _parsedAmount <= 0) return 0;
      return roundQuantity(_parsedAmount / unitPrice);
    }
    return _parsedQty;
  }

  double? get _effectiveCustomPrice {
    final qty = _effectiveQuantity;
    if (qty <= 0) return null;
    if (_byAmountMode) {
      final amount = _parsedAmount;
      if (amount <= 0) return null;
      final standard = qty * widget.product.priceValue;
      if ((standard - amount).abs() < 0.5) return null;
      return amount / qty;
    }
    if (_adjustTotalPrice && _parsedCustomTotal > 0) {
      final standard = qty * widget.product.priceValue;
      if ((standard - _parsedCustomTotal).abs() < 0.5) return null;
      return _parsedCustomTotal / qty;
    }
    return null;
  }

  double get _effectiveTotal {
    final qty = _effectiveQuantity;
    if (qty <= 0) return 0;
    if (_byAmountMode) return _parsedAmount > 0 ? _parsedAmount : 0;
    if (_adjustTotalPrice && _parsedCustomTotal > 0) return _parsedCustomTotal;
    return ((qty * widget.product.priceValue) * 100).round() / 100;
  }

  void _selectUnitPreset(double qty) {
    setState(() {
      _byAmountMode = false;
      _qtyController.text = formatQuantity(qty);
      if (_adjustTotalPrice) {
        _customTotalController.text =
            (qty * widget.product.priceValue).round().toString();
      }
    });
  }

  void _selectAmountPreset(double amount) {
    setState(() {
      _byAmountMode = true;
      _amountController.text = amount.round().toString();
    });
  }

  void _submit() {
    final qty = _effectiveQuantity;
    if (qty <= 0 || qty > widget.availableStock + 0.0001) return;
    Navigator.of(context).pop((
      quantity: qty,
      customPrice: _effectiveCustomPrice,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sw = context.strings.isSwahili;
    String t(String en, String swText) => sw ? swText : en;

    final unit = widget.product.unit.trim().isEmpty ? 'Pcs' : widget.product.unit.trim();
    final presets = measurementPresetsForUnit(unit);
    final qty = _effectiveQuantity;
    final total = _effectiveTotal;
    final remainingAfter =
        roundQuantity((widget.availableStock - qty).clamp(0.0, 1e12).toDouble());
    final exceedsStock = qty > widget.availableStock + 0.0001;
    final missingUnitPriceInAmountMode =
        _byAmountMode && widget.product.priceValue <= 0;
    final canSubmit =
        qty > 0 && !exceedsStock && !missingUnitPriceInAmountMode && total >= 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.extraRounded),
        ),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: AppTypography.sectionHeader.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'TSh ${formatCurrency(widget.product.priceValue)} / $unit • '
                          '${t('Available', 'Iliyopo')}: ${formatStockWithUnit(widget.availableStock, unit)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: t('Close', 'Funga'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ModeTabButton(
                      label: t('By weight ($unit)', 'Kwa kipimo ($unit)'),
                      selected: !_byAmountMode,
                      onTap: () => setState(() => _byAmountMode = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeTabButton(
                      label: t('By amount (TSh)', 'Kwa kiasi (TSh)'),
                      selected: _byAmountMode,
                      onTap: () => setState(() => _byAmountMode = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_byAmountMode) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final preset in presets)
                      _PresetChip(
                        label: sw ? preset.labelSw : preset.labelEn,
                        selected: (qty - preset.qty).abs() < 0.0005,
                        enabled: preset.qty <= widget.availableStock + 0.0001,
                        onTap: () => _selectUnitPreset(preset.qty),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('measurement-qty-input'),
                  controller: _qtyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: t('Quantity ($unit)', 'Kipimo ($unit)'),
                    hintText: '0.25',
                    suffixText: unit,
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: AppCorners.input,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppCorners.input,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppCorners.input,
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    setState(() {
                      _adjustTotalPrice = !_adjustTotalPrice;
                      if (_adjustTotalPrice && _customTotalController.text.isEmpty) {
                        final std = _parsedQty * widget.product.priceValue;
                        if (std > 0) {
                          _customTotalController.text = std.round().toString();
                        }
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          _adjustTotalPrice
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 18,
                          color: _adjustTotalPrice
                              ? AppColors.primaryDeep
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t(
                              'Adjust total price (optional rounding)',
                              'Rekebisha jumla ya bei (hiari)',
                            ),
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textBody,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_adjustTotalPrice) ...[
                  const SizedBox(height: 8),
                  TextField(
                    key: const ValueKey('measurement-custom-total-input'),
                    controller: _customTotalController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: t('Total price (TSh)', 'Jumla ya bei (TSh)'),
                      prefixText: 'TSh ',
                      hintText: (qty * widget.product.priceValue).round().toString(),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: AppCorners.input,
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppCorners.input,
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppCorners.input,
                        borderSide:
                            BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final amt in _amountPresets)
                      _PresetChip(
                        label: 'TSh ${formatCurrency(amt)}',
                        selected: (_parsedAmount - amt).abs() < 0.5,
                        enabled: widget.product.priceValue > 0 &&
                            roundQuantity(amt / widget.product.priceValue) <=
                                widget.availableStock + 0.0001,
                        onTap: () => _selectAmountPreset(amt),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('measurement-amount-input'),
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: t('Customer amount (TSh)', 'Kiasi cha mteja (TSh)'),
                    hintText: '1000',
                    prefixText: 'TSh ',
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: AppCorners.input,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppCorners.input,
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppCorners.input,
                      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(AppRadius.standard),
                  border: Border.all(
                    color: exceedsStock ? AppColors.danger : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t('Deduct from stock', 'Itakatwa stoo'),
                          style: AppTypography.label,
                        ),
                        Text(
                          formatStockWithUnit(qty, unit),
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t('Remaining stock', 'Salio la stoo'),
                          style: AppTypography.label,
                        ),
                        Text(
                          formatStockWithUnit(remainingAfter, unit),
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 14, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t('Line total', 'Jumla'),
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'TSh ${formatCurrency(total)}',
                          style: AppTypography.bodyMain.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (exceedsStock) ...[
                const SizedBox(height: 8),
                Text(
                  t(
                    'Only ${formatStockWithUnit(widget.availableStock, unit)} available in stock.',
                    'Imebaki ${formatStockWithUnit(widget.availableStock, unit)} tu stoo.',
                  ),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.dangerDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ] else if (missingUnitPriceInAmountMode) ...[
                const SizedBox(height: 8),
                Text(
                  t(
                    'Set a selling price per $unit on this item to sell by TSh amount.',
                    'Weka bei kwa $unit kwenye bidhaa hii ili kuuza kwa kiasi cha TSh.',
                  ),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.dangerDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                key: const ValueKey('measurement-add-button'),
                onPressed: canSubmit ? _submit : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  canSubmit
                      ? '${t('Add to cart', 'Weka kwenye kikapu')} • ${formatQtyForReceipt(qty, unit)} • TSh ${formatCurrency(total)}'
                      : t('Enter valid measurement', 'Weka kipimo sahihi'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  const _ModeTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.headerSurface : AppColors.pageBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppColors.primaryDeep : AppColors.textBody,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: !enabled
          ? AppColors.surfaceSecondary
          : selected
              ? AppColors.primary
              : AppColors.pageBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.standard),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: !enabled
                  ? AppColors.textLight
                  : selected
                      ? Colors.white
                      : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}
