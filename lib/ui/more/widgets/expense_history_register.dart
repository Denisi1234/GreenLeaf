import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_strings.dart';
import '../../../service/expense_model.dart';
import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';
import 'expense_cards.dart';
import 'expense_models.dart';

class ExpenseHistoryRegister extends StatelessWidget {
  const ExpenseHistoryRegister({
    super.key,
    required this.filtered,
    required this.strings,
    required this.store,
    required this.onShowExpense,
    required this.onEditExpense,
    required this.onConfirmDelete,
  });

  final List<Expense> filtered;
  final AppStrings strings;
  final PosLocalStore store;
  final void Function(BuildContext context, Expense expense) onShowExpense;
  final void Function(Expense expense) onEditExpense;
  final void Function(BuildContext context, PosLocalStore store, Expense expense) onConfirmDelete;

  @override
  Widget build(BuildContext context) {
    return WorkspaceRegister(
      columns: [
        DataColumn(label: Text(expenseDual(strings, 'Date', 'Tarehe'))),
        DataColumn(label: Text(expenseDual(strings, 'Expense', 'Matumizi'))),
        DataColumn(label: Text(expenseDual(strings, 'Category', 'Kundi'))),
        DataColumn(label: Text(expenseDual(strings, 'Payment', 'Malipo'))),
        DataColumn(label: Text(expenseDual(strings, 'Status', 'Hali'))),
        DataColumn(label: Text(expenseDual(strings, 'Total', 'Jumla')), numeric: true),
        const DataColumn(label: Text('')),
      ],
      rows: filtered
          .map((expense) => DataRow(cells: [
                DataCell(Text(DateFormat.yMMMd().format(expense.date))),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(expense.title, overflow: TextOverflow.ellipsis),
                  ),
                  onTap: () => onShowExpense(context, expense),
                ),
                DataCell(Text(expense.category)),
                DataCell(Text(expense.paymentMethod)),
                DataCell(WorkspaceStatus(
                    label: expense.status.localized(strings.isSwahili),
                    color: AppColors.textBody)),
                DataCell(Text(formatExpenseMoney(expense.totalWithTax))),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: expenseDual(strings, 'Edit expense', 'Badili matumizi'),
                      onPressed: () => onEditExpense(expense),
                      icon: const Icon(Icons.edit_outlined, size: 19),
                    ),
                    IconButton(
                      tooltip: expenseDual(strings, 'Delete expense', 'Futa matumizi'),
                      onPressed: expense.id == null
                          ? null
                          : () => onConfirmDelete(context, store, expense),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: AppColors.dangerDeep,
                      ),
                    ),
                  ],
                )),
              ]))
          .toList(),
      mobile: Column(
        children: [
          ...filtered.map(
            (expense) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ExpenseCard(
                expense: expense,
                strings: strings,
                onTap: () => onShowExpense(context, expense),
                onEdit: () => onEditExpense(expense),
                onDelete: expense.id == null
                    ? null
                    : () => onConfirmDelete(context, store, expense),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
