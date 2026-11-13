/// Ledger entries that explain how a customer's debit balance changed.
///
/// Every credit sale and every repayment is recorded so the shop can show a
/// full statement instead of a single running number.
class DebitEntry {
  const DebitEntry({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.type,
    required this.amount,
    this.note = '',
    this.orderId,
    required this.createdAt,
    this.recordedBy = '',
  });

  /// Creates an entry stamped with the current time when [createdAt] is absent.
  factory DebitEntry.now({
    required String id,
    required String customerId,
    required String customerName,
    required DebitType type,
    required double amount,
    String note = '',
    String? orderId,
    String recordedBy = '',
  }) {
    return DebitEntry(
      id: id,
      customerId: customerId,
      customerName: customerName,
      type: type,
      amount: amount,
      note: note,
      orderId: orderId,
      recordedBy: recordedBy,
      createdAt: DateTime.now(),
    );
  }

  final String id;
  final String customerId;
  final String customerName;
  final DebitType type;
  final double amount;
  final String note;
  final String? orderId;
  final DateTime createdAt;
  final String recordedBy;

  /// Positive when the entry increases the debt, negative when it reduces it.
  double get signedAmount => type == DebitType.payment ? -amount : amount;

  bool get isPayment => type == DebitType.payment;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'type': type.value,
      'amount': amount,
      'note': note,
      'order_id': orderId,
      'created_at': createdAt.toIso8601String(),
      'recorded_by': recordedBy,
    };
  }

  factory DebitEntry.fromMap(Map<String, Object?> map) {
    return DebitEntry(
      id: map['id'] as String? ?? '',
      customerId: map['customer_id'] as String? ?? '',
      customerName: map['customer_name'] as String? ?? '',
      type: DebitType.fromValue(map['type'] as String?),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      note: (map['note'] as String?) ?? '',
      orderId: map['order_id'] as String?,
      recordedBy: (map['recorded_by'] as String?) ?? '',
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}

/// Direction of a ledger entry.
enum DebitType {
  /// Goods taken on credit: increases the balance owed.
  charge('charge', 'Debit', 'Deni'),

  /// Money received from the customer: reduces the balance owed.
  payment('payment', 'Payment', 'Malipo');

  const DebitType(this.value, this.label, this.swahiliLabel);

  final String value;
  final String label;
  final String swahiliLabel;

  String localized(bool isSwahili) => isSwahili ? swahiliLabel : label;

  static DebitType fromValue(String? value) {
    for (final type in DebitType.values) {
      if (type.value == value) return type;
    }
    return DebitType.charge;
  }
}
