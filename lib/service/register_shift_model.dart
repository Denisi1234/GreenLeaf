/// Direction of a manual cash movement inside an open register shift.
enum CashMovementType {
  cashIn('cash_in', 'Cash In', 'Pesa Kuingia'),
  payout('payout', 'Payout', 'Pesa Kutoka'),
  drop('drop', 'Bank Drop', 'Pesa Kupelekwa Benki');

  const CashMovementType(this.value, this.label, this.swahiliLabel);

  final String value;
  final String label;
  final String swahiliLabel;

  String localized(bool isSwahili) => isSwahili ? swahiliLabel : label;

  /// Money leaving the drawer for `cashOut` and `drop`.
  bool get isOutflow => this != CashMovementType.cashIn;

  static CashMovementType fromValue(String? value) {
    for (final type in CashMovementType.values) {
      if (type.value == value) return type;
    }
    return CashMovementType.cashIn;
  }
}

/// Lifecycle of a register shift.
enum RegisterShiftStatus {
  open('open', 'Open', 'Wazi'),
  closed('closed', 'Closed', 'Imefungwa');

  const RegisterShiftStatus(this.value, this.label, this.swahiliLabel);

  final String value;
  final String label;
  final String swahiliLabel;

  String localized(bool isSwahili) => isSwahili ? swahiliLabel : label;

  static RegisterShiftStatus fromValue(String? value) {
    for (final status in RegisterShiftStatus.values) {
      if (status.value == value) return status;
    }
    return RegisterShiftStatus.closed;
  }
}

/// A single manual cash movement recorded while a shift is open.
class CashMovement {
  final int? id;
  final String shiftId;
  final CashMovementType type;
  final double amount;
  final String reason;
  final DateTime at;
  final String recordedBy;

  CashMovement({
    this.id,
    required this.shiftId,
    required this.type,
    required this.amount,
    this.reason = '',
    required this.at,
    this.recordedBy = '',
  });

  /// Positive for money added to the drawer, negative for money removed.
  double get signedAmount => type.isOutflow ? -amount : amount;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'shift_id': shiftId,
        'type': type.value,
        'amount': amount,
        'reason': reason,
        'at': at.toIso8601String(),
        'recorded_by': recordedBy,
      };

  factory CashMovement.fromMap(Map<String, Object?> map) => CashMovement(
        id: map['id'] as int?,
        shiftId: (map['shift_id'] ?? '').toString(),
        type: CashMovementType.fromValue(map['type']?.toString()),
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        reason: (map['reason'] ?? '').toString(),
        at: DateTime.tryParse((map['at'] ?? '').toString()) ?? DateTime.now(),
        recordedBy: (map['recorded_by'] ?? '').toString(),
      );
}

/// A register session: cash counted in at opening, closed with a counted total.
class RegisterShift {
  final int? id;
  final String register;
  final String openedBy;
  final DateTime openedAt;
  final double openingFloat;
  final DateTime? closedAt;
  final String closedBy;
  final double countedCash;
  final String notes;
  final List<CashMovement> movements;

  RegisterShift({
    this.id,
    required this.register,
    required this.openedBy,
    required this.openedAt,
    required this.openingFloat,
    this.closedAt,
    this.closedBy = '',
    this.countedCash = 0,
    this.notes = '',
    this.movements = const [],
  });

  RegisterShiftStatus get status =>
      closedAt == null ? RegisterShiftStatus.open : RegisterShiftStatus.closed;

  bool get isOpen => closedAt == null;

  DateTime get endsAt => closedAt ?? DateTime.now();

  /// Sum of every manual movement in the drawer for this shift.
  double get movementsTotal =>
      movements.fold<double>(0, (sum, movement) => sum + movement.signedAmount);

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'register': register,
        'opened_by': openedBy,
        'opened_at': openedAt.toIso8601String(),
        'opening_float': openingFloat,
        'closed_at': closedAt?.toIso8601String(),
        'closed_by': closedBy,
        'counted_cash': countedCash,
        'notes': notes,
      };

  factory RegisterShift.fromMap(Map<String, Object?> map) => RegisterShift(
        id: map['id'] as int?,
        register: (map['register'] ?? '').toString(),
        openedBy: (map['opened_by'] ?? '').toString(),
        openedAt: DateTime.tryParse((map['opened_at'] ?? '').toString()) ??
            DateTime.now(),
        openingFloat: (map['opening_float'] as num?)?.toDouble() ?? 0,
        closedAt:
            map['closed_at'] == null || (map['closed_at'] as String).isEmpty
                ? null
                : DateTime.tryParse(map['closed_at'].toString()),
        closedBy: (map['closed_by'] ?? '').toString(),
        countedCash: (map['counted_cash'] as num?)?.toDouble() ?? 0,
        notes: (map['notes'] ?? '').toString(),
      );
}

/// Reconciled cash position for one shift.
class CashUpSummary {
  final double openingFloat;
  final double cashSales;
  final double cashIn;
  final double cashOut;
  final double expected;
  final double counted;
  final double variance;

  const CashUpSummary({
    required this.openingFloat,
    required this.cashSales,
    required this.cashIn,
    required this.cashOut,
    required this.expected,
    required this.counted,
    required this.variance,
  });

  bool get isBalanced => variance.abs() < 0.5;
}
