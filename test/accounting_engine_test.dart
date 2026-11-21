import 'package:flutter_test/flutter_test.dart';
import 'package:track_mauzo/service/accounting_engine.dart';
import 'package:track_mauzo/service/accounting_model.dart';
import 'package:track_mauzo/service/expense_model.dart';
import 'package:track_mauzo/service/pos_order_models.dart';
import 'package:track_mauzo/service/register_shift_model.dart';
import 'package:track_mauzo/service/supplier_model.dart';
import 'package:track_mauzo/service/tax_settings.dart';
import 'package:track_mauzo/ui/models/product_item.dart';

const _accounts = <Account>[
  Account(id: 1, code: '1000', name: 'Cash', type: AccountType.asset),
  Account(id: 2, code: '1010', name: 'Bank', type: AccountType.asset),
  Account(id: 3, code: '1100', name: 'Receivables', type: AccountType.asset),
  Account(id: 4, code: '1200', name: 'Inventory', type: AccountType.asset),
  Account(id: 5, code: '2000', name: 'Payables', type: AccountType.liability),
  Account(id: 6, code: '2100', name: 'Tax', type: AccountType.liability),
  Account(id: 7, code: '4000', name: 'Sales', type: AccountType.income),
  Account(id: 8, code: '5000', name: 'COGS', type: AccountType.expense),
  Account(id: 9, code: '6000', name: 'Operating', type: AccountType.expense),
  Account(id: 10, code: '7000', name: 'Depreciation', type: AccountType.expense),
  Account(id: 11, code: '8000', name: 'Drawings', type: AccountType.equity),
];

void main() {
  const engine = AccountingEngine();

  List<LedgerPosting> post({
    List<CompletedOrder> orders = const [],
    List<Expense> expenses = const [],
    List<Receiving> receivings = const [],
    List<Supplier> suppliers = const [],
    List<RegisterShift> shifts = const [],
    List<FixedAsset> fixedAssets = const [],
    List<JournalEntry> journalEntries = const [],
    List<Account> accounts = _accounts,
    TaxSettings tax = const TaxSettings(),
  }) {
    return engine.postings(
      orders: orders,
      expenses: expenses,
      receivings: receivings,
      suppliers: suppliers,
      shifts: shifts,
      fixedAssets: fixedAssets,
      journalEntries: journalEntries,
      accounts: accounts,
      tax: tax,
    );
  }

  LedgerPosting posting(List<LedgerPosting> postings, String code) =>
      postings.singleWhere((item) => item.accountCode == code);

  double sumDebit(List<LedgerPosting> postings, String code) => postings
      .where((item) => item.accountCode == code)
      .fold(0, (sum, item) => sum + item.debit);

  double sumCredit(List<LedgerPosting> postings, String code) => postings
      .where((item) => item.accountCode == code)
      .fold(0, (sum, item) => sum + item.credit);

  test('cash sale posts cash, net sales, tax and cost of goods sold', () {
    final postings = post(
      orders: [_order(total: 1150, paymentMethod: 'Cash', unitCost: 400)],
      tax: const TaxSettings(
        enabled: true,
        ratePercent: 15,
        pricesIncludeTax: true,
      ),
    );

    expect(posting(postings, '1000').debit, 1150);
    expect(posting(postings, '1000').credit, 0);
    expect(posting(postings, '1000').balance, 1150);
    expect(posting(postings, '4000').credit, closeTo(1000, 0.001));
    expect(posting(postings, '2100').credit, closeTo(150, 0.001));
    expect(posting(postings, '5000').debit, 800);
    expect(posting(postings, '1200').credit, 800);
  });

  test('sales without tax enabled create no tax posting', () {
    final postings = post(
      orders: [_order(total: 500, paymentMethod: 'Cash')],
      tax: const TaxSettings(enabled: true, ratePercent: 0),
    );

    expect(() => posting(postings, '2100'), throwsStateError);
    expect(posting(postings, '4000').credit, 500);
  });

  test('only completed orders are posted', () {
    final postings = post(
      orders: [
        _order(id: 'A', total: 100, status: 'Completed'),
        _order(id: 'B', total: 900, status: 'Voided'),
        _order(id: 'C', total: 500, status: 'Open'),
      ],
    );

    expect(posting(postings, '1000').debit, 100);
    expect(posting(postings, '4000').credit, 100);
  });

  test('credit sales post to receivables and other methods to bank', () {
    final postings = post(
      orders: [
        _order(id: 'credit', total: 200, paymentMethod: 'Credit (Debt)'),
        _order(id: 'card', total: 300, paymentMethod: 'Card'),
        _order(id: 'kopesh', total: 400, paymentMethod: 'Kopesh'),
        _order(id: 'mobile', total: 500, paymentMethod: 'Mobile Money'),
      ],
    );

    expect(sumDebit(postings, '1100'), 600);
    expect(sumDebit(postings, '1010'), 800);
    expect(postings.where((item) => item.accountCode == '1000'), isEmpty);
  });

  test('expenses split net and tax and credit the payment account', () {
    final postings = post(
      expenses: [
        Expense(
          title: 'Rent',
          amount: 500,
          category: 'Rent',
          paymentMethod: 'Cash',
          date: DateTime(2026, 1, 1),
          taxAmount: 50,
        ),
        Expense(
          title: 'Fuel',
          amount: 200,
          category: 'Transport',
          paymentMethod: 'Card',
          date: DateTime(2026, 1, 2),
        ),
      ],
    );

    expect(posting(postings, '6000-Rent').debit, 450);
    expect(posting(postings, '6000-Transport').debit, 200);
    expect(posting(postings, '6000-Rent').accountName, 'Operating (Rent)');
    expect(posting(postings, '2100').debit, 50);
    expect(posting(postings, '1000').credit, 500);
    expect(posting(postings, '1010').credit, 200);
  });

  test('receivings increase inventory and accounts payable', () {
    final postings = post(
      receivings: [
        Receiving(supplierName: 'Acme', date: DateTime(2026), total: 2000),
      ],
    );

    expect(posting(postings, '1200').debit, 2000);
    expect(posting(postings, '2000').credit, 2000);
  });

  test('open shift movements post to cash and drawings', () {
    final shifts = [
      RegisterShift(
        register: 'Till 1',
        openedBy: 'Owner',
        openedAt: DateTime(2026, 1, 1),
        openingFloat: 100,
        movements: [
          CashMovement(
            shiftId: '1',
            type: CashMovementType.cashIn,
            amount: 100,
            at: DateTime(2026, 1, 1),
          ),
          CashMovement(
            shiftId: '1',
            type: CashMovementType.payout,
            amount: 40,
            at: DateTime(2026, 1, 1),
          ),
          CashMovement(
            shiftId: '1',
            type: CashMovementType.drop,
            amount: 20,
            at: DateTime(2026, 1, 1),
          ),
        ],
      ),
      RegisterShift(
        register: 'Till 2',
        openedBy: 'Owner',
        openedAt: DateTime(2026, 1, 1),
        openingFloat: 100,
        closedAt: DateTime(2026, 1, 2),
        movements: [
          CashMovement(
            shiftId: '2',
            type: CashMovementType.cashIn,
            amount: 999,
            at: DateTime(2026, 1, 1),
          ),
        ],
      ),
    ];

    final postings = post(shifts: shifts);

    expect(sumDebit(postings, '1000'), 100);
    expect(sumCredit(postings, '1000'), 60);
    expect(sumCredit(postings, '8000'), 100);
    expect(sumDebit(postings, '8000'), 60);
  });

  test('fixed assets post cost, equity and accumulated depreciation', () {
    final asset = FixedAsset(
      name: 'Laptop',
      category: 'Equipment',
      purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
      cost: 1200,
      usefulLifeYears: 5,
    );
    final accumulated = asset.accumulatedDepreciation();

    final postings = post(fixedAssets: [asset]);

    expect(posting(postings, '1500').debit, 1200);
    expect(posting(postings, '3000').credit, 1200);
    expect(posting(postings, '7000').debit, closeTo(accumulated, 0.001));
    expect(
      posting(postings, '1500-depreciation').credit,
      closeTo(accumulated, 0.001),
    );
  });

  test('fixed assets with no depreciation only post cost and equity', () {
    final postings = post(fixedAssets: [
      FixedAsset(
        name: 'Land',
        category: 'Land',
        purchaseDate: DateTime.now(),
        cost: 1000,
      ),
    ]);

    expect(posting(postings, '1500').debit, 1000);
    expect(posting(postings, '3000').credit, 1000);
    expect(() => posting(postings, '7000'), throwsStateError);
  });

  test('journal entries resolve account codes and flag unknown accounts', () {
    final postings = post(
      journalEntries: [
        JournalEntry(
          date: DateTime(2026, 1, 1),
          memo: 'Move cash',
          lines: const [
            JournalLine(accountId: 1, debit: 100),
            JournalLine(accountId: 7, credit: 100),
            JournalLine(accountId: 999, debit: 5),
          ],
        ),
      ],
    );

    expect(posting(postings, '1000').debit, 100);
    expect(posting(postings, '4000').credit, 100);
    expect(posting(postings, 'unknown?').debit, 5);
    expect(posting(postings, 'unknown?').type, AccountType.expense);
  });

  test('opening balances debit assets and expenses and credit the rest', () {
    final postings = post(
      accounts: const [
        Account(
          code: '1000',
          name: 'Cash',
          type: AccountType.asset,
          openingBalance: 100,
        ),
        Account(
          code: '2000',
          name: 'Payables',
          type: AccountType.liability,
          openingBalance: 50,
        ),
        Account(
          code: '6000',
          name: 'Expenses',
          type: AccountType.expense,
          openingBalance: 30,
        ),
        Account(
          code: '4000',
          name: 'Sales',
          type: AccountType.income,
          openingBalance: 10,
        ),
        Account(
          code: '8000',
          name: 'Drawings',
          type: AccountType.equity,
          openingBalance: 7,
        ),
      ],
    );

    expect(posting(postings, '1000').debit, 100);
    expect(posting(postings, '2000').credit, 50);
    expect(posting(postings, '6000').debit, 30);
    expect(posting(postings, '4000').credit, 10);
    expect(posting(postings, '8000').credit, 7);
  });

  test('trial balance groups duplicate codes, sorts and sums by type', () {
    final rows = engine.trialBalance(const [
      LedgerPosting(
        accountCode: '4000',
        accountName: 'Sales',
        type: AccountType.income,
        credit: 150,
      ),
      LedgerPosting(
        accountCode: '1000',
        accountName: 'Cash',
        type: AccountType.asset,
        debit: 100,
      ),
      LedgerPosting(
        accountCode: '1000',
        accountName: 'Cash',
        type: AccountType.asset,
        debit: 50,
      ),
      LedgerPosting(
        accountCode: '1000',
        accountName: 'Cash',
        type: AccountType.asset,
        credit: 20,
      ),
    ]);

    expect(rows.map((row) => row.code), ['1000', '4000']);
    expect(rows.first.debit, 150);
    expect(rows.first.credit, 20);
    expect(AccountingEngine.totalByType(rows, AccountType.asset), 130);
    expect(AccountingEngine.totalByType(rows, AccountType.income), -150);
    expect(AccountingEngine.totalByType(rows, AccountType.expense), 0);
  });

  test('account names are derived from the chart of accounts', () {
    final postings = post(
      orders: [_order(total: 200, paymentMethod: 'Cash')],
      accounts: const [
        Account(code: '1000', name: 'Cash', type: AccountType.asset),
        Account(code: '4000', name: 'Sales', type: AccountType.income),
      ],
    );

    expect(posting(postings, '1000').accountName, 'Cash');
    expect(posting(postings, '4000').accountName, 'Sales');
  });

  test('empty activity produces no postings', () {
    expect(post(), isEmpty);
  });
}

CompletedOrder _order({
  String id = 'ORD-1',
  double total = 100,
  String status = 'Completed',
  String paymentMethod = 'Cash',
  double? unitCost,
}) {
  return CompletedOrder(
    id: id,
    dateTime: '2026-01-01T10:00:00',
    date: '2026-01-01',
    time: '10:00',
    total: total,
    status: status,
    cashierName: 'Cashier',
    register: 'Till 1',
    paymentMethod: paymentMethod,
    cashTendered: total,
    changeDue: 0,
    lines: [
      OrderLine(
        itemCode: 'P1',
        itemCategory: 'General',
        itemName: 'Water',
        itemSize: '1 pc',
        quantity: 2,
        unitPrice: '${total / 2}',
        unitPriceValue: total / 2,
        unitCost: unitCost,
        artType: ProductArtType.aquafina,
        imagePath: null,
      ),
    ],
  );
}
