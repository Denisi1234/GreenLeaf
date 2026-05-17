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

  String get sellingPriceLabel => 'TSH ${sellingPrice.toStringAsFixed(0)}';
}

enum InventoryStockState {
  inStock,
  lowStock,
  outOfStock,
}
