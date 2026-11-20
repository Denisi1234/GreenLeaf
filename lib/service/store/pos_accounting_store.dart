part of '../pos_local_store.dart';

/// Accounting, ledger and bank reconciliation side of [PosLocalStore].
mixin PosAccountingStore on ChangeNotifier {
  final List<Account> _accounts = <Account>[];
  final List<JournalEntry> _journalEntries = <JournalEntry>[];
  final List<FixedAsset> _fixedAssets = <FixedAsset>[];
  final List<BankTransaction> _bankTransactions = <BankTransaction>[];
  bool _accountsSeeded = false;

  String get _activeStoreId;
  PosLocalDatabase get _database;
  List<CompletedOrder> get _orders;
  List<Expense> get _expenses;
  List<Receiving> get _receivings;
  List<Supplier> get _suppliers;
  List<RegisterShift> get _registerShifts;
  TaxSettings get _taxSettings;

  List<Account> get accounts => List.unmodifiable(_accounts);

  List<JournalEntry> get journalEntries => List.unmodifiable(_journalEntries);

  List<FixedAsset> get fixedAssets => List.unmodifiable(_fixedAssets);

  List<BankTransaction> get bankTransactions =>
      List.unmodifiable(_bankTransactions);

  Future<void> _reloadAccounting() async {
    final stored = await _database.loadAccounts(_activeStoreId);
    _accounts
      ..clear()
      ..addAll(stored.map(
        (row) => Account.fromMap(Map<String, dynamic>.from(row)),
      ));
    if (_accounts.isEmpty && !_accountsSeeded) {
      for (final account in Account.defaults()) {
        final id =
            await _database.insertAccount(account.toMap(), _activeStoreId);
        _accounts.add(Account(
          id: id,
          code: account.code,
          name: account.name,
          type: account.type,
          openingBalance: account.openingBalance,
        ));
      }
      _accountsSeeded = true;
      _accounts.sort((a, b) => a.code.compareTo(b.code));
    }

    final storedEntries = await _database.loadJournalEntries(_activeStoreId);
    final entries = <JournalEntry>[];
    for (final row in storedEntries) {
      final map = Map<String, dynamic>.from(row);
      final id = map['id'] as int?;
      final lines = id == null
          ? const <JournalLine>[]
          : (await _database.loadJournalLines(_activeStoreId, id))
              .map((line) =>
                  JournalLine.fromMap(Map<String, dynamic>.from(line)))
              .toList();
      entries.add(JournalEntry.fromMap(map, lines: lines));
    }
    _journalEntries
      ..clear()
      ..addAll(entries);

    final storedAssets = await _database.loadFixedAssets(_activeStoreId);
    _fixedAssets
      ..clear()
      ..addAll(storedAssets.map(
        (row) => FixedAsset.fromMap(Map<String, dynamic>.from(row)),
      ));

    final storedBank = await _database.loadBankTransactions(_activeStoreId);
    _bankTransactions
      ..clear()
      ..addAll(storedBank.map(
        (row) => BankTransaction.fromMap(Map<String, dynamic>.from(row)),
      ));
  }

  Future<Account> saveAccount(Account account) async {
    if (account.id == null) {
      final id = await _database.insertAccount(account.toMap(), _activeStoreId);
      await _reloadAccounting();
      notifyListeners();
      return Account(
        id: id,
        code: account.code,
        name: account.name,
        type: account.type,
        openingBalance: account.openingBalance,
      );
    }
    await _database.updateAccount(account.id!, account.toMap());
    await _reloadAccounting();
    notifyListeners();
    return account;
  }

  Future<void> deleteAccount(int id) async {
    await _database.deleteAccount(id);
    await _reloadAccounting();
    notifyListeners();
  }

  Future<void> saveJournalEntry(JournalEntry entry) async {
    final id =
        await _database.insertJournalEntry(entry.toMap(), _activeStoreId);
    if (entry.lines.isNotEmpty) {
      await _database.insertJournalLines(
        [
          for (final line in entry.lines)
            {
              'entry_id': id,
              'account_id': line.accountId,
              'debit': line.debit,
              'credit': line.credit,
            },
        ],
        _activeStoreId,
      );
    }
    await _reloadAccounting();
    notifyListeners();
  }

  Future<void> deleteJournalEntry(int id) async {
    await _database.deleteJournalEntry(id);
    await _reloadAccounting();
    notifyListeners();
  }

  Future<void> saveFixedAsset(FixedAsset asset) async {
    if (asset.id == null) {
      await _database.insertFixedAsset(asset.toMap(), _activeStoreId);
    } else {
      await _database.updateFixedAsset(asset.id!, asset.toMap());
    }
    await _reloadAccounting();
    notifyListeners();
  }

  Future<void> deleteFixedAsset(int id) async {
    await _database.deleteFixedAsset(id);
    await _reloadAccounting();
    notifyListeners();
  }

  Future<void> addBankTransaction(BankTransaction entry) async {
    await _database.insertBankTransaction(entry.toMap(), _activeStoreId);
    await _reloadAccounting();
    notifyListeners();
  }

  Future<void> setBankTransactionMatched(int id, bool matched) async {
    await _database.updateBankTransaction(id, {'matched': matched ? 1 : 0});
    await _reloadAccounting();
    notifyListeners();
  }

  Future<void> deleteBankTransaction(int id) async {
    await _database.deleteBankTransaction(id);
    await _reloadAccounting();
    notifyListeners();
  }

  /// Matches unmatched statement lines to card and mobile money sales.
  Future<int> autoMatchBankTransactions() async {
    final bankSales = <CompletedOrder>[];
    for (final order in _orders) {
      if (order.status.trim().toLowerCase() != 'completed') continue;
      final method = order.paymentMethod.toLowerCase();
      if (method.contains('cash')) continue;
      if (method.contains('debt') || method.contains('credit')) continue;
      bankSales.add(order);
    }
    var matched = 0;
    for (final entry in _bankTransactions) {
      if (entry.matched || entry.id == null) continue;
      final amount = entry.amount.abs();
      final hit = bankSales.any((order) =>
          order.total.round() == amount.round() &&
          order.dateTime.substring(0, 10) ==
              entry.date.toIso8601String().substring(0, 10));
      if (!hit) continue;
      await setBankTransactionMatched(entry.id!, true);
      matched++;
    }
    return matched;
  }

  List<LedgerPosting> ledgerPostings() => _accounting.postings(
        orders: _orders,
        expenses: _expenses,
        receivings: _receivings,
        suppliers: _suppliers,
        shifts: _registerShifts,
        fixedAssets: _fixedAssets,
        journalEntries: _journalEntries,
        accounts: _accounts,
        tax: _taxSettings,
      );

  List<TrialBalanceRow> trialBalance() =>
      _accounting.trialBalance(ledgerPostings());

  double cashOnHand() {
    final rows = trialBalance();
    final row = rows.where((item) => item.code == AccountingEngine.cashCode);
    return row.fold<double>(0, (sum, item) => sum + item.debit - item.credit);
  }
}
