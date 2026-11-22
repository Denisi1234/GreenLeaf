import '../utils/quantity_formatter.dart';

class Supplier {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final double openingBalance;
  final String notes;

  Supplier({
    this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.openingBalance = 0,
    this.notes = '',
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'opening_balance': openingBalance,
        'notes': notes,
      };

  factory Supplier.fromMap(Map<String, Object?> map) => Supplier(
        id: map['id'] as int?,
        name: (map['name'] ?? '').toString(),
        phone: (map['phone'] ?? '').toString(),
        email: (map['email'] ?? '').toString(),
        address: (map['address'] ?? '').toString(),
        openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0,
        notes: (map['notes'] ?? '').toString(),
      );
}

class ReceivingLine {
  final String productName;
  final double quantity;
  final double unitCost;
  final double sellingPrice;

  const ReceivingLine({
    required this.productName,
    required this.quantity,
    required this.unitCost,
    this.sellingPrice = 0,
  });

  double get total => quantity * unitCost;

  Map<String, Object?> toMap() => {
        'product_name': productName,
        'quantity': quantity,
        'unit_cost': unitCost,
        'selling_price': sellingPrice,
      };

  factory ReceivingLine.fromMap(Map<String, Object?> map) => ReceivingLine(
        productName: (map['product_name'] ?? '').toString(),
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        unitCost: (map['unit_cost'] as num?)?.toDouble() ?? 0,
        sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0,
      );
}

/// Goods received from a supplier (stock in).
class Receiving {
  final int? id;
  final int? supplierId;
  final String supplierName;
  final DateTime date;
  final String invoiceNo;
  final double total;
  final String receivedBy;
  final String notes;
  final List<ReceivingLine> lines;

  Receiving({
    this.id,
    this.supplierId,
    required this.supplierName,
    required this.date,
    this.invoiceNo = '',
    this.total = 0,
    this.receivedBy = '',
    this.notes = '',
    this.lines = const [],
  });

  double get itemCount =>
      roundQuantity(lines.fold<double>(0, (sum, line) => sum + line.quantity));

  bool get stockUpdated => lines.isEmpty;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'supplier_id': supplierId,
        'supplier_name': supplierName,
        'date': date.toIso8601String(),
        'invoice_no': invoiceNo,
        'total': total,
        'received_by': receivedBy,
        'notes': notes,
      };

  factory Receiving.fromMap(
    Map<String, Object?> map, {
    List<ReceivingLine> lines = const [],
  }) =>
      Receiving(
        id: map['id'] as int?,
        supplierId: map['supplier_id'] as int?,
        supplierName: (map['supplier_name'] ?? '').toString(),
        date:
            DateTime.tryParse((map['date'] ?? '').toString()) ?? DateTime.now(),
        invoiceNo: (map['invoice_no'] ?? '').toString(),
        total: (map['total'] as num?)?.toDouble() ?? 0,
        receivedBy: (map['received_by'] ?? '').toString(),
        notes: (map['notes'] ?? '').toString(),
        lines: lines,
      );
}
