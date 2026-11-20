import 'package:flutter/foundation.dart';
import '../accounting_model.dart';
import '../pos_local_store.dart';

/// Focused, injectable Accounting & Ledger Service.
///
/// Can be injected directly via `Provider<AccountingService>` or accessed through `store.accountingService`.
class AccountingService extends ChangeNotifier {
  AccountingService(this._store) {
    _store.addListener(_onStoreUpdate);
  }

  final PosLocalStore _store;

  void _onStoreUpdate() {
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

  Future<void> addAccount(Account account) => _store.addAccount(account);

  Future<void> updateAccount(Account account) => _store.updateAccount(account);

  Future<void> deleteAccount(String id) => _store.deleteAccount(id);

  Future<void> recordJournalEntry(JournalEntry entry) =>
      _store.recordJournalEntry(entry);

  Future<void> deleteJournalEntry(String id) => _store.deleteJournalEntry(id);

  TrialBalance trialBalance() => _store.trialBalance();

  ProfitAndLoss profitAndLoss({DateTime? from, DateTime? to}) =>
      _store.profitAndLoss(from: from, to: to);

  BalanceSheet balanceSheet({DateTime? asOf}) =>
      _store.balanceSheet(asOf: asOf);

  List<LedgerRow> accountLedger(String accountId) =>
      _store.accountLedger(accountId);

  Future<void> addFixedAsset(FixedAsset asset) => _store.addFixedAsset(asset);

  Future<void> updateFixedAsset(FixedAsset asset) =>
      _store.updateFixedAsset(asset);

  Future<void> deleteFixedAsset(String id) => _store.deleteFixedAsset(id);

  Future<void> runDepreciationForYear({required int year}) =>
      _store.runDepreciationForYear(year: year);

  Future<void> addBankTransaction(BankTransaction txn) =>
      _store.addBankTransaction(txn);

  Future<void> updateBankTransaction(BankTransaction txn) =>
      _store.updateBankTransaction(txn);

  Future<void> deleteBankTransaction(String id) =>
      _store.deleteBankTransaction(id);

  Future<void> matchBankTransaction({
    required String transactionId,
    required String matchedType,
    required String matchedId,
  }) =>
      _store.matchBankTransaction(
        transactionId: transactionId,
        matchedType: matchedType,
        matchedId: matchedId,
      );

  Future<void> unmatchBankTransaction(String transactionId) =>
      _store.unmatchBankTransaction(transactionId);

  Future<int> autoMatchBankTransactions() =>
      _store.autoMatchBankTransactions();
}
