part of '../pos_local_store.dart';

/// Suppliers, purchase receivings and supplier balances for [PosLocalStore].
mixin PosSupplierStore on ChangeNotifier {
  String get _activeStoreId;
  PosLocalDatabase get _database;
  List<Supplier> get _suppliers;
  List<Receiving> get _receivings;
  List<InventoryProductItem> get _allInventory;
  InventoryStockState _deriveStockState(double stockCount);
  String nextAutoProductCode({
    Iterable<String> extraUsedCodes = const <String>[],
  });
  Future<InventoryProductItem> addProduct(InventoryProductItem product);
  Future<void> updateProduct(InventoryProductItem product);
  PhpApiClient? get cloudApi;
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

  List<Supplier> get suppliers => List.unmodifiable(_suppliers);

  List<Receiving> get receivings => List.unmodifiable(_receivings);

  Supplier? supplierById(int id) {
    for (final supplier in _suppliers) {
      if (supplier.id == id) return supplier;
    }
    return null;
  }

  Future<void> _reloadSuppliers() async {
    final stored = await _database.loadSuppliers(_activeStoreId);
    _suppliers
      ..clear()
      ..addAll(stored.map(
        (row) => Supplier.fromMap(Map<String, dynamic>.from(row)),
      ));

    final storedReceivings = await _database.loadReceivings(_activeStoreId);
    final loaded = <Receiving>[];
    for (final row in storedReceivings) {
      final map = Map<String, dynamic>.from(row);
      final id = map['id'] as int?;
      final lines = id == null
          ? const <ReceivingLine>[]
          : (await _database.loadReceivingLines(_activeStoreId, id))
              .map((line) =>
                  ReceivingLine.fromMap(Map<String, dynamic>.from(line)))
              .toList();
      loaded.add(Receiving.fromMap(map, lines: lines));
    }
    _receivings
      ..clear()
      ..addAll(loaded);
  }

  Future<Supplier> saveSupplier(Supplier supplier) async {
    if (supplier.id == null) {
      final id =
          await _database.insertSupplier(supplier.toMap(), _activeStoreId);
      await _reloadSuppliers();
      notifyListeners();
      return supplier.id == id
          ? supplier
          : _suppliers.firstWhere((item) => item.id == id,
              orElse: () => supplier);
    }
    await _database.updateSupplier(supplier.id!, supplier.toMap());
    await _reloadSuppliers();
    notifyListeners();
    return supplier;
  }

  Future<void> deleteSupplier(int id) async {
    await _database.deleteSupplier(id);
    await _reloadSuppliers();
    notifyListeners();
  }

  /// Records goods received and adds the quantities to matching stock items.
  Future<Receiving> saveReceiving(Receiving receiving) async {
    final id =
        await _database.insertReceiving(receiving.toMap(), _activeStoreId);
    if (receiving.lines.isNotEmpty) {
      await _database.insertReceivingLines(
        [
          for (final line in receiving.lines)
            {
              'receiving_id': id,
              'product_name': line.productName,
              'quantity': line.quantity,
              'unit_cost': line.unitCost,
              'selling_price': line.sellingPrice,
            },
        ],
        _activeStoreId,
      );
    }
    for (final line in receiving.lines) {
      await _applyStockIn(line);
    }
    await _reloadSuppliers();
    notifyListeners();
    unawaited(
      recordAuditEvent(
        module: AuditModule.inventory,
        action: 'receiving.recorded',
        severity: AuditSeverity.info,
        entityType: 'Goods Receiving',
        entityId: '$id',
        entityLabel: receiving.supplierName.isEmpty
            ? 'Invoice ${receiving.invoiceNo}'
            : receiving.supplierName,
        summary:
            'Received ${receiving.lines.length} line(s) from ${receiving.supplierName.isEmpty ? 'supplier' : receiving.supplierName} totaling ${receiving.total.toStringAsFixed(0)} TSh',
        afterValues: {
          'Supplier': receiving.supplierName,
          'Invoice #': receiving.invoiceNo,
          'Total': receiving.total.toStringAsFixed(2),
          'Lines': '${receiving.lines.length}',
        },
      ),
    );
    return receiving.id == id
        ? receiving
        : Receiving(
            id: id,
            supplierId: receiving.supplierId,
            supplierName: receiving.supplierName,
            date: receiving.date,
            invoiceNo: receiving.invoiceNo,
            total: receiving.total,
            receivedBy: receiving.receivedBy,
            notes: receiving.notes,
            lines: receiving.lines,
          );
  }

  Future<void> _applyStockIn(ReceivingLine line) async {
    final name = line.productName.trim().toLowerCase();
    if (name.isEmpty || line.quantity <= 0) return;
    for (final item in _allInventory) {
      if (item.name.trim().toLowerCase() != name) continue;
      // Weighted average cost calculation (OSPOS inventory valuation)
      final existingCount = item.stockCount > 0 ? item.stockCount : 0;
      final existingCost = item.purchasePrice > 0 ? item.purchasePrice : 0.0;
      final newQty = line.quantity;
      final newUnitCost = line.unitCost > 0 ? line.unitCost : existingCost;
      final totalUnits = existingCount + newQty;
      final weightedAvgCost = totalUnits > 0
          ? ((existingCount * existingCost) + (newQty * newUnitCost)) /
              totalUnits
          : newUnitCost;
      final nextStock = roundQuantity(item.stockCount + line.quantity);

      final updated = item.copyWith(
        purchasePrice:
            weightedAvgCost > 0 ? weightedAvgCost : item.purchasePrice,
        stockCount: nextStock,
        stockState: _deriveStockState(nextStock),
        sellingPrice:
            line.sellingPrice > 0 ? line.sellingPrice : item.sellingPrice,
      );
      await updateProduct(updated);
      return;
    }

    // If product doesn't exist in catalog yet, auto-create it (OSPOS quick-add receiving)
    final nextCode = nextAutoProductCode();
    final newItem = InventoryProductItem(
      code: nextCode,
      name: line.productName.trim(),
      category: 'General',
      purchasePrice: line.unitCost > 0 ? line.unitCost : 0.0,
      sellingPrice:
          line.sellingPrice > 0 ? line.sellingPrice : (line.unitCost * 1.25),
      stockCount: line.quantity,
      stockState: InventoryStockState.inStock,
      artType: ProductArtType.aquafina,
    );
    await addProduct(newItem);
  }

  Future<void> deleteReceiving(int id) async {
    Receiving? target;
    for (final r in _receivings) {
      if (r.id == id) {
        target = r;
        break;
      }
    }
    await _database.deleteReceiving(id);
    await _reloadSuppliers();
    notifyListeners();
    unawaited(
      recordAuditEvent(
        module: AuditModule.inventory,
        action: 'receiving.deleted',
        severity: AuditSeverity.critical,
        entityType: 'Goods Receiving',
        entityId: '$id',
        entityLabel: target?.supplierName.isNotEmpty == true
            ? target!.supplierName
            : 'Receiving #$id',
        summary:
            'Deleted goods receiving #$id${target == null ? '' : ' (${target.total.toStringAsFixed(0)} TSh)'}',
      ),
    );
  }

  /// Outstanding payable per supplier from opening balances and receipts.
  double supplierBalance(int supplierId) {
    final supplier = supplierById(supplierId);
    final received = receivings
        .where((receiving) => receiving.supplierId == supplierId)
        .fold<double>(0, (sum, receiving) => sum + receiving.total);
    return (supplier?.openingBalance ?? 0) + received;
  }

  /// Cash collected from orders inside the given window.
}
