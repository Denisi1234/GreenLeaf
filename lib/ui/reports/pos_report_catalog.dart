enum ReportGroup {
  graphical('Graphical Reports'),
  summary('Summary Reports'),
  detailed('Detailed Reports'),
  inventory('Inventory Reports'),
  accounting('Accounting & Register'),
  operations('TrackMauzo Reports');

  const ReportGroup(this.label);
  final String label;
}

enum ReportData {
  sales,
  categories,
  expenses,
  customers,
  suppliers,
  items,
  employees,
  taxes,
  salesTaxes,
  discounts,
  payments,
  location,
  salesDetail,
  itemDetail,
  receivings,
  customerDetail,
  employeeDetail,
  discountDetail,
  supplierDetail,
  inventory,
  lowInventory,
  profitLoss,
  balanceSheet,
  bank,
  reconciliation,
  trialBalance,
  cashFlow,
  assets,
  taxCompliance,
  cashUp,
  shifts,
  hourly,
  weekdays,
  monthly,
  registers,
  balances,
  expenseDetail,
  expensePayments,
  stockByCategory,
  stockValue,
  outOfStock,
  averageBasket,
  creditSales,
  discountedItems,
  newCustomers,
}

class PosReport {
  const PosReport(this.title, this.group, this.data, {this.chart = false});

  final String title;
  final ReportGroup group;
  final ReportData data;
  final bool chart;

  String? get missingData => null;

  bool get isSnapshot => switch (data) {
        ReportData.inventory ||
        ReportData.lowInventory ||
        ReportData.balances ||
        ReportData.stockByCategory ||
        ReportData.stockValue ||
        ReportData.outOfStock =>
          true,
        _ => false,
      };
}

const posReports = [
  PosReport(
    'Sales Chart',
    ReportGroup.graphical,
    ReportData.sales,
    chart: true,
  ),
  PosReport(
    'Categories Chart',
    ReportGroup.graphical,
    ReportData.categories,
    chart: true,
  ),
  PosReport(
    'Expenses by Category Chart',
    ReportGroup.graphical,
    ReportData.expenses,
    chart: true,
  ),
  PosReport(
    'Customers Chart',
    ReportGroup.graphical,
    ReportData.customers,
    chart: true,
  ),
  PosReport(
    'Suppliers Chart',
    ReportGroup.graphical,
    ReportData.suppliers,
    chart: true,
  ),
  PosReport(
    'Items Chart',
    ReportGroup.graphical,
    ReportData.items,
    chart: true,
  ),
  PosReport(
    'Employees Chart',
    ReportGroup.graphical,
    ReportData.employees,
    chart: true,
  ),
  PosReport(
    'Taxes Chart',
    ReportGroup.graphical,
    ReportData.taxes,
    chart: true,
  ),
  PosReport(
    'Sales Taxes Chart',
    ReportGroup.graphical,
    ReportData.salesTaxes,
    chart: true,
  ),
  PosReport(
    'Discounts Chart',
    ReportGroup.graphical,
    ReportData.discounts,
    chart: true,
  ),
  PosReport(
    'Payments Chart',
    ReportGroup.graphical,
    ReportData.payments,
    chart: true,
  ),
  PosReport('Sales Summary', ReportGroup.summary, ReportData.sales),
  PosReport('Categories Summary', ReportGroup.summary, ReportData.categories),
  PosReport('Expenses by Category', ReportGroup.summary, ReportData.expenses),
  PosReport('Customers Summary', ReportGroup.summary, ReportData.customers),
  PosReport('Suppliers Summary', ReportGroup.summary, ReportData.suppliers),
  PosReport('Items Summary', ReportGroup.summary, ReportData.items),
  PosReport('Employees Summary', ReportGroup.summary, ReportData.employees),
  PosReport('Taxes Summary', ReportGroup.summary, ReportData.taxes),
  PosReport('Sales Taxes Summary', ReportGroup.summary, ReportData.salesTaxes),
  PosReport('Discounts Summary', ReportGroup.summary, ReportData.discounts),
  PosReport('Payments Summary', ReportGroup.summary, ReportData.payments),
  PosReport('Store Profit', ReportGroup.summary, ReportData.location),
  PosReport('Detailed Sales', ReportGroup.detailed, ReportData.salesDetail),
  PosReport('Detailed Item Sales', ReportGroup.detailed, ReportData.itemDetail),
  PosReport('Detailed Receivings', ReportGroup.detailed, ReportData.receivings),
  PosReport(
    'Specific Customer',
    ReportGroup.detailed,
    ReportData.customerDetail,
  ),
  PosReport(
    'Specific Employee',
    ReportGroup.detailed,
    ReportData.employeeDetail,
  ),
  PosReport(
    'Specific Discount',
    ReportGroup.detailed,
    ReportData.discountDetail,
  ),
  PosReport(
    'Specific Supplier',
    ReportGroup.detailed,
    ReportData.supplierDetail,
  ),
  PosReport('Low Inventory', ReportGroup.inventory, ReportData.lowInventory),
  PosReport('Inventory Summary', ReportGroup.inventory, ReportData.inventory),
  PosReport(
    'Financial Statement (P&L)',
    ReportGroup.accounting,
    ReportData.profitLoss,
  ),
  PosReport(
    'Balance Sheet (Financial Position)',
    ReportGroup.accounting,
    ReportData.balanceSheet,
  ),
  PosReport(
    'Bank & Digital Reconciliation',
    ReportGroup.accounting,
    ReportData.bank,
  ),
  PosReport(
    'Payment Reconciliation',
    ReportGroup.accounting,
    ReportData.reconciliation,
  ),
  PosReport('Trial Balance', ReportGroup.accounting, ReportData.trialBalance),
  PosReport('Cash Flow', ReportGroup.accounting, ReportData.cashFlow),
  PosReport('Fixed Assets', ReportGroup.accounting, ReportData.assets),
  PosReport('Tax Compliance', ReportGroup.accounting, ReportData.taxCompliance),
  PosReport('Cash-Up', ReportGroup.accounting, ReportData.cashUp),
  PosReport('Register Shifts', ReportGroup.accounting, ReportData.shifts),
  PosReport('Hourly Sales', ReportGroup.operations, ReportData.hourly),
  PosReport(
    'Sales by Day of Week',
    ReportGroup.operations,
    ReportData.weekdays,
  ),
  PosReport('Monthly Sales', ReportGroup.operations, ReportData.monthly),
  PosReport('Sales by Register', ReportGroup.operations, ReportData.registers),
  PosReport(
    'Outstanding Customer Credit',
    ReportGroup.operations,
    ReportData.balances,
  ),
  PosReport(
    'Detailed Expenses',
    ReportGroup.operations,
    ReportData.expenseDetail,
  ),
  PosReport(
    'Expenses by Payment Method',
    ReportGroup.operations,
    ReportData.expensePayments,
  ),
  PosReport(
    'Stock by Category',
    ReportGroup.operations,
    ReportData.stockByCategory,
  ),
  PosReport(
    'Inventory Valuation',
    ReportGroup.operations,
    ReportData.stockValue,
  ),
  PosReport('Out of Stock', ReportGroup.operations, ReportData.outOfStock),
  PosReport('Average Basket', ReportGroup.operations, ReportData.averageBasket),
  PosReport('Credit Sales', ReportGroup.operations, ReportData.creditSales),
  PosReport(
    'Items on Discounted Sales',
    ReportGroup.operations,
    ReportData.discountedItems,
  ),
  PosReport('New Customers', ReportGroup.operations, ReportData.newCustomers),
];
