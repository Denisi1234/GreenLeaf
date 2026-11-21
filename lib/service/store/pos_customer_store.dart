part of '../pos_local_store.dart';

/// Customers, debit ledgers and receivables for [PosLocalStore].
mixin PosCustomerStore on ChangeNotifier {
  String get _activeStoreId;
  PosLocalDatabase get _database;
  List<CustomerData> get _customers;
  List<CompletedOrder> get _orders;
  PhpApiClient? get cloudApi;

  List<CustomerData> get customers => _customers;

  final List<DebitEntry> _debitEntries = <DebitEntry>[];

  /// Full credit ledger, newest first.
  List<DebitEntry> get debitEntries => _debitEntries;

  /// Ledger entries for one customer, newest first.
  List<DebitEntry> debitEntriesFor(String customerId) {
    return _debitEntries
        .where((entry) => entry.customerId == customerId)
        .toList(growable: false);
  }

  /// Total money currently owed by all customers.
  double get outstandingDebit {
    var total = 0.0;
    for (final customer in _customers) {
      if (customer.debitBalance > 0) total += customer.debitBalance;
    }
    return total;
  }

  /// Number of customers with an unpaid balance.
  int get debtorCount {
    var count = 0;
    for (final customer in _customers) {
      if (customer.debitBalance > 0) count++;
    }
    return count;
  }

  /// Money collected from credit customers since [since].
  double debitCollectedSince(DateTime since) {
    var total = 0.0;
    for (final entry in _debitEntries) {
      if (!entry.isPayment) continue;
      if (entry.createdAt.isBefore(since)) continue;
      total += entry.amount;
    }
    return total;
  }

  Future<void> _persistDebitEntries() async {
    await _database.replaceDebitEntries(
      _debitEntries.map((entry) => entry.toMap()).toList(),
      _activeStoreId,
    );
  }

  Future<void> _appendDebitEntry(DebitEntry entry) async {
    _debitEntries.insert(0, entry);
    try {
      await _database.insertDebitEntry(entry.toMap(), _activeStoreId);
    } catch (_) {
      // Cloud accounts keep the ledger on the server; the in-memory entry is
      // still reported for this session.
    }
    notifyListeners();
  }

  /// Records money a customer paid towards their credit balance.
  ///
  /// Returns the updated customer, or null when the payment cannot be applied
  /// (unknown customer, non-positive amount, or nothing owed).
  Future<CustomerData?> recordDebtPayment({
    required String customerId,
    required double amount,
    String note = '',
    String recordedBy = '',
  }) async {
    final index =
        _customers.indexWhere((customer) => customer.id == customerId);
    if (index == -1) return null;
    if (amount <= 0) return null;

    final customer = _customers[index];
    final applied =
        amount > customer.debitBalance ? customer.debitBalance : amount;
    if (applied <= 0) return null;

    final updated = customer.copyWith(
      debitBalance: customer.debitBalance - applied,
    );
    _customers[index] = updated;
    await _database.upsertCustomer(
      _customerToMap(updated),
      _activeStoreId,
    );

    final entry = DebitEntry.now(
      id: 'DEB-${DateTime.now().microsecondsSinceEpoch}',
      customerId: customer.id,
      customerName: customer.name,
      type: DebitType.payment,
      amount: applied,
      note: note.trim(),
      recordedBy: recordedBy.trim().isEmpty
          ? (cloudApi?.user['name'] as String?) ?? ''
          : recordedBy.trim(),
    );
    await _appendDebitEntry(entry);
    return updated;
  }

  Future<void> addCustomer(CustomerData customer) async {
    await _database.upsertCustomer(
      _customerToMap(customer),
      _activeStoreId,
    );
    _customers.add(customer);
    notifyListeners();
  }

  CustomerData _customerFromMap(Map<String, Object?> map) {
    return CustomerData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      debitBalance: (map['debit_balance'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      tags: (map['tags'] as String? ?? '')
          .split(',')
          .where((tag) => tag.trim().isNotEmpty)
          .toList(),
    );
  }

  Map<String, Object?> _customerToMap(CustomerData customer) {
    return <String, Object?>{
      'id': customer.id,
      'name': customer.name,
      'email': customer.email,
      'phone': customer.phone,
      'address': customer.address,
      'debit_balance': customer.debitBalance,
      'created_at': customer.createdAt.toIso8601String(),
      'tags': customer.tags.join(','),
    };
  }

  Future<void> updateCustomer(CustomerData customer) async {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index == -1) return;
    await _database.upsertCustomer(
      _customerToMap(customer),
      _activeStoreId,
    );
    _customers[index] = customer;
    notifyListeners();
  }

  Future<void> deleteCustomer(String customerId) async {
    await _database.deleteCustomerRecord(customerId, _activeStoreId);
    _customers.removeWhere((c) => c.id == customerId);
    _debitEntries.removeWhere((entry) => entry.customerId == customerId);
    await _persistDebitEntries();
    notifyListeners();
  }

  /// Removes a single ledger entry (for example a mis-recorded payment) and
  /// re-applies it to the customer's outstanding balance.
  Future<void> deleteDebitEntry(String entryId) async {
    final index = _debitEntries.indexWhere((entry) => entry.id == entryId);
    if (index == -1) return;
    final entry = _debitEntries[index];
    _debitEntries.removeAt(index);

    final customerIndex =
        _customers.indexWhere((customer) => customer.id == entry.customerId);
    if (customerIndex != -1) {
      final customer = _customers[customerIndex];
      final next = customer.debitBalance - entry.signedAmount;
      _customers[customerIndex] =
          customer.copyWith(debitBalance: next > 0 ? next : 0);
      await _database.upsertCustomer(
        _customerToMap(_customers[customerIndex]),
        _activeStoreId,
      );
    }

    await _persistDebitEntries();
    notifyListeners();
  }

  /// Clears all old debit entries and resets debtor balances across the active store.
  Future<void> clearAllDebits() async {
    _debitEntries.clear();
    for (var i = 0; i < _customers.length; i++) {
      if (_customers[i].debitBalance > 0) {
        _customers[i] = _customers[i].copyWith(debitBalance: 0);
        await _database.upsertCustomer(
          _customerToMap(_customers[i]),
          _activeStoreId,
        );
      }
    }
    await _persistDebitEntries();
    notifyListeners();
  }

  CustomerData? customerById(String id) {
    for (final c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  CustomerData? customerByName(String name) {
    for (final c in _customers) {
      if (c.name == name) return c;
    }
    return null;
  }

  List<CompletedOrder> ordersForCustomer(String name) {
    return _orders.where((o) => o.customerName == name).toList();
  }
}
