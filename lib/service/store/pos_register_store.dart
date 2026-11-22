part of '../pos_local_store.dart';

/// Register shifts and cash drawer movements for [PosLocalStore].
mixin PosRegisterStore on ChangeNotifier {
  PosLocalDatabase get _database;
  String get _activeStoreId;
  List<RegisterShift> get _registerShifts;
  List<CashMovement> get _cashMovements;
  List<CompletedOrder> get _orders;

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


}
