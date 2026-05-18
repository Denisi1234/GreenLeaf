import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/product_item.dart';
import '../widgets/market_shared_widgets.dart';
import 'inventory_product_item.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({
    super.key,
    required this.nextCode,
  });

  final String nextCode;

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();
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
      code: widget.nextCode,
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      stockCount: stock,
      stockState: _deriveStockState(stock),
      artType: _deriveArtType(
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
    if (lower.contains('water')) return ProductArtType.aquafina;
    if (lower.contains('coke') || lower.contains('cola')) return ProductArtType.coke;
    if (lower.contains('lay') || lower.contains('chips')) return ProductArtType.lays;
    if (lower.contains('galaxy') || lower.contains('chocolate')) {
      return ProductArtType.galaxy;
    }
    if (lower.contains('corn') || lower.contains('flakes')) {
      return ProductArtType.kelloggs;
    }
    if (lower.contains('soap') || lower.contains('dove')) return ProductArtType.dove;
    if (lower.contains('colgate') || lower.contains('toothpaste')) {
      return ProductArtType.colgate;
    }
    if (lower.contains('dettol') || lower.contains('wash')) return ProductArtType.dettol;
    if (lower.contains('tide') || lower.contains('detergent')) return ProductArtType.tide;

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
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: BackdropGlow()),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF202938),
                            size: 30,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Add New Product',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE6EAF0)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 112),
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE8ECF1)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x10000000),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Product Name',
                                requiredField: true),
                            const SizedBox(height: 10),
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
                            const SizedBox(height: 22),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _FieldLabel('Purchase Price',
                                          requiredField: true),
                                      const SizedBox(height: 10),
                                      _TextInputField(
                                        controller: _purchasePriceController,
                                        hint: '0.00',
                                        leadingText: 'TSH ',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        validator: _validateMoney,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _FieldLabel('Selling Price',
                                          requiredField: true),
                                      const SizedBox(height: 10),
                                      _TextInputField(
                                        controller: _sellingPriceController,
                                        hint: '0.00',
                                        leadingText: 'TSH ',
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        validator: _validateMoney,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            const _FieldLabel('Category', requiredField: true),
                            const SizedBox(height: 10),
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
                            const SizedBox(height: 22),
                            const _FieldLabel('Stock Quantity',
                                requiredField: true),
                            const SizedBox(height: 10),
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
                            const SizedBox(height: 24),
                            const _FieldLabel('Product Image'),
                            const SizedBox(height: 12),
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
              left: 18,
              right: 18,
              bottom: 18,
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ActionButton(
                      label: 'Save',
                      icon: Icons.save_outlined,
                      isPrimary: true,
                      onTap: _saveProduct,
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
            color: Color(0xFF2B3343),
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (requiredField)
          const Text(
            ' *',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 14.5,
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
        color: Color(0xFF202938),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFFB0B7C3),
          fontSize: 13.8,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: leadingText != null
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 10, 15),
                child: Text(
                  leadingText!,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: trailingIcon != null
            ? Icon(
                trailingIcon,
                color: const Color(0xFF7F8898),
                size: 24,
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE2EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF2B6FF3), width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 1.1),
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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDCE2EA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF2B6FF3), width: 1.2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFFEF4444), width: 1.1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: field.value,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  hint: Text(
                    hint,
                    style: const TextStyle(
                      color: Color(0xFFB0B7C3),
                      fontSize: 13.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF7F8898),
                    size: 24,
                  ),
                  items: items
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Color(0xFF202938),
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
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFC8D2E4),
        ),
      ),
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
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
                        color: Colors.white.withValues(alpha: 0.92),
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
                  backgroundColor: Color(0xFFEAF0FF),
                  child: Icon(
                    Icons.photo_camera_outlined,
                    color: Color(0xFF4169E1),
                    size: 32,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Upload product image',
                  style: TextStyle(
                    color: Color(0xFF2B3343),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap to choose image from gallery',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'JPG, PNG up to 5MB',
                  style: TextStyle(
                    color: Color(0xFF9AA3B2),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF2B6FF3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFF2B6FF3)
                : const Color(0xFFCCD4E0),
          ),
          boxShadow: isPrimary
              ? const [
                  BoxShadow(
                    color: Color(0x222B6FF3),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : const Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
