import '../models/product_item.dart';

class InventoryProductItem {
  const InventoryProductItem({
    required this.code,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.stockCount,
    required this.stockState,
    required this.artType,
    this.imagePath,
    this.unit = 'Pcs',
    this.allowFractional = false,
    this.packName,
    this.packSize,
    this.categoryData = const <String, Object?>{},
  });

  final String code;
  final String name;
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  final double stockCount;
  final InventoryStockState stockState;
  final ProductArtType artType;
  final String? imagePath;
  final String unit;
  final bool allowFractional;
  final String? packName;
  final double? packSize;
  final Map<String, Object?> categoryData;

  bool get hasBulkPack =>
      (packName?.trim().isNotEmpty ?? false) && (packSize ?? 0) > 0;

  String get sellingPriceLabel => 'TSH ${sellingPrice.toStringAsFixed(0)}';

  InventoryProductItem copyWith({
    String? code,
    String? name,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    double? stockCount,
    InventoryStockState? stockState,
    ProductArtType? artType,
    String? imagePath,
    String? unit,
    bool? allowFractional,
    String? packName,
    double? packSize,
    bool clearBulkPack = false,
    Map<String, Object?>? categoryData,
  }) {
    return InventoryProductItem(
      code: code ?? this.code,
      name: name ?? this.name,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockCount: stockCount ?? this.stockCount,
      stockState: stockState ?? this.stockState,
      artType: artType ?? this.artType,
      imagePath: imagePath ?? this.imagePath,
      unit: unit ?? this.unit,
      allowFractional: allowFractional ?? this.allowFractional,
      packName: clearBulkPack ? null : (packName ?? this.packName),
      packSize: clearBulkPack ? null : (packSize ?? this.packSize),
      categoryData: categoryData ?? this.categoryData,
    );
  }
}

enum InventoryStockState {
  inStock,
  lowStock,
  outOfStock,
}
