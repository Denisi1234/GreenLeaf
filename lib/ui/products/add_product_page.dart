import '../widgets/app_image.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../l10n/app_strings.dart';
import '../business_category_config.dart';
import '../widgets/app_design.dart';
import '../models/product_item.dart';
import '../widgets/market_shared_widgets.dart';
import 'inventory_product_item.dart';

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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _purchasePriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _stockController;
  final _imagePicker = ImagePicker();

  String? _selectedCategory;
  String? _selectedImagePath;
  bool _trackExpiry = false;
  DateTime? _expiryDate;
  late BusinessCategory _businessCategory;
  late List<String> _categoryOptions;
  late AppStrings strings;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _purchasePriceController = TextEditingController(
      text: widget.product != null
          ? widget.product!.purchasePrice.toStringAsFixed(0)
          : '',
    );
    _sellingPriceController = TextEditingController(
      text: widget.product != null
          ? widget.product!.sellingPrice.toStringAsFixed(0)
          : '',
    );
    _stockController = TextEditingController(
      text: widget.product != null
          ? widget.product!.stockCount.toString()
          : '1',
    );
    _selectedCategory = widget.product?.category;
    _selectedImagePath = widget.product?.imagePath;
    _expiryDate =
        _parseExpiryDate(widget.product?.categoryData['expiry_date']);
    _trackExpiry = _expiryDate != null;
  }

  DateTime? _parseExpiryDate(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 15, 12, 31),
      helpText: 'Select expiry date',
    );
    if (picked == null) return;
    setState(() {
      _expiryDate = DateTime(picked.year, picked.month, picked.day);
      _trackExpiry = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = context.read<PosLocalStore>();
    strings = AppStrings.of(store.languageCode);
    final config = store.businessCategoryConfig;
    _businessCategory = config.category;
    _categoryOptions = _productCategoriesFor(_businessCategory);

    if (_selectedCategory == null ||
        !_categoryOptions.contains(_selectedCategory)) {
      _selectedCategory = _categoryOptions.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _showCreateCategoryDialog() async {
    final textController = TextEditingController();
    final newCategory = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'Create New Category',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter category name:',
              style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: textController,
                autofocus: true,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  hintText: 'e.g., Electronics, Bakery, Cosmetics',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
            ),
          ),
          FilledButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(dialogContext).pop(text);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text(
              'Add Category',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (newCategory != null && newCategory.isNotEmpty) {
      setState(() {
        if (!_categoryOptions.contains(newCategory)) {
          _categoryOptions.add(newCategory);
        }
        _selectedCategory = newCategory;
      });
    }
  }

  void _saveProduct() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showMarketNotice(
        context,
        title: strings.checkTheForm,
        message: strings.completeRequiredFields,
        type: MarketNoticeType.warning,
      );
      return;
    }

    final purchasePrice =
        double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final sellingPrice =
        double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    final metadata = <String, Object?>{
      ...?widget.product?.categoryData,
    };
    if (_trackExpiry && _expiryDate != null) {
      metadata['expiry_date'] = _isoDate(_expiryDate!);
    } else {
      metadata.remove('expiry_date');
    }

    final product = InventoryProductItem(
      code: widget.product?.code ?? widget.nextCode,
      name: _nameController.text.trim(),
      category: _selectedCategory ?? 'General',
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      stockCount: stock,
      stockState: _deriveStockState(stock),
      artType: widget.product?.artType ??
          _deriveArtType(
            _nameController.text.trim(),
            _selectedCategory ?? 'General',
          ),
      imagePath: _selectedImagePath,
      categoryData: metadata,
    );

    Navigator.of(context).pop(product);
  }

  List<String> _productCategoriesFor(BusinessCategory category) {
    return const [
      'Beverages',
      'Snacks',
      'Stationery',
      'Disposable',
      'Personal Care',
      'Groceries',
      'Household',
    ];
  }

  Future<void> _deleteProduct() async {
    final product = widget.product;
    if (product == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Item?',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Are you sure you want to remove "${product.name}"? This cannot be undone.',
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              strings.cancel,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              strings.delete,
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await context.read<PosLocalStore>().removeProduct(product.code);
    if (!mounted) return;

    showMarketNotice(
      context,
      title: 'Item Deleted',
      message: '${product.name} has been removed',
      type: MarketNoticeType.warning,
    );
    Navigator.of(context).pop();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );

      if (image == null || !mounted) return;

      final savedPath = await _persistSelectedImage(image);
      if (!mounted) return;

      setState(() {
        _selectedImagePath = savedPath;
      });

      showMarketNotice(
        context,
        title: strings.imageSelected,
        message: strings.productImageReady,
        type: MarketNoticeType.success,
      );
    } catch (_) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: strings.uploadFailed,
        message: strings.couldNotOpenGallery,
        type: MarketNoticeType.warning,
      );
    }
  }

  Future<String> _persistSelectedImage(XFile image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(appDir.path, 'product_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final extension = path.extension(image.path);
    final safeName =
        'product_${DateTime.now().millisecondsSinceEpoch}${extension.isEmpty ? '.png' : extension}';
    final storedFile = File(path.join(imagesDir.path, safeName));
    await File(image.path).copy(storedFile.path);
    return storedFile.path;
  }

  InventoryStockState _deriveStockState(int stock) {
    if (stock <= 0) return InventoryStockState.outOfStock;
    final threshold =
        context.read<PosLocalStore>().storePreferences.lowStockThreshold;
    if (stock <= threshold) return InventoryStockState.lowStock;
    return InventoryStockState.inStock;
  }

  ProductArtType _deriveArtType(String name, String category) {
    final lower = name.toLowerCase();
    if (lower.contains('water')) return ProductArtType.aquafina;
    if (lower.contains('coke') || lower.contains('soda')) return ProductArtType.coke;
    if (lower.contains('snack') || lower.contains('chips')) return ProductArtType.lays;
    if (lower.contains('chocolate') || lower.contains('candy')) return ProductArtType.galaxy;
    if (lower.contains('cereal') || lower.contains('grain')) return ProductArtType.kelloggs;
    if (lower.contains('beauty') || lower.contains('cream')) return ProductArtType.dove;
    if (lower.contains('toothpaste') || lower.contains('dental')) return ProductArtType.colgate;
    if (lower.contains('wash') || lower.contains('antiseptic')) return ProductArtType.dettol;
    if (lower.contains('soap') || lower.contains('detergent')) return ProductArtType.tide;
    return ProductArtType.lays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2F9), // Matching app theme
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEdit ? 'Edit Item' : 'New Item Details',
          style: GoogleFonts.manrope(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 22),
              onPressed: _deleteProduct,
              tooltip: 'Delete Item',
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFD6E4F0), height: 1),
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
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: Basic Info
                      _SectionHeader(title: 'Item Information'),
                      const SizedBox(height: 12),
                      MarketFormField(
                        label: 'Item Name',
                        isRequired: true,
                        controller: _nameController,
                        hintText: 'e.g., White Rice 1kg, Coca-Cola 350ml',
                        prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppColors.textMuted, size: 20),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Item name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      MarketDropdownField<String>(
                        label: 'Category',
                        isRequired: true,
                        labelAction: InkWell(
                          onTap: _showCreateCategoryDialog,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, size: 15, color: Color(0xFF0284C7)),
                                const SizedBox(width: 4),
                                Text(
                                  '+ New Category',
                                  style: GoogleFonts.manrope(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        value: _categoryOptions.contains(_selectedCategory)
                            ? _selectedCategory
                            : (_categoryOptions.isNotEmpty ? _categoryOptions.first : null),
                        items: [
                          ..._categoryOptions.map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat, style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 14)),
                              )),
                          DropdownMenuItem(
                            value: '__new__',
                            child: Row(
                              children: [
                                const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0284C7), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  '+ Add New Category',
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0284C7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == '__new__') {
                            _showCreateCategoryDialog();
                          } else {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                      const SizedBox(height: 24),

                      // Section 2: Pricing & Stock
                      _SectionHeader(title: 'Pricing & Stock'),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: MarketFormField(
                              label: 'Sale Price',
                              isRequired: true,
                              controller: _sellingPriceController,
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
                              label: 'Purchase Price',
                              controller: _purchasePriceController,
                              hintText: '0.00',
                              prefixText: 'Sh ',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MarketFormField(
                        label: 'Initial Stock Quantity',
                        isRequired: true,
                        controller: _stockController,
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

                      // Section 3: Expiry Tracking (Optional)
                      _SectionHeader(title: 'Expiry Tracking (Optional)'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_busy_rounded,
                                    size: 20, color: Color(0xFF0284C7)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Track expiry date',
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Receive alerts when this item is about to expire',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _trackExpiry,
                                  onChanged: (value) {
                                    setState(() {
                                      _trackExpiry = value;
                                      if (value && _expiryDate == null) {
                                        _expiryDate = DateTime.now();
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_trackExpiry) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Expiry date',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF475569),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _expiryDate == null
                                              ? 'No date selected'
                                              : _displayDate(_expiryDate!),
                                          style: GoogleFonts.manrope(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _pickExpiryDate,
                                    icon: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _expiryDate == null ? 'Set date' : 'Change',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 4: Photo (Optional)
                      _SectionHeader(title: 'Item Photo (Optional)'),
                      const SizedBox(height: 12),
                      _PhotoUploadTile(
                        imagePath: _selectedImagePath,
                        onPickTap: _pickImage,
                        onRemoveTap: () => setState(() => _selectedImagePath = null),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Floating Save Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFD6E4F0), width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: MarketButton.secondary(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(),
                      height: 48,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: MarketButton(
                      label: isEdit ? 'Update Item' : 'Save Item',
                      icon: isEdit ? Icons.check_circle_outline_rounded : Icons.add_circle_outline_rounded,
                      variant: MarketButtonVariant.success,
                      onTap: _saveProduct,
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

// ---------------------------------------------------------------------------
// Form Supporting Widgets
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
        letterSpacing: -0.1,
      ),
    );
  }
}

class _PhotoUploadTile extends StatelessWidget {
  const _PhotoUploadTile({
    required this.imagePath,
    required this.onPickTap,
    required this.onRemoveTap,
  });

  final String? imagePath;
  final VoidCallback onPickTap;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    if (hasImage) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          border: Border.all(color: const Color(0xFFD6E4F0)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.file(File(imagePath!), fit: BoxFit.cover),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: onRemoveTap,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: onPickTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF0284C7), size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload item photo',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'PNG, JPG up to 5MB',
              style: GoogleFonts.manrope(fontSize: 11, color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
