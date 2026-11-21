import 'package:flutter/foundation.dart';
import '../accounting_engine.dart';
import '../accounting_model.dart';
import '../pos_local_store.dart';

/// Focused, injectable Accounting & Ledger Service.
///
/// Can be injected directly via `Provider<AccountingService>` or accessed through `store.accountingService`.
class AccountingService extends ChangeNotifier {
  AccountingService(this._store) {
    _snapshot = _captureSnapshot();
    _store.addListener(_onStoreUpdate);
  }

  final PosLocalStore _store;
  late (int, int, int, int, int) _snapshot;

  (int, int, int, int, int) _captureSnapshot() => (
        _store.accounts.length,
        _store.journalEntries.length,
        _store.fixedAssets.length,
        _store.bankTransactions.length,
        _store.orders.length,
      );

  void _onStoreUpdate() {
    final next = _captureSnapshot();
    if (next == _snapshot) return;
    _snapshot = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreUpdate);
    super.dispose();
  }

  List<Account> get accounts => _store.accounts;
  List<JournalEntry> get journalEntries => _store.journalEntries;
  List<FixedAsset> get fixedAssets => _store.fixedAssets;
  List<BankTransaction> get bankTransactions => _store.bankTransactions;

  Future<Account> addAccount(Account account) => _store.saveAccount(account);

  Future<Account> updateAccount(Account account) => _store.saveAccount(account);

  Future<void> deleteAccount(int id) => _store.deleteAccount(id);

  Future<void> recordJournalEntry(JournalEntry entry) =>
      _store.saveJournalEntry(entry);

  Future<void> deleteJournalEntry(int id) => _store.deleteJournalEntry(id);

  List<LedgerPosting> ledgerPostings() => _store.ledgerPostings();

  List<TrialBalanceRow> trialBalance() => _store.trialBalance();

  double cashOnHand() => _store.cashOnHand();

  Future<void> addFixedAsset(FixedAsset asset) =>
      _store.saveFixedAsset(asset);

  Future<void> updateFixedAsset(FixedAsset asset) =>
      _store.saveFixedAsset(asset);

  Future<void> deleteFixedAsset(int id) => _store.deleteFixedAsset(id);

  Future<void> addBankTransaction(BankTransaction txn) =>
      _store.addBankTransaction(txn);

  Future<void> deleteBankTransaction(int id) =>
      _store.deleteBankTransaction(id);

  Future<void> setBankTransactionMatched(int id, bool matched) =>
      _store.setBankTransactionMatched(id, matched);

  Future<void> unmatchBankTransaction(int transactionId) =>
      _store.setBankTransactionMatched(transactionId, false);

  Future<int> autoMatchBankTransactions() =>
      _store.autoMatchBankTransactions();
}
