part of '../pos_local_store.dart';

/// Expense tracking management for [PosLocalStore].
mixin PosExpenseStore on ChangeNotifier {
  PosLocalDatabase get _database;
  String get _activeStoreId;
  List<Expense> get _expenses;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  Future<void> addExpense(Expense expense) async {
    await _database.insertExpense(expense.toMap(), _activeStoreId);
    await _reloadExpenses();
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) return;
    await _database.updateExpense(expense.id!, expense.toMap());
    await _reloadExpenses();
    notifyListeners();
  }

  Future<void> deleteExpense(int id) async {
    await _database.deleteExpense(id);
    _expenses.removeWhere((expense) => expense.id == id);
    notifyListeners();
  }

  Future<void> _reloadExpenses() async {
    _expenses
      ..clear()
      ..addAll((await _database.loadExpenses(_activeStoreId)).map(
        (row) => Expense.fromMap(Map<String, dynamic>.from(row)),
      ));
  }
}
