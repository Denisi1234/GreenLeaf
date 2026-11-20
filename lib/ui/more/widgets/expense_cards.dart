import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/expense_model.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import 'expense_models.dart';

class ExpenseCategoryIcon extends StatelessWidget {
  const ExpenseCategoryIcon({super.key, required this.style, this.size = 40});

  final CategoryStyle style;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.zero,
      ),
      child: Icon(style.icon, color: style.color, size: size * 0.5),
    );
  }
}

class ExpenseStatusBadge extends StatelessWidget {
  const ExpenseStatusBadge({super.key, required this.status, required this.strings});

  final ExpenseStatus status;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ExpenseStatus.draft => AppColors.textMuted,
      ExpenseStatus.submitted => AppColors.primary,
      ExpenseStatus.approved => AppColors.success,
      ExpenseStatus.reimbursed => AppColors.successDeep,
    };
    final bg = switch (status) {
      ExpenseStatus.draft => AppColors.surfaceSecondary,
      ExpenseStatus.submitted => AppColors.surfaceSecondary,
      ExpenseStatus.approved => AppColors.successLight,
      ExpenseStatus.reimbursed => AppColors.successLight,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        status.localized(strings.isSwahili),
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({
    super.key,
    required this.expense,
    required this.strings,
    required this.onTap,
    required this.onEdit,
    this.onDelete,
  });

  final Expense expense;
  final AppStrings strings;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cat = CategoryStyle.forName(expense.category);
    final fmt = DateFormat('MMM d, yyyy');
    final hasReceipt =
        expense.receiptPath != null && expense.receiptPath!.isNotEmpty;
    return MarketSurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: const Color(0xFFD6E4F0),
      radius: 0,
      showShadow: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              ExpenseCategoryIcon(style: cat),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            expense.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyMain.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        ExpenseStatusBadge(status: expense.status, strings: strings),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Text(
                              expense.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cat.color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${fmt.format(expense.date)} · ${expense.paymentMethod}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.helperText.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (expense.vendor.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.storefront_outlined,
                              size: 12, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              expense.vendor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.helperText.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (hasReceipt) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.image_outlined,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            expenseDual(strings, 'Receipt attached',
                                'Risiti imeambatishwa'),
                            style: AppTypography.helperText.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if ((expense.notes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        expense.notes!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.helperText.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatExpenseMoney(expense.totalWithTax, compact: true),
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  if (expense.taxAmount > 0)
                    Text(
                      expenseDual(strings, 'incl. tax', 'pamoja na kodi'),
                      style: AppTypography.helperText.copyWith(
                        color: AppColors.textLight,
                        fontSize: 9.5,
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip:
                            expenseDual(strings, 'Edit expense', 'Hariri matumizi'),
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primary, size: 18),
                      ),
                      if (onDelete != null) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: onDelete,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip:
                              expenseDual(strings, 'Delete expense', 'Futa matumizi'),
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.textLight, size: 18),
                        ),
                      ],
                    ],
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

class ExpenseEmptyState extends StatelessWidget {
  const ExpenseEmptyState({
    super.key,
    required this.strings,
    required this.onAdd,
    this.isFiltered = false,
    this.onClearFilter,
  });

  final AppStrings strings;
  final VoidCallback onAdd;
  final bool isFiltered;
  final VoidCallback? onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(
                  isFiltered
                      ? Icons.search_off_rounded
                      : Icons.receipt_long_outlined,
                  color: AppColors.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isFiltered
                    ? expenseDual(strings, 'No matching expenses', 'Hakuna matumizi yanayolingana')
                    : expenseDual(strings, 'No expenses recorded yet', 'Hakuna matumizi yaliyorekodiwa bado'),
                textAlign: TextAlign.center,
                style: AppTypography.cardHeader.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isFiltered
                    ? expenseDual(
                        strings,
                        'Try searching by different title, vendor, category or clearing payment filters.',
                        'Jaribu kutafuta kwa jina lingine, muuzaji, kundi au kuondoa vichujio vya malipo.',
                      )
                    : expenseDual(
                        strings,
                        'Track operational costs, rent, utilities, staff wages, inventory purchases, and tax deductions in one place.',
                        'Fuatilia gharama za uendeshaji, kodi ya pango, bili, mishahara, na ununuzi wa hifadhi sehemu moja.',
                      ),
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (isFiltered)
                MarketButton(
                  label: expenseDual(strings, 'Clear search filter', 'Ondoa kichujio'),
                  icon: Icons.filter_alt_off_rounded,
                  isFullWidth: false,
                  isPrimary: false,
                  onTap: onClearFilter,
                )
              else
                MarketButton(
                  label: expenseDual(strings, 'Record first expense', 'Rekodi matumizi ya kwanza'),
                  icon: Icons.add_rounded,
                  isFullWidth: false,
                  onTap: onAdd,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddExpenseFloatingButton extends StatelessWidget {
  const AddExpenseFloatingButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        splashColor: AppColors.primaryDeep.withValues(alpha: 0.3),
        highlightColor: Colors.transparent,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
