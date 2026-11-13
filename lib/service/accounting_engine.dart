import 'accounting_model.dart';
import 'expense_model.dart';
import 'expense_model.dart';
import 'pos_order_models.dart';
import 'register_shift_model.dart';
import 'supplier_model.dart';
import 'tax_settings.dart';

/// One derived ledger posting.
class LedgerPosting {
  final String accountCode;
  final String accountName;
  final AccountType type;
  final double debit;
  final double credit;

  const LedgerPosting({
    required this.accountCode,
    required this.accountName,
    required this.type,
    this.debit = 0,
    this.credit = 0,
  });

  double get balance => debit - credit;
}

class TrialBalanceRow {
  final String code;
  final String name;
  final AccountType type;
  final double debit;
  final double credit;

  const TrialBalanceRow({
    required this.code,
    required this.name,
    required this.type,
    required this.debit,
    required this.credit,
  });
}

/// Turns POS activity into a simple, derived double-entry ledger.
class AccountingEngine {
  const AccountingEngine();

  static const String cashCode = '1000';
  static const String bankCode = '1010';
  static const String receivableCode = '1100';
  static const String inventoryCode = '1200';
  static const String fixedAssetsCode = '1500';
  static const String payableCode = '2000';
  static const String taxPayableCode = '2100';
  static const String equityCode = '3000';
  static const String salesCode = '4000';
  static const String cogsCode = '5000';
  static const String expenseCode = '6000';
  static const String depreciationCode = '7000';
  static const String drawingsCode = '8000';

  List<LedgerPosting> postings({
    required List<CompletedOrder> orders,
    required List<Expense> expenses,
    required List<Receiving> receivings,
    required List<Supplier> suppliers,
    required List<RegisterShift> shifts,
    required List<FixedAsset> fixedAssets,
    required List<JournalEntry> journalEntries,
    required List<Account> accounts,
    TaxSettings tax = const TaxSettings(),
  }) {
    final result = <LedgerPosting>[];
    void post(
      String code,
      AccountType type,
      double debit, [
      double credit = 0,
    ]) {
      if (debit == 0 && credit == 0) return;
      result.add(LedgerPosting(
        accountCode: code,
        accountName: _nameFor(code, accounts),
        type: type,
        debit: debit,
        credit: credit,
      ));
    }

    for (final order in orders) {
      if (order.status.trim().toLowerCase() != 'completed') continue;
      final total = order.total;
      final taxPart = tax.taxFromGross(total);
      final method = order.paymentMethod.toLowerCase();
      final toCash = method.contains('cash');
      final toCredit = method.contains('debt') ||
          method.contains('credit') ||
          method.contains('kopesh');
      if (toCredit) {
        post(receivableCode, AccountType.asset, total);
      } else {
        post(toCash ? cashCode : bankCode, AccountType.asset, total);
      }
      post(salesCode, AccountType.income, 0, total - taxPart);
      if (taxPart > 0) post(taxPayableCode, AccountType.liability, 0, taxPart);
      var cost = 0.0;
      for (final line in order.lines) {
        cost += (line.unitCost ?? 0.0) * line.quantity;
      }
      if (cost > 0) {
        post(cogsCode, AccountType.expense, cost);
        post(inventoryCode, AccountType.asset, 0, cost);
      }
    }

    for (final expense in expenses) {
      final method = expense.paymentMethod.toLowerCase();
      final expenseTax = expense.taxAmount;
      final net = expense.amount - expenseTax;
      if (net > 0) {
        post('$expenseCode-${expense.category}', AccountType.expense, net);
      }
      if (expenseTax > 0) {
        post(taxPayableCode, AccountType.liability, expenseTax);
      }
      post(
        method.contains('cash') ? cashCode : bankCode,
        AccountType.asset,
        0,
        expense.amount,
      );
    }

    for (final receiving in receivings) {
      post(inventoryCode, AccountType.asset, receiving.total);
      post(payableCode, AccountType.liability, 0, receiving.total);
    }

    for (final shift in shifts) {
      if (!shift.isOpen) continue;
      for (final movement in shift.movements) {
        if (movement.type.isOutflow) {
          post(cashCode, AccountType.asset, 0, movement.amount);
          post(drawingsCode, AccountType.equity, movement.amount);
        } else {
          post(cashCode, AccountType.asset, movement.amount);
          post(drawingsCode, AccountType.equity, 0, movement.amount);
        }
      }
    }

    for (final asset in fixedAssets) {
      final accumulated = asset.accumulatedDepreciation();
      post(fixedAssetsCode, AccountType.asset, asset.cost);
      post(equityCode, AccountType.equity, 0, asset.cost);
      if (accumulated > 0) {
        post(depreciationCode, AccountType.expense, accumulated);
        post(
            '$fixedAssetsCode-depreciation', AccountType.asset, 0, accumulated);
      }
    }

    for (final entry in journalEntries) {
      for (final line in entry.lines) {
        Account? account;
        for (final item in accounts) {
          if (item.id == line.accountId) {
            account = item;
            break;
          }
        }
        final code = account?.code ?? 'unknown';
        final type = account?.type ?? AccountType.expense;
        post('$code${account == null ? '?' : ''}', type, line.debit,
            line.credit);
      }
    }

    for (final account in accounts) {
      if (account.openingBalance == 0) continue;
      final debit = account.type == AccountType.asset ||
              account.type == AccountType.expense
          ? account.openingBalance
          : 0.0;
      final credit = debit == 0 ? account.openingBalance : 0.0;
      post(account.code, account.type, debit, credit);
    }

    return result;
  }

  static String _nameFor(String code, List<Account> accounts) {
    final base = code.split('-').first;
    for (final account in accounts) {
      if (account.code == base) {
        return code.contains('-')
            ? '${account.name} (${code.split('-').last})'
            : account.name;
      }
    }
    return code;
  }

  /// Groups postings into a trial balance.
  List<TrialBalanceRow> trialBalance(List<LedgerPosting> postings) {
    final grouped = <String, TrialBalanceRow>{};
    for (final posting in postings) {
      final existing = grouped[posting.accountCode];
      if (existing == null) {
        grouped[posting.accountCode] = TrialBalanceRow(
          code: posting.accountCode,
          name: posting.accountName,
          type: posting.type,
          debit: posting.debit,
          credit: posting.credit,
        );
        continue;
      }
      grouped[posting.accountCode] = TrialBalanceRow(
        code: existing.code,
        name: existing.name,
        type: existing.type,
        debit: existing.debit + posting.debit,
        credit: existing.credit + posting.credit,
      );
    }
    final rows = grouped.values.toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    return rows;
  }

  /// Balances assets minus liabilities per account type.
  static double totalByType(List<TrialBalanceRow> rows, AccountType type) {
    return rows
        .where((row) => row.type == type)
        .fold<double>(0, (sum, row) => sum + row.debit - row.credit);
  }
}
