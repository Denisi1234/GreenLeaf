import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/expense_model.dart';
import '../../widgets/app_design.dart';
import '../../widgets/app_image.dart';
import 'expense_cards.dart';
import 'expense_models.dart';

class ExpenseDetailRow extends StatelessWidget {
  const ExpenseDetailRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label,
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          Expanded(
              child: Text(value,
                  style: AppTypography.bodySmall.copyWith(
                      color: AppColors.ink, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class ExpenseDetailSheet extends StatelessWidget {
  const ExpenseDetailSheet({
    super.key,
    required this.expense,
    required this.strings,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final AppStrings strings;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static Future<void> show({
    required BuildContext context,
    required Expense expense,
    required AppStrings strings,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) => ExpenseDetailSheet(
        expense: expense,
        strings: strings,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    final cat = CategoryStyle.forName(expense.category);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ExpenseCategoryIcon(style: cat, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expense.title,
                            style: AppTypography.h3.copyWith(fontSize: 18)),
                        const SizedBox(height: 2),
                        Text(expense.category,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  ExpenseStatusBadge(status: expense.status, strings: strings),
                ],
              ),
              const SizedBox(height: 14),
              Text(formatExpenseMoney(expense.totalWithTax),
                  style: AppTypography.h2
                      .copyWith(color: AppColors.ink, fontSize: 24)),
              const SizedBox(height: 16),
              ExpenseDetailRow(
                  label: expenseDual(strings, 'Date', 'Tarehe'),
                  value: fmt.format(expense.date)),
              ExpenseDetailRow(
                  label: expenseDual(strings, 'Category', 'Kategoria'),
                  value: expense.category),
              ExpenseDetailRow(
                  label: expenseDual(strings, 'Payment', 'Malipo'),
                  value: expense.paymentMethod),
              ExpenseDetailRow(
                  label: expenseDual(strings, 'Vendor', 'Muuzaji'),
                  value: expense.vendor.trim().isEmpty
                      ? expenseDual(strings, 'Not set', 'Haijawekwa')
                      : expense.vendor),
              ExpenseDetailRow(
                  label: expenseDual(strings, 'Base amount', 'Kiasi msingi'),
                  value: formatExpenseMoney(expense.amount)),
              if (expense.taxAmount > 0)
                ExpenseDetailRow(
                    label: expenseDual(strings, 'Tax / VAT', 'Kodi / VAT'),
                    value: formatExpenseMoney(expense.taxAmount)),
              ExpenseDetailRow(
                  label: expenseDual(strings, 'Status', 'Hali'),
                  value: expense.status.localized(strings.isSwahili)),
              if ((expense.notes ?? '').trim().isNotEmpty)
                ExpenseDetailRow(
                    label: expenseDual(strings, 'Notes', 'Maelezo'),
                    value: expense.notes!.trim()),
              if (expense.receiptPath != null &&
                  expense.receiptPath!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(expenseDual(strings, 'Receipt', 'Risiti'),
                    style: AppTypography.helperText.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: Image(
                    image: appImageProvider(context, expense.receiptPath!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 60,
                      color: AppColors.surfaceSecondary,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: AppColors.textLight),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onEdit();
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(
                        expenseDual(strings, 'Edit', 'Hariri'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (expense.id != null)
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.kpiDangerBg,
                          foregroundColor: AppColors.kpiDanger,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDelete();
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: Text(
                          expenseDual(strings, 'Delete', 'Futa'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
