import 'package:intl/intl.dart';

import '../../service/expense_model.dart';
import '../../service/pos_order_models.dart';
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
  });

  final List<CompletedOrder> orders;
  final List<InventoryProductItem> inventory;
  final List<Expense> expenses;
  final List<CustomerData> customers;
  final String storeName;

  List<String> filterOptions(
    ReportData report,
    DateTime? start,
    DateTime? end,
  ) {
    if (report != ReportData.customerDetail &&
        report != ReportData.employeeDetail &&
        report != ReportData.discountDetail) {
      return const [];
    }
    final sales = _salesInRange(orders, start, end);
    final values = switch (report) {
      ReportData.customerDetail => sales.map((sale) => sale.customer),
      ReportData.employeeDetail => sales.map((sale) => sale.order.cashierName),
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
      _ => throw ArgumentError.value(
          report,
          'report',
          'Required records are unavailable',
        ),
    };
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
