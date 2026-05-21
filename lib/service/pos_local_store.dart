import 'dart:convert';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../ui/models/product_item.dart';
import '../ui/products/inventory_product_item.dart';
import 'pos_local_database.dart';
import 'pos_order_models.dart';

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

  final List<ProductItem> _products = <ProductItem>[];
  final List<ProductItem> _cartItems = <ProductItem>[];
  final List<CompletedOrder> _orders = <CompletedOrder>[];
  final List<InventoryProductItem> _allInventory = <InventoryProductItem>[];
  final List<StaffRoleData> _staffRoles = <StaffRoleData>[];
  final List<StaffMemberData> _staffMembers = <StaffMemberData>[];
  AppProfileData _profile = AppProfileData.empty();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

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
            logoPath: storedProfile['logo_path'] as String?,
          );

    _updateCartTotals();
    _isInitialized = true;
    notifyListeners();
  }

  List<ProductItem> get products => List.unmodifiable(_products);
  List<ProductItem> get cartItems => List.unmodifiable(_cartItems);
  List<CompletedOrder> get orders => List.unmodifiable(_orders);
  List<InventoryProductItem> get inventory => List.unmodifiable(_allInventory);
  List<StaffRoleData> get staffRoles => List.unmodifiable(_staffRoles);
  List<StaffMemberData> get staffMembers => List.unmodifiable(_staffMembers);
  AppProfileData get profile => _profile;

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

  bool removeSingleFromCart(ProductItem product) {
    final index = _cartItems.indexWhere(_sameProduct(product));
    if (index == -1) return false;
    _cartItems.removeAt(index);
    _updateCartTotals();
    notifyListeners();
    unawaited(_database.replaceCart(_cartItems));
    return true;
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

    final total = normalized.fold<double>(
      0,
      (sum, line) => sum + line.totalPrice,
    );
    if (cashTendered < total) {
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
      paymentMethod: 'Cash',
      cashTendered: cashTendered,
      changeDue: cashTendered - total,
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

    _orders.insert(0, order);
    _cartItems.clear();
    _updateCartTotals();
    notifyListeners();

    await _database.replaceInventory(_allInventory);
    await _database.replaceCart(_cartItems);
    await _database.insertOrder(order);
    return order;
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
    return (item) =>
        item.code == product.code &&
        item.name == product.name &&
        item.price == product.price &&
        item.size == product.size;
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
}
