part of '../pos_report_data.dart';

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
    const [ReportColumn('POS activity', systemLabels: true), ReportColumn('Amount', money: true)],
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

class _ItemAgg {
  _ItemAgg(this.name);
  final String name;
  int units = 0;
  double net = 0;
}

class _TaxBucket {
  double gross = 0;
  double tax = 0;
  int count = 0;
}
