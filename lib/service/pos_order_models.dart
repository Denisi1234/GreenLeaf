import '../ui/models/product_item.dart';

/// Represents a completed sale order with all transaction details.
class CompletedOrder {
  /// Creates an immutable completed order record.
  const CompletedOrder({
    required this.id,
    required this.dateTime,
    required this.date,
    required this.time,
    required this.total,
    required this.status,
    required this.cashierName,
    required this.register,
    required this.paymentMethod,
    required this.cashTendered,
    required this.changeDue,
    required this.lines,
    this.customerName,
    this.discountAmount,
    this.discountLabel,
  });

  final String id;
  final String dateTime;
  final String date;
  final String time;
  final double total;
  final String status;
  final String cashierName;
  final String register;
  final String paymentMethod;
  final double cashTendered;
  final double changeDue;
  final List<OrderLine> lines;
  final String? customerName;
  final double? discountAmount;
  final String? discountLabel;
}

/// Single line item within an order.
/// Links to product data and calculates line total.
class OrderLine {
  const OrderLine({
    required this.itemCode,
    required this.itemCategory,
    required this.itemName,
    required this.itemSize,
    required this.quantity,
    required this.unitPrice,
    required this.unitPriceValue,
    required this.artType,
    required this.imagePath,
  });

  final String? itemCode;
  final String? itemCategory;
  final String itemName;
  final String itemSize;
  final int quantity;
  final String unitPrice;
  final double unitPriceValue;
  final ProductArtType artType;
  final String? imagePath;

  double get lineTotal => unitPriceValue * quantity;

  ProductItem get product => ProductItem(
        itemName,
        itemSize,
        unitPrice,
        artType,
        code: itemCode,
        category: itemCategory,
        imagePath: imagePath,
      );
}
