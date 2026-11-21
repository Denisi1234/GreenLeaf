import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:track_mauzo/l10n/app_localization.dart';

import '../../service/barcode_scan_service.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'inventory_product_item.dart';
import 'widgets/add_product_controller.dart';
import 'widgets/product_form_fields.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = AddProductController(
      context: context,
      nextCode: widget.nextCode,
      existingProduct: widget.product,
    );
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

  @override
  Widget build(BuildContext context) {
    final isEdit = _controller.isEdit;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.headerSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink, size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? context.tr('Edit Item') : context.tr('New Item Details'),
          style: GoogleFonts.manrope(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
              onPressed: _deleteProduct,
              tooltip: context.tr('Delete Item'),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Form(
                  key: _controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(title: context.tr('Item Information')),
                      const SizedBox(height: 12),
                      MarketFormField(
                        label: context.tr('Item Name'),
                        isRequired: true,
                        radius: 0,
                        controller: _controller.nameController,
                        hintText: context.tr('e.g., White Rice 1kg, Coca-Cola 350ml'),
                        prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 20),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Item name is required' : null,
                      ),
                      const SizedBox(height: 16),
                      MarketFormField(
                        label: context.tr('Barcode / SKU'),
                        radius: 0,
                        controller: _controller.codeController,
                        hintText: context.tr('Scan or type barcode'),
                        prefixIcon: const Icon(Icons.qr_code_2_rounded, color: AppColors.textMuted, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          tooltip: context.tr('Scan barcode'),
                          onPressed: _scanBarcode,
                        ),
                      ),
                      const SizedBox(height: 16),
                      MarketDropdownField<String>(
                        label: context.tr('Category'),
                        isRequired: true,
                        radius: 0,
                        labelAction: InkWell(
                          onTap: () => _controller.showCreateCategoryDialog(() => setState(() {})),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, size: 15, color: AppColors.kpiSky),
                                const SizedBox(width: 4),
                                Text(
                                  context.tr('+ New Category'),
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.kpiSky,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        value: _controller.categoryOptions.contains(_controller.selectedCategory)
                            ? _controller.selectedCategory
                            : (_controller.categoryOptions.isNotEmpty ? _controller.categoryOptions.first : null),
                        items: [
                          ..._controller.categoryOptions.map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat, style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14)),
                              )),
                          DropdownMenuItem(
                            value: '__new__',
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, color: AppColors.kpiSky, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('+ Add New Category'),
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.kpiSky,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == '__new__') {
                            _controller.showCreateCategoryDialog(() => setState(() {}));
                          } else {
                            setState(() => _controller.selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: context.tr('Pricing & Stock')),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: MarketFormField(
                              label: context.tr('Sale Price'),
                              isRequired: true,
                              radius: 0,
                              controller: _controller.sellingPriceController,
                              hintText: '0.00',
                              prefixText: 'Sh ',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                final num = double.tryParse(val.trim());
                                if (num == null || num < 0) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: MarketFormField(
                              label: context.tr('Purchase Price'),
                              radius: 0,
                              controller: _controller.purchasePriceController,
                              hintText: '0.00',
                              prefixText: 'Sh ',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MarketFormField(
                        label: context.tr('Initial Stock Quantity'),
                        isRequired: true,
                        radius: 0,
                        controller: _controller.stockController,
                        hintText: '1',
                        prefixIcon: const Icon(Icons.production_quantity_limits_rounded, color: AppColors.textMuted, size: 20),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Stock quantity is required';
                          final n = int.tryParse(val.trim());
                          if (n == null || n < 0) return 'Enter a valid count';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: context.tr('Expiry Tracking (Optional)')),
                      const SizedBox(height: 12),
                      ExpiryTrackingCard(
                        trackExpiry: _controller.trackExpiry,
                        expiryDate: _controller.expiryDate,
                        onToggleExpiry: (val) {
                          setState(() {
                            _controller.trackExpiry = val;
                            if (val && _controller.expiryDate == null) {
                              _controller.expiryDate = DateTime.now();
                            }
                          });
                        },
                        onPickExpiryDate: _pickExpiryDate,
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(title: context.tr('Item Photo (Optional)')),
                      const SizedBox(height: 12),
                      PhotoUploadTile(
                        imagePath: _controller.selectedImagePath,
                        onPickTap: () => _controller.pickImage(() => setState(() {})),
                        onRemoveTap: () => setState(() => _controller.selectedImagePath = null),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: MarketButton.secondary(
                      label: context.tr('Cancel'),
                      onTap: () => Navigator.of(context).pop(),
                      height: 48,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: MarketButton(
                      label: isEdit ? context.tr('Update Item') : context.tr('Save Item'),
                      icon: isEdit ? Icons.check_circle_outline_rounded : Icons.add_circle_outline_rounded,
                      variant: MarketButtonVariant.success,
                      radius: 0,
                      onTap: _save,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
