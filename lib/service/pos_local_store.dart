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
import 'app_notification_service.dart';
import 'tax_settings.dart';
import 'daily_sales_report_service.dart';
import 'pos_suspended_sale_model.dart';
import 'package:track_mauzo/ui/models/capability.dart';
import 'staff_credentials.dart';
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
part 'store/pos_expense_store.dart';
part 'store/pos_register_store.dart';
part 'store/pos_settings_store.dart';
part 'store/pos_multistore_store.dart';
part 'store/pos_cart_inventory_store.dart';
part 'store/pos_checkout_store.dart';

const _defaultStoreId = 'store-default';
const Duration _eastAfricaOffset = Duration(hours: 3);
const String _defaultLanguageCode = 'sw';

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
        PosCustomerStore,
        PosExpenseStore,
        PosRegisterStore,
        PosSettingsStore,
        PosMultiStore,
        PosCartInventoryStore,
        PosCheckoutStore {
  PosLocalStore({PosLocalDatabase? database})
      : _localDatabase = database ?? PosLocalDatabase.instance {
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

  @override
  String _activeStoreId = _defaultStoreId;
  @override
  final List<Store> _stores = <Store>[];
  @override
  bool _savingCheckout = false;
  @override
  bool _disposed = false;

  final PosLocalDatabase _localDatabase;
  @override
  PosLocalDatabase get _database => _cloudApi ?? _localDatabase;
  @override
  PosHybridDatabase? _cloudApi;

  @override
  final List<ProductItem> _products = <ProductItem>[];
  @override
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
  final List<CustomerData> _customers = <CustomerData>[];
  @override
  final List<Expense> _expenses = <Expense>[];
  @override
  final List<RegisterShift> _registerShifts = <RegisterShift>[];
  @override
  final List<CashMovement> _cashMovements = <CashMovement>[];
  @override
  final List<Supplier> _suppliers = <Supplier>[];
  @override
  final List<Receiving> _receivings = <Receiving>[];
  @override
  final List<SuspendedSale> _suspendedSales = <SuspendedSale>[];
  @override
  AppProfileData _profile = AppProfileData.empty();
  @override
  ReceiptSettings _receiptSettings = const ReceiptSettings();
  @override
  StorePreferences _storePreferences = const StorePreferences();
  @override
  TaxSettings _taxSettings = const TaxSettings();
  Timer? _midnightRefreshTimer;
  Timer? _dailySmsTimer;

  @override
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

  @override
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
    final id = _currentUserId;
    if (id == null) return null;
    for (final member in _staffMembers) {
      if (member.id == id) return member;
    }
    return null;
  }

  @override
  bool hasPermission(String permission) {
    final user = currentUser;
    if (user == null) return true;
    final role = staffRoleById(user.roleId);
    if (role == null) return false;
    return role.permissions.contains(permission);
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

  @override
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
    final storedSuspended = await _database.loadSuspendedSales(_activeStoreId);
    _suspendedSales
      ..clear()
      ..addAll(storedSuspended.map(SuspendedSale.fromJson));
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

  @override
  bool _hasCompletedOnboarding = false;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

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

  @override
  int _cartCount = 0;
  int get cartCount => _cartCount;

  @override
  double _cartTotal = 0;
  double get cartTotal => _cartTotal;

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
}
