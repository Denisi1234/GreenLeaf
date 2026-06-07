import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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

  static const _categories = [
    'Beverages',
    'Snacks',
    'Stationery',
    'Disposable',
    'Personal Care',
    'Groceries',
    'Household',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name);
    _purchasePriceController = TextEditingController(
      text: widget.product?.purchasePrice.toStringAsFixed(0),
    );
    _sellingPriceController = TextEditingController(
      text: widget.product?.sellingPrice.toStringAsFixed(0),
    );
    _stockController = TextEditingController(
      text: widget.product?.stockCount.toString(),
    );
    _selectedCategory = widget.product?.category;
    _selectedImagePath = widget.product?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _saveProduct() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      showMarketNotice(
        context,
        title: 'Check The Form',
        message: 'Complete the required fields before saving',
        type: MarketNoticeType.warning,
      );
      return;
    }

    final purchasePrice = double.parse(_purchasePriceController.text.trim());
    final sellingPrice = double.parse(_sellingPriceController.text.trim());
    final stock = int.parse(_stockController.text.trim());

    final product = InventoryProductItem(
      code: widget.product?.code ?? widget.nextCode,
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      stockCount: stock,
      stockState: _deriveStockState(stock),
      artType: widget.product?.artType ??
          _deriveArtType(
            _nameController.text.trim(),
            _selectedCategory!,
          ),
      imagePath: _selectedImagePath,
    );

    Navigator.of(context).pop(product);
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
        title: 'Image Selected',
        message: 'Product image is ready to save',
      );
    } catch (_) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Upload Failed',
        message: 'Could not open the gallery on this device',
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
    if (stock <= 20) return InventoryStockState.lowStock;
    return InventoryStockState.inStock;
  }

  ProductArtType _deriveArtType(String name, String category) {
    final lower = name.toLowerCase();
    if (lower.contains('water')) {
      return ProductArtType.aquafina;
    }
    if (lower.contains('coke') || lower.contains('cola')) {
      return ProductArtType.coke;
    }
    if (lower.contains('lay') || lower.contains('chips')) {
      return ProductArtType.lays;
    }
    if (lower.contains('galaxy') || lower.contains('chocolate')) {
      return ProductArtType.galaxy;
    }
    if (lower.contains('corn') || lower.contains('flakes')) {
      return ProductArtType.kelloggs;
    }
    if (lower.contains('soap') || lower.contains('dove')) {
      return ProductArtType.dove;
    }
    if (lower.contains('colgate') || lower.contains('toothpaste')) {
      return ProductArtType.colgate;
    }
    if (lower.contains('dettol') || lower.contains('wash')) {
      return ProductArtType.dettol;
    }
    if (lower.contains('tide') || lower.contains('detergent')) {
      return ProductArtType.tide;
    }

    return switch (category) {
      'Beverages' => ProductArtType.aquafina,
      'Snacks' => ProductArtType.lays,
      'Stationery' => ProductArtType.colgate,
      'Disposable' => ProductArtType.dove,
      'Personal Care' => ProductArtType.dettol,
      'Groceries' => ProductArtType.kelloggs,
      'Household' => ProductArtType.tide,
      _ => ProductArtType.aquafina,
    };
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final interTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(color: AppColors.pageBackground),
            ),
            Column(
              children: [
                MarketPageHeader(
                  title:
                      widget.product == null ? 'Add Product' : 'Edit Product',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 112),
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel(
                              'Product Name',
                              requiredField: true,
                            ),
                            const SizedBox(height: 8),
                            _TextInputField(
                              controller: _nameController,
                              hint: 'Enter product name',
                              trailingIcon: Icons.sell_outlined,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Product name is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _FieldLabel(
                                        'Purchase Price',
                                        requiredField: true,
                                      ),
                                      const SizedBox(height: 8),
                                      _TextInputField(
                                        controller: _purchasePriceController,
                                        hint: '0.00',
                                        leadingText: 'TSH ',
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        validator: _validateMoney,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _FieldLabel(
                                        'Selling Price',
                                        requiredField: true,
                                      ),
                                      const SizedBox(height: 8),
                                      _TextInputField(
                                        controller: _sellingPriceController,
                                        hint: '0.00',
                                        leadingText: 'TSH ',
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        validator: _validateMoney,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel('Category', requiredField: true),
                            const SizedBox(height: 8),
                            _DropdownInputField(
                              value: _selectedCategory,
                              hint: 'Select category',
                              items: _categories,
                              onChanged: (value) {
                                setState(() => _selectedCategory = value);
                              },
                              validator: (value) =>
                                  value == null ? 'Category is required' : null,
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel(
                              'Stock Quantity',
                              requiredField: true,
                            ),
                            const SizedBox(height: 8),
                            _TextInputField(
                              controller: _stockController,
                              hint: 'Enter stock quantity',
                              trailingIcon: Icons.inventory_2_outlined,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Stock quantity is required';
                                }
                                final parsed = int.tryParse(value.trim());
                                if (parsed == null || parsed < 0) {
                                  return 'Enter a valid stock quantity';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel('Product Image'),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _pickImage,
                              child: _UploadBox(
                                imagePath: _selectedImagePath,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: MarketButton(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(),
                      color: Colors.white.withValues(alpha: 0.92),
                      foregroundColor: AppColors.ink,
                      borderColor: const Color(0xFFE7EAF0),
                      height: 64,
                      radius: 8,
                      paddingHorizontal: 0,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: MarketButton(
                      label: 'Save',
                      icon: Icons.save_outlined,
                      onTap: _saveProduct,
                      color: const Color(0xFF5B8CFF),
                      foregroundColor: Colors.white,
                      borderColor: const Color(0xFF5B8CFF),
                      height: 64,
                      radius: 8,
                      paddingHorizontal: 0,
                      fontSize: 15,
                      iconSize: 24,
                      iconSpacing: 10,
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

  String? _validateMoney(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This price is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a valid amount';
    }
    return null;
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.requiredField = false});

  final String label;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF7B8598),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (requiredField)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _TextInputField extends StatelessWidget {
  const _TextInputField({
    required this.controller,
    required this.hint,
    required this.validator,
    this.leadingText,
    this.trailingIcon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final String? leadingText;
  final IconData? trailingIcon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(
        color: Color(0xFF33363F),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF8A93A7),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: leadingText != null
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
                child: Text(
                  leadingText!,
                  style: const TextStyle(
                    color: Color(0xFF7B8598),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: trailingIcon != null
            ? Icon(
                trailingIcon,
                color: const Color(0xFF5B8CFF),
                size: 20,
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE7EAF0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF5B8CFF), width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.1),
        ),
      ),
    );
  }
}

class _DropdownInputField extends FormField<String> {
  _DropdownInputField({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String? Function(String?) validator,
  }) : super(
          initialValue: value,
          validator: validator,
          builder: (field) {
            return InputDecorator(
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.92),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE7EAF0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF5B8CFF), width: 1.2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFFEF4444), width: 1.1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: field.value,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(8),
                  hint: Text(
                    hint,
                    style: const TextStyle(
                      color: Color(0xFF8A93A7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF5B8CFF),
                    size: 24,
                  ),
                  items: items
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Color(0xFF33363F),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    field.didChange(value);
                    onChanged(value);
                  },
                ),
              ),
            );
          },
        );
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    this.imagePath,
  });

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;

    return Container(
      height: 206,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF2B6FF3),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Change',
                            style: TextStyle(
                              color: Color(0xFF2B6FF3),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFEAF3FF),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    color: Color(0xFF5B8CFF),
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Upload product image',
                  style: TextStyle(
                    color: Color(0xFF33363F),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap to choose image from gallery',
                  style: TextStyle(
                    color: Color(0xFF7B8598),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'JPG, PNG up to 5MB',
                  style: TextStyle(
                    color: Color(0xFF8A93A7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}
