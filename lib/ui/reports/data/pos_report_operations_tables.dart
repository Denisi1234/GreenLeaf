part of '../pos_report_data.dart';

extension PosReportOperationsTables on PosReportData {
  ReportTable _suppliersTable() {
    final rows = <List<Object?>>[];
    for (final supplier in suppliers) {
      final purchases = receivings
          .where((entry) => entry.supplierId == supplier.id)
          .fold<double>(0, (sum, entry) => sum + entry.total);
      final receipts =
          receivings.where((entry) => entry.supplierId == supplier.id).length;
      rows.add([
        supplier.name,
        supplier.phone,
        supplier.address,
        receipts,
        purchases,
        supplier.openingBalance + purchases,
      ]);
    }
    return ReportTable(
      const [
        ReportColumn('Supplier'),
        ReportColumn('Phone'),
        ReportColumn('Address'),
        ReportColumn('Deliveries'),
        ReportColumn('Purchases', money: true),
        ReportColumn('Balance payable', money: true),
      ],
      rows,
      chartColumn: 4,
      note: suppliers.isEmpty
          ? 'No suppliers recorded. Add suppliers to track purchases.'
          : null,
    );
  }

  ReportTable _supplierDetailTable(String? selection) {
    final entries = receivings
        .where((entry) => selection == null || entry.supplierName == selection)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final rows = <List<Object?>>[];
    for (final entry in entries) {
      rows.add([
        _day.format(entry.date.toLocal()),
        entry.supplierName,
        entry.invoiceNo,
        entry.itemCount,
        entry.lines.map((line) => line.productName).join(', '),
        entry.total,
        entry.receivedBy,
        entry.notes,
      ]);
    }
    return ReportTable(
      const [
        ReportColumn('Date'),
        ReportColumn('Supplier'),
        ReportColumn('Invoice'),
        ReportColumn('Units'),
        ReportColumn('Items'),
        ReportColumn('Total', money: true),
        ReportColumn('Received by'),
        ReportColumn('Notes'),
      ],
      rows,
      note: suppliers.isEmpty && receivings.isEmpty
          ? 'No supplier deliveries recorded yet.'
          : null,
    );
  }

  ReportTable _receivingsTable(DateTime? start, DateTime? end) {
    final entries = receivings
        .where((entry) => _inRange(entry.date.toLocal(), start, end))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return ReportTable(
      const [
        ReportColumn('Date'),
        ReportColumn('Supplier'),
        ReportColumn('Invoice'),
        ReportColumn('Items'),
        ReportColumn('Units'),
        ReportColumn('Unit cost avg', money: true),
        ReportColumn('Total', money: true),
        ReportColumn('Received by'),
      ],
      [
        for (final entry in entries)
          [
            _day.format(entry.date.toLocal()),
            entry.supplierName,
            entry.invoiceNo,
            entry.lines.length,
            entry.itemCount,
            entry.itemCount == 0 ? 0 : entry.total / entry.itemCount,
            entry.total,
            entry.receivedBy,
          ],
      ],
      note: receivings.isEmpty
          ? 'No goods received yet. Record deliveries to build purchase history.'
          : null,
    );
  }

  ReportTable _cashUpTable(
    List<_Sale> sales,
    DateTime? start,
    DateTime? end,
  ) {
    final rows = <List<Object?>>[];
    for (final shift in _shiftsInRange(start, end)) {
      final summary = cashUpFor?.call(shift) ?? _fallbackCashUp(shift, sales);
      rows.add([
        shift.register,
        _timestamp.format(shift.openedAt.toLocal()),
        summary.openingFloat,
        summary.cashSales,
        summary.cashIn,
        summary.cashOut,
        summary.expected,
        shift.isOpen ? null : summary.counted,
        shift.isOpen ? null : summary.variance,
        shift.status.localized(false),
        shift.openedBy,
      ]);
    }
    return ReportTable(
      const [
        ReportColumn('Register'),
        ReportColumn('Opened'),
        ReportColumn('Opening float', money: true),
        ReportColumn('Cash sales', money: true),
        ReportColumn('Cash in', money: true),
        ReportColumn('Payouts', money: true),
        ReportColumn('Expected cash', money: true),
        ReportColumn('Counted cash', money: true),
        ReportColumn('Variance', money: true),
        ReportColumn('Status'),
        ReportColumn('Opened by'),
      ],
      rows,
      note: shifts.isEmpty
          ? 'No register shifts recorded yet. Open a register to start tracking cash.'
          : null,
    );
  }

  ReportTable _shiftsTable(
    List<_Sale> sales,
    DateTime? start,
    DateTime? end,
  ) {
    final rows = <List<Object?>>[];
    for (final shift in _shiftsInRange(start, end)) {
      final summary = cashUpFor?.call(shift) ?? _fallbackCashUp(shift, sales);
      rows.add([
        shift.register,
        _timestamp.format(shift.openedAt.toLocal()),
        shift.closedAt == null
            ? null
            : _timestamp.format(shift.closedAt!.toLocal()),
        _durationLabel(shift),
        shift.openingFloat,
        summary.cashSales,
        summary.expected,
        shift.isOpen ? null : shift.countedCash,
        shift.openedBy,
        shift.closedBy.isEmpty ? null : shift.closedBy,
        shift.status.localized(false),
        shift.notes.isEmpty ? null : shift.notes,
      ]);
    }
    return ReportTable(
      const [
        ReportColumn('Register'),
        ReportColumn('Opened'),
        ReportColumn('Closed'),
        ReportColumn('Duration'),
        ReportColumn('Opening float', money: true),
        ReportColumn('Cash sales', money: true),
        ReportColumn('Expected cash', money: true),
        ReportColumn('Counted cash', money: true),
        ReportColumn('Opened by'),
        ReportColumn('Closed by'),
        ReportColumn('Status'),
        ReportColumn('Notes'),
      ],
      rows,
      note: shifts.isEmpty
          ? 'No shifts recorded. Register Shifts lists every opening and closing of the drawer.'
          : null,
    );
  }

  List<RegisterShift> _shiftsInRange(DateTime? start, DateTime? end) {
    final dayStart =
        start == null ? null : DateTime(start.year, start.month, start.day);
    final dayEnd = end == null
        ? null
        : DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    final result = shifts
        .where((shift) =>
            (dayStart == null || !shift.openedAt.isBefore(dayStart)) &&
            (dayEnd == null || !shift.openedAt.isAfter(dayEnd)))
        .toList()
      ..sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return result;
  }

  CashUpSummary _fallbackCashUp(RegisterShift shift, List<_Sale> sales) {
    final cashSales = sales
        .where((sale) =>
            sale.order.paymentMethod.toLowerCase().contains('cash') &&
            !sale.date.isBefore(shift.openedAt) &&
            !sale.date.isAfter(shift.endsAt))
        .fold<double>(0, (sum, sale) => sum + sale.order.total);
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
