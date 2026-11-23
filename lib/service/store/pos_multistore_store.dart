part of '../pos_local_store.dart';

/// Multi-store management and cross-store snapshot loading for [PosLocalStore].
mixin PosMultiStore on ChangeNotifier {
  PosLocalDatabase get _database;
  List<Store> get _stores;
  String get _activeStoreId;
  set _activeStoreId(String value);
  bool get _isInitialized;
  set _isInitialized(bool value);
  bool get _disposed;
  AppProfileData get _profile;
  set _profile(AppProfileData value);
  Future<void> reloadFromLocal();
  Future<void> initialize();
  Future<void> _saveUiConfig();
  CustomerData _customerFromMap(Map<String, Object?> map);
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

  Future<void> _ensureStoresLoaded() async {
    try {
      final rows = await _database.loadStores();
      _stores
        ..clear()
        ..addAll(
            rows.map((row) => Store.fromMap(Map<String, dynamic>.from(row))));
    } catch (_) {
      _stores.clear();
    }
    if (_stores.isEmpty) {
      _stores.add(const Store(
        id: _defaultStoreId,
        name: 'Default Store',
        address: '',
        contact: '',
      ));
      try {
        await _database.upsertStore(_stores.first.toMap());
      } catch (_) {}
    }
    if (!_stores.any((s) => s.id == _activeStoreId)) {
      _activeStoreId = _stores.first.id;
    }
    final db = _database;
    if (db is PosHybridDatabase) {
      db.storeId = _activeStoreId;
      db.onSynced = () {
        if (!_disposed && _isInitialized) {
          reloadFromLocal();
        }
      };
      db.startAutoSync();
    }
  }

  Future<void> saveStore(Store store) async {
    final existed = _stores.any((s) => s.id == store.id);
    await _database.upsertStore(store.toMap());
    await _ensureStoresLoaded();
    if (_activeStoreId == store.id) {
      _profile = _profile.copyWith(storeName: store.name);
    }
    notifyListeners();
    unawaited(
      recordAuditEvent(
        module: AuditModule.settings,
        action: 'store.saved',
        severity: AuditSeverity.info,
        entityType: 'Store',
        entityId: store.id,
        entityLabel: store.name,
        summary: '${existed ? 'Updated' : 'Created'} store ${store.name}',
      ),
    );
  }

  Future<void> createStore({
    required String name,
    String address = '',
    String contact = '',
  }) async {
    final id = 'store-${DateTime.now().millisecondsSinceEpoch}';
    final store = Store(
        id: id,
        name: name.trim(),
        address: address.trim(),
        contact: contact.trim());
    await saveStore(store);
  }

  Future<void> deleteStore(String id) async {
    if (id == _defaultStoreId || _stores.length <= 1) return;
    Store? target;
    for (final s in _stores) {
      if (s.id == id) {
        target = s;
        break;
      }
    }
    await _database.deleteStore(id);
    unawaited(
      recordAuditEvent(
        module: AuditModule.settings,
        action: 'store.deleted',
        severity: AuditSeverity.critical,
        entityType: 'Store',
        entityId: id,
        entityLabel: target?.name ?? id,
        summary: 'Deleted store branch ${target?.name ?? id}',
      ),
    );
    if (_activeStoreId == id) {
      _activeStoreId = _defaultStoreId;
      await _saveUiConfig();
      await _reloadActiveStoreData();
    } else {
      await _ensureStoresLoaded();
      notifyListeners();
    }
  }

  Future<void> switchStore(String id) async {
    if (id == _activeStoreId) return;
    if (!_stores.any((s) => s.id == id)) return;
    final prevStoreId = _activeStoreId;
    final nextName = _stores.firstWhere((s) => s.id == id).name;
    _activeStoreId = id;
    final db = _database;
    if (db is PosHybridDatabase) {
      db.storeId = _activeStoreId;
      db.onSynced = () {
        if (!_disposed && _isInitialized) {
          reloadFromLocal();
        }
      };
      db.startAutoSync();
    }
    await _saveUiConfig();
    await _reloadActiveStoreData();
    unawaited(
      recordAuditEvent(
        module: AuditModule.settings,
        action: 'store.switched',
        severity: AuditSeverity.info,
        entityType: 'Store',
        entityId: id,
        entityLabel: nextName,
        summary: 'Switched active store from $prevStoreId to $nextName',
      ),
    );
  }

  Future<void> _reloadActiveStoreData() async {
    await _ensureStoresLoaded();
    _isInitialized = false;
    await initialize();
  }

  Future<List<StoreSnapshot>> loadAllStoreSnapshots() async {
    await _ensureStoresLoaded();
    final snapshots = <StoreSnapshot>[];
    for (final store in _stores) {
      snapshots.add(await _loadStoreSnapshot(store));
    }
    return snapshots;
  }

  Future<StoreSnapshot> _loadStoreSnapshot(Store store) async {
    final sid = store.id;
    final orders = await _database.loadOrders(sid);
    final inventory = await _database.loadInventory(sid);
    final expenses = (await _database.loadExpenses(sid))
        .map((e) => Expense.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final customers = (await _database.loadCustomers(sid))
        .map((c) => _customerFromMap(Map<String, Object?>.from(c)))
        .toList();
    final shiftRows = await _database.loadRegisterShifts(sid);
    final movementRows = await _database.loadCashMovements(sid);
    final movements = movementRows
        .map((m) => CashMovement.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    final shifts = shiftRows.map((s) {
      final shift = RegisterShift.fromMap(Map<String, dynamic>.from(s));
      final shiftKey = shift.id?.toString() ?? '';
      final list = movements.where((m) => m.shiftId == shiftKey).toList()
        ..sort((a, b) => b.at.compareTo(a.at));
      return RegisterShift(
        id: shift.id,
        register: shift.register,
        openedBy: shift.openedBy,
        openedAt: shift.openedAt,
        openingFloat: shift.openingFloat,
        closedAt: shift.closedAt,
        closedBy: shift.closedBy,
        countedCash: shift.countedCash,
        notes: shift.notes,
        movements: list,
      );
    }).toList();
    final suppliers = (await _database.loadSuppliers(sid))
        .map((s) => Supplier.fromMap(Map<String, dynamic>.from(s)))
        .toList();
    final receivingRows = await _database.loadReceivings(sid);
    final receivings = <Receiving>[];
    for (final row in receivingRows) {
      final map = Map<String, dynamic>.from(row);
      final id = map['id'] as int?;
      final lines = id == null
          ? const <ReceivingLine>[]
          : (await _database.loadReceivingLines(sid, id))
              .map((l) => ReceivingLine.fromMap(Map<String, dynamic>.from(l)))
              .toList();
      receivings.add(Receiving.fromMap(map, lines: lines));
    }
    final tax = await _database.loadTaxSettings();
    final accounts = (await _database.loadAccounts(sid))
        .map((a) => Account.fromMap(Map<String, dynamic>.from(a)))
        .toList();
    final journalRows = await _database.loadJournalEntries(sid);
    final journalEntries = <JournalEntry>[];
    for (final row in journalRows) {
      final map = Map<String, dynamic>.from(row);
      final id = map['id'] as int?;
      final lines = id == null
          ? const <JournalLine>[]
          : (await _database.loadJournalLines(sid, id))
              .map((l) => JournalLine.fromMap(Map<String, dynamic>.from(l)))
              .toList();
      journalEntries.add(JournalEntry.fromMap(map, lines: lines));
    }
    final fixedAssets = (await _database.loadFixedAssets(sid))
        .map((a) => FixedAsset.fromMap(Map<String, dynamic>.from(a)))
        .toList();
    final bankTransactions = (await _database.loadBankTransactions(sid))
        .map((b) => BankTransaction.fromMap(Map<String, dynamic>.from(b)))
        .toList();
    final postings = _accounting.postings(
      orders: orders,
      expenses: expenses,
      receivings: receivings,
      suppliers: suppliers,
      shifts: shifts,
      fixedAssets: fixedAssets,
      journalEntries: journalEntries,
      accounts: accounts,
      tax: tax,
    );
    final trial = _accounting.trialBalance(postings);
    return StoreSnapshot(
      store: store,
      orders: orders,
      inventory: inventory,
      expenses: expenses,
      customers: customers,
      shifts: shifts,
      suppliers: suppliers,
      receivings: receivings,
      tax: tax,
      trialBalanceRows: trial,
      fixedAssets: fixedAssets,
      bankTransactions: bankTransactions,
    );
  }
}
