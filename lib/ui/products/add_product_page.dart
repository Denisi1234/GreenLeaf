import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/barcode_scan_service.dart';
import '../../service/pos_local_store.dart';
import '../../utils/quantity_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/app_theme_palette.dart';
import '../widgets/market_shared_widgets.dart';
import 'inventory_product_item.dart';
import 'widgets/add_product_controller.dart';
import 'widgets/product_form_fields.dart';

/// Fast, clean native Android/iOS Add/Edit Item form.
/// Shows only essential POS fields up front; barcode, measurement units,
/// expiry tracking, and item photo live under a collapsible Advanced options card.
class AddProductPage extends StatefulWidget {
  const AddProductPage({
    super.key,
    required this.nextCode,
    this.product,
  });

  final String nextCode;
  final InventoryProductItem? product;

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  late final AddProductController _controller;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _controller = AddProductController(
      context: context,
      nextCode: widget.nextCode,
      existingProduct: widget.product,
    );
    // Auto-expand Advanced options only when editing an item that already uses them.
    final p = widget.product;
    if (p != null) {
      final hasExpiry =
          (p.categoryData['expiry_date']?.toString().trim().isNotEmpty ??
              false);
      _showAdvanced = p.allowFractional ||
          p.unit.toLowerCase() != 'pcs' ||
          hasExpiry;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.expiryDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15, 12, 31),
      helpText: 'Select expiry date',
    );
    if (picked == null) return;
    setState(() {
      _controller.expiryDate = DateTime(picked.year, picked.month, picked.day);
      _controller.trackExpiry = true;
    });
  }

  Future<void> _scanBarcode() async {
    final code = await BarcodeScanService.instance.scan(context);
    if (code == null || !mounted) return;
    setState(() {
      _controller.codeController.text = code;
    });
  }

  Future<void> _deleteProduct() async {
    final product = widget.product;
    if (product == null) return;

    final confirmed = await showMarketConfirmDialog(
      context,
      title: context.tr('Delete Item?'),
      message: context.tr(
        'Are you sure you want to remove "{p0}"? This cannot be undone.',
        args: {'p0': product.name},
      ),
      confirmLabel: context.tr('Delete'),
      cancelLabel: context.tr('Cancel'),
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    await context.read<PosLocalStore>().removeProduct(product.code);
    if (!mounted) return;

    showMarketNotice(
      context,
      title: context.tr('Item Deleted'),
      message: context.tr('{p0} has been removed', args: {'p0': product.name}),
      type: MarketNoticeType.success,
    );
    Navigator.of(context).pop();
  }

  void _save() {
    final product = _controller.buildProduct();
    if (product != null) {
      Navigator.of(context).pop(product);
    }
  }

  InputDecoration _inputDecoration(
    AppThemePalette palette, {
    String? hint,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: palette.textMuted, fontSize: 14),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        color: palette.textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: palette.pageBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _controller.isEdit;
    final palette = AppThemePalette.of(context);
    final sw = context.strings.isSwahili;
    String t(String en, String swText) => sw ? swText : en;

    final unitOptions = <String>{
      ...kMeasurementUnits,
      _controller.selectedUnit,
    }.toList();
    final unit = _controller.selectedUnit;
    final showUnitSuffix = unit.toLowerCase() != 'pcs';
    final selectedCategory =
        _controller.categoryOptions.contains(_controller.selectedCategory)
            ? _controller.selectedCategory
            : (_controller.categoryOptions.isNotEmpty
                ? _controller.categoryOptions.first
                : null);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: Column(
        children: [
          MarketPageHeader(
            title: isEdit
                ? context.tr('Edit Item')
                : t('Add item', 'Ongeza bidhaa'),
            showBackButton: true,
            centerTitle: false,
            titleSize: 20,
            titleWeight: FontWeight.w800,
            showBorder: true,
            actions: [
              if (isEdit)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    size: 22,
                  ),
                  onPressed: _deleteProduct,
                  tooltip: context.tr('Delete Item'),
                ),
            ],
          ),
          Expanded(
            child: SafeArea(
              top: false,
              bottom: false,
              child: Form(
                key: _controller.formKey,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                      children: [
                        // 1. Essential Item Details (fast 5-second POS entry)
                        _GroupLabel(
                          t('ITEM DETAILS', 'TAARIFA ZA BIDHAA'),
                          palette,
                        ),
                        _NativeCard(
                          palette: palette,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _FieldLabel(
                                    '${context.tr('Item Name')} *',
                                    palette,
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _controller.nameController,
                                    style: TextStyle(
                                      color: palette.ink,
                                      fontSize: 15,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    decoration: _inputDecoration(
                                      palette,
                                      hint: context.tr(
                                        'e.g., White Rice 1kg, Coca-Cola 350ml',
                                      ),
                                    ),
                                    validator: (val) =>
                                        (val == null || val.trim().isEmpty)
                                            ? 'Item name is required'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FieldLabel(
                                              showUnitSuffix
                                                  ? '${context.tr('Sale Price')} ($unit) *'
                                                  : '${context.tr('Sale Price')} *',
                                              palette,
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _controller
                                                  .sellingPriceController,
                                              style: TextStyle(
                                                color: palette.ink,
                                                fontSize: 15,
                                              ),
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                decimal: true,
                                              ),
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: _inputDecoration(
                                                palette,
                                                hint: '0',
                                                prefixText: 'Sh ',
                                              ),
                                              validator: (val) {
                                                if (val == null ||
                                                    val.trim().isEmpty) {
                                                  return 'Required';
                                                }
                                                final num = double.tryParse(
                                                  val.trim(),
                                                );
                                                if (num == null || num < 0) {
                                                  return 'Invalid';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FieldLabel(
                                              showUnitSuffix
                                                  ? '${context.tr('Purchase Price')} ($unit)'
                                                  : context
                                                      .tr('Purchase Price'),
                                              palette,
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller: _controller
                                                  .purchasePriceController,
                                              style: TextStyle(
                                                color: palette.ink,
                                                fontSize: 15,
                                              ),
                                              keyboardType: const TextInputType
                                                  .numberWithOptions(
                                                decimal: true,
                                              ),
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: _inputDecoration(
                                                palette,
                                                hint: '0',
                                                prefixText: 'Sh ',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _FieldLabel(
                                              showUnitSuffix
                                                  ? '${t('Stock', 'Stoo')} ($unit) *'
                                                  : '${t('Stock', 'Stoo')} *',
                                              palette,
                                            ),
                                            const SizedBox(height: 6),
                                            TextFormField(
                                              controller:
                                                  _controller.stockController,
                                              style: TextStyle(
                                                color: palette.ink,
                                                fontSize: 15,
                                              ),
                                              keyboardType:
                                                  _controller.allowFractional
                                                      ? const TextInputType
                                                          .numberWithOptions(
                                                          decimal: true,
                                                        )
                                                      : TextInputType.number,
                                              decoration: _inputDecoration(
                                                palette,
                                                hint:
                                                    _controller.allowFractional
                                                        ? '100'
                                                        : '1',
                                              ),
                                              validator: (val) {
                                                if (val == null ||
                                                    val.trim().isEmpty) {
                                                  return 'Required';
                                                }
                                                final n = double.tryParse(
                                                  val
                                                      .trim()
                                                      .replaceAll(',', ''),
                                                );
                                                if (n == null || n < 0) {
                                                  return 'Invalid';
                                                }
                                                return null;
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: _FieldLabel(
                                                    '${context.tr('Category')} *',
                                                    palette,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () => _controller
                                                      .showCreateCategoryDialog(
                                                    () => setState(() {}),
                                                  ),
                                                  child: Text(
                                                    t('+ New', '+ Mpya'),
                                                    style: AppTypography.caption
                                                        .copyWith(
                                                      color: palette.primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            DropdownButtonFormField<String>(
                                              initialValue: selectedCategory,
                                              isExpanded: true,
                                              dropdownColor: palette.surface,
                                              style: TextStyle(
                                                color: palette.ink,
                                                fontSize: 15,
                                              ),
                                              decoration:
                                                  _inputDecoration(palette),
                                              items: [
                                                for (final cat in _controller
                                                    .categoryOptions)
                                                  DropdownMenuItem(
                                                    value: cat,
                                                    child: Text(
                                                      cat,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                DropdownMenuItem(
                                                  value: '__new__',
                                                  child: Text(
                                                    context.tr(
                                                      '+ Add New Category',
                                                    ),
                                                    style: TextStyle(
                                                      color: palette.primary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              onChanged: (val) {
                                                if (val == '__new__') {
                                                  _controller
                                                      .showCreateCategoryDialog(
                                                    () => setState(() {}),
                                                  );
                                                } else {
                                                  setState(
                                                    () => _controller
                                                        .selectedCategory = val,
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // 2. Item Photo (always accessible on the main form)
                        _GroupLabel(t('ITEM PHOTO', 'PICHA YA BIDHAA'), palette),
                        PhotoUploadTile(
                          imagePath: _controller.selectedImagePath,
                          onPickTap: () => _controller.pickImage(
                            () => setState(() {}),
                          ),
                          onRemoveTap: () => setState(
                            () => _controller.selectedImagePath = null,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // 3. Collapsible Advanced Options (Barcode, Unit, Expiry)
                        _NativeCard(
                          palette: palette,
                          children: [
                            InkWell(
                              key: const ValueKey('toggle-advanced-options'),
                              onTap: () => setState(
                                () => _showAdvanced = !_showAdvanced,
                              ),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(minHeight: 54),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 13,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.tune_rounded,
                                        size: 21,
                                        color: palette.textMuted,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t(
                                                'Advanced options',
                                                'Chaguo za juu',
                                              ),
                                              style: AppTypography.bodyMain
                                                  .copyWith(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: palette.ink,
                                              ),
                                            ),
                                            Text(
                                              t(
                                                'Barcode, unit & expiry date',
                                                'Msimbo, kipimo na muda wa matumizi',
                                              ),
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color: palette.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        _showAdvanced
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons
                                                .keyboard_arrow_down_rounded,
                                        size: 22,
                                        color: palette.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_showAdvanced) ...[
                              Divider(height: 1, color: palette.divider),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Barcode / SKU
                                    _FieldLabel(
                                      context.tr('Barcode / SKU'),
                                      palette,
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _controller.codeController,
                                      style: TextStyle(
                                        color: palette.ink,
                                        fontSize: 15,
                                      ),
                                      decoration: _inputDecoration(
                                        palette,
                                        hint: context.tr(
                                          'Scan or type barcode',
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            Icons.qr_code_scanner_rounded,
                                            color: palette.primary,
                                          ),
                                          tooltip: context.tr('Scan barcode'),
                                          onPressed: _scanBarcode,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // Selling unit
                                    _FieldLabel(
                                      t('Selling unit', 'Kipimo cha kuuzia'),
                                      palette,
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      initialValue: _controller.selectedUnit,
                                      dropdownColor: palette.surface,
                                      style: TextStyle(
                                        color: palette.ink,
                                        fontSize: 15,
                                      ),
                                      decoration: _inputDecoration(palette),
                                      items: [
                                        for (final u in unitOptions)
                                          DropdownMenuItem<String>(
                                            value: u,
                                            child: Text(
                                              u == 'Pcs'
                                                  ? t(
                                                      'Pcs (whole items)',
                                                      'Pcs (bidhaa nzima)',
                                                    )
                                                  : u == 'kg'
                                                      ? 'kg (${t('kilograms', 'kilo')})'
                                                      : u == 'L'
                                                          ? 'L (${t('liters', 'lita')})'
                                                          : u,
                                            ),
                                          ),
                                      ],
                                      onChanged: (val) {
                                        if (val == null) return;
                                        setState(() {
                                          _controller.selectedUnit = val;
                                          _controller.allowFractional =
                                              isMeasuredUnit(val);
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 10),

                                    // Fractional / custom measurement toggle
                                    SwitchListTile.adaptive(
                                      key: const ValueKey(
                                        'toggle-allow-fractional',
                                      ),
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        t(
                                          'Sell by custom measurement',
                                          'Uza kwa kipimo maalum',
                                        ),
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                          color: palette.ink,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      subtitle: Text(
                                        t(
                                          'Half, quarter, or custom amount',
                                          'Robo, nusu, au kiasi cha TSh',
                                        ),
                                        style: AppTypography.caption.copyWith(
                                          color: palette.textMuted,
                                        ),
                                      ),
                                      value: _controller.allowFractional,
                                      activeTrackColor: palette.primary,
                                      onChanged: (val) {
                                        setState(
                                          () =>
                                              _controller.allowFractional = val,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),

                                    // Expiry tracking
                                    ExpiryTrackingCard(
                                      trackExpiry: _controller.trackExpiry,
                                      expiryDate: _controller.expiryDate,
                                      onToggleExpiry: (val) {
                                        setState(() {
                                          _controller.trackExpiry = val;
                                          if (val &&
                                              _controller.expiryDate == null) {
                                            _controller.expiryDate =
                                                DateTime.now();
                                          }
                                        });
                                      },
                                      onPickExpiryDate: _pickExpiryDate,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Sticky bottom action bar with unified 48px pill buttons
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(top: BorderSide(color: palette.border)),
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: palette.ink,
                                backgroundColor: palette.surface,
                                side: BorderSide(color: palette.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                              child: Text(
                                context.tr('Cancel'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 48,
                            child: FilledButton(
                              onPressed: _save,
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                              child: Text(
                                isEdit
                                    ? context.tr('Update Item')
                                    : context.tr('Save Item'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text, this.palette);
  final String text;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        text,
        style: AppTypography.label.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: palette.textMuted,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, this.palette);
  final String text;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(
        color: palette.textMuted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NativeCard extends StatelessWidget {
  const _NativeCard({required this.palette, required this.children});
  final AppThemePalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: palette.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(children: children),
      ),
    );
  }
}
