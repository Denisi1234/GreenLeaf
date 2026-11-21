import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:track_mauzo/service/accounting_model.dart';
import 'package:track_mauzo/service/expense_model.dart';
import 'package:track_mauzo/service/pos_local_store.dart';
import 'package:track_mauzo/service/register_shift_model.dart';
import 'package:track_mauzo/service/staff_credentials.dart';
import 'package:track_mauzo/service/supplier_model.dart';
import 'package:track_mauzo/service/tax_settings.dart';
import 'package:track_mauzo/ui/models/customer_data.dart';
import 'package:track_mauzo/ui/models/product_item.dart';
import 'package:track_mauzo/ui/products/inventory_product_item.dart';

import 'support/memory_pos_database.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late MemoryPosLocalDatabase database;
  late PosLocalStore store;

  setUp(() {
    database = MemoryPosLocalDatabase();
    store = PosLocalStore(database: database);
  });

  tearDown(() async {
    store.dispose();
    await database.close();
  });

  Future<InventoryProductItem> addProduct({
    String code = 'P001',
    String name = 'Mineral Water',
    double purchasePrice = 10,
    double sellingPrice = 20,
    int stockCount = 10,
  }) async {
    final product = InventoryProductItem(
      code: code,
      name: name,
      category: 'Drinks',
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      stockCount: stockCount,
      stockState: InventoryStockState.inStock,
      artType: ProductArtType.aquafina,
    );
    return store.addProduct(product);
  }

  group('PosRegisterStore', () {
    test('starts one shift at a time and blocks a second open shift', () async {
      final shift = await store.startShift(
        register: 'Till 1',
        openedBy: 'Owner',
        openingFloat: 100,
      );

      expect(shift, isNotNull);
      expect(shift!.id, isNotNull);
      expect(shift.openingFloat, 100);
      expect(store.openShift?.id, shift.id);
      expect(store.registerShifts, hasLength(1));

      final second = await store.startShift(
        register: 'Till 2',
        openedBy: 'Owner',
        openingFloat: 50,
      );

      expect(second, isNull);
      expect(store.registerShifts, hasLength(1));
    });

    test('records drawer movements only while a shift is open', () async {
      await store.addCashMovement(
        type: CashMovementType.cashIn,
        amount: 100,
        recordedBy: 'Owner',
      );
      expect(store.cashMovements, isEmpty);

      await store.startShift(
        register: 'Till 1',
        openedBy: 'Owner',
        openingFloat: 50,
      );
      await store.addCashMovement(
        type: CashMovementType.cashIn,
        amount: 100,
        reason: 'Float top-up',
        recordedBy: 'Owner',
      );
      await store.addCashMovement(
        type: CashMovementType.payout,
        amount: 30,
        reason: 'Delivery',
        recordedBy: 'Owner',
      );
      await store.addCashMovement(
        type: CashMovementType.cashIn,
        amount: 0,
        recordedBy: 'Owner',
      );

      expect(store.cashMovements, hasLength(2));
      expect(store.openShift!.movements, hasLength(2));
    });

    test('cash-up reconciles float, sales and movements', () async {
      await addProduct(sellingPrice: 20);
      final shift = await store.startShift(
        register: 'Till 1',
        openedBy: 'Owner',
        openingFloat: 100,
      );
      await store.completeCashSale(
        items: [
          OrderLineItem(product: store.products.single, quantity: 2),
        ],
        cashTendered: 40,
        cashierName: 'Cashier',
        registerName: 'Till 1',
      );
      await store.addCashMovement(
        type: CashMovementType.cashIn,
        amount: 10,
        recordedBy: 'Owner',
      );

      final open = store.registerShifts.single;
      final beforeClose = store.cashUpFor(open);
      expect(beforeClose.cashSales, 40);
      expect(beforeClose.cashIn, 10);
      expect(beforeClose.expected, 150);
      expect(beforeClose.counted, 0);

      await store.closeShift(
        shift!.id!,
        countedCash: 150,
        closedBy: 'Owner',
      );

      final closed = store.registerShifts.single;
      expect(store.openShift, isNull);
      expect(closed.isOpen, isFalse);
      final summary = store.cashUpFor(closed);
      expect(summary.counted, 150);
      expect(summary.variance, 0);
      expect(summary.isBalanced, isTrue);
    });

    test('cash sales window excludes credit and outside orders', () async {
      await addProduct(sellingPrice: 25);
      final from = DateTime.now().subtract(const Duration(minutes: 1));
      await store.completeCashSale(
        items: [
          OrderLineItem(product: store.products.single, quantity: 2),
        ],
        cashTendered: 50,
        cashierName: 'Cashier',
        registerName: 'Till 1',
        paymentMethod: 'Cash',
      );
      await store.completeCashSale(
        items: [
          OrderLineItem(product: store.products.single, quantity: 2),
        ],
        cashTendered: 0,
        cashierName: 'Cashier',
        registerName: 'Till 1',
        paymentMethod: 'Card',
      );

      final to = DateTime.now().add(const Duration(minutes: 1));
      expect(store.cashSalesBetween(from, to), 50);
      expect(
        store.cashSalesBetween(
          from.subtract(const Duration(hours: 2)),
          from.subtract(const Duration(hours: 1)),
        ),
        0,
      );
    });

    test('closes, reopens and deletes shifts', () async {
      final shift = await store.startShift(
        register: 'Till 1',
        openedBy: 'Owner',
        openingFloat: 20,
      );
      await store.closeShift(
        shift!.id!,
        countedCash: 25,
        closedBy: 'Owner',
        notes: 'Short by 5',
      );
      expect(store.registerShifts.single.notes, 'Short by 5');
      expect(store.registerShifts.single.countedCash, 25);

      await store.reopenShift(shift.id!);
      expect(store.registerShifts.single.isOpen, isTrue);
      expect(store.registerShifts.single.countedCash, 0);
    });
  });

  group('PosCustomerStore', () {
    CustomerData customer({
      String id = 'C1',
      String name = 'Amina',
      double debitBalance = 100,
      String phone = '0700000000',
    }) {
      return CustomerData(
        id: id,
        name: name,
        phone: phone,
        debitBalance: debitBalance,
        createdAt: DateTime(2026, 1, 1),
        tags: const ['wholesale'],
      );
    }

    test('records a payment capped at the outstanding balance', () async {
      await store.addCustomer(customer());

      final updated = await store.recordDebtPayment(
        customerId: 'C1',
        amount: 150,
        note: 'Cleared',
        recordedBy: 'Owner',
      );

      expect(updated, isNotNull);
      expect(updated!.debitBalance, 0);
      expect(store.outstandingDebit, 0);
      expect(store.debtorCount, 0);
      expect(store.debitEntries, hasLength(1));
      expect(store.debitEntries.single.amount, 100);
      expect(store.debitEntries.single.isPayment, isTrue);
      expect(store.debitEntries.single.recordedBy, 'Owner');
      expect(
        store.debitCollectedSince(DateTime.now().subtract(
          const Duration(minutes: 1),
        )),
        100,
      );
    });

    test('rejects invalid payments', () async {
      await store.addCustomer(customer());

      expect(
        await store.recordDebtPayment(customerId: 'missing', amount: 10),
        isNull,
      );
      expect(
        await store.recordDebtPayment(customerId: 'C1', amount: 0),
        isNull,
      );
      expect(
        await store.recordDebtPayment(customerId: 'C1', amount: -5),
        isNull,
      );

      await store.addCustomer(customer(id: 'C2', name: 'Paid up', debitBalance: 0));
      expect(
        await store.recordDebtPayment(customerId: 'C2', amount: 10),
        isNull,
      );
    });

    test('partial payment keeps the remaining balance', () async {
      await store.addCustomer(customer());

      final updated = await store.recordDebtPayment(
        customerId: 'C1',
        amount: 40,
      );

      expect(updated!.debitBalance, 60);
      expect(store.outstandingDebit, 60);
      expect(store.debtorCount, 1);
      expect(store.debitEntries.single.amount, 40);
      expect(store.debitEntriesFor('C1'), hasLength(1));
    });

    test('deleting a payment re-applies its amount to the balance', () async {
      await store.addCustomer(customer());
      await store.recordDebtPayment(customerId: 'C1', amount: 40);
      final entryId = store.debitEntries.single.id;

      await store.deleteDebitEntry(entryId);

      expect(store.debitEntries, isEmpty);
      expect(store.customerById('C1')!.debitBalance, 100);
    });

    test('clearing all debits resets entries and balances', () async {
      await store.addCustomer(customer());
      await store.addCustomer(customer(id: 'C2', name: 'Juma', debitBalance: 20));
      await store.recordDebtPayment(customerId: 'C1', amount: 10);

      await store.clearAllDebits();

      expect(store.debitEntries, isEmpty);
      expect(store.outstandingDebit, 0);
      expect(store.customers.every((item) => item.debitBalance == 0), isTrue);
    });

    test('deleting a customer removes their ledger entries', () async {
      await store.addCustomer(customer());
      await store.recordDebtPayment(customerId: 'C1', amount: 10);
      expect(store.debitEntries, isNotEmpty);

      await store.deleteCustomer('C1');

      expect(store.customers, isEmpty);
      expect(store.debitEntries, isEmpty);
    });

    test('lookup helpers and updateCustomer work', () async {
      await store.addCustomer(customer());
      expect(store.customerByName('Amina')?.id, 'C1');

      await store.updateCustomer(
        store.customerById('C1')!.copyWith(name: 'Amina Trading'),
      );

      expect(store.customerById('C1')!.name, 'Amina Trading');
      expect(store.customerByName('Amina'), isNull);
      expect(store.ordersForCustomer('Amina Trading'), isEmpty);
    });

    test('credit sales create a debtor and a charge entry', () async {
      await addProduct(sellingPrice: 50);

      final order = await store.completeCashSale(
        items: [
          OrderLineItem(product: store.products.single, quantity: 2),
        ],
        cashTendered: 0,
        cashierName: 'Cashier',
        registerName: 'Till 1',
        customerName: 'New Customer',
        paymentMethod: 'Credit',
      );

      expect(order.total, 100);
      expect(store.customers.single.name, 'New Customer');
      expect(store.customers.single.debitBalance, 100);
      expect(store.debitEntries.single.isPayment, isFalse);
      expect(store.debitEntries.single.amount, 100);
      expect(store.debitEntries.single.orderId, order.id);
    });
  });

  group('PosExpenseStore', () {
    test('adds, updates and deletes expenses', () async {
      await store.addExpense(Expense(
        title: 'Electricity',
        amount: 120,
        category: 'Utilities',
        paymentMethod: 'Cash',
        date: DateTime(2026, 1, 1),
      ));

      expect(store.expenses, hasLength(1));
      final saved = store.expenses.single;
      expect(saved.id, isNotNull);

      await store.updateExpense(saved.copyWith(title: 'Electricity bill'));
      expect(store.expenses.single.title, 'Electricity bill');

      await store.deleteExpense(saved.id!);
      expect(store.expenses, isEmpty);
    });

    test('ignores updates to an unsaved expense', () async {
      await store.updateExpense(Expense(
        title: 'Draft',
        amount: 1,
        category: 'Other',
        paymentMethod: 'Cash',
        date: DateTime(2026, 1, 1),
      ));

      expect(store.expenses, isEmpty);
    });
  });

  group('PosSupplierStore', () {
    test('saves and updates suppliers', () async {
      final created = await store.saveSupplier(
        Supplier(name: 'Acme', openingBalance: 100),
      );

      expect(created.id, isNotNull);
      expect(store.suppliers.single.name, 'Acme');
      expect(store.supplierById(created.id!)!.openingBalance, 100);

      await store.saveSupplier(
        Supplier(id: created.id, name: 'Acme Ltd', openingBalance: 150),
      );

      expect(store.suppliers.single.name, 'Acme Ltd');
      expect(store.supplierById(created.id!)!.openingBalance, 150);
      expect(store.supplierById(999), isNull);
    });

    test('receiving updates stock with weighted average cost', () async {
      final supplier = await store.saveSupplier(
        Supplier(name: 'Acme', openingBalance: 100),
      );
      await addProduct(purchasePrice: 10, stockCount: 10, sellingPrice: 15);

      final receiving = await store.saveReceiving(Receiving(
        supplierId: supplier.id,
        supplierName: 'Acme',
        date: DateTime(2026, 1, 2),
        invoiceNo: 'INV-1',
        total: 200,
        lines: const [
          ReceivingLine(
            productName: 'Mineral Water',
            quantity: 10,
            unitCost: 20,
            sellingPrice: 25,
          ),
        ],
      ));

      expect(receiving.id, isNotNull);
      expect(store.receivings, hasLength(1));
      expect(store.receivings.single.lines, hasLength(1));
      final item = store.inventory.single;
      expect(item.stockCount, 20);
      expect(item.purchasePrice, 15);
      expect(item.sellingPrice, 25);
      expect(store.supplierBalance(supplier.id!), 300);
    });

    test('receiving auto-creates unknown products', () async {
      await addProduct();

      await store.saveReceiving(Receiving(
        supplierName: 'Acme',
        date: DateTime(2026, 1, 2),
        total: 20,
        lines: const [
          ReceivingLine(productName: 'Milk', quantity: 5, unitCost: 4),
        ],
      ));

      final created = store.inventory.firstWhere((item) => item.name == 'Milk');
      expect(created.code, 'P002');
      expect(created.stockCount, 5);
      expect(created.purchasePrice, 4);
      expect(created.sellingPrice, 5);
    });

    test('deletes suppliers and receivings', () async {
      final supplier = await store.saveSupplier(Supplier(name: 'Acme'));
      final receiving = await store.saveReceiving(Receiving(
        supplierId: supplier.id,
        supplierName: 'Acme',
        date: DateTime(2026, 1, 2),
        total: 10,
      ));

      await store.deleteReceiving(receiving.id!);
      expect(store.receivings, isEmpty);

      await store.deleteSupplier(supplier.id!);
      expect(store.suppliers, isEmpty);
    });
  });

  group('PosAccountingStore', () {
    test('seeds the default chart of accounts', () async {
      await store.deleteAccount(999);

      expect(store.accounts, hasLength(Account.defaults().length));
      final codes = store.accounts.map((item) => item.code).toList();
      expect(codes, orderedEquals(List<String>.from(codes)..sort()));
      expect(codes, containsAll(['1000', '4000', '5000']));
    });

    test('creates, updates and deletes accounts', () async {
      final created = await store.saveAccount(const Account(
        code: '9999',
        name: 'Petty cash',
        type: AccountType.asset,
        openingBalance: 250,
      ));

      expect(created.id, isNotNull);
      expect(store.accounts.single.code, '9999');
      expect(
        store.ledgerPostings().singleWhere((p) => p.accountCode == '9999').debit,
        250,
      );

      await store.saveAccount(Account(
        id: created.id,
        code: '9999',
        name: 'Petty cash box',
        type: AccountType.asset,
        openingBalance: 250,
      ));
      expect(store.accounts.single.name, 'Petty cash box');

      await store.deleteAccount(created.id!);
      expect(store.accounts.map((item) => item.code), isNot(contains('9999')));
      expect(store.accounts, hasLength(Account.defaults().length));
    });

    test('saves journal entries with their lines', () async {
      await store.deleteAccount(999);
      final cash = store.accounts.firstWhere((item) => item.code == '1000');
      final sales = store.accounts.firstWhere((item) => item.code == '4000');

      await store.saveJournalEntry(JournalEntry(
        date: DateTime(2026, 1, 1),
        memo: 'Cash sale',
        createdBy: 'Owner',
        lines: [
          JournalLine(accountId: cash.id, debit: 100),
          JournalLine(accountId: sales.id, credit: 100),
        ],
      ));

      expect(store.journalEntries, hasLength(1));
      expect(store.journalEntries.single.lines, hasLength(2));
      expect(store.journalEntries.single.isBalanced, isTrue);

      final trial = store.trialBalance();
      expect(
        trial.singleWhere((row) => row.code == '1000').debit,
        100,
      );
      expect(
        trial.singleWhere((row) => row.code == '4000').credit,
        100,
      );

      await store.deleteJournalEntry(store.journalEntries.single.id!);
      expect(store.journalEntries, isEmpty);
    });

    test('saves and deletes fixed assets', () async {
      await store.saveFixedAsset(FixedAsset(
        name: 'Laptop',
        category: 'Equipment',
        purchaseDate: DateTime.now(),
        cost: 1200,
      ));

      expect(store.fixedAssets, hasLength(1));
      expect(
        store.ledgerPostings().singleWhere((p) => p.accountCode == '1500').debit,
        1200,
      );

      await store.deleteFixedAsset(store.fixedAssets.single.id!);
      expect(store.fixedAssets, isEmpty);
    });

    test('matches bank statement lines to non-cash sales', () async {
      await addProduct(sellingPrice: 50);
      await store.completeCashSale(
        items: [
          OrderLineItem(product: store.products.single, quantity: 2),
        ],
        cashTendered: 0,
        cashierName: 'Cashier',
        registerName: 'Till 1',
        paymentMethod: 'Card',
      );
      await store.addBankTransaction(BankTransaction(
        date: DateTime.now(),
        description: 'Card settlement',
        amount: 100,
      ));
      await store.addBankTransaction(BankTransaction(
        date: DateTime.now(),
        description: 'Unrelated',
        amount: 999,
      ));

      final matched = await store.autoMatchBankTransactions();

      expect(matched, 1);
      expect(
        store.bankTransactions.where((entry) => entry.matched),
        hasLength(1),
      );
      expect(
        store.bankTransactions.firstWhere((entry) => entry.matched).amount,
        100,
      );

      final entry = store.bankTransactions
          .firstWhere((item) => item.description == 'Unrelated');
      await store.setBankTransactionMatched(entry.id!, true);
      expect(
        store.bankTransactions
            .firstWhere((item) => item.id == entry.id)
            .matched,
        isTrue,
      );

      await store.deleteBankTransaction(entry.id!);
      expect(store.bankTransactions, hasLength(1));
    });

    test('cash on hand reflects cash sales', () async {
      await addProduct(sellingPrice: 20);
      await store.completeCashSale(
        items: [
          OrderLineItem(product: store.products.single, quantity: 2),
        ],
        cashTendered: 40,
        cashierName: 'Cashier',
        registerName: 'Till 1',
      );

      expect(store.cashOnHand(), 40);
      expect(
        store.ledgerPostings().where((p) => p.accountCode == '1000').single.debit,
        40,
      );
    });
  });

  group('PosStaffStore', () {
    test('saves roles in sort order and updates permissions', () async {
      await store.saveStaffRole(const StaffRoleData(
        id: 'cashier',
        title: 'Cashier',
        subtitle: 'Front desk',
        permissions: ['View Sales'],
        sortOrder: 0,
      ));
      await store.saveStaffRole(const StaffRoleData(
        id: 'manager',
        title: 'Manager',
        subtitle: 'Operations',
        permissions: ['View Reports'],
        sortOrder: 0,
      ));

      expect(store.staffRoles.map((role) => role.id), ['cashier', 'manager']);
      expect(store.staffRoles.first.sortOrder, 0);
      expect(store.staffRoles.last.sortOrder, 1);

      await store.updateStaffRolePermissions('cashier', ['View Sales', 'Discounts']);
      expect(store.staffRoleById('cashier')!.permissions,
          ['View Sales', 'Discounts']);
      expect(store.staffRoleByTitle('Manager')?.id, 'manager');
      expect(store.staffRoleById('missing'), isNull);
    });

    test('staff member passwords are salted and verifiable', () async {
      await store.saveStaffRole(const StaffRoleData(
        id: 'cashier',
        title: 'Cashier',
        subtitle: 'Front desk',
        permissions: [],
        sortOrder: 0,
      ));

      final member = await store.addStaffMember(
        name: 'Jane Cashier',
        email: 'jane@example.test',
        phone: '0712345678',
        roleId: 'cashier',
        username: 'jane',
        password: 'secret123',
        employeeNumber: 'EMP-1',
      );

      expect(member.passwordHash, isNotEmpty);
      expect(member.passwordSalt, isNotEmpty);
      expect(member.passwordHash,
          isNot('secret123'));
      expect(store.staffUsernameExists('JANE'), isTrue);
      expect(store.staffUsernameExists('JANE', excludingId: member.id), isFalse);
      expect(store.staffEmployeeNumberExists('emp-1'), isTrue);
      expect(store.staffMembersForRole('cashier').single.id, member.id);

      expect(await store.login('jane', 'secret123'), isTrue);
      expect(store.isLoggedIn, isTrue);
      expect(store.currentUser?.id, member.id);

      expect(await store.login('jane', 'wrong'), isFalse);
      expect(store.lastAuthError, 'invalid_password');

      expect(await store.login('unknown', 'secret123'), isFalse);
      expect(store.lastAuthError, 'user_not_found');

      expect(await store.login('', ''), isFalse);
      expect(store.lastAuthError, 'missing_credentials');
    });

    test('inactive staff cannot sign in', () async {
      final member = await store.addStaffMember(
        name: 'Jane',
        email: 'jane@example.test',
        phone: '0712345678',
        roleId: 'cashier',
        username: 'jane',
        password: 'secret123',
      );
      await store.setStaffStatus(member.id, StaffStatus.inactive);

      expect(await store.login('jane', 'secret123'), isFalse);
      expect(store.lastAuthError, 'account_inactive');
    });

    test('changes the current user password', () async {
      await store.addStaffMember(
        name: 'Jane',
        email: 'jane@example.test',
        phone: '0712345678',
        roleId: 'cashier',
        username: 'jane',
        password: 'secret123',
      );
      await store.login('jane', 'secret123');

      expect(
        await store.changeCurrentUserPassword(
          currentPassword: 'wrong',
          newPassword: 'newsecret',
        ),
        isFalse,
      );
      expect(store.lastAuthError, 'current_password_incorrect');

      expect(
        await store.changeCurrentUserPassword(
          currentPassword: 'secret123',
          newPassword: 'newsecret',
        ),
        isTrue,
      );

      expect(await store.login('jane', 'secret123'), isFalse);
      expect(await store.login('jane', 'newsecret'), isTrue);
    });

    test('rejects short new passwords', () async {
      await store.addStaffMember(
        name: 'Jane',
        email: 'jane@example.test',
        phone: '0712345678',
        roleId: 'cashier',
        username: 'jane',
        password: 'secret123',
      );
      await store.login('jane', 'secret123');

      expect(
        await store.changeCurrentUserPassword(
          currentPassword: 'secret123',
          newPassword: '123',
        ),
        isFalse,
      );
      expect(store.lastAuthError, 'password_too_short');
    });

    test('resets a password by phone number', () async {
      await store.addStaffMember(
        name: 'Jane',
        email: 'jane@example.test',
        phone: '0712345678',
        roleId: 'cashier',
        username: 'jane',
        password: 'secret123',
      );

      expect(
        await store.resetPassword(phone: '0700000000', newPassword: 'newsecret'),
        isFalse,
      );
      expect(store.lastAuthError, 'user_not_found');

      expect(
        await store.resetPassword(phone: '0712345678', newPassword: 'newsecret'),
        isTrue,
      );
      expect(await store.login('jane', 'newsecret'), isTrue);
    });

    test('deleting a role is blocked while staff use it', () async {
      await store.saveStaffRole(const StaffRoleData(
        id: 'cashier',
        title: 'Cashier',
        subtitle: 'Front desk',
        permissions: [],
        sortOrder: 0,
      ));
      final member = await store.addStaffMember(
        name: 'Jane',
        email: 'jane@example.test',
        phone: '0712345678',
        roleId: 'cashier',
        username: 'jane',
        password: 'secret123',
      );

      await store.deleteStaffRole('cashier');
      expect(store.staffRoles, hasLength(1));

      await store.deleteStaffMember(member.id);
      expect(store.staffMembers, isEmpty);

      await store.deleteStaffRole('cashier');
      expect(store.staffRoles, isEmpty);
    });

    test('register creates an owner account and signs in', () async {
      expect(
        await store.register(
          name: 'Owner',
          phone: '0712345678',
          password: '123',
        ),
        isFalse,
      );
      expect(store.lastAuthError, 'invalid_password');

      expect(
        await store.register(
          name: 'Owner',
          phone: '0712345678',
          password: 'secret123',
        ),
        isTrue,
      );
      expect(store.isLoggedIn, isTrue);
      expect(store.currentUser?.name, 'Owner');

      expect(
        await store.register(
          name: 'Duplicate',
          phone: '0712345678',
          password: 'secret123',
        ),
        isFalse,
      );
      expect(store.lastAuthError, 'phone_taken');
    });
  });

  group('Checkout, tax, cart stock and security guards', () {
    test('addToCart and addToCartQuantity block out-of-stock inventory items',
        () async {
      await addProduct(code: 'P000', name: 'Empty Stock', stockCount: 0);
      final product = store.products.single;

      expect(store.addToCart(product), isFalse);
      expect(store.addToCartQuantity(product, 2), isFalse);
      expect(store.cartItems, isEmpty);
    });

    test('completeCashSale validates discounts and applies TaxSettings',
        () async {
      await addProduct(
        code: 'P100',
        name: 'Soap',
        sellingPrice: 1000,
        stockCount: 10,
      );
      final product = store.products.single;

      await expectLater(
        () => store.completeCashSale(
          items: [OrderLineItem(product: product, quantity: 1)],
          cashTendered: 1000,
          cashierName: 'Cashier',
          registerName: 'POS-01',
          discountAmount: -50,
        ),
        throwsStateError,
      );

      final clampedOrder = await store.completeCashSale(
        items: [OrderLineItem(product: product, quantity: 1)],
        cashTendered: 0,
        cashierName: 'Cashier',
        registerName: 'POS-01',
        discountAmount: 5000,
        discountLabel: 'Full comp',
      );
      expect(clampedOrder.total, 0);
      expect(clampedOrder.discountAmount, 1000);

      await store.updateTaxSettings(
        const TaxSettings(
          enabled: true,
          ratePercent: 18,
          pricesIncludeTax: false,
        ),
      );
      final exclusiveOrder = await store.completeCashSale(
        items: [OrderLineItem(product: product, quantity: 1)],
        cashTendered: 1180,
        cashierName: 'Cashier',
        registerName: 'POS-01',
      );
      expect(exclusiveOrder.total, 1180);

      await store.updateTaxSettings(
        const TaxSettings(
          enabled: true,
          ratePercent: 18,
          pricesIncludeTax: true,
        ),
      );
      final inclusiveOrder = await store.completeCashSale(
        items: [OrderLineItem(product: product, quantity: 1)],
        cashTendered: 1000,
        cashierName: 'Cashier',
        registerName: 'POS-01',
      );
      expect(inclusiveOrder.total, 1000);
    });

    test('StaffCredentials uses PBKDF2-SHA256 and still verifies legacy hashes',
        () {
      final creds = StaffCredentials.hashPassword('secret123');
      expect(creds.hash, startsWith('pbkdf2_sha256\$'));
      expect(
        StaffCredentials.verifyPassword(
          'secret123',
          salt: creds.salt,
          hash: creds.hash,
        ),
        isTrue,
      );
      expect(
        StaffCredentials.verifyPassword(
          'wrongpass',
          salt: creds.salt,
          hash: creds.hash,
        ),
        isFalse,
      );

      const legacySalt = 'legacy-salt';
      final legacyHash =
          sha256.convert(utf8.encode('$legacySalt:secret123')).toString();
      expect(
        StaffCredentials.verifyPassword(
          'secret123',
          salt: legacySalt,
          hash: legacyHash,
        ),
        isTrue,
      );
    });

    test('currentUser returns null when signed-in staff member is deleted',
        () async {
      await store.saveStaffRole(const StaffRoleData(
        id: 'owner',
        title: 'Owner',
        subtitle: 'All access',
        permissions: ['View Sales', 'Discounts', 'Process Returns'],
        sortOrder: 0,
      ));
      await store.addStaffMember(
        name: 'Alice',
        email: 'alice@example.test',
        phone: '0700000001',
        roleId: 'owner',
        username: 'alice',
        password: 'password123',
      );
      await store.saveStaffRole(const StaffRoleData(
        id: 'cashier',
        title: 'Cashier',
        subtitle: 'POS only',
        permissions: ['View Sales', 'Manage Staff'],
        sortOrder: 1,
      ));
      final cashier = await store.addStaffMember(
        name: 'Bob',
        email: 'bob@example.test',
        phone: '0700000002',
        roleId: 'cashier',
        username: 'bob',
        password: 'password123',
      );

      expect(await store.login('bob', 'password123'), isTrue);
      expect(store.currentUser?.id, cashier.id);

      await store.deleteStaffMember(cashier.id);
      expect(store.currentUser, isNull);
    });

    test('cashier without permissions cannot apply discounts or void orders',
        () async {
      await addProduct(
        code: 'P200',
        name: 'Juice',
        sellingPrice: 500,
        stockCount: 10,
      );
      await store.saveStaffRole(const StaffRoleData(
        id: 'cashier',
        title: 'Cashier',
        subtitle: 'POS only',
        permissions: ['View Sales'],
        sortOrder: 0,
      ));
      await store.addStaffMember(
        name: 'Bob',
        email: 'bob@example.test',
        phone: '0700000002',
        roleId: 'cashier',
        username: 'bob',
        password: 'password123',
      );
      expect(await store.login('bob', 'password123'), isTrue);

      final product = store.products.single;
      await expectLater(
        () => store.completeCashSale(
          items: [OrderLineItem(product: product, quantity: 1)],
          cashTendered: 500,
          cashierName: 'Bob',
          registerName: 'POS-01',
          discountAmount: 50,
        ),
        throwsStateError,
      );

      final order = await store.completeCashSale(
        items: [OrderLineItem(product: product, quantity: 1)],
        cashTendered: 500,
        cashierName: 'Bob',
        registerName: 'POS-01',
      );

      await expectLater(
        () => store.voidOrder(order.id),
        throwsStateError,
      );
      expect(store.orders, hasLength(1));
    });
  });
}
