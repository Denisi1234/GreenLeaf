import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../service/expense_model.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_expense_page.dart';

class ExpensesTrackingPage extends StatefulWidget {
  const ExpensesTrackingPage({super.key});

  @override
  State<ExpensesTrackingPage> createState() => _ExpensesTrackingPageState();
}

class _ExpensesTrackingPageState extends State<ExpensesTrackingPage> {
  String _search = '';
  String _paymentFilter = 'All';
  _ExpenseRange _range = _ExpenseRange.thisMonth;
  DateTimeRange? _customRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Consumer<PosLocalStore>(
          builder: (context, store, _) {
            final all = List<Expense>.from(store.expenses)
              ..sort((a, b) => b.date.compareTo(a.date));
            final inRange = _applyRange(all);
            final payments = <String>{
              'All',
              ...all.map((e) => e.paymentMethod).where((e) => e.trim().isNotEmpty),
            }.toList()
              ..sort();
            final filtered = inRange.where((e) {
              final q = _search.trim().toLowerCase();
              final matchesSearch = q.isEmpty ||
                  e.title.toLowerCase().contains(q) ||
                  e.category.toLowerCase().contains(q) ||
                  e.paymentMethod.toLowerCase().contains(q) ||
                  (e.notes ?? '').toLowerCase().contains(q);
              final matchesPayment =
                  _paymentFilter == 'All' || e.paymentMethod == _paymentFilter;
              return matchesSearch && matchesPayment;
            }).toList();
            final total = filtered.fold<double>(0, (s, e) => s + e.amount);
            final byPayment = <String, double>{};
            for (final e in filtered) {
              final k = e.paymentMethod.trim().isEmpty ? 'Unspecified' : e.paymentMethod;
              byPayment[k] = (byPayment[k] ?? 0) + e.amount;
            }
            final paymentSummary = byPayment.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Column(
              children: [
                MarketPageHeader(
                  title: 'Expenses',
                  subtitle: 'Track and review recorded expenses',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Add expense',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => const AddExpensePage()),
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _SummaryCard(
                        total: total,
                        count: filtered.length,
                        rangeLabel: _rangeLabel(),
                        onPickRange: _pickRange,
                        onPickCustom: _pickCustomRange,
                      ),
                      const SizedBox(height: 12),
                      _FilterCard(
                        search: _search,
                        paymentFilter: _paymentFilter,
                        payments: payments,
                        onSearchChanged: (v) => setState(() => _search = v),
                        onPaymentChanged: (v) => setState(() => _paymentFilter = v),
                      ),
                      if (paymentSummary.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _PaymentSummaryCard(items: paymentSummary),
                      ],
                      const SizedBox(height: 16),
                      MarketSectionHeader(
                        title: 'Expense Records',
trailing: Text(
                          '${filtered.length} entr${filtered.length == 1 ? 'y' : 'ies'}',
                          style: AppTypography.helperText
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (filtered.isEmpty)
                        const _EmptyState()
                      else
                        MarketSurfaceCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              const _TableHeader(),
                              const Divider(height: 1, color: AppColors.border),
                              for (var i = 0; i < filtered.length; i++) ...[
                                _ExpenseRow(
                                  expense: filtered[i],
                                  onTap: () => _showExpense(context, filtered[i]),
                                  onDelete: filtered[i].id == null
                                      ? null
                                      : () => _confirmDelete(context, store, filtered[i]),
                                ),
                                if (i != filtered.length - 1)
const Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: AppColors.borderLight),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AddExpensePage()),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  List<Expense> _applyRange(List<Expense> items) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    switch (_range) {
      case _ExpenseRange.today:
        start = DateTime(now.year, now.month, now.day);
        end = start.add(const Duration(days: 1));
        break;
      case _ExpenseRange.thisWeek:
        start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        end = start.add(const Duration(days: 7));
        break;
      case _ExpenseRange.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1);
        break;
      case _ExpenseRange.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 1);
        break;
      case _ExpenseRange.all:
        return items;
      case _ExpenseRange.custom:
        if (_customRange == null) return items;
        start = DateTime(_customRange!.start.year, _customRange!.start.month,
            _customRange!.start.day);
        end = DateTime(_customRange!.end.year, _customRange!.end.month,
                _customRange!.end.day)
            .add(const Duration(days: 1));
        break;
    }
    return items
        .where((e) => !e.date.isBefore(start) && e.date.isBefore(end))
        .toList();
  }

  String _rangeLabel() {
    if (_range == _ExpenseRange.custom && _customRange != null) {
      final f = DateFormat('MMM d, yyyy');
      return '${f.format(_customRange!.start)} - ${f.format(_customRange!.end)}';
    }
    return _range.label;
  }

  Future<void> _pickRange() async {
    final selected = await showModalBottomSheet<_ExpenseRange>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('Select period', style: AppTypography.cardHeader),
            const SizedBox(height: 8),
            for (final r in _ExpenseRange.values)
              ListTile(
                title: Text(r.label, style: AppTypography.bodyMedium),
                trailing: r == _range
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(r),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected == null) return;
    setState(() => _range = selected);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _customRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                surface: AppColors.surface,
                onSurface: AppColors.ink,
              ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _range = _ExpenseRange.custom;
    });
  }

  Future<void> _showExpense(BuildContext context, Expense expense) async {
    final fmt = DateFormat('MMM d, yyyy');
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(expense.title, style: AppTypography.h3.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
Text('TSH ${NumberFormat('#,##0.00').format(expense.amount)}',
                  style: AppTypography.h2
                      .copyWith(color: AppColors.danger, fontSize: 22)),
              const SizedBox(height: 16),
              _DetailRow(label: 'Date', value: fmt.format(expense.date)),
              _DetailRow(label: 'Category', value: expense.category),
              _DetailRow(label: 'Payment', value: expense.paymentMethod),
              if ((expense.notes ?? '').trim().isNotEmpty)
                _DetailRow(label: 'Notes', value: expense.notes!.trim()),
              const SizedBox(height: 8),
              if (expense.id != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _confirmDelete(context, context.read<PosLocalStore>(), expense);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete expense'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

Future<void> _confirmDelete(
      BuildContext ctx, PosLocalStore store, Expense expense) async {
    if (expense.id == null) return;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete expense?', style: AppTypography.cardHeader),
        content: Text('This will remove "${expense.title}" from recorded expenses.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await store.deleteExpense(expense.id!);
    if (!mounted) return;
    showMarketNotice(context,
        title: 'Expense deleted', message: 'The expense record was removed.');
  }
}

enum _ExpenseRange { today, thisWeek, thisMonth, lastMonth, all, custom }

extension on _ExpenseRange {
  String get label => switch (this) {
        _ExpenseRange.today => 'Today',
        _ExpenseRange.thisWeek => 'This week',
        _ExpenseRange.thisMonth => 'This month',
        _ExpenseRange.lastMonth => 'Last month',
        _ExpenseRange.all => 'All time',
        _ExpenseRange.custom => 'Custom range',
      };
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.total,
    required this.count,
    required this.rangeLabel,
    required this.onPickRange,
    required this.onPickCustom,
  });
  final double total;
  final int count;
  final String rangeLabel;
  final VoidCallback onPickRange;
  final VoidCallback onPickCustom;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL EXPENSES',
                        style: AppTypography.label
                            .copyWith(color: AppColors.textMuted, fontSize: 11)),
                    const SizedBox(height: 6),
Text('TSH ${NumberFormat('#,##0.00').format(total)}',
                        style: AppTypography.h2.copyWith(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text('$count record${count == 1 ? '' : 's'} · $rangeLabel',
                        style: AppTypography.helperText
                            .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.danger),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickRange,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Period'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPickCustom,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.date_range_rounded, size: 18),
                  label: const Text('Date range'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.search,
    required this.paymentFilter,
    required this.payments,
    required this.onSearchChanged,
    required this.onPaymentChanged,
  });
  final String search;
  final String paymentFilter;
  final List<String> payments;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onPaymentChanged;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search title, category, notes...',
              hintStyle:
                  AppTypography.bodySmall.copyWith(color: AppColors.textLight),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 20),
              isDense: true,
              filled: true,
              fillColor: AppColors.surfaceSecondary,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.payments_outlined,
                  size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
Text('Payment',
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: payments.contains(paymentFilter) ? paymentFilter : 'All',
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: payments
                          .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p, style: AppTypography.bodySmall)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) onPaymentChanged(v);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({required this.items});
  final List<MapEntry<String, double>> items;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment summary',
              style: AppTypography.label
                  .copyWith(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 10),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(e.key,
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textMedium))),
                    Text('TSH ${NumberFormat('#,##0.00').format(e.value)}',
                        style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: Text('EXPENSE',
                  style: AppTypography.label
                      .copyWith(color: AppColors.textMuted, fontSize: 10))),
          Expanded(
              flex: 3,
              child: Text('CATEGORY',
                  style: AppTypography.label
                      .copyWith(color: AppColors.textMuted, fontSize: 10))),
          Expanded(
              flex: 3,
              child: Text('AMOUNT',
                  textAlign: TextAlign.right,
                  style: AppTypography.label
                      .copyWith(color: AppColors.textMuted, fontSize: 10))),
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.onTap, this.onDelete});
  final Expense expense;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${fmt.format(expense.date)} · ${expense.paymentMethod}',
style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Text(expense.category,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMedium)),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TSH ${NumberFormat('#,##0').format(expense.amount)}',
                      style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w800, color: AppColors.ink)),
                  if (onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
child: Text('Delete',
                            style: AppTypography.helperText
                                .copyWith(color: AppColors.danger)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
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
            width: 90,
child: Text(label,
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          Expanded(
              child: Text(value,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.ink, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: AppColors.textLight, size: 32),
          ),
          const SizedBox(height: 14),
Text('No expenses found',
              style: AppTypography.cardHeader.copyWith(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            'Add an expense or adjust filters to see records here.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
