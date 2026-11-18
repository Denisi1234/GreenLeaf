enum ReportGroup {
  graphical('Graphical Reports'),
  summary('Summary Reports'),
  detailed('Detailed Reports'),
  inventory('Inventory Reports'),
  accounting('Accounting & Register'),
  operations('TrackMauzo Reports'),
  multiStore('Multi-Store Reports');

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
  multiStoreSales,
  multiStoreProfit,
  multiStoreExpenses,
  multiStoreInventoryValue,
  multiStoreLowStock,
  multiStoreOutOfStock,
  multiStoreCustomers,
  multiStoreNewCustomers,
  multiStoreCredit,
  multiStoreSuppliers,
  multiStoreReceivings,
  multiStoreTax,
  multiStoreCashFlow,
  multiStoreBank,
  multiStoreAssets,
  multiStoreStaff,
  multiStorePayments,
  multiStoreDiscounts,
  multiStoreCategories,
  multiStoreItems,
  multiStoreRegister,
  multiStoreComparison,
  multiStorePerformance,
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
        ReportData.outOfStock ||
        ReportData.multiStoreInventoryValue ||
        ReportData.multiStoreLowStock ||
        ReportData.multiStoreOutOfStock ||
        ReportData.multiStoreAssets ||
        ReportData.multiStoreCredit =>
          true,
        _ => false,
      };

  bool get isMultiStore => group == ReportGroup.multiStore;
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
  PosReport('Multi-Store Sales Comparison', ReportGroup.multiStore, ReportData.multiStoreSales, chart: true),
  PosReport('Multi-Store Profit Comparison', ReportGroup.multiStore, ReportData.multiStoreProfit, chart: true),
  PosReport('Multi-Store Expenses Comparison', ReportGroup.multiStore, ReportData.multiStoreExpenses, chart: true),
  PosReport('Multi-Store Inventory Value', ReportGroup.multiStore, ReportData.multiStoreInventoryValue),
  PosReport('Multi-Store Low Stock', ReportGroup.multiStore, ReportData.multiStoreLowStock),
  PosReport('Multi-Store Out of Stock', ReportGroup.multiStore, ReportData.multiStoreOutOfStock),
  PosReport('Multi-Store Customer Base', ReportGroup.multiStore, ReportData.multiStoreCustomers),
  PosReport('Multi-Store New Customers', ReportGroup.multiStore, ReportData.multiStoreNewCustomers),
  PosReport('Multi-Store Outstanding Credit', ReportGroup.multiStore, ReportData.multiStoreCredit),
  PosReport('Multi-Store Suppliers & Purchases', ReportGroup.multiStore, ReportData.multiStoreSuppliers),
  PosReport('Multi-Store Goods Received', ReportGroup.multiStore, ReportData.multiStoreReceivings),
  PosReport('Multi-Store Tax Summary', ReportGroup.multiStore, ReportData.multiStoreTax),
  PosReport('Multi-Store Cash Flow', ReportGroup.multiStore, ReportData.multiStoreCashFlow),
  PosReport('Multi-Store Bank Position', ReportGroup.multiStore, ReportData.multiStoreBank),
  PosReport('Multi-Store Fixed Assets', ReportGroup.multiStore, ReportData.multiStoreAssets),
  PosReport('Multi-Store Staff & Registers', ReportGroup.multiStore, ReportData.multiStoreStaff),
  PosReport('Multi-Store Payment Methods', ReportGroup.multiStore, ReportData.multiStorePayments, chart: true),
  PosReport('Multi-Store Discounts', ReportGroup.multiStore, ReportData.multiStoreDiscounts),
  PosReport('Multi-Store Category Performance', ReportGroup.multiStore, ReportData.multiStoreCategories),
  PosReport('Multi-Store Top Items', ReportGroup.multiStore, ReportData.multiStoreItems),
  PosReport('Multi-Store Register/Cash-Up', ReportGroup.multiStore, ReportData.multiStoreRegister),
  PosReport('Multi-Store Side-by-Side Comparison', ReportGroup.multiStore, ReportData.multiStoreComparison),
  PosReport('Multi-Store Performance Scorecard', ReportGroup.multiStore, ReportData.multiStorePerformance),
];
