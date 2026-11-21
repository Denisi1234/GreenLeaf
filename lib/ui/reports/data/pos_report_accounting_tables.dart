part of '../pos_report_data.dart';

extension PosReportAccountingTables on PosReportData {
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
        ReportColumn('Section', systemLabels: true),
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
        ReportColumn('Activity', systemLabels: true),
        ReportColumn('Category', systemLabels: true),
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
        ReportColumn('Item', systemLabels: true),
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
      chartColumn: 3,
      note: tax.enabled
          ? 'Tax calculated at ${tax.ratePercent.toStringAsFixed(1)}% '
              '${tax.pricesIncludeTax ? 'included in' : 'added to'} prices.'
          : 'Tax is disabled. Enable it in Settings â†’ Tax settings to populate tax figures.',
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
        ReportColumn('Item', systemLabels: true),
        ReportColumn('Amount', money: true),
      ],
      rows,
      note: tax.enabled
          ? 'Tax identification number: ${tax.taxId.isEmpty ? 'not set' : tax.taxId}.'
          : 'Tax is disabled. Turn it on in Settings â†’ Tax settings.',
    );
  }

}
