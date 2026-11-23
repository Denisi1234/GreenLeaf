part of '../pos_local_store.dart';

/// Expense tracking management for [PosLocalStore].
mixin PosExpenseStore on ChangeNotifier {
  PosLocalDatabase get _database;
  String get _activeStoreId;
  List<Expense> get _expenses;
  Future<AuditLogEntry> recordAuditEvent({
    required AuditModule module,
    required String action,
    AuditSeverity severity = AuditSeverity.info,
    required String entityType,
    String entityId = '',
    String entityLabel = '',
    required String summary,
    Map<String, String> beforeValues = const <String, String>{},
    Map<String, String> afterValues = const <String, String>{},
    Map<String, String> metadata = const <String, String>{},
    String? actorIdOverride,
    String? actorNameOverride,
    String? actorRoleOverride,
  });

  List<Expense> get expenses => List.unmodifiable(_expenses);

  Future<void> addExpense(Expense expense) async {
    await _database.insertExpense(expense.toMap(), _activeStoreId);
    await _reloadExpenses();
    notifyListeners();
    unawaited(
      recordAuditEvent(
        module: AuditModule.expenses,
        action: 'expense.added',
        severity: AuditSeverity.info,
        entityType: 'Expense',
        entityLabel: expense.title,
        summary:
            'Recorded ${expense.category} expense ${expense.title} (${expense.totalWithTax.toStringAsFixed(0)} TSh)',
        afterValues: {
          'Title': expense.title,
          'Category': expense.category,
          'Total': expense.totalWithTax.toStringAsFixed(2),
          'Payment': expense.paymentMethod,
        },
      ),
    );
  }

  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) return;
    Expense? previous;
    for (final item in _expenses) {
      if (item.id == expense.id) {
        previous = item;
        break;
      }
    }
    await _database.updateExpense(expense.id!, expense.toMap());
    await _reloadExpenses();
    notifyListeners();
    unawaited(
      recordAuditEvent(
        module: AuditModule.expenses,
        action: 'expense.updated',
        severity: AuditSeverity.warning,
        entityType: 'Expense',
        entityId: '${expense.id}',
        entityLabel: expense.title,
        summary: 'Updated expense ${expense.title}',
        beforeValues: previous == null
            ? const <String, String>{}
            : {
                'Title': previous.title,
                'Category': previous.category,
                'Total': previous.totalWithTax.toStringAsFixed(2),
                'Status': previous.status.label,
              },
        afterValues: {
          'Title': expense.title,
          'Category': expense.category,
          'Total': expense.totalWithTax.toStringAsFixed(2),
          'Status': expense.status.label,
        },
      ),
    );
  }

  Future<void> deleteExpense(int id) async {
    Expense? removed;
    for (final item in _expenses) {
      if (item.id == id) {
        removed = item;
        break;
      }
    }
    await _database.deleteExpense(id);
    _expenses.removeWhere((expense) => expense.id == id);
    notifyListeners();
    unawaited(
      recordAuditEvent(
        module: AuditModule.expenses,
        action: 'expense.deleted',
        severity: AuditSeverity.critical,
        entityType: 'Expense',
        entityId: '$id',
        entityLabel: removed?.title ?? 'Expense #$id',
        summary:
            'Deleted expense ${removed?.title ?? '#$id'} (${(removed?.totalWithTax ?? 0).toStringAsFixed(0)} TSh)',
        beforeValues: removed == null
            ? const <String, String>{}
            : {
                'Title': removed.title,
                'Category': removed.category,
                'Total': removed.totalWithTax.toStringAsFixed(2),
              },
      ),
    );
  }

  Future<void> _reloadExpenses() async {
    _expenses
      ..clear()
      ..addAll((await _database.loadExpenses(_activeStoreId)).map(
        (row) => Expense.fromMap(Map<String, dynamic>.from(row)),
      ));
  }
}
