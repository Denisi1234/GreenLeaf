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

/// Line item in an order with mutable quantity and line discount / price override.
class OrderLineItem {
  OrderLineItem({
    required this.product,
    required this.quantity,
    this.discountPercent = 0.0,
    this.customPrice,
  });

  final ProductItem product;
  int quantity;
  double discountPercent; // e.g. 10.0 for 10%
  double? customPrice; // price override per unit if set

  double get unitPrice => customPrice ?? product.priceValue;

  double get lineDiscountAmount =>
      (unitPrice * quantity) * (discountPercent.clamp(0.0, 100.0) / 100.0);

  double get totalPrice => (unitPrice * quantity) - lineDiscountAmount;
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

