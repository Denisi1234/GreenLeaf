import '../../widgets/app_design.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../../service/pos_local_store.dart';
import '../../../utils/quantity_formatter.dart';
import '../../business_category_config.dart';
import '../../models/product_item.dart';
import '../../widgets/market_shared_widgets.dart';
import '../inventory_product_item.dart';

/// Controller handling validation, image picking, categories and data packaging for AddProduct.
class AddProductController {
  AddProductController({
    required this.context,
    required this.nextCode,
    this.existingProduct,
  });

  final BuildContext context;
  final String nextCode;
  final InventoryProductItem? existingProduct;

  final formKey = GlobalKey<FormState>();
  late final TextEditingController codeController;
  late final TextEditingController nameController;
  late final TextEditingController purchasePriceController;
  late final TextEditingController sellingPriceController;
  late final TextEditingController stockController;
  final imagePicker = ImagePicker();

  bool _initialized = false;
  String? selectedCategory;
  String? selectedImagePath;
  String selectedUnit = 'Pcs';
  bool allowFractional = false;
  bool trackExpiry = false;
  DateTime? expiryDate;
  late List<String> categoryOptions;

  bool get isEdit => existingProduct != null;

  void init() {
    if (_initialized) return;
    _initialized = true;
    final savedBarcode =
        existingProduct?.categoryData['barcode']?.toString().trim() ?? '';
    codeController = TextEditingController(
      text: savedBarcode.isNotEmpty
          ? savedBarcode
          : (existingProduct?.code ?? nextCode),
    );
    nameController = TextEditingController(text: existingProduct?.name ?? '');
    purchasePriceController = TextEditingController(
      text: existingProduct != null
          ? existingProduct!.purchasePrice.toStringAsFixed(0)
          : '',
    );
    sellingPriceController = TextEditingController(
      text: existingProduct != null
          ? existingProduct!.sellingPrice.toStringAsFixed(0)
          : '',
    );
    stockController = TextEditingController(
      text: existingProduct != null
          ? formatQuantity(existingProduct!.stockCount)
          : '1',
    );
    selectedUnit = (existingProduct?.unit.trim().isNotEmpty ?? false)
        ? existingProduct!.unit.trim()
        : 'Pcs';
    allowFractional = existingProduct?.allowFractional ?? false;

    selectedCategory = existingProduct?.category;
    selectedImagePath = existingProduct?.imagePath;
    expiryDate = _parseExpiryDate(existingProduct?.categoryData['expiry_date']);
    trackExpiry = expiryDate != null;

    final store = context.read<PosLocalStore>();
    final config = store.businessCategoryConfig;
    categoryOptions = _productCategoriesFor(config.category);

    if (selectedCategory == null || !categoryOptions.contains(selectedCategory)) {
      selectedCategory = categoryOptions.first;
    }
  }

  void dispose() {
    codeController.dispose();
    nameController.dispose();
    purchasePriceController.dispose();
    sellingPriceController.dispose();
    stockController.dispose();
  }

  DateTime? _parseExpiryDate(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  List<String> _productCategoriesFor(BusinessCategory category) {
    return [
      'Beverages',
      'Snacks',
      'Stationery',
      'Disposable',
      'Personal Care',
      'Groceries',
      'Household',
    ];
  }

  Future<void> showCreateCategoryDialog(VoidCallback onUpdate) async {
    final textController = TextEditingController();
    final newCategory = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        title: Text(
          context.tr('Create New Category'),
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: AppColors.ink,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Enter category name:'),
              style: GoogleFonts.manrope(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.standard),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: textController,
                autofocus: true,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
                decoration: InputDecoration(
                  hintText: context.tr('e.g., Beverages, Bakery, Cosmetics'),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              side: BorderSide(color: AppColors.borderInput),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              context.tr('Cancel'),
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
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              context.tr('Add Category'),
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (newCategory != null && newCategory.isNotEmpty) {
      if (!categoryOptions.contains(newCategory)) {
        categoryOptions.add(newCategory);
      }
      selectedCategory = newCategory;
      onUpdate();
    }
  }

  InventoryProductItem? buildProduct() {
    final form = formKey.currentState;
    if (form == null || !form.validate()) {
      showMarketNotice(
        context,
        title: context.tr('Check the form'),
        message: context.tr('Complete required fields'),
        type: MarketNoticeType.warning,
      );
      return null;
    }

    final purchasePrice =
        double.tryParse(purchasePriceController.text.trim().replaceAll(',', '')) ??
            0.0;
    final sellingPrice =
        double.tryParse(sellingPriceController.text.trim().replaceAll(',', '')) ??
            0.0;
    final stock = roundQuantity(
      double.tryParse(stockController.text.trim().replaceAll(',', '')) ?? 0.0,
    );

    final metadata = <String, Object?>{
      ...?existingProduct?.categoryData,
    };
    final enteredCode = codeController.text.trim();
    if (existingProduct != null) {
      if (enteredCode.isNotEmpty && enteredCode != existingProduct!.code) {
        metadata['barcode'] = enteredCode;
      } else {
        metadata.remove('barcode');
      }
    }
    if (trackExpiry && expiryDate != null) {
      metadata['expiry_date'] = isoDate(expiryDate!);
    } else {
      metadata.remove('expiry_date');
    }

    metadata['unit'] = selectedUnit;
    metadata['allow_fractional'] = allowFractional;

    return InventoryProductItem(
      code: existingProduct?.code ??
          (enteredCode.isNotEmpty ? enteredCode : nextCode),
      name: nameController.text.trim(),
      category: selectedCategory ?? 'General',
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      stockCount: stock,
      stockState: _deriveStockState(stock),
      artType: existingProduct?.artType ??
          _deriveArtType(nameController.text.trim(), selectedCategory ?? 'General'),
      imagePath: selectedImagePath,
      unit: selectedUnit,
      allowFractional: allowFractional,
      packName: existingProduct?.packName,
      packSize: existingProduct?.packSize,
      categoryData: metadata,
    );
  }

  Future<void> pickImage(VoidCallback onUpdate) async {
    try {
      final image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );

      if (image == null || !context.mounted) return;

      final savedPath = await _persistSelectedImage(image);
      selectedImagePath = savedPath;
      onUpdate();

      if (context.mounted) {
        showMarketNotice(
          context,
          title: context.tr('Image selected'),
          message: context.tr('Product image ready'),
          type: MarketNoticeType.success,
        );
      }
    } catch (_) {
      if (context.mounted) {
        showMarketNotice(
          context,
          title: context.tr('Upload failed'),
          message: context.tr('Could not open gallery'),
          type: MarketNoticeType.warning,
        );
      }
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

  InventoryStockState _deriveStockState(double stock) {
    if (stock <= 0) return InventoryStockState.outOfStock;
    final threshold = context.read<PosLocalStore>().storePreferences.lowStockThreshold;
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
}
