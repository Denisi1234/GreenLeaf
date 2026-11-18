class Store {
  final String id;
  final String name;
  final String address;
  final String contact;

  const Store({
    required this.id,
    required this.name,
    required this.address,
    required this.contact,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'contact': contact,
    };
  }

  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      contact: (map['contact'] ?? '').toString(),
    );
  }

  Store copyWith({
    String? id,
    String? name,
    String? address,
    String? contact,
  }) {
    return Store(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contact: contact ?? this.contact,
    );
  }
}

class StoreSnapshot {
  const StoreSnapshot({
    required this.store,
    required this.orders,
    required this.inventory,
    required this.expenses,
    required this.customers,
    required this.shifts,
    required this.suppliers,
    required this.receivings,
    required this.tax,
    required this.trialBalanceRows,
    required this.fixedAssets,
    required this.bankTransactions,
    this.cashUpFor,
  });

  final Store store;
  final List<dynamic> orders;
  final List<dynamic> inventory;
  final List<dynamic> expenses;
  final List<dynamic> customers;
  final List<dynamic> shifts;
  final List<dynamic> suppliers;
  final List<dynamic> receivings;
  final dynamic tax;
  final List<dynamic> trialBalanceRows;
  final List<dynamic> fixedAssets;
  final List<dynamic> bankTransactions;
  final dynamic cashUpFor;

  String get label => store.name.trim().isEmpty ? store.id : store.name.trim();
}
