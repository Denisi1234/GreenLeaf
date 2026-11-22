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
    this.unit = 'Pcs',
    this.allowFractional = false,
    this.quantity = 1.0,
    this.customPrice,
    this.packName,
    this.packSize,
  });

  final String name;
  final String size;
  final String price;
  final ProductArtType type;
  final String? code;
  final String? category;
  final String? imagePath;
  final String unit;
  final bool allowFractional;
  final double quantity;
  final double? customPrice;
  final String? packName;
  final double? packSize;

  double get priceValue => double.tryParse(price) ?? 0;

  double get effectiveUnitPrice => customPrice ?? priceValue;

  double get lineTotal => ((effectiveUnitPrice * quantity) * 100).round() / 100;

  ProductItem copyWith({
    double? quantity,
    double? customPrice,
    bool clearCustomPrice = false,
    String? unit,
    bool? allowFractional,
    String? packName,
    double? packSize,
  }) {
    return ProductItem(
      name,
      size,
      price,
      type,
      code: code,
      category: category,
      imagePath: imagePath,
      unit: unit ?? this.unit,
      allowFractional: allowFractional ?? this.allowFractional,
      quantity: quantity ?? this.quantity,
      customPrice: clearCustomPrice ? null : (customPrice ?? this.customPrice),
      packName: packName ?? this.packName,
      packSize: packSize ?? this.packSize,
    );
  }
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
  double quantity;
  double discountPercent; // e.g. 10.0 for 10%
  double? customPrice; // price override per unit if set

  double get unitPrice => customPrice ?? product.effectiveUnitPrice;

  double get lineDiscountAmount =>
      (unitPrice * quantity) * (discountPercent.clamp(0.0, 100.0) / 100.0);

  double get totalPrice =>
      (((unitPrice * quantity) - lineDiscountAmount) * 100).round() / 100;
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

