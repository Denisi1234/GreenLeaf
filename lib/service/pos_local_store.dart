import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../ui/models/product_item.dart';
import '../ui/models/customer_data.dart';
import '../ui/products/inventory_product_item.dart';
import 'daftari_recovery_models.dart';
import 'duka_ai_service.dart';
import 'pos_local_database.dart';
import 'pos_order_models.dart';
import 'expense_model.dart';

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
    required this.businessCategory,
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
      businessCategory: '',
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
  final String businessCategory;
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
    String? businessCategory,
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
      businessCategory: businessCategory ?? this.businessCategory,
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

class StaffMemberData {
  const StaffMemberData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.roleId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String roleId;
  final String createdAt;

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
  }) {
    return StaffMemberData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PosLocalStore extends ChangeNotifier {
  PosLocalStore({PosLocalDatabase? database})
      : _database = database ?? PosLocalDatabase.instance;

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
  String? _activeDukaAiThreadId;
  Timer? _midnightRefreshTimer;

  static const String _defaultGeminiApiKey = '';
  static const String _defaultGroqApiKey = '';
  static const String _defaultGroqModel = 'llama-3.1-8b-instant';
  String _geminiApiKey = _defaultGeminiApiKey;
  String _groqApiKey = _defaultGroqApiKey;
  String _groqModel = _defaultGroqModel;
  bool _useLiveGeminiOcr = true;

  String get geminiApiKey => _geminiApiKey;
  String get groqApiKey => _groqApiKey;
  String get groqModel => _groqModel;
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

    final storedInventory = await _database.loadInventory();
    if (storedInventory.isEmpty) {
      _allInventory
        ..clear()
        ..addAll(_seedInventory);
      await _database.replaceInventory(_allInventory);
    } else {
      _allInventory
        ..clear()
        ..addAll(storedInventory);
    }

    _syncProductsFromInventory();

    final storedCart = await _database.loadCart();
    if (storedCart.isEmpty) {
      _cartItems
        ..clear()
        ..addAll(_products.take(3));
      await _database.replaceCart(_cartItems);
    } else {
      _cartItems
        ..clear()
        ..addAll(storedCart);
    }

    _orders
      ..clear()
      ..addAll(await _database.loadOrders());

    final storedRoles = await _database.loadStaffRoles();
    if (storedRoles.isEmpty) {
      _staffRoles
        ..clear()
        ..addAll(_seedStaffRoles);
      await _database.replaceStaffRoles(
        _staffRoles.map(_staffRoleToMap).toList(),
      );
    } else {
      _staffRoles
        ..clear()
        ..addAll(storedRoles.map(_staffRoleFromMap));
    }

    final storedMembers = await _database.loadStaffMembers();
    _staffMembers
      ..clear()
      ..addAll(storedMembers.map(_staffMemberFromMap));

    final storedProfile = await _database.loadAppProfile();
    _profile = storedProfile == null
        ? AppProfileData.empty()
        : AppProfileData(
            storeName: storedProfile['store_name'] as String,
            ownerName: storedProfile['owner_name'] as String,
            roleTitle: storedProfile['role_title'] as String,
            businessCategory: storedProfile['business_category'] as String,
            contactNumber: storedProfile['contact_number'] as String,
            emailAddress: storedProfile['email_address'] as String,
            physicalAddress: storedProfile['physical_address'] as String,
            memberSince: storedProfile['member_since'] as String,
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
      ..addAll(await _database.loadDaftariSessions());
    _daftariLearningRules
      ..clear()
      ..addAll(await _database.loadDaftariLearningRules());
    _dukaAiThreads
      ..clear()
      ..addAll(await _database.loadDukaAiThreads());

    final storedExpenses = await _database.loadExpenses();
    _expenses
      ..clear()
      ..addAll(storedExpenses.map(Expense.fromMap));

    final storedCustomers = await _database.loadCustomers();
    _customers
      ..clear()
      ..addAll(storedCustomers.map(_customerFromMap));

    if (_dukaAiThreads.isEmpty) {
      final now = DateTime.now().toIso8601String();
      final defaultThread = DukaAiThread(
        id: 'thread-default',
        title: 'MyDuka AI',
        preview: '',
        createdAt: now,
        updatedAt: now,
      );
      _dukaAiThreads.add(defaultThread);
      await _database.upsertDukaAiThread(defaultThread);
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
    await _database.insertExpense(expense.toMap());
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

  List<ProductItem> get products => List.unmodifiable(_products);
  List<ProductItem> get cartItems => List.unmodifiable(_cartItems);
  List<CompletedOrder> get orders => List.unmodifiable(_orders);
  List<InventoryProductItem> get inventory => List.unmodifiable(_allInventory);
  List<StaffRoleData> get staffRoles => List.unmodifiable(_staffRoles);
  List<StaffMemberData> get staffMembers => List.unmodifiable(_staffMembers);
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
    unawaited(_database.replaceCart(_cartItems));
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
    unawaited(_database.replaceCart(_cartItems));
    return true;
  }

  bool removeSingleFromCart(ProductItem product) {
    final index = _cartItems.indexWhere(_sameProduct(product));
    if (index == -1) return false;
    _cartItems.removeAt(index);
    _updateCartTotals();
    notifyListeners();
    unawaited(_database.replaceCart(_cartItems));
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
    await _database.upsertDaftariSession(session);
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
    await _database.upsertDaftariLearningRule(updated);
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
    await _database.replaceDukaAiMessages(threadId, _dukaAiMessages);
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
    await _database.upsertDukaAiThread(thread);
    await _database.replaceDukaAiMessages(thread.id, _dukaAiMessages);
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
    await _database.upsertDukaAiThread(updated);
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
    await _database.upsertDukaAiThread(updated);
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
        id: 'thread-default',
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
      await _database.upsertDukaAiThread(defaultThread);
      await _database.replaceDukaAiMessages(defaultThread.id, _dukaAiMessages);
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
    unawaited(_database.replaceCart(_cartItems));
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
    unawaited(_database.replaceCart(_cartItems));
  }

  Future<void> clearCart() async {
    _cartItems.clear();
    _updateCartTotals();
    notifyListeners();
    await _database.replaceCart(_cartItems);
  }

  InventoryProductItem addProduct(InventoryProductItem product) {
    _allInventory.insert(0, product);
    _syncProductsFromInventory();
    notifyListeners();
    unawaited(_database.replaceInventory(_allInventory));
    return product;
  }

  void updateProduct(InventoryProductItem product) {
    final index = _allInventory.indexWhere((item) => item.code == product.code);
    if (index != -1) {
      _allInventory[index] = product;
      _syncProductsFromInventory();
      notifyListeners();
      unawaited(_database.replaceInventory(_allInventory));
    }
  }

  void removeProduct(String code) {
    _allInventory.removeWhere((item) => item.code == code);
    _syncProductsFromInventory();
    notifyListeners();
    unawaited(_database.replaceInventory(_allInventory));
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
    await _database.replaceInventory(_allInventory);
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
    if (items.isEmpty) {
      throw StateError('Cannot complete a sale with no items.');
    }

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

    for (final line in normalized) {
      final inventoryIndex = _findInventoryIndex(line.product);
      if (inventoryIndex == -1) {
        throw StateError(
            'Product ${line.product.name} is no longer in inventory.');
      }
      final inventoryItem = _allInventory[inventoryIndex];
      if (inventoryItem.stockCount < line.quantity) {
        throw StateError(
          'Only ${inventoryItem.stockCount} unit(s) of ${inventoryItem.name} left in stock.',
        );
      }
    }

    for (final line in normalized) {
      final index = _findInventoryIndex(line.product);
      final item = _allInventory[index];
      final nextStock = item.stockCount - line.quantity;
      _allInventory[index] = InventoryProductItem(
        code: item.code,
        name: item.name,
        category: item.category,
        purchasePrice: item.purchasePrice,
        sellingPrice: item.sellingPrice,
        stockCount: nextStock,
        stockState: _deriveStockState(nextStock),
        artType: item.artType,
        imagePath: item.imagePath,
      );
    }

    _syncProductsFromInventory();

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
      lines: normalized
          .map(
            (line) => OrderLine(
              itemCode: line.product.code,
              itemCategory: line.product.category,
              itemName: line.product.name,
              itemSize: line.product.size,
              quantity: line.quantity,
              unitPrice: line.product.price,
              unitPriceValue: line.product.priceValue,
              artType: line.product.type,
              imagePath: line.product.imagePath,
            ),
          )
          .toList(),
    );

    var customerUpdated = false;
    if (paymentMethod.toLowerCase() == 'credit' &&
        customerName != null &&
        customerName.trim().isNotEmpty) {
      final customerIndex =
          _customers.indexWhere((customer) => customer.name == customerName);
      if (customerIndex != -1) {
        _customers[customerIndex] = _customers[customerIndex].copyWith(
          debitBalance: _customers[customerIndex].debitBalance + total,
        );
        customerUpdated = true;
      }
    }

    _orders.insert(0, order);
    _cartItems.clear();
    _updateCartTotals();
    notifyListeners();

    await _database.replaceInventory(_allInventory);
    await _database.replaceCart(_cartItems);
    await _database.insertOrder(order);
    if (customerUpdated) {
      await _database.replaceCustomers(_customers.map(_customerToMap).toList());
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
        );
      }
    }

    _orders.removeAt(index);
    _syncProductsFromInventory();
    notifyListeners();

    await _database.replaceInventory(_allInventory);
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
    _profile = profile;
    notifyListeners();
    await _database.saveAppProfile(<String, Object?>{
      'store_name': profile.storeName,
      'owner_name': profile.ownerName,
      'role_title': profile.roleTitle,
      'business_category': profile.businessCategory,
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
    });
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

  Future<StaffRoleData> saveStaffRole(StaffRoleData role) async {
    final existingIndex = _staffRoles.indexWhere((item) => item.id == role.id);
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
    );
    return nextStaff;
  }

  Future<StaffMemberData> addStaffMember({
    required String name,
    required String email,
    required String phone,
    required String roleId,
  }) async {
    return saveStaffMember(
      StaffMemberData(
        id: 'staff-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        phone: phone,
        roleId: roleId,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<void> updateStaffMemberRole(String staffId, String roleId) async {
    final index = _staffMembers.indexWhere((staff) => staff.id == staffId);
    if (index == -1) return;
    _staffMembers[index] = _staffMembers[index].copyWith(roleId: roleId);
    notifyListeners();
    await _database.replaceStaffMembers(
      _staffMembers.map(_staffMemberToMap).toList(),
    );
  }

  Future<void> deleteStaffMember(String staffId) async {
    _staffMembers.removeWhere((staff) => staff.id == staffId);
    notifyListeners();
    await _database.replaceStaffMembers(
      _staffMembers.map(_staffMemberToMap).toList(),
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
        jsonDecode(map['permissions_json'] as String) as List<dynamic>;
    return StaffRoleData(
      id: map['id'] as String,
      title: map['title'] as String,
      subtitle: map['subtitle'] as String,
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
    };
  }

  StaffMemberData _staffMemberFromMap(Map<String, Object?> map) {
    return StaffMemberData(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      roleId: map['role_id'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  final List<CustomerData> _customers = <CustomerData>[];
  List<CustomerData> get customers => _customers;

  Future<void> addCustomer(CustomerData customer) async {
    _customers.add(customer);
    notifyListeners();
    await _database.replaceCustomers(_customers.map(_customerToMap).toList());
  }

  CustomerData _customerFromMap(Map<String, Object?> map) {
    return CustomerData(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String,
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
    await _database.replaceCustomers(_customers.map(_customerToMap).toList());
  }

  Future<void> deleteCustomer(String customerId) async {
    _customers.removeWhere((c) => c.id == customerId);
    notifyListeners();
    await _database.replaceCustomers(_customers.map(_customerToMap).toList());
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
