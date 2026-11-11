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
import 'daftari_recovery_models.dart';
import 'duka_ai_service.dart';
import 'pos_local_database.dart';
import 'pos_order_models.dart';
import 'receipt_settings.dart';
import 'expense_model.dart';
import 'package:track_mauzo/ui/models/capability.dart';

const _seedInventory = <InventoryProductItem>[
  InventoryProductItem(
    code: 'P001',
    name: 'Mineral Water 500ml',
    category: 'Beverages',
    purchasePrice: 2200,
    sellingPrice: 3000,
    stockCount: 120,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.aquafina,
  ),
  InventoryProductItem(
    code: 'P002',
    name: 'Coca-Cola',
    category: 'Beverages',
    purchasePrice: 2800,
    sellingPrice: 3750,
    stockCount: 85,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.coke,
  ),
  InventoryProductItem(
    code: 'P003',
    name: "Lay's Classic",
    category: 'Snacks',
    purchasePrice: 3400,
    sellingPrice: 4500,
    stockCount: 60,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.lays,
  ),
  InventoryProductItem(
    code: 'P004',
    name: 'Galaxy Milk',
    category: 'Snacks',
    purchasePrice: 3100,
    sellingPrice: 4000,
    stockCount: 40,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.galaxy,
  ),
  InventoryProductItem(
    code: 'P005',
    name: "Kellogg's Corn Flakes",
    category: 'Groceries',
    purchasePrice: 6400,
    sellingPrice: 8500,
    stockCount: 32,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.kelloggs,
  ),
  InventoryProductItem(
    code: 'P006',
    name: 'Dove Beauty Bar',
    category: 'Personal Care',
    purchasePrice: 2400,
    sellingPrice: 3125,
    stockCount: 54,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.dove,
  ),
  InventoryProductItem(
    code: 'P007',
    name: 'Colgate',
    category: 'Personal Care',
    purchasePrice: 3900,
    sellingPrice: 5250,
    stockCount: 28,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.colgate,
  ),
  InventoryProductItem(
    code: 'P008',
    name: 'Dettol Hand Wash',
    category: 'Personal Care',
    purchasePrice: 5200,
    sellingPrice: 7125,
    stockCount: 24,
    stockState: InventoryStockState.inStock,
    artType: ProductArtType.dettol,
  ),
  InventoryProductItem(
    code: 'P009',
    name: 'Tide Original',
    category: 'Household',
    purchasePrice: 9100,
    sellingPrice: 12250,
    stockCount: 18,
    stockState: InventoryStockState.lowStock,
    artType: ProductArtType.tide,
  ),
];

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

const _seedStaffRoles = <StaffRoleData>[
  StaffRoleData(
    id: 'role-admin',
    title: 'Admin',
    subtitle: 'Super full access',
    permissions: _staffPermissionCatalog,
    sortOrder: 0,
  ),
  StaffRoleData(
    id: 'role-manager',
    title: 'Manager',
    subtitle: 'Store management access',
    permissions: <String>[
      'View Sales',
      'View Reports',
      'Process Returns',
      'Discounts',
      'Manage Inventory',
      'Manage Staff',
    ],
    sortOrder: 1,
  ),
  StaffRoleData(
    id: 'role-cashier',
    title: 'Cashier',
    subtitle: 'Limited access for front counter',
    permissions: <String>[
      'View Sales',
      'Process Returns',
    ],
    sortOrder: 2,
  ),
];

class AppProfileData {
  const AppProfileData({
    required this.storeName,
    required this.ownerName,
    required this.roleTitle,
    required this.contactNumber,
    required this.emailAddress,
    required this.physicalAddress,
    required this.memberSince,
    required this.taxId,
    required this.weekdayOpen,
    required this.weekdayClose,
    required this.saturdayOpen,
    required this.saturdayClose,
    required this.sundaySchedule,
    required this.open24Hours,
    this.logoPath,
  });

  factory AppProfileData.empty() {
    return const AppProfileData(
      storeName: '',
      ownerName: '',
      roleTitle: '',
      contactNumber: '',
      emailAddress: '',
      physicalAddress: '',
      memberSince: '',
      taxId: '',
      weekdayOpen: '',
      weekdayClose: '',
      saturdayOpen: '',
      saturdayClose: '',
      sundaySchedule: '',
      open24Hours: false,
      logoPath: null,
    );
  }

  final String storeName;
  final String ownerName;
  final String roleTitle;
  final String contactNumber;
  final String emailAddress;
  final String physicalAddress;
  final String memberSince;
  final String taxId;
  final String weekdayOpen;
  final String weekdayClose;
  final String saturdayOpen;
  final String saturdayClose;
  final String sundaySchedule;
  final bool open24Hours;
  final String? logoPath;

  AppProfileData copyWith({
    String? storeName,
    String? ownerName,
    String? roleTitle,
    String? contactNumber,
    String? emailAddress,
    String? physicalAddress,
    String? memberSince,
    String? taxId,
    String? weekdayOpen,
    String? weekdayClose,
    String? saturdayOpen,
    String? saturdayClose,
    String? sundaySchedule,
    bool? open24Hours,
    String? logoPath,
  }) {
    return AppProfileData(
      storeName: storeName ?? this.storeName,
      ownerName: ownerName ?? this.ownerName,
      roleTitle: roleTitle ?? this.roleTitle,
      contactNumber: contactNumber ?? this.contactNumber,
      emailAddress: emailAddress ?? this.emailAddress,
      physicalAddress: physicalAddress ?? this.physicalAddress,
      memberSince: memberSince ?? this.memberSince,
      taxId: taxId ?? this.taxId,
      weekdayOpen: weekdayOpen ?? this.weekdayOpen,
      weekdayClose: weekdayClose ?? this.weekdayClose,
      saturdayOpen: saturdayOpen ?? this.saturdayOpen,
      saturdayClose: saturdayClose ?? this.saturdayClose,
      sundaySchedule: sundaySchedule ?? this.sundaySchedule,
      open24Hours: open24Hours ?? this.open24Hours,
      logoPath: logoPath ?? this.logoPath,
    );
  }
}

class StaffRoleData {
  const StaffRoleData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.permissions,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> permissions;
  final int sortOrder;

  StaffRoleData copyWith({
    String? id,
    String? title,
    String? subtitle,
    List<String>? permissions,
    int? sortOrder,
  }) {
    return StaffRoleData(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      permissions: permissions ?? this.permissions,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

enum StaffStatus {
  active('active', 'Active'),
  onLeave('on_leave', 'On Leave'),
  inactive('inactive', 'Inactive');

  const StaffStatus(this.value, this.label);

  final String value;
  final String label;

  static StaffStatus fromValue(String? value) {
    for (final status in StaffStatus.values) {
      if (status.value == value) return status;
    }
    return StaffStatus.active;
  }
}

enum EmploymentType {
  fullTime('full_time', 'Full-time'),
  partTime('part_time', 'Part-time'),
  contract('contract', 'Contract'),
  intern('intern', 'Intern'),
  temporary('temporary', 'Temporary');

  const EmploymentType(this.value, this.label);

  final String value;
  final String label;

  static EmploymentType? fromValue(String? value) {
    for (final type in EmploymentType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

class StaffMemberData {
  const StaffMemberData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.roleId,
    required this.createdAt,
    this.username = '',
    this.passwordHash = '',
    this.passwordSalt = '',
    this.employeeNumber = '',
    this.jobTitle = '',
    this.department = '',
    this.hireDate = '',
    this.employmentType = '',
    this.hourlyRate = 0,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelation = '',
    this.address = '',
    this.notes = '',
    this.avatarPath,
    this.status = StaffStatus.active,
    this.updatedAt = '',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String roleId;
  final String createdAt;
  final String username;
  final String passwordHash;
  final String passwordSalt;
  final String employeeNumber;
  final String jobTitle;
  final String department;
  final String hireDate;
  final String employmentType;
  final double hourlyRate;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelation;
  final String address;
  final String notes;
  final String? avatarPath;
  final StaffStatus status;
  final String updatedAt;

  bool get hasLogin => username.trim().isNotEmpty;
  bool get hasPassword => passwordHash.isNotEmpty;
  bool get isActive => status == StaffStatus.active;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'ST';
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  StaffMemberData copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? roleId,
    String? createdAt,
    String? username,
    String? passwordHash,
    String? passwordSalt,
    String? employeeNumber,
    String? jobTitle,
    String? department,
    String? hireDate,
    String? employmentType,
    double? hourlyRate,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? address,
    String? notes,
    String? avatarPath,
    StaffStatus? status,
    String? updatedAt,
  }) {
    return StaffMemberData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      employeeNumber: employeeNumber ?? this.employeeNumber,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      hireDate: hireDate ?? this.hireDate,
      employmentType: employmentType ?? this.employmentType,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      avatarPath: avatarPath ?? this.avatarPath,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PosLocalStore extends ChangeNotifier {
  PosLocalStore({PosLocalDatabase? database})
      : _database = database ?? PosLocalDatabase.instance;

  static const _storeId = 'store-default';
  static const _defaultThreadId = 'thread-$_storeId';
  bool _savingCheckout = false;

  final PosLocalDatabase _database;
  static const Duration _eastAfricaOffset = Duration(hours: 3);

  final List<ProductItem> _products = <ProductItem>[];
  final List<ProductItem> _cartItems = <ProductItem>[];
  final List<CompletedOrder> _orders = <CompletedOrder>[];
  final List<InventoryProductItem> _allInventory = <InventoryProductItem>[];
  final List<StaffRoleData> _staffRoles = <StaffRoleData>[];
  final List<StaffMemberData> _staffMembers = <StaffMemberData>[];
  final List<DaftariRecoverySession> _daftariSessions =
      <DaftariRecoverySession>[];
  final List<DaftariLearningRule> _daftariLearningRules =
      <DaftariLearningRule>[];
  final List<DukaAiThread> _dukaAiThreads = <DukaAiThread>[];
  final List<DukaAiMessage> _dukaAiMessages = <DukaAiMessage>[];
  final List<Expense> _expenses = <Expense>[];
  AppProfileData _profile = AppProfileData.empty();
  ReceiptSettings _receiptSettings = const ReceiptSettings();
  String? _activeDukaAiThreadId;
  Timer? _midnightRefreshTimer;

  static const String _defaultGeminiApiKey = '';
  static const String _defaultGroqApiKey = '';
  static const String _defaultGroqModel = 'llama-3.1-8b-instant';
  static const String _defaultLanguageCode = 'sw';
  String _geminiApiKey = _defaultGeminiApiKey;
  String _groqApiKey = _defaultGroqApiKey;
  String _groqModel = _defaultGroqModel;
  String _languageCode = _defaultLanguageCode;
  bool _useLiveGeminiOcr = true;

  String get geminiApiKey => _geminiApiKey;
  String get groqApiKey => _groqApiKey;
  String get groqModel => _groqModel;
  String get languageCode => _languageCode;
  ReceiptSettings get receiptSettings => _receiptSettings;
  bool get useLiveGeminiOcr => _useLiveGeminiOcr;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  void dispose() {
    _midnightRefreshTimer?.cancel();
    super.dispose();
  }

  static PosLocalStore of(BuildContext context) {
    return context.read<PosLocalStore>();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    final storedInventory = await _database.loadInventory(_storeId);
    if (storedInventory.isEmpty) {
      _allInventory
        ..clear()
        ..addAll(_seedInventory);
      await _database.replaceInventory(_allInventory, _storeId);
    } else {
      _allInventory
        ..clear()
        ..addAll(storedInventory);
    }
    // ... continue updating other loaders

    _syncProductsFromInventory();

    final storedCart = await _database.loadCart(_storeId);
    if (storedCart.isEmpty) {
      _cartItems
        ..clear()
        ..addAll(_products.take(3));
      await _database.replaceCart(_cartItems, _storeId);
    } else {
      _cartItems
        ..clear()
        ..addAll(storedCart);
    }

    _orders
      ..clear()
      ..addAll(await _database.loadOrders(_storeId));

    final storedRoles = await _database.loadStaffRoles(_storeId);
    if (storedRoles.isEmpty) {
      _staffRoles
        ..clear()
        ..addAll(_seedStaffRoles.map((role) => role.copyWith(id: '$_storeId:${role.id}')));
      await _database.replaceStaffRoles(
        _staffRoles.map(_staffRoleToMap).toList(),
        _storeId,
      );
    } else {
      _staffRoles
        ..clear()
        ..addAll(storedRoles.map(_staffRoleFromMap));
    }

    final storedMembers = await _database.loadStaffMembers(_storeId);
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

    _daftariSessions
      ..clear()
      ..addAll(await _database.loadDaftariSessions(_storeId));
    _daftariLearningRules
      ..clear()
      ..addAll(await _database.loadDaftariLearningRules(_storeId));
    _dukaAiThreads
      ..clear()
      ..addAll(await _database.loadDukaAiThreads(_storeId));

    final storedExpenses = await _database.loadExpenses(_storeId);
    _expenses
      ..clear()
      ..addAll(storedExpenses.map(Expense.fromMap));

    final storedCustomers = await _database.loadCustomers(_storeId);
    _customers
      ..clear()
      ..addAll(storedCustomers.map(_customerFromMap));

    if (_dukaAiThreads.isEmpty) {
      final now = DateTime.now().toIso8601String();
      final defaultThread = DukaAiThread(
        id: _defaultThreadId,
        title: 'MyDuka AI',
        preview: '',
        createdAt: now,
        updatedAt: now,
      );
      _dukaAiThreads.add(defaultThread);
      await _database.upsertDukaAiThread(defaultThread, _storeId);
    }

    _activeDukaAiThreadId = _dukaAiThreads.first.id;
    _dukaAiMessages
      ..clear()
      ..addAll(await _database.loadDukaAiMessages(_activeDukaAiThreadId!));
    if (_dukaAiMessages.isEmpty) {
      _dukaAiMessages.add(
        DukaAiMessage(
          role: 'assistant',
          content:
              'Hi, I am DUKA AI. Ask me anything about sales, stock, pricing, expenses, or what to do next.',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      await _database.replaceDukaAiMessages(
        _activeDukaAiThreadId!,
        _dukaAiMessages,
        _storeId,
      );
    }

    _dukaAiMessages.sort(_compareMessagesByTime);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/daftari_gemini_config.json');
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _geminiApiKey = map['apiKey'] as String? ?? _defaultGeminiApiKey;
        _groqApiKey = map['groqApiKey'] as String? ?? _defaultGroqApiKey;
        _groqModel = map['groqModel'] as String? ?? _defaultGroqModel;
        _useLiveGeminiOcr = map['useLiveOcr'] as bool? ?? true;
      } else {
        // Write default config so it persists
        await file.writeAsString(jsonEncode({
          'apiKey': _defaultGeminiApiKey,
          'groqApiKey': _defaultGroqApiKey,
          'groqModel': _defaultGroqModel,
          'useLiveOcr': true,
        }));
      }
    } catch (e) {
      // Ignore
    }

    _receiptSettings = await _database.loadReceiptSettings();
    await _loadUiConfig();

    _updateCartTotals();
    _scheduleMidnightRefresh();
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
    });
  }

  List<Expense> get expenses => List.unmodifiable(_expenses);

  Future<void> addExpense(Expense expense) async {
    _expenses.insert(0, expense);
    notifyListeners();
    await _database.insertExpense(expense.toMap(), _storeId);
  }

  Future<void> deleteExpense(int id) async {
    _expenses.removeWhere((expense) => expense.id == id);
    notifyListeners();
    await _database.deleteExpense(id);
  }

  Future<void> updateGeminiSettings({
    required String apiKey,
    required bool useLiveOcr,
    String? groqApiKey,
    String? groqModel,
  }) async {
    _geminiApiKey = apiKey;
    _useLiveGeminiOcr = useLiveOcr;
    if (groqApiKey != null) _groqApiKey = groqApiKey;
    if (groqModel != null) _groqModel = groqModel;
    notifyListeners();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/daftari_gemini_config.json');
      await file.writeAsString(jsonEncode({
        'apiKey': _geminiApiKey,
        'groqApiKey': _groqApiKey,
        'groqModel': _groqModel,
        'useLiveOcr': _useLiveGeminiOcr,
      }));
    } catch (e) {
      // Ignore
    }
  }

  Future<void> updateReceiptSettings(ReceiptSettings settings) async {
    await _database.saveReceiptSettings(settings);
    _receiptSettings = settings;
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    final nextCode = AppStrings.normalize(code);
    if (_languageCode == nextCode) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/track_mauzo_ui_config.json');
    await file.writeAsString(jsonEncode({'languageCode': nextCode}), flush: true);
    _languageCode = nextCode;
    notifyListeners();
  }

  Future<void> _loadUiConfig() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/track_mauzo_ui_config.json');
      if (!await file.exists()) {
        await file.writeAsString(
          jsonEncode({'languageCode': _defaultLanguageCode}),
        );
        return;
      }

      final jsonStr = await file.readAsString();
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      _languageCode = AppStrings.normalize(
        map['languageCode'] as String? ?? _defaultLanguageCode,
      );
    } catch (e) {
      _languageCode = _defaultLanguageCode;
    }
  }

  List<ProductItem> get products => List.unmodifiable(_products);
  List<ProductItem> get cartItems => List.unmodifiable(_cartItems);
  List<CompletedOrder> get orders => List.unmodifiable(_orders);
  List<InventoryProductItem> get inventory => List.unmodifiable(_allInventory);
  List<StaffRoleData> get staffRoles => List.unmodifiable(_staffRoles);
  List<StaffMemberData> get staffMembers => List.unmodifiable(_staffMembers);
  List<String> get staffPermissionCatalog =>
      List.unmodifiable(_staffPermissionCatalog);
  List<DaftariRecoverySession> get daftariSessions =>
      List.unmodifiable(_daftariSessions);
  List<DaftariLearningRule> get daftariLearningRules =>
      List.unmodifiable(_daftariLearningRules);
  List<DukaAiThread> get dukaAiThreads => List.unmodifiable(_dukaAiThreads);
  List<DukaAiMessage> get dukaAiMessages => List.unmodifiable(_dukaAiMessages);
  String get activeDukaAiThreadId =>
      _activeDukaAiThreadId ?? _dukaAiThreads.first.id;
  DukaAiThread? get activeDukaAiThread {
    final activeId = _activeDukaAiThreadId;
    if (activeId == null) {
      return _dukaAiThreads.isEmpty ? null : _dukaAiThreads.first;
    }
    for (final thread in _dukaAiThreads) {
      if (thread.id == activeId) return thread;
    }
    return _dukaAiThreads.isEmpty ? null : _dukaAiThreads.first;
  }

  AppProfileData get profile => _profile;
  BusinessCategory get businessCategory => BusinessCategory.retail;

  BusinessCategoryConfig get businessCategoryConfig =>
      BusinessCategoryConfig.forCategory(businessCategory);

  Set<Capability> get activeCapabilities => businessCategoryConfig.capabilities;

  int _compareMessagesByTime(DukaAiMessage a, DukaAiMessage b) {
    final aTime = DateTime.tryParse(a.createdAt ?? '');
    final bTime = DateTime.tryParse(b.createdAt ?? '');
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return aTime.compareTo(bTime);
  }

  DaftariRecoverySession? get latestDaftariSession =>
      _daftariSessions.isEmpty ? null : _daftariSessions.first;

  DaftariRecoverySession? daftariSessionById(String id) {
    for (final session in _daftariSessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  Map<String, List<String>> get daftariLearningAliases {
    final aliases = <String, List<String>>{};
    for (final rule in _daftariLearningRules) {
      aliases.putIfAbsent(rule.targetProductCode, () => <String>[]);
      aliases[rule.targetProductCode]!.add(rule.sourceText);
    }
    return aliases;
  }

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
    unawaited(_database.replaceCart(_cartItems, _storeId));
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
    unawaited(_database.replaceCart(_cartItems, _storeId));
    return true;
  }

  bool removeSingleFromCart(ProductItem product) {
    final index = _cartItems.indexWhere(_sameProduct(product));
    if (index == -1) return false;
    _cartItems.removeAt(index);
    _updateCartTotals();
    notifyListeners();
    unawaited(_database.replaceCart(_cartItems, _storeId));
    return true;
  }

  Future<void> saveDaftariSession(DaftariRecoverySession session) async {
    final index = _daftariSessions.indexWhere((item) => item.id == session.id);
    if (index == -1) {
      _daftariSessions.insert(0, session);
    } else {
      _daftariSessions[index] = session;
      _daftariSessions
          .sort((left, right) => right.createdAt.compareTo(left.createdAt));
    }
    notifyListeners();
    await _database.upsertDaftariSession(session, _storeId);
  }

  Future<void> rememberDaftariCorrection({
    required String sourceText,
    required ProductItem product,
  }) async {
    final normalizedSource = sourceText.trim();
    if (normalizedSource.isEmpty) return;

    final targetCode = product.code ?? product.name;
    final now = DateTime.now().toIso8601String();
    final existingIndex = _daftariLearningRules.indexWhere(
      (rule) =>
          rule.sourceText.toLowerCase() == normalizedSource.toLowerCase() &&
          rule.targetProductCode == targetCode,
    );

    final updated = existingIndex == -1
        ? DaftariLearningRule(
            id: 'learn-${DateTime.now().microsecondsSinceEpoch}',
            sourceText: normalizedSource,
            targetProductCode: targetCode,
            targetProductName: product.name,
            createdAt: now,
            hitCount: 1,
            lastUsedAt: now,
          )
        : DaftariLearningRule(
            id: _daftariLearningRules[existingIndex].id,
            sourceText: normalizedSource,
            targetProductCode: targetCode,
            targetProductName: product.name,
            createdAt: _daftariLearningRules[existingIndex].createdAt,
            hitCount: _daftariLearningRules[existingIndex].hitCount + 1,
            lastUsedAt: now,
          );

    if (existingIndex == -1) {
      _daftariLearningRules.insert(0, updated);
    } else {
      _daftariLearningRules[existingIndex] = updated;
    }
    _daftariLearningRules.sort((left, right) {
      final lastUsed = right.lastUsedAt.compareTo(left.lastUsedAt);
      if (lastUsed != 0) return lastUsed;
      return right.hitCount.compareTo(left.hitCount);
    });
    notifyListeners();
    await _database.upsertDaftariLearningRule(updated, _storeId);
  }

  Future<void> replaceDukaAiMessages(List<DukaAiMessage> messages) async {
    await replaceDukaAiMessagesForThread(activeDukaAiThreadId, messages);
  }

  Future<void> replaceDukaAiMessagesForThread(
    String threadId,
    List<DukaAiMessage> messages,
  ) async {
    _dukaAiMessages
      ..clear()
      ..addAll(messages);
    notifyListeners();
    await _database.replaceDukaAiMessages(threadId, _dukaAiMessages, _storeId);
  }

  Future<DukaAiThread> createDukaAiThread({
    String? title,
    List<DukaAiMessage>? seedMessages,
  }) async {
    final now = DateTime.now().toIso8601String();
    final thread = DukaAiThread(
      id: 'thread-${DateTime.now().millisecondsSinceEpoch}',
      title: title?.trim().isNotEmpty == true ? title!.trim() : 'New chat',
      preview: seedMessages == null || seedMessages.isEmpty
          ? ''
          : seedMessages.last.content,
      createdAt: now,
      updatedAt: now,
    );
    _dukaAiThreads.insert(0, thread);
    _activeDukaAiThreadId = thread.id;
    _dukaAiMessages
      ..clear()
      ..addAll(seedMessages ?? const <DukaAiMessage>[]);
    notifyListeners();
    await _database.upsertDukaAiThread(thread, _storeId);
    await _database.replaceDukaAiMessages(thread.id, _dukaAiMessages, _storeId);
    return thread;
  }

  Future<void> setActiveDukaAiThread(String threadId) async {
    final thread = _dukaAiThreads.firstWhere(
      (item) => item.id == threadId,
      orElse: () => _dukaAiThreads.first,
    );
    _activeDukaAiThreadId = thread.id;
    _dukaAiMessages
      ..clear()
      ..addAll(await _database.loadDukaAiMessages(thread.id));
    notifyListeners();
  }

  Future<void> updateDukaAiThreadTitle(
    String threadId,
    String title,
  ) async {
    final index = _dukaAiThreads.indexWhere((thread) => thread.id == threadId);
    if (index == -1) return;
    final current = _dukaAiThreads[index];
    final updated = current.copyWith(
      title: title.trim().isEmpty ? current.title : title.trim(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    _dukaAiThreads[index] = updated;
    _dukaAiThreads
        .sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    notifyListeners();
    await _database.upsertDukaAiThread(updated, _storeId);
  }

  Future<void> updateDukaAiThreadPreview(
    String threadId,
    String preview,
  ) async {
    final index = _dukaAiThreads.indexWhere((thread) => thread.id == threadId);
    if (index == -1) return;
    final current = _dukaAiThreads[index];
    final updated = current.copyWith(
      preview: preview.trim(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    _dukaAiThreads[index] = updated;
    _dukaAiThreads
        .sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    notifyListeners();
    await _database.upsertDukaAiThread(updated, _storeId);
  }

  Future<void> deleteDukaAiThread(String threadId) async {
    final index = _dukaAiThreads.indexWhere((thread) => thread.id == threadId);
    if (index == -1) return;

    final wasActive = _activeDukaAiThreadId == threadId;
    _dukaAiThreads.removeAt(index);
    await _database.deleteDukaAiThread(threadId);

    if (_dukaAiThreads.isEmpty) {
      final now = DateTime.now().toIso8601String();
      final defaultThread = DukaAiThread(
        id: _defaultThreadId,
        title: 'MyDuka AI',
        preview: '',
        createdAt: now,
        updatedAt: now,
      );
      _dukaAiThreads.add(defaultThread);
      _activeDukaAiThreadId = defaultThread.id;
      _dukaAiMessages
        ..clear()
        ..add(
          DukaAiMessage(
            role: 'assistant',
            content:
                'Hi, I am DUKA AI. Ask me anything about sales, stock, pricing, expenses, or what to do next.',
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      await _database.upsertDukaAiThread(defaultThread, _storeId);
      await _database.replaceDukaAiMessages(defaultThread.id, _dukaAiMessages, _storeId);
    } else if (wasActive) {
      _activeDukaAiThreadId = _dukaAiThreads.first.id;
      _dukaAiMessages
        ..clear()
        ..addAll(await _database.loadDukaAiMessages(_activeDukaAiThreadId!));
    }

    notifyListeners();
  }

  void removeFromCart(int index) {
    if (index < 0 || index >= _cartItems.length) return;
    _cartItems.removeAt(index);
    _updateCartTotals();
    notifyListeners();
    unawaited(_database.replaceCart(_cartItems, _storeId));
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
    unawaited(_database.replaceCart(_cartItems, _storeId));
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    _updateCartTotals();
    notifyListeners();
    await _database.replaceCart(_cartItems, _storeId);
  }

  InventoryProductItem addProduct(InventoryProductItem product) {
    _allInventory.insert(0, product);
    _syncProductsFromInventory();
    notifyListeners();
    unawaited(_database.replaceInventory(_allInventory, _storeId));
    return product;
  }

  void updateProduct(InventoryProductItem product) {
    final index = _allInventory.indexWhere((item) => item.code == product.code);
    if (index != -1) {
      _allInventory[index] = product;
      _syncProductsFromInventory();
      notifyListeners();
      unawaited(_database.replaceInventory(_allInventory, _storeId));
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
    await _database.replaceInventory(_allInventory, _storeId);
    await _database.replaceCart(_cartItems, _storeId);

    final imagePath = removedItem?.imagePath;
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
    await _database.replaceInventory(_allInventory, _storeId);
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
    final total = subtotal - (discountAmount ?? 0);
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
      final inventoryItem = stockUpdates[inventoryIndex] ?? _allInventory[inventoryIndex];
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
    final order = CompletedOrder(
      id: 'ORD-${now.millisecondsSinceEpoch}',
      dateTime: now.toIso8601String(),
      date: _formatDate(now),
      time: _formatTime(now),
      total: total,
      status: 'Completed',
      cashierName: cashierName,
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
      }
    }

    _savingCheckout = true;
    try {
      await _database.saveCheckout(
        order: order,
        storeId: _storeId,
        stockUpdates: stockUpdates.values.toList(),
        creditCustomer: creditCustomer == null ? null : _customerToMap(creditCustomer),
      );
      for (final item in stockUpdates.values) {
        final index = _allInventory.indexWhere((product) => product.code == item.code);
        if (index >= 0) _allInventory[index] = item;
      }
      if (creditCustomer != null) {
        final id = creditCustomer.id;
        final index = _customers.indexWhere((customer) => customer.id == id);
        if (index >= 0) _customers[index] = creditCustomer;
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
    _syncProductsFromInventory();
    notifyListeners();

    await _database.replaceInventory(_allInventory, _storeId);
    await _database.deleteOrder(orderId);
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

  List<StaffMemberData> staffMembersForRole(String roleId) {
    return _staffMembers.where((staff) => staff.roleId == roleId).toList();
  }

  Future<StaffRoleData> saveStaffRole(StaffRoleData role) async {    final existingIndex = _staffRoles.indexWhere((item) => item.id == role.id);
    final nextRole = existingIndex == -1
        ? role.copyWith(sortOrder: _staffRoles.length)
        : role.copyWith(sortOrder: _staffRoles[existingIndex].sortOrder);
    if (existingIndex == -1) {
      _staffRoles.add(nextRole);
    } else {
      _staffRoles[existingIndex] = nextRole;
    }
    _staffRoles.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    notifyListeners();
    await _database.replaceStaffRoles(
      _staffRoles.map(_staffRoleToMap).toList(),
      _storeId,
    );
    return nextRole;
  }

  Future<void> updateStaffRolePermissions(
    String roleId,
    List<String> permissions,
  ) async {
    final index = _staffRoles.indexWhere((role) => role.id == roleId);
    if (index == -1) return;
    _staffRoles[index] = _staffRoles[index].copyWith(
      permissions: List<String>.from(permissions),
    );
    notifyListeners();
    await _database.replaceStaffRoles(
      _staffRoles.map(_staffRoleToMap).toList(),
      _storeId,
    );
  }

  Future<void> deleteStaffRole(String roleId) async {
    if (_staffMembers.any((staff) => staff.roleId == roleId)) return;
    _staffRoles.removeWhere((role) => role.id == roleId);
    notifyListeners();
    await _database.replaceStaffRoles(
      _staffRoles.map(_staffRoleToMap).toList(),
      _storeId,
    );
  }

  Future<StaffMemberData> saveStaffMember(StaffMemberData staff) async {
    final existingIndex =
        _staffMembers.indexWhere((item) => item.id == staff.id);
    final nextStaff = existingIndex == -1
        ? staff
        : staff.copyWith(createdAt: _staffMembers[existingIndex].createdAt);
    if (existingIndex == -1) {
      _staffMembers.insert(0, nextStaff);
    } else {
      _staffMembers[existingIndex] = nextStaff;
    }
    notifyListeners();
    await _database.replaceStaffMembers(
      _staffMembers.map(_staffMemberToMap).toList(),
      _storeId,
    );
    return nextStaff;
  }

  Future<StaffMemberData> addStaffMember({
    required String name,
    required String email,
    required String phone,
    required String roleId,
    String username = '',
    String? password,
    String employeeNumber = '',
    String jobTitle = '',
    String department = '',
    String hireDate = '',
    String employmentType = '',
    double hourlyRate = 0,
    String emergencyContactName = '',
    String emergencyContactPhone = '',
    String emergencyContactRelation = '',
    String address = '',
    String notes = '',
    String? avatarPath,
    StaffStatus status = StaffStatus.active,
  }) async {
    final now = DateTime.now().toIso8601String();
    final credentials = password == null || password.isEmpty
        ? (hash: '', salt: '')
        : _hashPassword(password);

    return saveStaffMember(
      StaffMemberData(
        id: 'staff-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        phone: phone,
        roleId: roleId,
        createdAt: now,
        username: username,
        passwordHash: credentials.hash,
        passwordSalt: credentials.salt,
        employeeNumber: employeeNumber,
        jobTitle: jobTitle,
        department: department,
        hireDate: hireDate,
        employmentType: employmentType,
        hourlyRate: hourlyRate,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
        emergencyContactRelation: emergencyContactRelation,
        address: address,
        notes: notes,
        avatarPath: avatarPath,
        status: status,
        updatedAt: now,
      ),
    );
  }

  Future<StaffMemberData> updateStaffMember(
    StaffMemberData member, {
    String? newPassword,
  }) async {
    var next = member;
    if (newPassword != null && newPassword.isNotEmpty) {
      final credentials = _hashPassword(newPassword);
      next = next.copyWith(
        passwordHash: credentials.hash,
        passwordSalt: credentials.salt,
      );
    }
    next = next.copyWith(updatedAt: DateTime.now().toIso8601String());
    return saveStaffMember(next);
  }

  Future<void> setStaffStatus(String staffId, StaffStatus status) async {
    final index = _staffMembers.indexWhere((staff) => staff.id == staffId);
    if (index == -1) return;
    _staffMembers[index] = _staffMembers[index].copyWith(
      status: status,
      updatedAt: DateTime.now().toIso8601String(),
    );
    notifyListeners();
    await _database.replaceStaffMembers(
      _staffMembers.map(_staffMemberToMap).toList(),
      _storeId,
    );
  }

  bool staffUsernameExists(String username, {String? excludingId}) {
    final needle = username.trim().toLowerCase();
    if (needle.isEmpty) return false;
    for (final staff in _staffMembers) {
      if (staff.id == excludingId) continue;
      if (staff.username.trim().toLowerCase() == needle) return true;
    }
    return false;
  }

  bool staffEmployeeNumberExists(String employeeNumber, {String? excludingId}) {
    final needle = employeeNumber.trim().toLowerCase();
    if (needle.isEmpty) return false;
    for (final staff in _staffMembers) {
      if (staff.id == excludingId) continue;
      if (staff.employeeNumber.trim().toLowerCase() == needle) return true;
    }
    return false;
  }

  ({String hash, String salt}) _hashPassword(String password) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt = base64UrlEncode(saltBytes);
    final digest = sha256.convert(utf8.encode('$salt:$password')).toString();
    return (hash: digest, salt: salt);
  }

  Future<void> updateStaffMemberRole(String staffId, String roleId) async {
    final index = _staffMembers.indexWhere((staff) => staff.id == staffId);
    if (index == -1) return;
    _staffMembers[index] = _staffMembers[index].copyWith(roleId: roleId);
    notifyListeners();
    await _database.replaceStaffMembers(
      _staffMembers.map(_staffMemberToMap).toList(),
      _storeId,
    );
  }

  Future<void> deleteStaffMember(String staffId) async {
    _staffMembers.removeWhere((staff) => staff.id == staffId);
    notifyListeners();
    await _database.replaceStaffMembers(
      _staffMembers.map(_staffMemberToMap).toList(),
      _storeId,
    );
  }

  void _syncProductsFromInventory() {
    _products
      ..clear()
      ..addAll(_allInventory.map(_toProductItem));
  }

  ProductItem _toProductItem(InventoryProductItem product) {
    return ProductItem(
      product.name,
      _deriveProductSize(product),
      product.sellingPrice.toStringAsFixed(0),
      product.artType,
      code: product.code,
      category: product.category,
      imagePath: product.imagePath,
    );
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
    if (stockCount <= 20) return InventoryStockState.lowStock;
    return InventoryStockState.inStock;
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
    return '${monthNames[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $suffix';
  }

  Map<String, Object?> _staffRoleToMap(StaffRoleData role) {
    return <String, Object?>{
      'id': role.id,
      'title': role.title,
      'subtitle': role.subtitle,
      'permissions_json': jsonEncode(role.permissions),
      'sort_order': role.sortOrder,
    };
  }

  StaffRoleData _staffRoleFromMap(Map<String, Object?> map) {
    final permissions =
        jsonDecode(map['permissions_json'] as String? ?? '[]') as List<dynamic>;
    return StaffRoleData(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      permissions: permissions.map((item) => item.toString()).toList(),
      sortOrder: (map['sort_order'] as num).toInt(),
    );
  }

  Map<String, Object?> _staffMemberToMap(StaffMemberData staff) {
    return <String, Object?>{
      'id': staff.id,
      'name': staff.name,
      'email': staff.email,
      'phone': staff.phone,
      'role_id': staff.roleId,
      'created_at': staff.createdAt,
      'username': staff.username,
      'password_hash': staff.passwordHash,
      'password_salt': staff.passwordSalt,
      'employee_number': staff.employeeNumber,
      'job_title': staff.jobTitle,
      'department': staff.department,
      'hire_date': staff.hireDate,
      'employment_type': staff.employmentType,
      'hourly_rate': staff.hourlyRate,
      'emergency_contact_name': staff.emergencyContactName,
      'emergency_contact_phone': staff.emergencyContactPhone,
      'emergency_contact_relation': staff.emergencyContactRelation,
      'address': staff.address,
      'notes': staff.notes,
      'avatar_path': staff.avatarPath,
      'status': staff.status.value,
      'updated_at': staff.updatedAt,
    };
  }

  StaffMemberData _staffMemberFromMap(Map<String, Object?> map) {
    return StaffMemberData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      roleId: map['role_id'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
      username: map['username'] as String? ?? '',
      passwordHash: map['password_hash'] as String? ?? '',
      passwordSalt: map['password_salt'] as String? ?? '',
      employeeNumber: map['employee_number'] as String? ?? '',
      jobTitle: map['job_title'] as String? ?? '',
      department: map['department'] as String? ?? '',
      hireDate: map['hire_date'] as String? ?? '',
      employmentType: map['employment_type'] as String? ?? '',
      hourlyRate: (map['hourly_rate'] as num?)?.toDouble() ?? 0,
      emergencyContactName: map['emergency_contact_name'] as String? ?? '',
      emergencyContactPhone: map['emergency_contact_phone'] as String? ?? '',
      emergencyContactRelation:
          map['emergency_contact_relation'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      avatarPath: map['avatar_path'] as String?,
      status: StaffStatus.fromValue(map['status'] as String?),
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  final List<CustomerData> _customers = <CustomerData>[];
  List<CustomerData> get customers => _customers;

  Future<void> addCustomer(CustomerData customer) async {
    _customers.add(customer);
    notifyListeners();
    await _database.replaceCustomers(_customers.map(_customerToMap).toList(), _storeId);
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
    _customers[index] = customer;
    notifyListeners();
    await _database.replaceCustomers(_customers.map(_customerToMap).toList(), _storeId);
  }

  Future<void> deleteCustomer(String customerId) async {
    _customers.removeWhere((c) => c.id == customerId);
    notifyListeners();
    await _database.replaceCustomers(_customers.map(_customerToMap).toList(), _storeId);
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
