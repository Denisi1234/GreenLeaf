part of '../pos_report_data.dart';

extension PosReportMultiStoreTables on PosReportData {
  ReportTable _multiStoreSales(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final sales = _snapshotSales(snap, start, end);
      final total = _sum(sales, (s) => s.order.total);
      final cost = _cost(sales.expand((s) => s.order.lines));
      rows.add([snap.label, sales.length, roundQuantity(sales.fold<double>(0, (sum, s) => sum + s.quantity)), total, cost, cost == null ? null : total - cost]);
    }
    rows.sort((a, b) => (b[3] as num).compareTo(a[3] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Sales'), ReportColumn('Units'), ReportColumn('Net sales', money: true), ReportColumn('Cost', money: true), ReportColumn('Gross profit', money: true)], rows, chartColumn: 3, note: '$_multiStoreNote $_historicCostNote');
  }

  ReportTable _multiStoreProfit(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final sales = _snapshotSales(snap, start, end);
      final spending = _snapshotExpenses(snap, start, end);
      final revenue = _sum(sales, (s) => s.order.total);
      final cost = _cost(sales.expand((s) => s.order.lines));
      final expenseTotal = _sum(spending, (e) => e.amount);
      final gross = cost == null ? null : revenue - cost;
      final operating = gross == null ? null : gross - expenseTotal;
      rows.add([snap.label, revenue, cost, gross, expenseTotal, operating]);
    }
    rows.sort((a, b) => ((b[5] ?? -999999999) as num).compareTo((a[5] ?? -999999999) as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Net sales', money: true), ReportColumn('Cost of goods', money: true), ReportColumn('Gross profit', money: true), ReportColumn('Expenses', money: true), ReportColumn('Operating result', money: true)], rows, chartColumn: 5, note: '$_multiStoreNote $_historicCostNote');
  }

  ReportTable _multiStoreExpenses(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final spending = _snapshotExpenses(snap, start, end);
      rows.add([snap.label, spending.length, _sum(spending, (e) => e.amount)]);
    }
    rows.sort((a, b) => (b[2] as num).compareTo(a[2] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Entries'), ReportColumn('Total expenses', money: true)], rows, chartColumn: 2, note: _multiStoreNote);
  }

  ReportTable _multiStoreInventoryValue(List<StoreSnapshot> snaps) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final items = snap.inventory.cast<InventoryProductItem>();
      final units = roundQuantity(
          items.fold<double>(0, (sum, i) => sum + i.stockCount));
      final costValue = _sum(items, (i) => i.purchasePrice * i.stockCount);
      final retailValue = _sum(items, (i) => i.sellingPrice * i.stockCount);
      rows.add([snap.label, items.length, units, costValue, retailValue]);
    }
    rows.sort((a, b) => (b[3] as num).compareTo(a[3] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Products'), ReportColumn('Units'), ReportColumn('Cost value', money: true), ReportColumn('Retail value', money: true)], rows, chartColumn: 3, note: 'Current inventory snapshot across all stores.');
  }

  ReportTable _multiStoreLowStock(List<StoreSnapshot> snaps) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final items = snap.inventory.cast<InventoryProductItem>();
      final low = items.where((i) => i.stockState != InventoryStockState.inStock).toList();
      final out = items.where((i) => i.stockCount <= 0).length;
      rows.add([snap.label, low.length, out, low.length - out]);
    }
    rows.sort((a, b) => (b[1] as num).compareTo(a[1] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Low/out items'), ReportColumn('Out of stock'), ReportColumn('Low (not out)')], rows, chartColumn: 1, note: 'Current stock status across all stores.');
  }

  ReportTable _multiStoreOutOfStock(List<StoreSnapshot> snaps) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      for (final item in snap.inventory.cast<InventoryProductItem>().where((i) => i.stockCount <= 0)) {
        rows.add([snap.label, item.code, item.name, item.category, item.stockCount]);
      }
    }
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Code'), ReportColumn('Product'), ReportColumn('Category'), ReportColumn('In stock')], rows, note: 'Products currently out of stock across all stores.');
  }

  ReportTable _multiStoreCustomers(List<StoreSnapshot> snaps) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final customers = snap.customers.cast<CustomerData>();
      final withCredit = customers.where((c) => c.debitBalance > 0).toList();
      final creditTotal = _sum(withCredit, (c) => c.debitBalance);
      rows.add([snap.label, customers.length, withCredit.length, creditTotal]);
    }
    rows.sort((a, b) => (b[1] as num).compareTo(a[1] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Customers'), ReportColumn('With outstanding credit'), ReportColumn('Credit balance', money: true)], rows, chartColumn: 1, note: 'Customer base and credit exposure across all stores.');
  }

  ReportTable _multiStoreNewCustomers(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final newCount = snap.customers.cast<CustomerData>().where((c) => _inRange(c.createdAt.toLocal(), start, end)).length;
      rows.add([snap.label, newCount, snap.customers.length]);
    }
    rows.sort((a, b) => (b[1] as num).compareTo(a[1] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('New customers'), ReportColumn('Total customers')], rows, chartColumn: 1, note: _multiStoreNote);
  }

  ReportTable _multiStoreCredit(List<StoreSnapshot> snaps) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      for (final c in snap.customers.cast<CustomerData>().where((c) => c.debitBalance > 0)) {
        rows.add([snap.label, c.name, c.phone, c.debitBalance]);
      }
    }
    rows.sort((a, b) => (b[3] as num).compareTo(a[3] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Customer'), ReportColumn('Phone'), ReportColumn('Credit balance', money: true)], rows, chartColumn: 3, note: 'Outstanding customer credit across all stores.');
  }

  ReportTable _multiStoreSuppliers(List<StoreSnapshot> snaps) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final suppliers = snap.suppliers.cast<Supplier>();
      final receivings = snap.receivings.cast<Receiving>();
      final purchaseTotal = _sum(receivings, (r) => r.total);
      final payable = suppliers.fold<double>(0, (sum, s) => sum + s.openingBalance) + purchaseTotal;
      rows.add([snap.label, suppliers.length, receivings.length, purchaseTotal, payable]);
    }
    rows.sort((a, b) => (b[3] as num).compareTo(a[3] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Suppliers'), ReportColumn('Deliveries'), ReportColumn('Purchases', money: true), ReportColumn('Total payable', money: true)], rows, chartColumn: 3, note: 'Supplier and purchase totals across all stores.');
  }

  ReportTable _multiStoreReceivings(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final recs = _snapshotReceivings(snap, start, end);
      final units =
          roundQuantity(recs.fold<double>(0, (sum, r) => sum + r.itemCount));
      rows.add([snap.label, recs.length, units, _sum(recs, (r) => r.total)]);
    }
    rows.sort((a, b) => (b[3] as num).compareTo(a[3] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Deliveries'), ReportColumn('Units received'), ReportColumn('Total value', money: true)], rows, chartColumn: 3, note: _multiStoreNote);
  }

  ReportTable _multiStoreTax(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final sales = _snapshotSales(snap, start, end);
      final gross = _sum(sales, (s) => s.order.total);
      final tax = snap.tax as TaxSettings;
      final collected = _sum(sales, (s) => tax.taxFromGross(s.order.total));
      rows.add([snap.label, sales.length, gross, collected, gross - collected]);
    }
    rows.sort((a, b) => (b[3] as num).compareTo(a[3] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Orders'), ReportColumn('Gross sales', money: true), ReportColumn('Tax collected', money: true), ReportColumn('Net sales', money: true)], rows, chartColumn: 3, note: _multiStoreNote);
  }

  ReportTable _multiStoreCashFlow(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final sales = _snapshotSales(snap, start, end);
      final spending = _snapshotExpenses(snap, start, end);
      final shifts = _snapshotShifts(snap, start, end);
      final cashSales = sales.where((s) => s.order.paymentMethod.toLowerCase().contains('cash')).fold<double>(0, (sum, s) => sum + s.order.total);
      final cashExpenses = spending.where((e) => e.paymentMethod.toLowerCase().contains('cash')).fold<double>(0, (sum, e) => sum + e.amount);
      final cashIn = shifts.expand((s) => s.movements).where((m) => !m.type.isOutflow).fold<double>(0, (sum, m) => sum + m.amount);
      final payouts = shifts.expand((s) => s.movements).where((m) => m.type.isOutflow).fold<double>(0, (sum, m) => sum + m.amount);
      rows.add([snap.label, cashSales, cashExpenses, cashIn, payouts, cashSales - cashExpenses + cashIn - payouts]);
    }
    rows.sort((a, b) => (b[5] as num).compareTo(a[5] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Cash sales', money: true), ReportColumn('Cash expenses', money: true), ReportColumn('Cash in', money: true), ReportColumn('Payouts', money: true), ReportColumn('Net cash movement', money: true)], rows, chartColumn: 5, note: '$_multiStoreNote Cash basis per store.');
  }

  ReportTable _multiStoreBank(List<StoreSnapshot> snaps) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final tx = snap.bankTransactions.cast<BankTransaction>();
      final matched = tx.where((t) => t.matched).toList();
      final unmatched = tx.where((t) => !t.matched).toList();
      rows.add([snap.label, tx.length, matched.length, unmatched.length, _sum(matched, (t) => t.amount), _sum(unmatched, (t) => t.amount)]);
    }
    rows.sort((a, b) => (b[3] as num).compareTo(a[3] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Statement lines'), ReportColumn('Matched'), ReportColumn('Unmatched'), ReportColumn('Matched amount', money: true), ReportColumn('Unmatched amount', money: true)], rows, chartColumn: 3, note: 'Bank/mobile money reconciliation position across all stores.');
  }

  ReportTable _multiStoreAssets(List<StoreSnapshot> snaps) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final assets = snap.fixedAssets.cast<FixedAsset>();
      final cost = _sum(assets, (a) => a.cost);
      final dep = _sum(assets, (a) => a.accumulatedDepreciation());
      final nbv = _sum(assets, (a) => a.netBookValue());
      rows.add([snap.label, assets.length, cost, dep, nbv]);
    }
    rows.sort((a, b) => (b[4] as num).compareTo(a[4] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Assets'), ReportColumn('Total cost', money: true), ReportColumn('Depreciation', money: true), ReportColumn('Net book value', money: true)], rows, chartColumn: 4, note: 'Fixed assets across all stores.');
  }

  ReportTable _multiStoreStaff(List<StoreSnapshot> snaps) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final shifts = snap.shifts.cast<RegisterShift>();
      final open = shifts.where((s) => s.isOpen).length;
      rows.add([snap.label, shifts.length, open, shifts.length - open]);
    }
    rows.sort((a, b) => (b[1] as num).compareTo(a[1] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Total shifts'), ReportColumn('Open shifts'), ReportColumn('Closed shifts')], rows, chartColumn: 1, note: 'Register/shift activity across all stores.');
  }

  ReportTable _multiStorePayments(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final byStoreMethod = <String, Map<String, double>>{};
    final methods = <String>{};
    for (final snap in snaps) {
      final sales = _snapshotSales(snap, start, end);
      final map = <String, double>{};
      for (final sale in sales) {
        final method = _label(sale.order.paymentMethod, 'Unrecorded');
        methods.add(method);
        map[method] = (map[method] ?? 0) + sale.order.total;
      }
      byStoreMethod[snap.label] = map;
    }
    final methodList = methods.toList()..sort();
    final rows = <List<Object?>>[
      for (final snap in snaps)
        [snap.label, for (final m in methodList) byStoreMethod[snap.label]?[m] ?? 0.0, _snapshotSales(snap, start, end).fold<double>(0, (s, sale) => s + sale.order.total)],
    ];
    rows.sort((a, b) => (b.last as num).compareTo(a.last as num));
    return ReportTable([const ReportColumn('Store'), for (final m in methodList) ReportColumn(m, money: true), const ReportColumn('Total', money: true)], rows, chartColumn: methodList.isEmpty ? 0 : 1, note: _multiStoreNote);
  }

  ReportTable _multiStoreDiscounts(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final discounted = _snapshotSales(snap, start, end).where((s) => s.discount > 0).toList();
      rows.add([snap.label, discounted.length, _sum(discounted, (s) => s.discount), _sum(discounted, (s) => s.order.total)]);
    }
    rows.sort((a, b) => (b[2] as num).compareTo(a[2] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Discounted sales'), ReportColumn('Total discount', money: true), ReportColumn('Net sales (discounted)', money: true)], rows, chartColumn: 2, note: _multiStoreNote);
  }

  ReportTable _multiStoreCategories(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final sales = _snapshotSales(snap, start, end);
      final byCat = <String, double>{};
      for (final line in _soldLines(sales)) {
        byCat[line.category] = (byCat[line.category] ?? 0) + line.net;
      }
      if (byCat.isEmpty) {
        rows.add([snap.label, 'â€”', 0.0, 0.0]);
      } else {
        final top = byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        rows.add([snap.label, top.first.key, top.first.value, _sum(sales, (s) => s.order.total)]);
      }
    }
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Top category'), ReportColumn('Top category sales', money: true), ReportColumn('Total net sales', money: true)], rows, chartColumn: 2, note: _multiStoreNote);
  }

  ReportTable _multiStoreItems(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final sales = _snapshotSales(snap, start, end);
      final byItem = <String, _ItemAgg>{};
      for (final line in _soldLines(sales)) {
        final agg = byItem.putIfAbsent(line.product, () => _ItemAgg(line.line.itemName));
        agg.units += line.line.quantity;
        agg.net += line.net;
      }
      if (byItem.isEmpty) {
        rows.add([snap.label, 'â€”', 0, 0.0]);
      } else {
        final top = byItem.values.toList()..sort((a, b) => b.net.compareTo(a.net));
        rows.add([snap.label, top.first.name, top.first.units, top.first.net]);
      }
    }
    rows.sort((a, b) => (b[3] as num).compareTo(a[3] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Top item'), ReportColumn('Units'), ReportColumn('Net sales', money: true)], rows, chartColumn: 3, note: _multiStoreNote);
  }

  ReportTable _multiStoreRegister(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final shifts = _snapshotShifts(snap, start, end);
      final sales = _snapshotSales(snap, start, end);
      double expectedTotal = 0;
      double countedTotal = 0;
      double varianceTotal = 0;
      for (final shift in shifts) {
        final cashSales = sales.where((sale) => sale.order.paymentMethod.toLowerCase().contains('cash') && !sale.date.isBefore(shift.openedAt) && !sale.date.isAfter(shift.endsAt)).fold<double>(0, (sum, sale) => sum + sale.order.total);
        final cashIn = shift.movements.where((m) => !m.type.isOutflow).fold<double>(0, (sum, m) => sum + m.amount);
        final cashOut = shift.movements.where((m) => m.type.isOutflow).fold<double>(0, (sum, m) => sum + m.amount);
        final expected = shift.openingFloat + cashSales + cashIn - cashOut;
        final counted = shift.isOpen ? 0.0 : shift.countedCash.toDouble();
        expectedTotal += expected;
        if (!shift.isOpen) {
          countedTotal += counted;
          varianceTotal += counted - expected;
        }
      }
      rows.add([snap.label, shifts.length, shifts.where((s) => s.isOpen).length, expectedTotal, countedTotal, varianceTotal]);
    }
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Shifts'), ReportColumn('Open'), ReportColumn('Expected cash', money: true), ReportColumn('Counted cash', money: true), ReportColumn('Variance', money: true)], rows, chartColumn: 5, note: _multiStoreNote);
  }

  ReportTable _multiStoreComparison(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final sales = _snapshotSales(snap, start, end);
      final spending = _snapshotExpenses(snap, start, end);
      final inventory = snap.inventory.cast<InventoryProductItem>();
      final customers = snap.customers.cast<CustomerData>();
      final revenue = _sum(sales, (s) => s.order.total);
      final expenseTotal = _sum(spending, (e) => e.amount);
      final stockValue = _sum(inventory, (i) => i.purchasePrice * i.stockCount);
      final credit = _sum(customers.where((c) => c.debitBalance > 0), (c) => c.debitBalance);
      rows.add([snap.label, sales.length, revenue, expenseTotal, revenue - expenseTotal, stockValue, customers.length, credit]);
    }
    rows.sort((a, b) => (b[2] as num).compareTo(a[2] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Sales count'), ReportColumn('Net sales', money: true), ReportColumn('Expenses', money: true), ReportColumn('Net (sales-exp)', money: true), ReportColumn('Stock value', money: true), ReportColumn('Customers'), ReportColumn('Credit outstanding', money: true)], rows, chartColumn: 2, note: _multiStoreNote);
  }

  ReportTable _multiStorePerformance(List<StoreSnapshot> snaps, DateTime? start, DateTime? end) {
    final rows = <List<Object?>>[];
    for (final snap in snaps) {
      final sales = _snapshotSales(snap, start, end);
      final spending = _snapshotExpenses(snap, start, end);
      final revenue = _sum(sales, (s) => s.order.total);
      final cost = _cost(sales.expand((s) => s.order.lines));
      final gross = cost == null ? 0.0 : revenue - cost;
      final margin = revenue <= 0 ? 0.0 : (gross / revenue) * 100;
      final avgBasket = sales.isEmpty ? 0.0 : revenue / sales.length;
      final expenseRatio = revenue <= 0 ? 0.0 : (_sum(spending, (e) => e.amount) / revenue) * 100;
      rows.add([snap.label, sales.length, revenue, avgBasket, margin, expenseRatio, gross - _sum(spending, (e) => e.amount)]);
    }
    rows.sort((a, b) => (b[6] as num).compareTo(a[6] as num));
    return ReportTable(const [ReportColumn('Store'), ReportColumn('Sales'), ReportColumn('Revenue', money: true), ReportColumn('Avg basket', money: true), ReportColumn('Gross margin %'), ReportColumn('Expense/revenue %'), ReportColumn('Operating result', money: true)], rows, chartColumn: 6, note: '$_multiStoreNote Margin/ratios based on available cost data.');
  }
}
