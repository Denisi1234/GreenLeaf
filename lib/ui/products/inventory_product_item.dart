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
    this.categoryData = const <String, Object?>{},
  });

  final String code;
  final String name;
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  final int stockCount;
  final InventoryStockState stockState;
  final ProductArtType artType;
  final String? imagePath;
  final Map<String, Object?> categoryData;

  String get sellingPriceLabel => 'TSH ${sellingPrice.toStringAsFixed(0)}';

  InventoryProductItem copyWith({
    String? code,
    String? name,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    int? stockCount,
    InventoryStockState? stockState,
    ProductArtType? artType,
    String? imagePath,
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
      categoryData: categoryData ?? this.categoryData,
    );
  }
}

enum InventoryStockState {
  inStock,
  lowStock,
  outOfStock,
}
