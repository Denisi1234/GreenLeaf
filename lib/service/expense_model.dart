/// Lifecycle state of a recorded expense.
enum ExpenseStatus {
  draft('draft', 'Draft', 'Rasimu'),
  submitted('submitted', 'Submitted', 'Imewasilishwa'),
  approved('approved', 'Approved', 'Imeidhinishwa'),
  reimbursed('reimbursed', 'Reimbursed', 'Imelipwa');

  const ExpenseStatus(this.value, this.label, this.swahiliLabel);

  final String value;
  final String label;
  final String swahiliLabel;

  String localized(bool isSwahili) => isSwahili ? swahiliLabel : label;

  static ExpenseStatus fromValue(String? value) {
    for (final status in ExpenseStatus.values) {
      if (status.value == value) return status;
    }
    return ExpenseStatus.submitted;
  }
}

/// Business expense record model.
/// Represents a single expense entry with category, payment method, vendor,
/// optional tax, receipt attachment, and approval status.
class Expense {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final String paymentMethod;
  final DateTime date;
  final String? notes;
  final String vendor;
  final double taxAmount;
  final String? receiptPath;
  final ExpenseStatus status;
  final String createdAt;
  final String updatedAt;

  Expense({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.paymentMethod,
    required this.date,
    this.notes,
    this.vendor = '',
    this.taxAmount = 0,
    this.receiptPath,
    this.status = ExpenseStatus.submitted,
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  /// Amount inclusive of tax (amount + tax).
  double get totalWithTax => amount + taxAmount;

  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    String? paymentMethod,
    DateTime? date,
    String? notes,
    String? vendor,
    double? taxAmount,
    String? receiptPath,
    ExpenseStatus? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      vendor: vendor ?? this.vendor,
      taxAmount: taxAmount ?? this.taxAmount,
      receiptPath: receiptPath ?? this.receiptPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'payment_method': paymentMethod,
      'date': date.toIso8601String(),
      'notes': notes,
      'vendor': vendor,
      'tax_amount': taxAmount,
      'receipt_path': receiptPath,
      'status': status.value,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      paymentMethod: map['payment_method'] as String,
      date: DateTime.parse(map['date'] as String),
      notes: map['notes'] as String?,
      vendor: (map['vendor'] as String?) ?? '',
      taxAmount: (map['tax_amount'] as num?)?.toDouble() ?? 0,
      receiptPath: map['receipt_path'] as String?,
      status: ExpenseStatus.fromValue(map['status'] as String?),
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
