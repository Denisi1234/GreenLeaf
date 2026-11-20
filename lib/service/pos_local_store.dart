import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../ui/business_category_config.dart';
import '../ui/models/product_item.dart';
import '../ui/models/customer_data.dart';
import '../ui/products/inventory_product_item.dart';
import 'debit_entry_model.dart';
import 'pos_hybrid_database.dart';
import 'pos_local_database.dart';
import 'pos_cloud_database.dart';
import 'php_api_client.dart';
import 'pos_order_models.dart';
import 'receipt_settings.dart';
import 'store_models.dart';
import 'store_preferences.dart';
import 'expense_model.dart';
import 'register_shift_model.dart';
import 'supplier_model.dart';
import 'accounting_engine.dart';
import 'accounting_model.dart';
import 'tax_settings.dart';
import 'daily_sales_report_service.dart';
import 'pos_suspended_sale_model.dart';
import 'package:track_mauzo/ui/models/capability.dart';
import 'models/staff_models.dart';
import 'services/accounting_service.dart';
import 'services/auth_service.dart';
import 'services/inventory_service.dart';
import 'services/sales_service.dart';

export 'models/staff_models.dart';
export 'services/accounting_service.dart';
export 'services/auth_service.dart';
export 'services/inventory_service.dart';
export 'services/sales_service.dart';

part 'store/pos_accounting_store.dart';
part 'store/pos_auth_store.dart';
part 'store/pos_supplier_store.dart';
part 'store/pos_staff_store.dart';
part 'store/pos_customer_store.dart';

const _staffPermissionCatalog = <String>[
  'View Sales',
  'View Reports',
  'Process Returns',
  'Discounts',
  'Manage Inventory',
  'Manage Staff',
  'Manage Payments',
  'System Settings',
];

const AccountingEngine _accounting = AccountingEngine();

const _demoProducts = <String, String>{
  'P001': 'Mineral Water 500ml',
  'P002': 'Coca-Cola',
  'P003': "Lay's Classic",
  'P004': 'Galaxy Milk',
  'P005': "Kellogg's Corn Flakes",
  'P006': 'Dove Beauty Bar',
  'P007': 'Colgate',
  'P008': 'Dettol Hand Wash',
  'P009': 'Tide Original',
};


class PosLocalStore extends ChangeNotifier
    with
        PosAccountingStore,
        PosAuthStore,
        PosSupplierStore,
        PosStaffStore,
        PosCustomerStore {
  PosLocalStore({PosLocalDatabase? database})
      : _database = database ?? PosLocalDatabase.instance {
    _authService = AuthService(this);
    _salesService = SalesService(this);
    _inventoryService = InventoryService(this);
    _accountingService = AccountingService(this);
  }

  late final AuthService _authService;
  late final SalesService _salesService;
  late final InventoryService _inventoryService;
  late final AccountingService _accountingService;

  AuthService get authService => _authService;
  SalesService get salesService => _salesService;
  InventoryService get inventoryService => _inventoryService;
  AccountingService get accountingService => _accountingService;

  static const _defaultStoreId = 'store-default';
  @override
  String _activeStoreId = _defaultStoreId;
  final List<Store> _stores = <Store>[];
  bool _savingCheckout = false;
  @override
  bool _disposed = false;

  @override
  final PosLocalDatabase _database;
  @override
  PosHybridDatabase? _cloudApi;
  static const Duration _eastAfricaOffset = Duration(hours: 3);

  final List<ProductItem> _products = <ProductItem>[];
  final List<ProductItem> _cartItems = <ProductItem>[];
  @override
  final List<CompletedOrder> _orders = <CompletedOrder>[];
  @override
  final List<InventoryProductItem> _allInventory = <InventoryProductItem>[];
  @override
  final List<StaffRoleData> _staffRoles = <StaffRoleData>[];
  @override
  final List<StaffMemberData> _staffMembers = <StaffMemberData>[];
  @override
  final List<Expense> _expenses = <Expense>[];
  @override
  final List<RegisterShift> _registerShifts = <RegisterShift>[];
  final List<CashMovement> _cashMovements = <CashMovement>[];
  @override
  final List<Supplier> _suppliers = <Supplier>[];
  @override
  final List<Receiving> _receivings = <Receiving>[];
  final List<SuspendedSale> _suspendedSales = <SuspendedSale>[];
  AppProfileData _profile = AppProfileData.empty();
  ReceiptSettings _receiptSettings = const ReceiptSettings();
  StorePreferences _storePreferences = const StorePreferences();
  @override
  TaxSettings _taxSettings = const TaxSettings();
  Timer? _midnightRefreshTimer;
  Timer? _dailySmsTimer;

  static const String _defaultLanguageCode = 'sw';
  String _languageCode = _defaultLanguageCode;
  // ignore: prefer_final_fields
  // ignore: prefer_final_fields
  @override
  bool _isLoggedIn = false;
  @override
  String? _currentUserId;
  @override
  String? _lastAuthError;

  /// Machine-readable reason for the most recent failed sign-in or sign-up.
  String? get lastAuthError => _lastAuthError;

  String get languageCode => _languageCode;
  ReceiptSettings get receiptSettings => _receiptSettings;
  StorePreferences get storePreferences => _storePreferences;
  @override
  PhpApiClient? get cloudApi {
    final database = _cloudApi ?? _database;
    if (database is PosCloudDatabase) return database.api;
    if (database is PosHybridDatabase) return database.api;
    return null;
  }

  String? _lastPersistenceError;
  String? get lastPersistenceError => _lastPersistenceError;

  bool _reloading = false;

  @override
  Future<void> reloadFromLocal() async {
    if (_reloading) return;
    _reloading = true;
    _isInitialized = false;
    try {
      await initialize();
    } finally {
      _reloading = false;
    }
  }

  @override
  Future<void> refreshFromServer() async {
    final database = _cloudApi ?? _database;
    if (database is PosHybridDatabase) {
      await database.retryFailed();
      await database.syncNow(pull: true);
    }
    await reloadFromLocal();
  }

  Future<({int pending, int failed})> syncHealth() async {
    final database = _cloudApi ?? _database;
    if (database is PosHybridDatabase) {
      return (
        pending: await database.pendingCount(),
        failed: await database.failedCount(),
      );
    }
    return (pending: 0, failed: 0);
  }

  Future<void> retryFailedSync() async {
    final database = _cloudApi ?? _database;
    if (database is PosHybridDatabase) {
      await database.retryFailed();
      await database.syncNow();
    }
    await reloadFromLocal();
  }

  bool get isLoggedIn =>
      (cloudApi?.token != null && cloudApi!.token!.isNotEmpty) || _isLoggedIn;
  @override
  String? get currentUserId =>
      cloudApi?.user['id'] as String? ?? _currentUserId;
  @override
  StaffMemberData? get currentUser {
    if (_currentUserId == null) return null;
    return _staffMembers.firstWhere(
      (s) => s.id == _currentUserId,
      orElse: () => _staffMembers.first,
    );
  }

  @override
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  void dispose() {
    _disposed = true;
    _midnightRefreshTimer?.cancel();
    _dailySmsTimer?.cancel();
    super.dispose();
  }

  static PosLocalStore of(BuildContext context) {
    return context.read<PosLocalStore>();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadUiConfig();
    await _ensureStoresLoaded();

    // If a saved cloud session exists, restore the cloud API so the app
    // can sync with the shared backend automatically â€” no user action needed.
    // If no session exists yet, initialize the default PhpApiClient so the app
    // is ready to authenticate and sync with the cloud server seamlessly.
    final session = await _database.loadSyncSession();
    if (session != null) {
      final endpoint = session['endpoint'] as String?;
      final token = session['token'] as String?;
      if (endpoint != null && token != null && endpoint.isNotEmpty) {
        final api = PhpApiClient(endpoint);
        api.restoreSession(
          token: token,
          user: jsonDecode(session['user_json'] as String? ?? '{}')
              as Map<String, dynamic>,
        );
        _cloudApi = PosHybridDatabase(api);
      }
    } else {
      final api = PhpApiClient();
      _cloudApi = PosHybridDatabase(api);
    }

    final db = _cloudApi ?? _database;
    if (db is PosHybridDatabase) {
      db.storeId = _activeStoreId;
      db.onSynced = () {
        if (!_disposed && _isInitialized) {
          reloadFromLocal();
        }
      };
      if (db.api.token != null && db.api.token!.isNotEmpty) {
        db.startAutoSync();
      }
    }

    _accountsSeeded = false;
    _allInventory.clear();
    _products.clear();
    _cartItems.clear();
    _orders.clear();
    _expenses.clear();
    _customers.clear();
    _debitEntries.clear();
    _staffRoles.clear();
    _staffMembers.clear();
    _registerShifts.clear();
    _cashMovements.clear();
    _suppliers.clear();
    _receivings.clear();
    _accounts.clear();
    _journalEntries.clear();
    _fixedAssets.clear();
    _bankTransactions.clear();

    final storedInventory = await _database.loadInventory(_activeStoreId);
    _allInventory
      ..clear()
      ..addAll(storedInventory);

    final storedCart = await _database.loadCart(_activeStoreId);
    _cartItems
      ..clear()
      ..addAll(storedCart);

    await _removeDemoInventory();
    _syncProductsFromInventory();

    _orders
      ..clear()
      ..addAll(await _database.loadOrders(_activeStoreId));

    final storedRoles = await _database.loadStaffRoles(_activeStoreId);
    _staffRoles
      ..clear()
      ..addAll(storedRoles.map(_staffRoleFromMap));

    final storedMembers = await _database.loadStaffMembers(_activeStoreId);
    _staffMembers
      ..clear()
      ..addAll(storedMembers.map(_staffMemberFromMap));

    final storedProfile = await _database.loadAppProfile();
    _profile = storedProfile == null
        ? AppProfileData.empty()
        : AppProfileData(
            storeName: storedProfile['store_name'] as String? ?? '',
            ownerName: storedProfile['owner_name'] as String? ?? '',
            roleTitle: storedProfile['role_title'] as String? ?? '',
            contactNumber: storedProfile['contact_number'] as String? ?? '',
            emailAddress: storedProfile['email_address'] as String? ?? '',
            physicalAddress: storedProfile['physical_address'] as String? ?? '',
            memberSince: storedProfile['member_since'] as String? ?? '',
            taxId: storedProfile['tax_id'] as String? ?? '',
            weekdayOpen: storedProfile['weekday_open'] as String? ?? '',
            weekdayClose: storedProfile['weekday_close'] as String? ?? '',
            saturdayOpen: storedProfile['saturday_open'] as String? ?? '',
            saturdayClose: storedProfile['saturday_close'] as String? ?? '',
            sundaySchedule: storedProfile['sunday_schedule'] as String? ?? '',
            open24Hours: (storedProfile['open_24_hours'] as int? ?? 0) == 1,
            logoPath: storedProfile['logo_path'] as String?,
          );

    final storedExpenses = await _database.loadExpenses(_activeStoreId);
    _expenses
      ..clear()
      ..addAll(storedExpenses.map(Expense.fromMap));

    final storedCustomers = await _database.loadCustomers(_activeStoreId);
    _customers
      ..clear()
      ..addAll(storedCustomers.map(_customerFromMap));

    final storedDebitEntries = await _database.loadDebitEntries(_activeStoreId);
    _debitEntries
      ..clear()
      ..addAll(storedDebitEntries.map(DebitEntry.fromMap))
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    await _reloadRegister();
    await _reloadSuppliers();

    _receiptSettings = await _database.loadReceiptSettings();
    _taxSettings = await _database.loadTaxSettings();
    await _reloadAccounting();
    await _recalculateStockStates();

    _updateCartTotals();
    _scheduleMidnightRefresh();
    _scheduleDailySmsCheck();
    _isInitialized = true;
    notifyListeners();
  }

  void _scheduleMidnightRefresh() {
    _midnightRefreshTimer?.cancel();
    final nowUtc = DateTime.now().toUtc();
    final eastAfricaNow = nowUtc.add(_eastAfricaOffset);
    final nextMidnightUtc = DateTime.utc(
      eastAfricaNow.year,
      eastAfricaNow.month,
      eastAfricaNow.day + 1,
    ).subtract(_eastAfricaOffset);
    final delay = nextMidnightUtc.difference(nowUtc);
    _midnightRefreshTimer = Timer(delay, () {
      if (!_isInitialized) return;
      notifyListeners();
      _scheduleMidnightRefresh();
      _checkAndSendDailySms();
    });
  }

  void _scheduleDailySmsCheck() {
    _dailySmsTimer?.cancel();
    // Periodically evaluate every 15 minutes if it is time to dispatch daily SMS
    _dailySmsTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (!_isInitialized || _disposed) return;
      _checkAndSendDailySms();
    });
    // Also perform an initial check on start/init
    _checkAndSendDailySms();
  }

  Future<void> _checkAndSendDailySms() async {
    if (!_storePreferences.autoDailySmsReport) return;

    final nowUtc = DateTime.now().toUtc();
    final eatNow = nowUtc.add(_eastAfricaOffset);
    final todayStr =
        '${eatNow.year}-${eatNow.month.toString().padLeft(2, '0')}-${eatNow.day.toString().padLeft(2, '0')}';

    // Already sent for today
    if (_storePreferences.lastDailySmsDate == todayStr) return;

    // Parse configured target time (e.g. "21:00")
    int targetHour = 21;
    int targetMinute = 0;
    try {
      final parts = _storePreferences.dailySmsTime.split(':');
      if (parts.isNotEmpty) targetHour = int.parse(parts[0]);
      if (parts.length > 1) targetMinute = int.parse(parts[1]);
    } catch (_) {}

    // Check if current East Africa Time has reached target time
    if (eatNow.hour > targetHour ||
        (eatNow.hour == targetHour && eatNow.minute >= targetMinute)) {
      final result = await DailySalesReportService.sendDailyReport(store: this);
      if (result.success) {
        // Record sent date so we don't duplicate
        await setStorePreferences(
            _storePreferences.copyWith(lastDailySmsDate: todayStr));
      }
    }
  }

  Future<DailySmsResult> sendDailySmsNow({String? overridePhone}) async {
    final result = await DailySalesReportService.sendDailyReport(
      store: this,
      overridePhone: overridePhone,
    );
    if (result.success) {
      final eatNow = DateTime.now().toUtc().add(_eastAfricaOffset);
      final todayStr =
          '${eatNow.year}-${eatNow.month.toString().padLeft(2, '0')}-${eatNow.day.toString().padLeft(2, '0')}';
      await setStorePreferences(
          _storePreferences.copyWith(lastDailySmsDate: todayStr));
    }
    return result;
  }

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

  Future<void> _reloadRegister() async {
    final storedShifts = await _database.loadRegisterShifts(_activeStoreId);
    _registerShifts
      ..clear()
      ..addAll(storedShifts.map(
        (row) => RegisterShift.fromMap(Map<String, dynamic>.from(row)),
      ));

    final storedMovements = await _database.loadCashMovements(_activeStoreId);
    _cashMovements
      ..clear()
      ..addAll(storedMovements.map(
        (row) => CashMovement.fromMap(Map<String, dynamic>.from(row)),
      ));
    _attachMovements();
  }

  /// Groups the loaded movements onto their shifts for quick reads.
  void _attachMovements() {
    final grouped = <String, List<CashMovement>>{};
    for (final movement in _cashMovements) {
      grouped
          .putIfAbsent(movement.shiftId, () => <CashMovement>[])
          .add(movement);
    }
    for (var i = 0; i < _registerShifts.length; i++) {
      final shift = _registerShifts[i];
      final key = shift.id?.toString() ?? '';
      _registerShifts[i] = RegisterShift(
        id: shift.id,
        register: shift.register,
        openedBy: shift.openedBy,
        openedAt: shift.openedAt,
        openingFloat: shift.openingFloat,
        closedAt: shift.closedAt,
        closedBy: shift.closedBy,
        countedCash: shift.countedCash,
        notes: shift.notes,
        movements: grouped[key] ?? const <CashMovement>[],
      );
    }
    _registerShifts.sort((a, b) => b.openedAt.compareTo(a.openedAt));
  }

  List<RegisterShift> get registerShifts => List.unmodifiable(_registerShifts);

  RegisterShift? get openShift {
    for (final shift in _registerShifts) {
      if (shift.isOpen) return shift;
    }
    return null;
  }

  List<CashMovement> get cashMovements => List.unmodifiable(_cashMovements);

  /// Opens a new register shift, refusing a second concurrent open shift.
  Future<RegisterShift?> startShift({
    required String register,
    required String openedBy,
    required double openingFloat,
  }) async {
    if (openShift != null) return null;
    final shift = RegisterShift(
      register: register,
      openedBy: openedBy,
      openedAt: DateTime.now(),
      openingFloat: openingFloat,
    );
    final id =
        await _database.insertRegisterShift(shift.toMap(), _activeStoreId);
    await _reloadRegister();

    notifyListeners();
    return _registerShifts.firstWhere(
      (item) => item.id == id,
      orElse: () => shift,
    );
  }

  /// Closes the given shift with the counted cash total.
  Future<void> closeShift(
    int shiftId, {
    required double countedCash,
    required String closedBy,
    String notes = '',
  }) async {
    await _database.updateRegisterShift(shiftId, {
      'closed_at': DateTime.now().toIso8601String(),
      'closed_by': closedBy,
      'counted_cash': countedCash,
      'notes': notes,
    });
    await _reloadRegister();

    notifyListeners();
  }

  Future<void> reopenShift(int shiftId) async {
    await _database.updateRegisterShift(shiftId, {
      'closed_at': null,
      'closed_by': '',
      'counted_cash': 0,
    });
    await _reloadRegister();

    notifyListeners();
  }

  /// Records a manual drawer movement against the open shift.
  Future<void> addCashMovement({
    required CashMovementType type,
    required double amount,
    String reason = '',
    required String recordedBy,
  }) async {
    final shift = openShift;
    if (shift == null || shift.id == null || amount <= 0) return;
    final movement = CashMovement(
      shiftId: shift.id.toString(),
      type: type,
      amount: amount,
      reason: reason,
      at: DateTime.now(),
      recordedBy: recordedBy,
    );
    await _database.insertCashMovement(movement.toMap(), _activeStoreId);
    await _reloadRegister();

    notifyListeners();
  }

  Future<void> deleteCashMovement(int id) async {
    await _database.deleteCashMovement(id);
    _cashMovements.removeWhere((movement) => movement.id == id);
    await _reloadRegister();

    notifyListeners();
  }

  double cashSalesBetween(DateTime start, DateTime end) {
    var total = 0.0;
    for (final order in _orders) {
      final at = DateTime.tryParse(order.dateTime);
      if (at == null) continue;
      if (at.isBefore(start) || at.isAfter(end)) continue;
      if (order.paymentMethod.toLowerCase().contains('cash')) {
        total += order.total;
      }
    }
    return total;
  }

  /// Reconciles one shift against its drawer movements and cash sales.
  CashUpSummary cashUpFor(RegisterShift shift) {
    final cashSales = cashSalesBetween(shift.openedAt, shift.endsAt);
    final cashIn = shift.movements
        .where((movement) => !movement.type.isOutflow)
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final cashOut = shift.movements
        .where((movement) => movement.type.isOutflow)
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final expected = shift.openingFloat + cashSales + cashIn - cashOut;
    final counted = shift.isOpen ? 0.0 : shift.countedCash.toDouble();
    return CashUpSummary(
      openingFloat: shift.openingFloat,
      cashSales: cashSales,
      cashIn: cashIn,
      cashOut: cashOut,
      expected: expected,
      counted: counted,
      variance: counted - expected,
    );
  }

  Future<void> updateReceiptSettings(ReceiptSettings settings) async {
    await _database.saveReceiptSettings(settings);
    _receiptSettings = settings;
    notifyListeners();
  }

  TaxSettings get taxSettings => _taxSettings;

  Future<void> updateTaxSettings(TaxSettings settings) async {
    await _database.saveTaxSettings(settings);
    _taxSettings = settings;
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    final nextCode = AppStrings.normalize(code);
    if (_languageCode == nextCode) return;
    final db = _cloudApi ?? _database;
    if (db is PosCloudDatabase) {
      await cloudApi!.put('preferences', '1', <String, Object?>{
        'languageCode': nextCode,
        ..._storePreferences.toJson(),
      });
    }
    _languageCode = nextCode;
    await _writeUiConfig();
    if (db is PosHybridDatabase) {
      await db.saveLanguagePreference(nextCode);
    }
    notifyListeners();
  }

  Future<void> setStorePreferences(StorePreferences preferences) async {
    final thresholdChanged =
        _storePreferences.lowStockThreshold != preferences.lowStockThreshold;
    _storePreferences = preferences;
    if (thresholdChanged) {
      await _recalculateStockStates();
    }
    await _writeUiConfig();
    final db = _cloudApi ?? _database;
    if (db is PosCloudDatabase) {
      try {
        await cloudApi!.put('preferences', '1', <String, Object?>{
          'languageCode': _languageCode,
          ...preferences.toJson(),
        });
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _loadUiConfig() async {
    _storePreferences = const StorePreferences();
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/track_mauzo_ui_config.json');
      if (!await file.exists()) {
        final defaults = <String, dynamic>{
          'languageCode': _defaultLanguageCode,
          'activeStoreId': _activeStoreId,
          'hasCompletedOnboarding': 0,
          ..._storePreferences.toJson(),
        };
        await file.writeAsString(jsonEncode(defaults));
      } else {
        final jsonStr = await file.readAsString();
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _languageCode = AppStrings.normalize(
          map['languageCode'] as String? ?? _defaultLanguageCode,
        );
        _hasCompletedOnboarding =
            (map['hasCompletedOnboarding'] as int? ?? 0) == 1;
        final savedStoreId = (map['activeStoreId'] as String?)?.trim();
        if (savedStoreId != null && savedStoreId.isNotEmpty) {
          _activeStoreId = savedStoreId;
        }
        _storePreferences = StorePreferences.fromJson(map);
      }
    } catch (_) {
      _languageCode = _defaultLanguageCode;
      _storePreferences = const StorePreferences();
    }

    if (_database is PosCloudDatabase) {
      try {
        final rows = await cloudApi!.rows('preferences');
        if (rows.isNotEmpty) {
          _languageCode = AppStrings.normalize(
            rows.first['languageCode'] as String? ?? _languageCode,
          );
          _storePreferences = StorePreferences.fromJson(
            <String, dynamic>{
              ..._storePreferences.toJson(),
              ...Map<String, dynamic>.from(rows.first),
            },
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _saveUiConfig() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/track_mauzo_ui_config.json');
      Map<String, dynamic> existing = <String, dynamic>{};
      if (await file.exists()) {
        try {
          final decoded = jsonDecode(await file.readAsString());
          if (decoded is Map<String, dynamic>) existing = decoded;
        } catch (_) {}
      }
      existing['languageCode'] = _languageCode;
      existing['activeStoreId'] = _activeStoreId;
      existing['hasCompletedOnboarding'] = _hasCompletedOnboarding ? 1 : 0;
      existing.addAll(_storePreferences.toJson());
      await file.writeAsString(jsonEncode(existing), flush: true);
    } catch (_) {}
  }

  Future<void> _writeUiConfig() => _saveUiConfig();

  bool _hasCompletedOnboarding = false;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  Future<void> markOnboardingComplete() async {
    _hasCompletedOnboarding = true;
    await _saveUiConfig();
    notifyListeners();
  }

  List<ProductItem> get products => List.unmodifiable(_products);
  List<ProductItem> get cartItems => List.unmodifiable(_cartItems);
  List<CompletedOrder> get orders => List.unmodifiable(_orders);
  List<Store> get stores => List.unmodifiable(_stores);
  String get activeStoreId => _activeStoreId;
  Store get activeStore {
    for (final store in _stores) {
      if (store.id == _activeStoreId) return store;
    }
    if (_stores.isNotEmpty) return _stores.first;
    return const Store(
      id: _defaultStoreId,
      name: 'Default Store',
      address: '',
      contact: '',
    );
  }

  String get activeStoreName {
    final name = activeStore.name.trim();
    return name.isEmpty ? profile.storeName : name;
  }

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
    await _database.upsertStore(store.toMap());
    await _ensureStoresLoaded();
    if (_activeStoreId == store.id) {
      _profile = _profile.copyWith(storeName: store.name);
    }
    notifyListeners();
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
    await _database.deleteStore(id);
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

  List<InventoryProductItem> get inventory => List.unmodifiable(_allInventory);
  List<StaffRoleData> get staffRoles => List.unmodifiable(_staffRoles);
  List<StaffMemberData> get staffMembers => List.unmodifiable(_staffMembers);
  List<String> get staffPermissionCatalog =>
      List.unmodifiable(_staffPermissionCatalog);
  @override
  AppProfileData get profile => _profile;
  BusinessCategory get businessCategory => BusinessCategory.retail;

  BusinessCategoryConfig get businessCategoryConfig =>
      BusinessCategoryConfig.forCategory(businessCategory);

  Set<Capability> get activeCapabilities => businessCategoryConfig.capabilities;

  int _cartCount = 0;
  int get cartCount => _cartCount;

  double _cartTotal = 0;
  double get cartTotal => _cartTotal;

  bool addToCart(ProductItem product) {
    final availableStock = _availableStockForProduct(product);
    final currentCartQuantity = _cartItems.where(_sameProduct(product)).length;
    if (availableStock > 0 && currentCartQuantity >= availableStock) {
      return false;
    }

    _cartItems.add(product);
    _updateCartTotals();
    notifyListeners();
    unawaited(_persistCart());
    return true;
  }

  bool addToCartQuantity(ProductItem product, int quantity) {
    if (quantity <= 0) return false;

    final availableStock = _availableStockForProduct(product);
    final currentCartQuantity = _cartItems.where(_sameProduct(product)).length;
    if (availableStock > 0 && currentCartQuantity + quantity > availableStock) {
      return false;
    }

    for (var i = 0; i < quantity; i++) {
      _cartItems.add(product);
    }
    _updateCartTotals();
    notifyListeners();
    unawaited(_persistCart());
    return true;
  }

  bool removeSingleFromCart(ProductItem product) {
    final index = _cartItems.indexWhere(_sameProduct(product));
    if (index == -1) return false;
    _cartItems.removeAt(index);
    _updateCartTotals();
    notifyListeners();
    unawaited(_persistCart());
    return true;
  }

  void removeFromCart(int index) {
    if (index < 0 || index >= _cartItems.length) return;
    _cartItems.removeAt(index);
    _updateCartTotals();
    notifyListeners();
    unawaited(_persistCart());
  }

  void updateQuantity(int index, int delta) {
    if (index < 0 || index >= _cartItems.length) return;
    final item = _cartItems[index];
    if (delta > 0) {
      addToCart(item);
      return;
    }

    _cartItems.removeAt(index);
    _updateCartTotals();
    notifyListeners();
    unawaited(_persistCart());
  }

  Future<void> _persistCart() async {
    try {
      await _database.replaceCart(_cartItems, _activeStoreId);
      _lastPersistenceError = null;
    } catch (error) {
      _lastPersistenceError = error.toString();
    }
    if (!_disposed) notifyListeners();
  }

  List<SuspendedSale> get suspendedSales => List.unmodifiable(_suspendedSales);

  /// Holds / parks current cart (OSPOS Suspended Sale pattern)
  Future<SuspendedSale?> suspendCurrentSale(
      {String? customerName, String? comment}) async {
    if (_cartItems.isEmpty) return null;
    final sale = SuspendedSale(
      id: 'HOLD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      createdAt: DateTime.now(),
      items: List<ProductItem>.from(_cartItems),
      customerName: customerName,
      comment: comment,
    );
    _suspendedSales.insert(0, sale);
    _cartItems.clear();
    _updateCartTotals();
    notifyListeners();
    await _persistCart();
    return sale;
  }

  /// Resumes a previously suspended sale and puts its items back into the active cart
  Future<void> resumeSuspendedSale(String id) async {
    final index = _suspendedSales.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final sale = _suspendedSales.removeAt(index);
    _cartItems.addAll(sale.items);
    _updateCartTotals();
    notifyListeners();
    await _persistCart();
  }

  /// Cancels / deletes a suspended sale without resuming it
  void deleteSuspendedSale(String id) {
    _suspendedSales.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    _updateCartTotals();
    notifyListeners();
    await _database.replaceCart(_cartItems, _activeStoreId);
  }

  @override
  Future<InventoryProductItem> addProduct(InventoryProductItem product) async {
    if (_allInventory.any((item) => item.code == product.code)) {
      throw StateError(
          'A product with this code already exists. Refresh and try again.');
    }
    await _database
        .replaceInventory([product, ..._allInventory], _activeStoreId);
    _allInventory.insert(0, product);
    _syncProductsFromInventory();
    notifyListeners();
    return product;
  }

  @override
  Future<void> updateProduct(InventoryProductItem product) async {
    final index = _allInventory.indexWhere((item) => item.code == product.code);
    if (index != -1) {
      final next = List<InventoryProductItem>.from(_allInventory);
      next[index] = product;
      await _database.replaceInventory(next, _activeStoreId);
      _allInventory[index] = product;
      _syncProductsFromInventory();
      notifyListeners();
    }
  }

  Future<void> removeProduct(String code) async {
    final removedIndex = _allInventory.indexWhere((item) => item.code == code);
    final removedItem = removedIndex == -1 ? null : _allInventory[removedIndex];

    _allInventory.removeWhere((item) => item.code == code);
    _cartItems.removeWhere((item) => item.code?.trim() == code);
    _syncProductsFromInventory();
    _updateCartTotals();
    notifyListeners();
    await _database.replaceInventory(_allInventory, _activeStoreId);
    await _database.replaceCart(_cartItems, _activeStoreId);

    final imagePath = removedItem?.imagePath;
    if (cloudApi != null) return;
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> applyInventoryAdjustments(
    Map<String, int> adjustments,
  ) async {
    if (adjustments.isEmpty) return;

    for (var index = 0; index < _allInventory.length; index++) {
      final item = _allInventory[index];
      final delta = adjustments[item.code];
      if (delta == null || delta == 0) continue;

      final nextStock = (item.stockCount + delta).clamp(0, 1 << 31).toInt();
      _allInventory[index] = item.copyWith(
        stockCount: nextStock,
        stockState: _deriveStockState(nextStock),
      );
    }

    _syncProductsFromInventory();
    notifyListeners();
    await _database.replaceInventory(_allInventory, _activeStoreId);
  }

  Future<CompletedOrder> completeCashSale({
    required List<OrderLineItem> items,
    required double cashTendered,
    required String cashierName,
    required String registerName,
    String? customerName,
    double? discountAmount,
    String? discountLabel,
    String paymentMethod = 'Cash',
  }) async {
    if (_savingCheckout) throw StateError('A sale is already being saved.');

    final normalized = items
        .where((line) => line.quantity > 0)
        .map(
          (line) => OrderLineItem(
            product: line.product,
            quantity: line.quantity,
          ),
        )
        .toList();
    if (normalized.isEmpty) {
      throw StateError('Cannot complete a sale with no items.');
    }

    final subtotal = normalized.fold<double>(
      0,
      (sum, line) => sum + line.totalPrice,
    );
    final total = ((subtotal - (discountAmount ?? 0)) * 100).round() / 100;
    final isCashSale = paymentMethod.toLowerCase() == 'cash';
    if (isCashSale && cashTendered < total) {
      throw StateError('Cash tendered is less than total due.');
    }

    final stockUpdates = <int, InventoryProductItem>{};
    final saleLines = <OrderLine>[];
    for (final line in normalized) {
      final inventoryIndex = _findInventoryIndex(line.product);
      if (inventoryIndex == -1) {
        throw StateError(
            'Product ${line.product.name} is no longer in inventory.');
      }
      final inventoryItem =
          stockUpdates[inventoryIndex] ?? _allInventory[inventoryIndex];
      if (inventoryItem.stockCount < line.quantity) {
        throw StateError(
          'Only ${inventoryItem.stockCount} unit(s) of ${inventoryItem.name} left in stock.',
        );
      }
      final nextStock = inventoryItem.stockCount - line.quantity;
      stockUpdates[inventoryIndex] = inventoryItem.copyWith(
        stockCount: nextStock,
        stockState: _deriveStockState(nextStock),
      );
      saleLines.add(OrderLine(
        itemCode: inventoryItem.code,
        itemCategory: inventoryItem.category,
        itemName: line.product.name,
        itemSize: line.product.size,
        quantity: line.quantity,
        unitPrice: line.product.price,
        unitPriceValue: line.product.priceValue,
        unitCost: inventoryItem.purchasePrice,
        artType: line.product.type,
        imagePath: line.product.imagePath,
      ));
    }

    final now = DateTime.now();
    var order = CompletedOrder(
      id: 'ORD-${now.microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32).toRadixString(16)}',
      dateTime: now.toIso8601String(),
      date: _formatDate(now),
      time: _formatTime(now),
      total: total,
      status: 'Completed',
      cashierName: cloudApi?.user['name'] as String? ?? cashierName,
      register: registerName,
      paymentMethod: paymentMethod,
      cashTendered: isCashSale ? cashTendered : 0,
      changeDue: isCashSale ? cashTendered - total : 0,
      customerName: customerName,
      discountAmount: discountAmount,
      discountLabel: discountLabel,
      lines: saleLines,
    );

    CustomerData? creditCustomer;
    if (paymentMethod.toLowerCase() == 'credit' &&
        customerName != null &&
        customerName.trim().isNotEmpty) {
      final customerIndex =
          _customers.indexWhere((customer) => customer.name == customerName);
      if (customerIndex != -1) {
        creditCustomer = _customers[customerIndex].copyWith(
          debitBalance: _customers[customerIndex].debitBalance + total,
        );
      } else {
        // Credit taken for a name that is not on file: create the customer so
        // the debt is tracked instead of being lost.
        final now = DateTime.now();
        creditCustomer = CustomerData(
          id: 'CUST-${now.microsecondsSinceEpoch}',
          name: customerName.trim(),
          phone: '',
          debitBalance: total,
          createdAt: now,
        );
        _customers.add(creditCustomer);
        await _database.replaceCustomers(
          _customers.map(_customerToMap).toList(),
          _activeStoreId,
        );
      }
    }

    _savingCheckout = true;
    try {
      await _database.saveCheckout(
        order: order,
        storeId: _activeStoreId,
        stockUpdates: stockUpdates.values.toList(),
        creditCustomer:
            creditCustomer == null ? null : _customerToMap(creditCustomer),
      );
      for (final item in stockUpdates.values) {
        final index =
            _allInventory.indexWhere((product) => product.code == item.code);
        if (index >= 0) _allInventory[index] = item;
      }
      if (creditCustomer != null) {
        final id = creditCustomer.id;
        final index = _customers.indexWhere((customer) => customer.id == id);
        if (index >= 0) _customers[index] = creditCustomer;
      }
      if (creditCustomer != null) {
        await _appendDebitEntry(
          DebitEntry.now(
            id: 'DEB-${order.id}',
            customerId: creditCustomer.id,
            customerName: creditCustomer.name,
            type: DebitType.charge,
            amount: total,
            orderId: order.id,
            recordedBy: order.cashierName,
            note: 'Credit sale ${order.id}',
          ),
        );
      }
      final db = _cloudApi ?? _database;
      if (db is PosCloudDatabase) {
        final cloud = db;
        order = cloud.savedCheckout!;
        _allInventory
          ..clear()
          ..addAll(cloud.inventoryAfterCheckout!);
        _customers
          ..clear()
          ..addAll(cloud.customersAfterCheckout!.map(_customerFromMap));
      }
      _syncProductsFromInventory();
      _orders.insert(0, order);
      _cartItems.clear();
      _updateCartTotals();
      notifyListeners();
    } finally {
      _savingCheckout = false;
    }
    return order;
  }

  Future<void> voidOrder(String orderId) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return;

    final db = _cloudApi ?? _database;
    if (db is PosCloudDatabase) {
      await db.deleteOrder(orderId);
      await refreshFromServer();
      return;
    }

    final order = _orders[index];

    // Restore stock
    for (final line in order.lines) {
      final invIndex =
          _allInventory.indexWhere((item) => item.code == line.itemCode);
      if (invIndex != -1) {
        final item = _allInventory[invIndex];
        final nextStock = item.stockCount + line.quantity;
        _allInventory[invIndex] = InventoryProductItem(
          code: item.code,
          name: item.name,
          category: item.category,
          purchasePrice: item.purchasePrice,
          sellingPrice: item.sellingPrice,
          stockCount: nextStock,
          stockState: _deriveStockState(nextStock),
          artType: item.artType,
          imagePath: item.imagePath,
          categoryData: item.categoryData,
        );
      }
    }

    _orders.removeAt(index);
    await _reverseVoidedCredit(order);
    _syncProductsFromInventory();
    notifyListeners();

    final database = _database;
    if (database is PosHybridDatabase) {
      await database.replaceInventoryLocal(_allInventory, _activeStoreId);
      await database.deleteOrder(orderId);
    } else {
      await database.replaceInventory(_allInventory, _activeStoreId);
      await database.deleteOrder(orderId);
    }
  }

  /// Removes the ledger charge created by a credit sale that is being voided
  /// and reduces the customer's outstanding balance accordingly.
  Future<void> _reverseVoidedCredit(CompletedOrder order) async {
    if (order.paymentMethod.toLowerCase() != 'credit') return;
    final name = order.customerName;
    if (name == null || name.trim().isEmpty) return;

    final index = _customers.indexWhere((customer) => customer.name == name);
    if (index == -1) return;

    final customer = _customers[index];
    final remaining = customer.debitBalance - order.total;
    _customers[index] = customer.copyWith(
      debitBalance: remaining > 0 ? remaining : 0,
    );
    _debitEntries
        .removeWhere((entry) => entry.orderId == order.id && !entry.isPayment);

    await _database.replaceCustomers(
      _customers.map(_customerToMap).toList(),
      _activeStoreId,
    );
    await _persistDebitEntries();
  }

  Future<void> reopenOrderForEdit(String orderId) async {
    final order = _orders.firstWhere((o) => o.id == orderId);

    // 1. Clear current cart
    await clearCart();

    // 2. Add order items back to cart
    for (final line in order.lines) {
      for (var i = 0; i < line.quantity; i++) {
        addToCart(line.product);
      }
    }

    // 3. Void the original order
    await voidOrder(orderId);
  }

  Future<void> updateProfile(AppProfileData profile) async {
    await _database.saveAppProfile(_profileToMap(profile));
    _profile = profile;
    notifyListeners();
  }

  Map<String, Object?> _profileToMap(AppProfileData profile) {
    return <String, Object?>{
      'store_name': profile.storeName,
      'owner_name': profile.ownerName,
      'role_title': profile.roleTitle,
      'business_category': BusinessCategory.retail.storageKey,
      'contact_number': profile.contactNumber,
      'email_address': profile.emailAddress,
      'physical_address': profile.physicalAddress,
      'member_since': profile.memberSince,
      'tax_id': profile.taxId,
      'weekday_open': profile.weekdayOpen,
      'weekday_close': profile.weekdayClose,
      'saturday_open': profile.saturdayOpen,
      'saturday_close': profile.saturdayClose,
      'sunday_schedule': profile.sundaySchedule,
      'open_24_hours': profile.open24Hours ? 1 : 0,
      'logo_path': profile.logoPath,
    };
  }

  StaffRoleData? staffRoleById(String roleId) {
    for (final role in _staffRoles) {
      if (role.id == roleId) return role;
    }
    return null;
  }

  StaffRoleData? staffRoleByTitle(String title) {
    for (final role in _staffRoles) {
      if (role.title == title) return role;
    }
    return null;
  }

  bool _isDemoProduct(String? code, String name) =>
      _demoProducts[code?.trim()] == name.trim();

  Future<void> _removeDemoInventory() async {
    final inventoryBefore = _allInventory.length;
    final cartBefore = _cartItems.length;
    _allInventory.removeWhere((item) => _isDemoProduct(item.code, item.name));
    _cartItems.removeWhere((item) => _isDemoProduct(item.code, item.name));
    if (_allInventory.length != inventoryBefore) {
      await _database.replaceInventory(_allInventory, _activeStoreId);
    }
    if (_cartItems.length != cartBefore) {
      _updateCartTotals();
      await _persistCart();
    }
  }

  @override
  void _syncProductsFromInventory() {
    _products
      ..clear()
      ..addAll(_allInventory.map(_toProductItem));
  }

  ProductItem _toProductItem(InventoryProductItem product) {
    return ProductItem(
      product.name,
      _deriveProductSize(product),
      product.sellingPrice.toStringAsFixed(2),
      product.artType,
      code: product.code,
      category: product.category,
      imagePath: product.imagePath,
    );
  }

  int availableStockForProduct(ProductItem product) {
    return _availableStockForProduct(product);
  }

  int _availableStockForProduct(ProductItem product) {
    final index = _findInventoryIndex(product);
    if (index == -1) return 0;
    return _allInventory[index].stockCount;
  }

  int _findInventoryIndex(ProductItem product) {
    return _allInventory.indexWhere(
      (item) => item.code == product.code || item.name == product.name,
    );
  }

  bool Function(ProductItem) _sameProduct(ProductItem product) {
    final productCode = product.code?.trim();
    if (productCode != null && productCode.isNotEmpty) {
      return (item) => item.code?.trim() == productCode;
    }

    final productName = product.name.trim();
    final productSize = product.size.trim();
    return (item) =>
        item.name.trim() == productName && item.size.trim() == productSize;
  }

  void _updateCartTotals() {
    _cartCount = _cartItems.length;
    _cartTotal = _cartItems.fold<double>(
      0,
      (sum, item) => sum + item.priceValue,
    );
  }

  InventoryStockState _deriveStockState(int stockCount) {
    if (stockCount <= 0) return InventoryStockState.outOfStock;
    if (stockCount <= _storePreferences.lowStockThreshold) {
      return InventoryStockState.lowStock;
    }
    return InventoryStockState.inStock;
  }

  @override
  Future<void> _recalculateStockStates() async {
    var changed = false;
    for (var i = 0; i < _allInventory.length; i++) {
      final item = _allInventory[i];
      final nextState = _deriveStockState(item.stockCount);
      if (item.stockState != nextState) {
        _allInventory[i] = item.copyWith(stockState: nextState);
        changed = true;
      }
    }
    if (!changed) return;
    _syncProductsFromInventory();
    final database = _database;
    if (database is PosHybridDatabase) {
      await database.replaceInventoryLocal(_allInventory, _activeStoreId);
    } else {
      await database.replaceInventory(_allInventory, _activeStoreId);
    }
  }

  String _deriveProductSize(InventoryProductItem product) {
    final lowerCategory = product.category.toLowerCase();
    final lowerName = product.name.toLowerCase();
    if (lowerName.contains('500ml')) return '500 ml';
    if (lowerName.contains('330ml')) return '330 ml';
    if (lowerName.contains('250ml')) return '250 ml';
    if (lowerName.contains('500g')) return '500 g';
    if (lowerName.contains('100g')) return '100 g';
    if (lowerName.contains('40g')) return '40 g';
    if (lowerCategory.contains('beverage')) return '1 item';
    if (lowerCategory.contains('snack')) return '1 pack';
    if (lowerCategory.contains('personal')) return '1 unit';
    if (lowerCategory.contains('household')) return '1 pack';
    return '1 item';
  }

  String _formatDate(DateTime dateTime) {
    final monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = monthNames[dateTime.month - 1];
    final day = dateTime.day.toString().padLeft(2, '0');
    final monthNumber = dateTime.month.toString().padLeft(2, '0');
    return switch (_storePreferences.dateFormat) {
      'd MMM yyyy' => '${dateTime.day} $month ${dateTime.year}',
      'dd/MM/yyyy' => '$day/$monthNumber/${dateTime.year}',
      'MM/dd/yyyy' => '$monthNumber/$day/${dateTime.year}',
      'yyyy-MM-dd' => '${dateTime.year}-$monthNumber-$day',
      _ => '$month ${dateTime.day}, ${dateTime.year}',
    };
  }

  String _formatTime(DateTime dateTime) {
    final minute = dateTime.minute.toString().padLeft(2, '0');
    if (_storePreferences.uses24HourTime) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:$minute';
    }
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  Map<String, dynamic> customerStats() {
    final total = _customers.length;
    final names = _customers.map((c) => c.name).toSet();
    final active = _orders
        .map((o) => o.customerName)
        .where((n) => n != null && names.contains(n))
        .toSet()
        .length;

    final spendByCustomer = <String, double>{};
    for (final order in _orders) {
      final name = order.customerName;
      if (name == null) continue;
      spendByCustomer[name] = (spendByCustomer[name] ?? 0) + order.total;
    }

    String? topName;
    double topValue = 0;
    spendByCustomer.forEach((name, value) {
      if (value > topValue) {
        topValue = value;
        topName = name;
      }
    });

    return <String, dynamic>{
      'total': total,
      'active': active,
      'topName': topName,
      'topValue': topValue,
    };
  }

}
