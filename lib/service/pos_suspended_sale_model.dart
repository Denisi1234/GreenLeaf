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

  int get itemCount => items.length;
  double get total => items.fold<double>(0.0, (sum, item) => sum + item.priceValue);

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'customerName': customerName,
        'comment': comment,
        'items': items.map((item) => item.toMap()).toList(),
      };

  factory SuspendedSale.fromJson(Map<String, dynamic> json) => SuspendedSale(
        id: json['id'] as String,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        customerName: json['customerName'] as String?,
        comment: json['comment'] as String?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => ProductItem.fromMap(e as Map<String, dynamic>))
            .toList(),
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

  factory SplitPaymentEntry.fromJson(Map<String, dynamic> json) => SplitPaymentEntry(
        method: json['method'] as String? ?? 'Cash',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      );
}
