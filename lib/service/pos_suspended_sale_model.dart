import '../ui/models/product_item.dart';

/// Represents a held/parked sale in POS (OpenSourcePOS Suspended Sales pattern).
class SuspendedSale {
  const SuspendedSale({
    required this.id,
    required this.createdAt,
    required this.items,
    this.customerName,
    this.comment,
  });

  final String id;
  final DateTime createdAt;
  final List<ProductItem> items;
  final String? customerName;
  final String? comment;

  int get itemCount => items.fold<int>(
        0,
        (sum, item) => sum + (item.allowFractional ? 1 : item.quantity.round()),
      );
  double get total =>
      items.fold<double>(0.0, (sum, item) => sum + item.lineTotal);

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'customerName': customerName,
        'comment': comment,
        'items': items
            .map((item) => {
                  'name': item.name,
                  'size': item.size,
                  'price': item.price,
                  'type': item.type.name,
                  'code': item.code,
                  'category': item.category,
                  'imagePath': item.imagePath,
                  'unit': item.unit,
                  'allowFractional': item.allowFractional,
                  'quantity': item.quantity,
                  if (item.customPrice != null) 'customPrice': item.customPrice,
                  if (item.packName != null) 'packName': item.packName,
                  if (item.packSize != null) 'packSize': item.packSize,
                })
            .toList(),
      };

  factory SuspendedSale.fromJson(Map<String, dynamic> json) => SuspendedSale(
        id: json['id'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        customerName: json['customerName'] as String?,
        comment: json['comment'] as String?,
        items: (json['items'] as List<dynamic>? ?? []).map((e) {
          final m = e as Map<String, dynamic>;
          final typeName = m['type'] as String? ?? '';
          final type = ProductArtType.values.firstWhere(
            (t) => t.name == typeName,
            orElse: () => ProductArtType.aquafina,
          );
          return ProductItem(
            m['name'] as String? ?? '',
            m['size'] as String? ?? '',
            m['price'] as String? ?? '0',
            type,
            code: m['code'] as String?,
            category: m['category'] as String?,
            imagePath: m['imagePath'] as String?,
            unit: (m['unit'] as String?) ?? 'Pcs',
            allowFractional: m['allowFractional'] == true,
            quantity: (m['quantity'] as num?)?.toDouble() ?? 1.0,
            customPrice: (m['customPrice'] as num?)?.toDouble(),
            packName: m['packName'] as String?,
            packSize: (m['packSize'] as num?)?.toDouble(),
          );
        }).toList(),
      );
}

/// Represents an individual payment chunk in a split-tender sale.
class SplitPaymentEntry {
  const SplitPaymentEntry({
    required this.method,
    required this.amount,
  });

  final String method; // 'Cash', 'M-Pesa / Mobile', 'Card / Bank', etc.
  final double amount;

  Map<String, dynamic> toJson() => {
        'method': method,
        'amount': amount,
      };

  factory SplitPaymentEntry.fromJson(Map<String, dynamic> json) =>
      SplitPaymentEntry(
        method: json['method'] as String? ?? 'Cash',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      );
}
