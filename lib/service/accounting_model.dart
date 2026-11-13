enum AccountType {
  asset('asset', 'Asset', 'Mali'),
  liability('liability', 'Liability', 'Denki'),
  equity('equity', 'Equity', 'Mtaji'),
  income('income', 'Income', 'Mapato'),
  expense('expense', 'Expense', 'Matumizi');

  const AccountType(this.value, this.label, this.swahiliLabel);

  final String value;
  final String label;
  final String swahiliLabel;

  String localized(bool isSwahili) => isSwahili ? swahiliLabel : label;

  bool get isBalanceSheet =>
      this == AccountType.asset ||
      this == AccountType.liability ||
      this == AccountType.equity;

  static AccountType fromValue(String? value) {
    for (final type in AccountType.values) {
      if (type.value == value) return type;
    }
    return AccountType.expense;
  }
}

class Account {
  final int? id;
  final String code;
  final String name;
  final AccountType type;
  final double openingBalance;

  const Account({
    this.id,
    required this.code,
    required this.name,
    required this.type,
    this.openingBalance = 0,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'code': code,
        'name': name,
        'type': type.value,
        'opening_balance': openingBalance,
      };

  factory Account.fromMap(Map<String, Object?> map) => Account(
        id: map['id'] as int?,
        code: (map['code'] ?? '').toString(),
        name: (map['name'] ?? '').toString(),
        type: AccountType.fromValue(map['type']?.toString()),
        openingBalance: (map['opening_balance'] as num?)?.toDouble() ?? 0,
      );

  static List<Account> defaults() => const [
        Account(code: '1000', name: 'Cash on hand', type: AccountType.asset),
        Account(code: '1010', name: 'Bank', type: AccountType.asset),
        Account(
            code: '1100', name: 'Accounts receivable', type: AccountType.asset),
        Account(code: '1200', name: 'Inventory', type: AccountType.asset),
        Account(code: '1500', name: 'Fixed assets', type: AccountType.asset),
        Account(
            code: '2000',
            name: 'Accounts payable',
            type: AccountType.liability),
        Account(code: '2100', name: 'Tax payable', type: AccountType.liability),
        Account(code: '3000', name: 'Owner equity', type: AccountType.equity),
        Account(code: '4000', name: 'Sales', type: AccountType.income),
        Account(
            code: '5000',
            name: 'Cost of goods sold',
            type: AccountType.expense),
        Account(
            code: '6000',
            name: 'Operating expenses',
            type: AccountType.expense),
        Account(code: '7000', name: 'Depreciation', type: AccountType.expense),
        Account(code: '8000', name: 'Drawings', type: AccountType.equity),
      ];
}

class JournalLine {
  final int? accountId;
  final double debit;
  final double credit;

  const JournalLine({
    this.accountId,
    this.debit = 0,
    this.credit = 0,
  });

  Map<String, Object?> toMap() => {
        'account_id': accountId,
        'debit': debit,
        'credit': credit,
      };

  factory JournalLine.fromMap(Map<String, Object?> map) => JournalLine(
        accountId: map['account_id'] as int?,
        debit: (map['debit'] as num?)?.toDouble() ?? 0,
        credit: (map['credit'] as num?)?.toDouble() ?? 0,
      );
}

class JournalEntry {
  final int? id;
  final DateTime date;
  final String memo;
  final String createdBy;
  final List<JournalLine> lines;

  const JournalEntry({
    this.id,
    required this.date,
    required this.memo,
    this.createdBy = '',
    this.lines = const [],
  });

  double get debitTotal =>
      lines.fold<double>(0, (sum, line) => sum + line.debit);

  double get creditTotal =>
      lines.fold<double>(0, (sum, line) => sum + line.credit);

  bool get isBalanced => (debitTotal - creditTotal).abs() < 0.01;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String(),
        'memo': memo,
        'created_by': createdBy,
      };

  factory JournalEntry.fromMap(
    Map<String, Object?> map, {
    List<JournalLine> lines = const [],
  }) =>
      JournalEntry(
        id: map['id'] as int?,
        date:
            DateTime.tryParse((map['date'] ?? '').toString()) ?? DateTime.now(),
        memo: (map['memo'] ?? '').toString(),
        createdBy: (map['created_by'] ?? '').toString(),
        lines: lines,
      );
}

/// Straight-line depreciable fixed asset.
class FixedAsset {
  final int? id;
  final String name;
  final String category;
  final DateTime purchaseDate;
  final double cost;
  final double salvageValue;
  final int usefulLifeYears;

  const FixedAsset({
    this.id,
    required this.name,
    required this.category,
    required this.purchaseDate,
    required this.cost,
    this.salvageValue = 0,
    this.usefulLifeYears = 5,
  });

  double get depreciableBase =>
      cost - salvageValue < 0 ? 0 : cost - salvageValue;

  double get annualDepreciation =>
      usefulLifeYears <= 0 ? 0 : depreciableBase / usefulLifeYears;

  double get monthlyDepreciation => annualDepreciation / 12;

  double get ageInYears {
    final days = DateTime.now().difference(purchaseDate).inDays;
    return days <= 0 ? 0 : days / 365;
  }

  double accumulatedDepreciation([DateTime? asOf]) {
    final months =
        ((asOf ?? DateTime.now()).difference(purchaseDate).inDays / 30)
            .clamp(0, usefulLifeYears * 12)
            .toDouble();
    return monthlyDepreciation * months;
  }

  double netBookValue([DateTime? asOf]) =>
      cost - accumulatedDepreciation(asOf).clamp(0, depreciableBase);

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'purchase_date': purchaseDate.toIso8601String(),
        'cost': cost,
        'salvage_value': salvageValue,
        'useful_life_years': usefulLifeYears,
      };

  factory FixedAsset.fromMap(Map<String, Object?> map) => FixedAsset(
        id: map['id'] as int?,
        name: (map['name'] ?? '').toString(),
        category: (map['category'] ?? '').toString(),
        purchaseDate:
            DateTime.tryParse((map['purchase_date'] ?? '').toString()) ??
                DateTime.now(),
        cost: (map['cost'] as num?)?.toDouble() ?? 0,
        salvageValue: (map['salvage_value'] as num?)?.toDouble() ?? 0,
        usefulLifeYears: (map['useful_life_years'] as num?)?.toInt() ?? 5,
      );
}

/// Imported or manually recorded bank statement line.
class BankTransaction {
  final int? id;
  final DateTime date;
  final String description;
  final double amount;
  final String reference;
  final bool matched;
  final String accountName;

  const BankTransaction({
    this.id,
    required this.date,
    required this.description,
    required this.amount,
    this.reference = '',
    this.matched = false,
    this.accountName = 'Bank',
  });

  bool get isInflow => amount >= 0;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String(),
        'description': description,
        'amount': amount,
        'reference': reference,
        'matched': matched ? 1 : 0,
        'account_name': accountName,
      };

  factory BankTransaction.fromMap(Map<String, Object?> map) => BankTransaction(
        id: map['id'] as int?,
        date:
            DateTime.tryParse((map['date'] ?? '').toString()) ?? DateTime.now(),
        description: (map['description'] ?? '').toString(),
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        reference: (map['reference'] ?? '').toString(),
        matched: (map['matched'] as num?)?.toInt() == 1,
        accountName: (map['account_name'] ?? 'Bank').toString(),
      );
}
