import 'package:flutter/material.dart';

/// Product item model for catalog and cart operations.
class ProductItem {
  const ProductItem(
    this.name,
    this.size,
    this.price,
    this.type, {
    this.code,
    this.category,
    this.imagePath,
  });

  final String name;
  final String size;
  final String price;
  final ProductArtType type;
  final String? code;
  final String? category;
  final String? imagePath;

  double get priceValue => double.tryParse(price) ?? 0;
}

/// Category navigation item for product filtering.
class CategoryItem {
  const CategoryItem(this.label, this.icon, this.isActive);

  final String label;
  final IconData icon;
  final bool isActive;
}

/// Line item in an order with mutable quantity.
class OrderLineItem {
  OrderLineItem({
    required this.product,
    required this.quantity,
  });

  final ProductItem product;
  int quantity;

  double get totalPrice => product.priceValue * quantity;
}

enum ProductArtType {
  aquafina,
  coke,
  lays,
  galaxy,
  kelloggs,
  dove,
  colgate,
  dettol,
  tide,
}

const productItems = <ProductItem>[
  ProductItem('Mineral Water 500ml', '500 ml', '3000', ProductArtType.aquafina),
  ProductItem('Coca-Cola', '330 ml', '3750', ProductArtType.coke),
  ProductItem("Lay's Classic", 'Potato Chips 52g', '4500', ProductArtType.lays),
  ProductItem('Galaxy Milk', 'Chocolate 40g', '4000', ProductArtType.galaxy),
  ProductItem("Kellogg's Corn Flakes", '500g', '8500', ProductArtType.kelloggs),
  ProductItem('Dove Beauty Bar', '100g', '3125', ProductArtType.dove),
  ProductItem('Colgate', 'Maximum Protection', '5250', ProductArtType.colgate),
  ProductItem('Dettol Hand Wash', '250 ml', '7125', ProductArtType.dettol),
  ProductItem('Tide Original', 'Detergent Powder', '12250', ProductArtType.tide),
];
