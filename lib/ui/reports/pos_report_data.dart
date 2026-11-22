import 'package:intl/intl.dart';
import '../../l10n/app_strings.dart';

import '../../service/expense_model.dart';
import '../../service/pos_order_models.dart';
import '../../service/register_shift_model.dart';
import '../../service/store_models.dart';
import '../../service/supplier_model.dart';
import '../../service/accounting_engine.dart';
import '../../service/accounting_model.dart';
import '../../service/tax_settings.dart';
import '../../utils/quantity_formatter.dart';
import '../models/customer_data.dart';
import '../products/inventory_product_item.dart';
import 'pos_report_catalog.dart';

export '../products/inventory_product_item.dart';

part 'data/pos_report_accounting_tables.dart';
part 'data/pos_report_operations_tables.dart';
part 'data/pos_report_multistore_tables.dart';
part 'data/pos_report_helpers.dart';

class ReportColumn {
  const ReportColumn(this.label, {this.money = false, this.systemLabels = false});
  final String label;
  final bool money;
  /// Generated labels that PDF renderers may translate, never business names.
  final bool systemLabels;

  Object? displayValue(Object? value, AppStrings strings) {
    if (value is! String) return value;
    // Names, descriptions and categories belong to the business. Only these
    // system-defined values are translated for presentation and exports.
    if (const {'Payment', 'Payment method'}.contains(label)) {
      return strings.paymentMethod(value);
    }
    if (const {'Status', 'Day', 'Weekday', 'Section', 'Activity'}.contains(label)) {
      return strings.text(value);
    }
    return value;
  }
}

class ReportTable {
  const ReportTable(this.columns, this.rows, {this.chartColumn, this.note});

  final List<ReportColumn> columns;
  final List<List<Object?>> rows;
  final int? chartColumn;
  final String? note;

  ReportTable localized(AppStrings strings) => ReportTable(
    [for (final column in columns) ReportColumn(strings.text(column.label), money: column.money, systemLabels: column.systemLabels)],
    [for (final row in rows) [for (var i = 0; i < columns.length; i++) i < row.length ? columns[i].displayValue(row[i], strings) : null]],
    chartColumn: chartColumn,
    note: note == null ? null : strings.paragraph(note!),
  );
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
    this.storeSnapshots = const <StoreSnapshot>[],
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
  final List<StoreSnapshot> storeSnapshots;

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
      ReportData.multiStoreSales => _multiStoreSales(storeSnapshots, start, end),
      ReportData.multiStoreProfit => _multiStoreProfit(storeSnapshots, start, end),
      ReportData.multiStoreExpenses => _multiStoreExpenses(storeSnapshots, start, end),
      ReportData.multiStoreInventoryValue => _multiStoreInventoryValue(storeSnapshots),
      ReportData.multiStoreLowStock => _multiStoreLowStock(storeSnapshots),
      ReportData.multiStoreOutOfStock => _multiStoreOutOfStock(storeSnapshots),
      ReportData.multiStoreCustomers => _multiStoreCustomers(storeSnapshots),
      ReportData.multiStoreNewCustomers => _multiStoreNewCustomers(storeSnapshots, start, end),
      ReportData.multiStoreCredit => _multiStoreCredit(storeSnapshots),
      ReportData.multiStoreSuppliers => _multiStoreSuppliers(storeSnapshots),
      ReportData.multiStoreReceivings => _multiStoreReceivings(storeSnapshots, start, end),
      ReportData.multiStoreTax => _multiStoreTax(storeSnapshots, start, end),
      ReportData.multiStoreCashFlow => _multiStoreCashFlow(storeSnapshots, start, end),
      ReportData.multiStoreBank => _multiStoreBank(storeSnapshots),
      ReportData.multiStoreAssets => _multiStoreAssets(storeSnapshots),
      ReportData.multiStoreStaff => _multiStoreStaff(storeSnapshots),
      ReportData.multiStorePayments => _multiStorePayments(storeSnapshots, start, end),
      ReportData.multiStoreDiscounts => _multiStoreDiscounts(storeSnapshots, start, end),
      ReportData.multiStoreCategories => _multiStoreCategories(storeSnapshots, start, end),
      ReportData.multiStoreItems => _multiStoreItems(storeSnapshots, start, end),
      ReportData.multiStoreRegister => _multiStoreRegister(storeSnapshots, start, end),
      ReportData.multiStoreComparison => _multiStoreComparison(storeSnapshots, start, end),
      ReportData.multiStorePerformance => _multiStorePerformance(storeSnapshots, start, end),
    };
  }
}

String _paymentLabel(String method) {
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

String _durationLabel(RegisterShift shift) {
  final minutes =
      shift.endsAt.difference(shift.openedAt).inMinutes.clamp(0, 1440 * 60);
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return hours > 0 ? '${hours}h ${rest}m' : '${rest}m';
}

const _multiStoreNote =
    'Compared across all stores. Date filters apply to sales, expenses, receivings and shifts where relevant.';

List<_Sale> _snapshotSales(StoreSnapshot snap, DateTime? start, DateTime? end) {
  return _salesInRange(snap.orders.cast<CompletedOrder>(), start, end);
}

List<Expense> _snapshotExpenses(StoreSnapshot snap, DateTime? start, DateTime? end) {
  return snap.expenses
      .cast<Expense>()
      .where((e) => _inRange(e.date.toLocal(), start, end))
      .toList();
}

List<Receiving> _snapshotReceivings(StoreSnapshot snap, DateTime? start, DateTime? end) {
  return snap.receivings
      .cast<Receiving>()
      .where((r) => _inRange(r.date.toLocal(), start, end))
      .toList();
}

List<RegisterShift> _snapshotShifts(StoreSnapshot snap, DateTime? start, DateTime? end) {
  final dayStart = start == null ? null : DateTime(start.year, start.month, start.day);
  final dayEnd = end == null ? null : DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
  return snap.shifts
      .cast<RegisterShift>()
      .where((shift) =>
          (dayStart == null || !shift.openedAt.isBefore(dayStart)) &&
          (dayEnd == null || !shift.openedAt.isAfter(dayEnd)))
      .toList();
}
