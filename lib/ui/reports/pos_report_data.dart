import 'package:intl/intl.dart';

import '../../service/expense_model.dart';
import '../../service/pos_order_models.dart';
import '../../service/register_shift_model.dart';
import '../../service/supplier_model.dart';
import '../../service/accounting_engine.dart';
import '../../service/accounting_model.dart';
import '../../service/tax_settings.dart';
import '../models/customer_data.dart';
import '../products/inventory_product_item.dart';
import 'pos_report_catalog.dart';

export '../products/inventory_product_item.dart';

class ReportColumn {
  const ReportColumn(this.label, {this.money = false});
  final String label;
  final bool money;
}

class ReportTable {
  const ReportTable(this.columns, this.rows, {this.chartColumn, this.note});

  final List<ReportColumn> columns;
  final List<List<Object?>> rows;
  final int? chartColumn;
  final String? note;
}

class PosReportData {
  PosReportData({
    required this.orders,
    required this.inventory,
    required this.expenses,
    required this.customers,
    this.storeName = '',
    this.shifts = const <RegisterShift>[],
    this.suppliers = const <Supplier>[],
    this.receivings = const <Receiving>[],
    this.tax = const TaxSettings(),
    this.trialBalanceRows = const <TrialBalanceRow>[],
    this.fixedAssets = const <FixedAsset>[],
    this.bankTransactions = const <BankTransaction>[],
    this.cashUpFor,
  });

  final List<CompletedOrder> orders;
  final List<InventoryProductItem> inventory;
  final List<Expense> expenses;
  final List<CustomerData> customers;
  final String storeName;
  final List<RegisterShift> shifts;
  final List<Supplier> suppliers;
  final List<Receiving> receivings;
  final TaxSettings tax;
  final List<TrialBalanceRow> trialBalanceRows;
  final List<FixedAsset> fixedAssets;
  final List<BankTransaction> bankTransactions;

  /// Resolves the reconciled cash position of a shift.
  final CashUpSummary Function(RegisterShift shift)? cashUpFor;

  List<String> filterOptions(
    ReportData report,
    DateTime? start,
    DateTime? end,
  ) {
    if (report != ReportData.customerDetail &&
        report != ReportData.employeeDetail &&
        report != ReportData.discountDetail &&
        report != ReportData.supplierDetail) {
      return const [];
    }
    final sales = _salesInRange(orders, start, end);
    final values = switch (report) {
      ReportData.customerDetail => sales.map((sale) => sale.customer),
      ReportData.employeeDetail => sales.map((sale) => sale.order.cashierName),
      ReportData.supplierDetail =>
        receivings.map((entry) => entry.supplierName),
      ReportData.discountDetail => sales
          .where((sale) => sale.discount > 0)
          .map((sale) => sale.discountLabel),
      _ => const <String>[],
    };
    return values.toSet().toList()..sort();
  }

  ReportTable build(
    ReportData report, {
    DateTime? start,
    DateTime? end,
    String? selection,
  }) {
    final sales = _salesInRange(orders, start, end);
    final spending = expenses
        .where((expense) => _inRange(expense.date.toLocal(), start, end))
        .toList();
    final discounted = sales.where((sale) => sale.discount > 0);
    return switch (report) {
      ReportData.sales => _salesSummary(
          sales,
          'Date',
          (sale) => _day.format(sale.date),
        ),
      ReportData.categories => _itemSummary(sales, byCategory: true),
      ReportData.expenses => _expenseSummary(
          spending,
          'Category',
          (expense) => expense.category,
        ),
      ReportData.customers => _salesSummary(
          sales,
          'Customer',
          (sale) => sale.customer,
          note:
              'Older sales without a saved customer appear as Unrecorded customer.',
        ),
      ReportData.items => _itemSummary(sales),
      ReportData.employees => _salesSummary(
          sales,
          'Cashier',
          (sale) => sale.order.cashierName,
        ),
      ReportData.discounts => _discounts(discounted),
      ReportData.payments => _payments(sales),
      ReportData.location => ReportTable(
          _salesColumns('Store'),
          [_salesRow(_label(storeName, 'Default Store'), sales)],
          note: _historicCostNote,
        ),
      ReportData.salesDetail => _saleRows(sales),
      ReportData.itemDetail => _itemRows(sales),
      ReportData.customerDetail => _saleRows(
          sales
              .where((sale) => selection == null || sale.customer == selection),
        ),
      ReportData.employeeDetail => _saleRows(
          sales.where(
            (sale) => selection == null || sale.order.cashierName == selection,
          ),
        ),
      ReportData.discountDetail => _saleRows(
          discounted.where(
            (sale) => selection == null || sale.discountLabel == selection,
          ),
          showDiscountLabel: true,
        ),
      ReportData.inventory => _inventoryRows(inventory),
      ReportData.lowInventory => _inventoryRows(
          inventory.where(
            (item) => item.stockState != InventoryStockState.inStock,
          ),
        ),
      ReportData.profitLoss => _profitLoss(sales, spending),
      ReportData.hourly => _salesSummary(
          sales,
          'Hour',
          (sale) => _hour.format(sale.date),
        ),
      ReportData.weekdays => _salesSummary(
          sales,
          'Day',
          (sale) => _weekday.format(sale.date),
        ),
      ReportData.monthly => _salesSummary(
          sales,
          'Month',
          (sale) => _month.format(sale.date),
        ),
      ReportData.registers => _salesSummary(
          sales,
          'Register',
          (sale) => sale.order.register,
        ),
      ReportData.balances => ReportTable(
          const [
            ReportColumn('Customer'),
            ReportColumn('Phone'),
            ReportColumn('Credit balance', money: true),
          ],
          [
            for (final customer in customers.where(
              (customer) => customer.debitBalance > 0,
            ))
              [customer.name, customer.phone, customer.debitBalance],
          ],
        ),
      ReportData.expenseDetail => ReportTable(
          const [
            ReportColumn('Date'),
            ReportColumn('Expense'),
            ReportColumn('Category'),
            ReportColumn('Payment method'),
            ReportColumn('Amount', money: true),
            ReportColumn('Notes'),
          ],
          [
            for (final expense in spending)
              [
                _day.format(expense.date.toLocal()),
                expense.title,
                expense.category,
                expense.paymentMethod,
                expense.amount,
                expense.notes,
              ],
          ],
        ),
      ReportData.expensePayments => _expenseSummary(
          spending,
          'Payment method',
          (expense) => expense.paymentMethod,
        ),
      ReportData.stockByCategory => _stockSummary(inventory, byCategory: true),
      ReportData.stockValue => _stockSummary(inventory),
      ReportData.outOfStock => _inventoryRows(
          inventory.where((item) => item.stockCount <= 0),
        ),
      ReportData.averageBasket => _averageBasket(sales),
      ReportData.creditSales => _saleRows(sales.where((sale) => sale.isCredit)),
      ReportData.discountedItems => _itemRows(discounted),
      ReportData.newCustomers => _newCustomerReport(customers, start, end),
      ReportData.cashUp => _cashUpTable(sales, start, end),
      ReportData.shifts => _shiftsTable(sales, start, end),
      ReportData.suppliers => _suppliersTable(),
      ReportData.supplierDetail => _supplierDetailTable(selection),
      ReportData.receivings => _receivingsTable(start, end),
      ReportData.taxes => _taxTable(sales, byMethod: false),
      ReportData.salesTaxes => _taxTable(sales, byMethod: true),
      ReportData.taxCompliance => _taxComplianceTable(sales, spending),
      ReportData.trialBalance => _trialBalanceTable(),
      ReportData.balanceSheet => _balanceSheetTable(),
      ReportData.cashFlow => _cashFlowTable(sales, spending),
      ReportData.assets => _assetsTable(),
      ReportData.bank => _bankTable(),
      ReportData.reconciliation => _reconciliationTable(),
      _ => throw ArgumentError.value(
          report,
          'report',
          'Required records are unavailable',
        ),
    };
  }

  ReportTable _trialBalanceTable() {
    final rows = trialBalanceRows;
    return ReportTable(
      const [
        ReportColumn('Account'),
        ReportColumn('Name'),
        ReportColumn('Type'),
        ReportColumn('Debit', money: true),
        ReportColumn('Credit', money: true),
      ],
      [
        for (final row in rows)
          [
            row.code,
            row.name,
            row.type.label,
            row.debit == 0 ? null : row.debit,
            row.credit == 0 ? null : row.credit,
          ],
      ],
      note: rows.isEmpty
          ? 'No ledger activity yet. Sales, expenses, purchases and journal entries populate this report.'
          : null,
    );
  }

  ReportTable _balanceSheetTable() {
    double totalFor(AccountType type) => trialBalanceRows
        .where((row) => row.type == type)
        .fold<double>(0, (sum, row) => sum + row.debit - row.credit);
    final assets = totalFor(AccountType.asset);
    final liabilities = -totalFor(AccountType.liability);
    final equity = -totalFor(AccountType.equity);
    final income = -totalFor(AccountType.income);
    final expense = totalFor(AccountType.expense);
    final retained = income - expense;
    final rows = <List<Object?>>[
      for (final row
          in trialBalanceRows.where((r) => r.type == AccountType.asset))
        ['Assets', row.name, row.debit - row.credit],
      for (final row
          in trialBalanceRows.where((r) => r.type == AccountType.liability))
        ['Liabilities', row.name, row.credit - row.debit],
      for (final row
          in trialBalanceRows.where((r) => r.type == AccountType.equity))
        ['Equity', row.name, row.credit - row.debit],
      ['Equity', 'Retained earnings', retained],
      ['Check', 'Total assets', assets],
      ['Check', 'Liabilities and equity', liabilities + equity + retained],
    ];
    return ReportTable(
      const [
        ReportColumn('Section'),
        ReportColumn('Account'),
        ReportColumn('Amount', money: true),
      ],
      rows,
      note: trialBalanceRows.isEmpty
          ? 'No ledger balances yet. Record sales and expenses to build the balance sheet.'
          : 'Derived from sales, expenses, purchases, payments and manual journal entries.',
    );
  }

  ReportTable _cashFlowTable(List<_Sale> sales, List<Expense> spending) {
    final cashSales = sales
        .where(
            (sale) => sale.order.paymentMethod.toLowerCase().contains('cash'))
        .fold<double>(0, (sum, sale) => sum + sale.order.total);
    final cashExpenses = spending
        .where(
            (expense) => expense.paymentMethod.toLowerCase().contains('cash'))
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final payouts = shifts
        .expand((shift) => shift.movements)
        .where((movement) => movement.type.isOutflow)
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final cashIn = shifts
        .expand((shift) => shift.movements)
        .where((movement) => !movement.type.isOutflow)
        .fold<double>(0, (sum, movement) => sum + movement.amount);
    final operating = cashSales - cashExpenses;
    final financing = cashIn - payouts;
    final assetPurchases =
        fixedAssets.fold<double>(0, (sum, asset) => sum + asset.cost);
    final net = operating + financing - assetPurchases;
    return ReportTable(
      const [
        ReportColumn('Activity'),
        ReportColumn('Category'),
        ReportColumn('Amount', money: true),
      ],
      [
        ['Cash sales', 'Operating', cashSales],
        ['Cash expenses', 'Operating', -cashExpenses],
        ['Cash from drawer top-ups', 'Financing', cashIn],
        ['Drawings and payouts', 'Financing', -payouts],
        ['Fixed asset purchases', 'Investing', -assetPurchases],
        ['Net cash movement', 'Total', net],
      ],
      note:
          'Cash basis: card, mobile money and credit sales settle through the bank or receivables.',
    );
  }

  ReportTable _assetsTable() {
    final rows = <List<Object?>>[
      for (final asset in fixedAssets)
        [
          asset.name,
          asset.category,
          _day.format(asset.purchaseDate.toLocal()),
          asset.cost,
          asset.salvageValue,
          asset.usefulLifeYears,
          asset.annualDepreciation,
          asset.accumulatedDepreciation(),
          asset.netBookValue(),
        ],
    ];
    return ReportTable(
      const [
        ReportColumn('Asset'),
        ReportColumn('Category'),
        ReportColumn('Purchased'),
        ReportColumn('Cost', money: true),
        ReportColumn('Salvage', money: true),
        ReportColumn('Life (years)'),
        ReportColumn('Annual depreciation', money: true),
        ReportColumn('Accumulated', money: true),
        ReportColumn('Net book value', money: true),
      ],
      rows,
      note: fixedAssets.isEmpty
          ? 'No fixed assets recorded. Add assets to track depreciation.'
          : 'Straight line depreciation, calculated to date.',
    );
  }

  ReportTable _bankTable() {
    return ReportTable(
      const [
        ReportColumn('Date'),
        ReportColumn('Description'),
        ReportColumn('Reference'),
        ReportColumn('Amount', money: true),
        ReportColumn('Status'),
      ],
      [
        for (final entry in bankTransactions)
          [
            _day.format(entry.date.toLocal()),
            entry.description,
            entry.reference,
            entry.amount,
            entry.matched ? 'Matched' : 'Unmatched',
          ],
      ],
      note: bankTransactions.isEmpty
          ? 'No statement lines imported. Add or paste statement lines to reconcile bank and mobile money.'
          : null,
    );
  }

  ReportTable _reconciliationTable() {
    final matched = bankTransactions.where((entry) => entry.matched);
    final unmatched = bankTransactions.where((entry) => !entry.matched);
    final matchedTotal =
        matched.fold<double>(0, (sum, entry) => sum + entry.amount);
    final unmatchedTotal =
        unmatched.fold<double>(0, (sum, entry) => sum + entry.amount);
    return ReportTable(
      const [
        ReportColumn('Item'),
        ReportColumn('Count'),
        ReportColumn('Amount', money: true),
      ],
      [
        ['Matched statement lines', matched.length, matchedTotal],
        ['Unmatched statement lines', unmatched.length, unmatchedTotal],
        [
          'Difference',
          matched.length + unmatched.length,
          matchedTotal + unmatchedTotal
        ],
      ],
      note: bankTransactions.isEmpty
          ? 'No bank statement lines yet. Import or add statement lines to reconcile.'
          : null,
    );
  }

  ReportTable _taxTable(List<_Sale> sales, {required bool byMethod}) {
    final grouped = <String, _TaxBucket>{};
    for (final sale in sales) {
      final gross = sale.order.total;
      final label = byMethod
          ? _paymentLabel(sale.order.paymentMethod)
          : _day.format(sale.date);
      final bucket = grouped.putIfAbsent(label, () => _TaxBucket());
      bucket.gross += gross;
      bucket.tax += tax.taxFromGross(gross);
      bucket.count += 1;
    }
    final rows = <List<Object?>>[
      for (final entry in grouped.entries)
        [
          entry.key,
          entry.value.count,
          entry.value.gross,
          entry.value.tax,
          entry.value.gross - entry.value.tax,
        ],
    ]..sort((a, b) => (b[2] as double).compareTo(a[2] as double));
    return ReportTable(
      [
        ReportColumn(byMethod ? 'Payment method' : 'Date'),
        const ReportColumn('Orders'),
        const ReportColumn('Gross sales', money: true),
        ReportColumn('${tax.taxLabel.isEmpty ? 'Tax' : tax.taxLabel} collected',
            money: true),
        const ReportColumn('Net sales', money: true),
      ],
      rows,
      note: tax.enabled
          ? 'Tax calculated at ${tax.ratePercent.toStringAsFixed(1)}% '
              '${tax.pricesIncludeTax ? 'included in' : 'added to'} prices.'
          : 'Tax is disabled. Enable it in Settings → Tax settings to populate tax figures.',
    );
  }

  ReportTable _taxComplianceTable(
    List<_Sale> sales,
    List<Expense> expenses,
  ) {
    final grossSales =
        sales.fold<double>(0, (sum, sale) => sum + sale.order.total);
    final outputTax = sales.fold<double>(
        0, (sum, sale) => sum + tax.taxFromGross(sale.order.total));
    final expenseTax = tax.trackExpenseTax
        ? expenses.fold<double>(0, (sum, expense) => sum + expense.taxAmount)
        : 0.0;
    final rows = <List<Object?>>[
      ['Gross sales', grossSales],
      ['Taxable sales', grossSales],
      ['${tax.taxLabel.isEmpty ? 'Tax' : tax.taxLabel} collected', outputTax],
      ['Tax paid on expenses', expenseTax],
      ['Net tax payable', outputTax - expenseTax],
      ['Tax rate (%)', tax.ratePercent],
    ];
    return ReportTable(
      const [
        ReportColumn('Item'),
        ReportColumn('Amount', money: true),
      ],
      rows,
      note: tax.enabled
          ? 'Tax identification number: ${tax.taxId.isEmpty ? 'not set' : tax.taxId}.'
          : 'Tax is disabled. Turn it on in Settings → Tax settings.',
    );
  }

  static String _paymentLabel(String method) {
    final value = method.trim().toLowerCase();
    if (value.contains('cash')) return 'Cash';
    if (value.contains('card')) return 'Card';
    if (value.contains('mobile') ||
        value.contains('mpesa') ||
        value.contains('tigopesa') ||
        value.contains('mixx')) {
      return 'Mobile money';
    }
    if (value.contains('debt') ||
        value.contains('credit') ||
        value.contains('kopesh')) {
      return 'Issued on credit';
    }
    if (value.isEmpty) return 'Unknown';
    return value[0].toUpperCase() + value.substring(1);
  }

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

  static String _durationLabel(RegisterShift shift) {
    final minutes =
        shift.endsAt.difference(shift.openedAt).inMinutes.clamp(0, 1440 * 60);
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return hours > 0 ? '${hours}h ${rest}m' : '${rest}m';
  }
}

final _day = DateFormat('yyyy-MM-dd', 'en_US');
final _timestamp = DateFormat('yyyy-MM-dd HH:mm', 'en_US');
final _hour = DateFormat('HH:00', 'en_US');
final _weekday = DateFormat('EEEE', 'en_US');
final _month = DateFormat('yyyy-MM', 'en_US');

const _historicCostNote =
    'Cost and profit are blank for groups containing sales without a saved unit cost.';

bool _inRange(DateTime date, DateTime? start, DateTime? end) {
  final day = DateTime(date.year, date.month, date.day);
  return (start == null || !day.isBefore(start)) &&
      (end == null || !day.isAfter(end));
}

List<_Sale> _salesInRange(
  List<CompletedOrder> orders,
  DateTime? start,
  DateTime? end,
) {
  final sales = <_Sale>[];
  for (final order in orders) {
    if (order.status.trim().toLowerCase() != 'completed') continue;
    final date = DateTime.tryParse(order.dateTime)?.toLocal();
    if (date != null && _inRange(date, start, end)) {
      sales.add(_Sale(order, date));
    }
  }
  return sales;
}

class _Sale {
  _Sale(this.order, this.date)
      : gross =
            order.lines.fold<double>(0, (sum, line) => sum + line.lineTotal);

  final CompletedOrder order;
  final DateTime date;
  final double gross;

  String get customer => _label(order.customerName, 'Unrecorded customer');
  String get discountLabel =>
      _label(order.discountLabel, 'Unlabelled discount');
  double get discount =>
      order.discountAmount ??
      (gross - order.total).clamp(0.0, double.infinity).toDouble();
  bool get isCredit => order.paymentMethod.trim().toLowerCase() == 'credit';
  int get quantity => order.lines.fold(0, (sum, line) => sum + line.quantity);
}

String _label(String? value, String fallback) {
  final label = value?.trim();
  return label == null || label.isEmpty ? fallback : label;
}

Map<String, List<T>> _group<T>(Iterable<T> records, String Function(T) key) {
  final groups = <String, List<T>>{};
  for (final record in records) {
    groups.putIfAbsent(key(record), () => []).add(record);
  }
  return groups;
}

double _sum<T>(Iterable<T> records, num Function(T) value) =>
    records.fold(0.0, (total, record) => total + value(record));

double? _cost(Iterable<OrderLine> lines) {
  var cost = 0.0;
  for (final line in lines) {
    final unitCost = line.unitCost;
    if (unitCost == null) return null;
    cost += unitCost * line.quantity;
  }
  return cost;
}

List<ReportColumn> _salesColumns(String label) => [
      ReportColumn(label),
      const ReportColumn('Sales'),
      const ReportColumn('Units'),
      const ReportColumn('Net sales', money: true),
      const ReportColumn('Cost', money: true),
      const ReportColumn('Gross profit', money: true),
    ];

List<Object?> _salesRow(String label, List<_Sale> sales) {
  final total = _sum(sales, (sale) => sale.order.total);
  final cost = _cost(sales.expand((sale) => sale.order.lines));
  return [
    label,
    sales.length,
    sales.fold<int>(0, (sum, sale) => sum + sale.quantity),
    total,
    cost,
    cost == null ? null : total - cost,
  ];
}

ReportTable _salesSummary(
  List<_Sale> sales,
  String label,
  String Function(_Sale) key, {
  String? note,
}) {
  final groups = _group(sales, key);
  final keys = groups.keys.toList()..sort();
  return ReportTable(
    _salesColumns(label),
    [for (final key in keys) _salesRow(key, groups[key]!)],
    chartColumn: 3,
    note: [if (note != null) note, _historicCostNote].join(' '),
  );
}

class _SoldLine {
  const _SoldLine(this.sale, this.line);
  final _Sale sale;
  final OrderLine line;

  double get net => sale.gross == 0
      ? line.lineTotal
      : line.lineTotal * sale.order.total / sale.gross;
  double? get profit {
    final unitCost = line.unitCost;
    return unitCost == null ? null : net - unitCost * line.quantity;
  }

  String get category => _label(line.itemCategory, 'Uncategorized');
  String get product => _label(line.itemCode, line.itemName);
}

Iterable<_SoldLine> _soldLines(Iterable<_Sale> sales) sync* {
  for (final sale in sales) {
    for (final line in sale.order.lines) {
      yield _SoldLine(sale, line);
    }
  }
}

ReportTable _itemSummary(List<_Sale> sales, {bool byCategory = false}) {
  final groups = _group(
    _soldLines(sales),
    (line) => byCategory ? line.category : line.product,
  );
  final rows = <List<Object?>>[];
  for (final entry in groups.entries) {
    final lines = entry.value;
    final cost = _cost(lines.map((line) => line.line));
    final net = _sum(lines, (line) => line.net);
    final label = byCategory ? entry.key : lines.first.line.itemName;
    rows.add([
      label,
      if (!byCategory) lines.first.line.itemCode,
      lines.fold<int>(0, (sum, line) => sum + line.line.quantity),
      net,
      cost,
      cost == null ? null : net - cost,
    ]);
  }
  final chartColumn = byCategory ? 2 : 3;
  rows.sort((a, b) => (b[chartColumn] as num).compareTo(a[chartColumn] as num));
  return ReportTable(
    [
      ReportColumn(byCategory ? 'Category' : 'Product'),
      if (!byCategory) const ReportColumn('Code'),
      const ReportColumn('Units'),
      const ReportColumn('Net sales', money: true),
      const ReportColumn('Cost', money: true),
      const ReportColumn('Gross profit', money: true),
    ],
    rows,
    chartColumn: chartColumn,
    note:
        'Order discounts are allocated proportionally across items. $_historicCostNote',
  );
}

ReportTable _saleRows(Iterable<_Sale> sales, {bool showDiscountLabel = false}) {
  return ReportTable(
    [
      const ReportColumn('Order'),
      const ReportColumn('Sale time'),
      const ReportColumn('Customer'),
      const ReportColumn('Cashier'),
      const ReportColumn('Register'),
      const ReportColumn('Payment'),
      const ReportColumn('Units'),
      if (showDiscountLabel) const ReportColumn('Discount type'),
      const ReportColumn('Discount', money: true),
      const ReportColumn('Net sales', money: true),
    ],
    [
      for (final sale in sales)
        [
          sale.order.id,
          _timestamp.format(sale.date),
          sale.customer,
          sale.order.cashierName,
          sale.order.register,
          sale.order.paymentMethod,
          sale.quantity,
          if (showDiscountLabel) sale.discountLabel,
          sale.discount,
          sale.order.total,
        ],
    ],
  );
}

ReportTable _itemRows(Iterable<_Sale> sales) {
  return ReportTable(
    const [
      ReportColumn('Order'),
      ReportColumn('Date'),
      ReportColumn('Product'),
      ReportColumn('Code'),
      ReportColumn('Category'),
      ReportColumn('Units'),
      ReportColumn('Unit price', money: true),
      ReportColumn('Net sales', money: true),
      ReportColumn('Unit cost', money: true),
      ReportColumn('Gross profit', money: true),
    ],
    [
      for (final sold in _soldLines(sales))
        [
          sold.sale.order.id,
          _day.format(sold.sale.date),
          sold.line.itemName,
          sold.line.itemCode,
          sold.category,
          sold.line.quantity,
          sold.line.unitPriceValue,
          sold.net,
          sold.line.unitCost,
          sold.profit,
        ],
    ],
    note:
        'Order discounts are allocated proportionally across items. $_historicCostNote',
  );
}

ReportTable _discounts(Iterable<_Sale> sales) {
  final groups = _group(sales, (sale) => sale.discountLabel);
  return ReportTable(
    const [
      ReportColumn('Discount type'),
      ReportColumn('Sales'),
      ReportColumn('Discount', money: true),
      ReportColumn('Net sales', money: true),
    ],
    [
      for (final entry in groups.entries)
        [
          entry.key,
          entry.value.length,
          _sum(entry.value, (sale) => sale.discount),
          _sum(entry.value, (sale) => sale.order.total),
        ],
    ],
    chartColumn: 2,
    note:
        'For older orders, discounts are inferred from line totals and the order total.',
  );
}

ReportTable _payments(List<_Sale> sales) {
  final groups = _group(
    sales,
    (sale) => _label(sale.order.paymentMethod, 'Unrecorded method'),
  );
  return ReportTable(
    const [
      ReportColumn('Payment method'),
      ReportColumn('Sales'),
      ReportColumn('Collected', money: true),
      ReportColumn('Sold on credit', money: true),
    ],
    [
      for (final entry in groups.entries)
        [
          entry.key,
          entry.value.length,
          _sum(
            entry.value.where((sale) => !sale.isCredit),
            (sale) => sale.order.total,
          ),
          _sum(
            entry.value.where((sale) => sale.isCredit),
            (sale) => sale.order.total,
          ),
        ],
    ],
    chartColumn: 2,
    note: 'Credit sales are shown separately from payments collected.',
  );
}

ReportTable _expenseSummary(
  List<Expense> expenses,
  String label,
  String Function(Expense) key,
) {
  final groups = _group(
    expenses,
    (expense) => _label(key(expense), 'Unspecified'),
  );
  return ReportTable(
    [
      ReportColumn(label),
      const ReportColumn('Entries'),
      const ReportColumn('Expenses', money: true),
    ],
    [
      for (final entry in groups.entries)
        [
          entry.key,
          entry.value.length,
          _sum(entry.value, (expense) => expense.amount),
        ],
    ],
    chartColumn: 2,
  );
}

ReportTable _inventoryRows(Iterable<InventoryProductItem> items) {
  return ReportTable(
    const [
      ReportColumn('Code'),
      ReportColumn('Product'),
      ReportColumn('Category'),
      ReportColumn('In stock'),
      ReportColumn('Unit cost', money: true),
      ReportColumn('Sale price', money: true),
      ReportColumn('Cost value', money: true),
    ],
    [
      for (final item in items)
        [
          item.code,
          item.name,
          item.category,
          item.stockCount,
          item.purchasePrice,
          item.sellingPrice,
          item.purchasePrice * item.stockCount,
        ],
    ],
  );
}

ReportTable _stockSummary(
  List<InventoryProductItem> items, {
  bool byCategory = false,
}) {
  final groups = _group(
    items,
    (item) => byCategory ? item.category : 'All products',
  );
  return ReportTable(
    const [
      ReportColumn('Stock group'),
      ReportColumn('Products'),
      ReportColumn('Units'),
      ReportColumn('Cost value', money: true),
      ReportColumn('Retail value', money: true),
    ],
    [
      for (final entry in groups.entries)
        [
          entry.key,
          entry.value.length,
          entry.value.fold<int>(0, (sum, item) => sum + item.stockCount),
          _sum(entry.value, (item) => item.purchasePrice * item.stockCount),
          _sum(entry.value, (item) => item.sellingPrice * item.stockCount),
        ],
    ],
  );
}

ReportTable _averageBasket(List<_Sale> sales) {
  final groups = _group(sales, (sale) => _day.format(sale.date));
  final keys = groups.keys.toList()..sort();
  return ReportTable(
    const [
      ReportColumn('Date'),
      ReportColumn('Sales'),
      ReportColumn('Average units'),
      ReportColumn('Average sale', money: true),
    ],
    [
      for (final key in keys)
        [
          key,
          groups[key]!.length,
          _sum(groups[key]!, (sale) => sale.quantity) / groups[key]!.length,
          _sum(groups[key]!, (sale) => sale.order.total) / groups[key]!.length,
        ],
    ],
  );
}

ReportTable _profitLoss(List<_Sale> sales, List<Expense> expenses) {
  final revenue = _sum(sales, (sale) => sale.order.total);
  final cost = _cost(sales.expand((sale) => sale.order.lines));
  final spending = _sum(expenses, (expense) => expense.amount);
  return ReportTable(
    const [ReportColumn('POS activity'), ReportColumn('Amount', money: true)],
    [
      ['Net sales', revenue],
      ['Cost of goods sold', cost],
      ['Gross profit', cost == null ? null : revenue - cost],
      ['Recorded expenses', spending],
      ['Operating result', cost == null ? null : revenue - cost - spending],
    ],
    note:
        'Based on POS sales and recorded expenses. General ledger adjustments are unavailable. $_historicCostNote',
  );
}

ReportTable _newCustomerReport(
  List<CustomerData> customers,
  DateTime? start,
  DateTime? end,
) {
  return ReportTable(
    const [
      ReportColumn('Joined'),
      ReportColumn('Customer'),
      ReportColumn('Phone'),
    ],
    [
      for (final customer in customers.where(
        (customer) => _inRange(customer.createdAt.toLocal(), start, end),
      ))
        [
          _day.format(customer.createdAt.toLocal()),
          customer.name,
          customer.phone,
        ],
    ],
  );
}

class _TaxBucket {
  double gross = 0;
  double tax = 0;
  int count = 0;
}
