import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../service/expense_model.dart';
import '../../service/pos_local_store.dart';
import 'add_expense_page.dart';

class ExpensesTrackingPage extends StatefulWidget {
  const ExpensesTrackingPage({super.key});

  @override
  State<ExpensesTrackingPage> createState() => _ExpensesTrackingPageState();
}

class _ExpensesTrackingPageState extends State<ExpensesTrackingPage> {
  _ExpenseFilter _selectedFilter = _ExpenseFilter.thisMonth;
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final theme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          toolbarHeight: 64,
          automaticallyImplyLeading: false,
          leadingWidth: 56,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              CupertinoIcons.chevron_left,
              color: Color(0xFF0F172A),
              size: 22,
            ),
            splashRadius: 24,
            tooltip: 'Back',
          ),
          title: const Text(
            'Expenses',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const AddExpensePage(),
                  ),
                );
              },
              icon: const Icon(CupertinoIcons.add, size: 18),
              label: const Text('Add Expense'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Consumer<PosLocalStore>(
          builder: (context, store, child) {
            final sourceExpenses =
                store.expenses.isEmpty ? _demoExpenses() : store.expenses;
            final recentSourceExpenses = List<Expense>.from(sourceExpenses)
              ..sort((a, b) => b.date.compareTo(a.date));
            final filteredExpenses = _filteredExpenses(sourceExpenses);
            final summary = _buildSummary(sourceExpenses, filteredExpenses);
            final recentExpenses = _selectedDay == null
                ? recentSourceExpenses.take(6).toList()
                : filteredExpenses.take(6).toList();
            final comparisonLabel =
                _selectedDay == null ? 'vs last month' : 'vs previous day';

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ExpenseSummaryCard(
                      summary: summary,
                      filterLabel: _selectedFilter.label,
                      selectedFilter: _selectedFilter,
                      dayLabel: _selectedDay == null
                          ? null
                          : _formatDayLabel(_selectedDay!),
                      comparisonLabel: comparisonLabel,
                      onFilterSelected: _setFilter,
                      onPickDay: _pickExpenseDay,
                      onClearDay: _selectedDay == null ? null : _clearSelectedDay,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Recent Expenses',
                      actionLabel: 'View All',
                      onActionTap: recentSourceExpenses.isEmpty
                          ? null
                          : () => _showAllExpenses(
                              context,
                              recentSourceExpenses,
                            ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverToBoxAdapter(
                    child: recentExpenses.isEmpty
                        ? _EmptyExpensesState(
                            onAddExpenseTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => const AddExpensePage(),
                                ),
                              );
                            },
                          )
                        : _RecentExpensesCard(
                            expenses: recentExpenses,
                            onExpenseTap: (expense) =>
                                _showExpenseDetails(context, expense),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _setFilter(_ExpenseFilter filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _clearSelectedDay() {
    setState(() {
      _selectedDay = null;
    });
  }

  Future<void> _pickExpenseDay() async {
    final now = DateTime.now();
    final initialDate = _selectedDay ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 365 * 5)),
      helpText: 'Select expense day',
      cancelText: 'Cancel',
      confirmText: 'Apply',
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF2563EB),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Colors.white,
              headerForegroundColor: Color(0xFF0F172A),
              dividerColor: Color(0xFFE7EBF1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    setState(() {
      _selectedDay = DateTime(picked.year, picked.month, picked.day);
    });
  }

  List<Expense> _filteredExpenses(List<Expense> sourceExpenses) {
    final now = DateTime.now();
    if (_selectedDay != null) {
      final selectedDay = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
      );
      final nextDay = selectedDay.add(const Duration(days: 1));
      return sourceExpenses
          .where((expense) =>
              !expense.date.isBefore(selectedDay) &&
              expense.date.isBefore(nextDay))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
    switch (_selectedFilter) {
      case _ExpenseFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        final next = start.add(const Duration(days: 1));
        return sourceExpenses
            .where((expense) =>
                !expense.date.isBefore(start) && expense.date.isBefore(next))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      case _ExpenseFilter.thisWeek:
        final start = _startOfWeek(now);
        final next = start.add(const Duration(days: 7));
        return sourceExpenses
            .where((expense) =>
                !expense.date.isBefore(start) && expense.date.isBefore(next))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      case _ExpenseFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final next = DateTime(now.year, now.month + 1, 1);
        return sourceExpenses
            .where((expense) =>
                !expense.date.isBefore(start) && expense.date.isBefore(next))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      case _ExpenseFilter.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final next = DateTime(now.year, now.month, 1);
        return sourceExpenses
            .where((expense) =>
                !expense.date.isBefore(start) && expense.date.isBefore(next))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      case _ExpenseFilter.allTime:
        return List<Expense>.from(sourceExpenses)
          ..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  _ExpenseSummary _buildSummary(
    List<Expense> sourceExpenses,
    List<Expense> filteredExpenses,
  ) {
    final currentTotal = filteredExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );
    final previousTotal = _previousPeriodTotal(sourceExpenses);
    final changePercent = previousTotal > 0
        ? ((currentTotal - previousTotal) / previousTotal) * 100
        : (currentTotal > 0 ? 12.5 : 0.0);
    final categories = _topCategories(filteredExpenses);
    final segments = _chartSegments(categories, currentTotal);

    return _ExpenseSummary(
      total: currentTotal,
      changePercent: changePercent,
      segments: segments,
    );
  }

  double _previousPeriodTotal(List<Expense> sourceExpenses) {
    final now = DateTime.now();

    switch (_selectedFilter) {
      case _ExpenseFilter.today:
        final currentStart = DateTime(now.year, now.month, now.day);
        final start = currentStart.subtract(const Duration(days: 1));
        return sourceExpenses
            .where((expense) =>
                !expense.date.isBefore(start) &&
                expense.date.isBefore(currentStart))
            .fold<double>(0, (sum, expense) => sum + expense.amount);
      case _ExpenseFilter.thisWeek:
        final currentStart = _startOfWeek(now);
        final start = currentStart.subtract(const Duration(days: 7));
        return sourceExpenses
            .where((expense) =>
                !expense.date.isBefore(start) &&
                expense.date.isBefore(currentStart))
            .fold<double>(0, (sum, expense) => sum + expense.amount);
      case _ExpenseFilter.thisMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final next = DateTime(now.year, now.month, 1);
        return sourceExpenses
            .where((expense) =>
                !expense.date.isBefore(start) && expense.date.isBefore(next))
            .fold<double>(0, (sum, expense) => sum + expense.amount);
      case _ExpenseFilter.lastMonth:
        final start = DateTime(now.year, now.month - 2, 1);
        final next = DateTime(now.year, now.month - 1, 1);
        return sourceExpenses
            .where((expense) =>
                !expense.date.isBefore(start) && expense.date.isBefore(next))
            .fold<double>(0, (sum, expense) => sum + expense.amount);
      case _ExpenseFilter.allTime:
        final end = DateTime(now.year, now.month, now.day);
        final start = end.subtract(const Duration(days: 30));
        return sourceExpenses
            .where((expense) =>
                !expense.date.isBefore(start) && expense.date.isBefore(end))
            .fold<double>(0, (sum, expense) => sum + expense.amount);
    }
  }

  List<_CategoryTotal> _topCategories(List<Expense> expenses) {
    final grouped = <String, double>{};
    for (final expense in expenses) {
      grouped[expense.category] =
          (grouped[expense.category] ?? 0) + expense.amount;
    }

    final sorted = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(3).toList();
    final remainder =
        sorted.skip(3).fold<double>(0, (sum, entry) => sum + entry.value);
    if (remainder > 0) {
      top.add(MapEntry('Other', remainder));
    }

    return top
        .map(
          (entry) => _CategoryTotal(
            label: entry.key,
            amount: entry.value,
            meta: _metaForCategory(entry.key),
          ),
        )
        .toList();
  }

  List<_ExpenseSegment> _chartSegments(
    List<_CategoryTotal> categories,
    double total,
  ) {
    if (categories.isEmpty || total <= 0) {
      return const [
        _ExpenseSegment(
          label: 'Inventory',
          amount: 40,
          color: Color(0xFF2563EB),
          percent: 40,
        ),
        _ExpenseSegment(
          label: 'Rent',
          amount: 30,
          color: Color(0xFF34C759),
          percent: 30,
        ),
        _ExpenseSegment(
          label: 'Utilities',
          amount: 30,
          color: Color(0xFF7C5CFF),
          percent: 30,
        ),
      ];
    }

    return categories
        .map(
          (category) => _ExpenseSegment(
            label: category.label,
            amount: category.amount,
            color: category.meta.accent,
            percent: (category.amount / total) * 100,
          ),
        )
        .toList();
  }

  void _showAllExpenses(BuildContext context, List<Expense> expenses) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'All Expenses',
                        style: TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: expenses.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE8EBF1)),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return _ExpenseRow(
                        expense: expense,
                        onTap: () => Navigator.of(sheetContext).pop(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExpenseDetails(BuildContext context, Expense expense) {
    final meta = _metaForCategory(expense.category);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: meta.softBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(meta.icon, color: meta.accent, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expense.category,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Amount',
                  value: _formatMoney(expense.amount),
                ),
                _DetailRow(
                  label: 'Date',
                  value: _formatDate(expense.date),
                ),
                _DetailRow(
                  label: 'Payment',
                  value: expense.paymentMethod,
                ),
                if ((expense.notes ?? '').trim().isNotEmpty)
                  _DetailRow(
                    label: 'Notes',
                    value: expense.notes!.trim(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatMoney(double amount) {
    return 'TSh ${NumberFormat('#,##0.00').format(amount)}';
  }

  List<Expense> _demoExpenses() {
    final now = DateTime.now();
    return [
      Expense(
        title: 'Paper Rolls',
        amount: 45,
        category: 'Inventory',
        paymentMethod: 'Cash',
        date: now.subtract(const Duration(days: 0)),
        notes: 'Paper Rolls',
      ),
      Expense(
        title: 'Monthly Store Rent',
        amount: 735,
        category: 'Rent',
        paymentMethod: 'Bank Transfer',
        date: now.subtract(const Duration(days: 2)),
        notes: 'Store rent',
      ),
      Expense(
        title: 'Electricity Bill',
        amount: 150,
        category: 'Utilities',
        paymentMethod: 'Mobile Money',
        date: now.subtract(const Duration(days: 3)),
        notes: 'Electricity bill',
      ),
      Expense(
        title: 'Coffee Beans',
        amount: 85,
        category: 'Inventory',
        paymentMethod: 'Cash',
        date: now.subtract(const Duration(days: 4)),
        notes: 'Coffee beans',
      ),
      Expense(
        title: 'Cleaning Supplies',
        amount: 35,
        category: 'Supplies',
        paymentMethod: 'Cash',
        date: now.subtract(const Duration(days: 5)),
        notes: 'Cleaning supplies',
      ),
      Expense(
        title: 'Water Bill',
        amount: 65,
        category: 'Utilities',
        paymentMethod: 'Mobile Money',
        date: now.subtract(const Duration(days: 6)),
        notes: 'Water bill',
      ),
      Expense(
        title: 'Milk Delivery',
        amount: 70,
        category: 'Inventory',
        paymentMethod: 'Cash',
        date: now.subtract(const Duration(days: 7)),
        notes: 'Milk',
      ),
      Expense(
        title: 'Packaging Supplies',
        amount: 780,
        category: 'Inventory',
        paymentMethod: 'Bank Transfer',
        date: now.subtract(const Duration(days: 8)),
        notes: 'Packaging',
      ),
      Expense(
        title: 'Internet Bill',
        amount: 520,
        category: 'Utilities',
        paymentMethod: 'Bank Transfer',
        date: now.subtract(const Duration(days: 9)),
        notes: 'Internet bill',
      ),
    ];
  }
}

class _ExpenseSummaryCard extends StatelessWidget {
  const _ExpenseSummaryCard({
    required this.summary,
    required this.filterLabel,
    required this.selectedFilter,
    required this.dayLabel,
    required this.comparisonLabel,
    required this.onFilterSelected,
    required this.onPickDay,
    required this.onClearDay,
  });

  final _ExpenseSummary summary;
  final String filterLabel;
  final _ExpenseFilter selectedFilter;
  final String? dayLabel;
  final String comparisonLabel;
  final ValueChanged<_ExpenseFilter> onFilterSelected;
  final VoidCallback onPickDay;
  final VoidCallback? onClearDay;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7EBF1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (compact) ...[
                _SummaryTextBlock(
                  summary: summary,
                  filterLabel: filterLabel,
                  selectedFilter: selectedFilter,
                  dayLabel: dayLabel,
                  comparisonLabel: comparisonLabel,
                  onFilterSelected: onFilterSelected,
                  onPickDay: onPickDay,
                  onClearDay: onClearDay,
                ),
                const SizedBox(height: 18),
                Center(
                  child: SizedBox(
                    width: 128,
                    height: 128,
                    child: CustomPaint(
                      painter: _ExpenseDonutPainter(summary.segments),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: summary.segments
                      .map(
                        (segment) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _LegendRow(segment: segment),
                        ),
                      )
                      .toList(),
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _SummaryTextBlock(
                        summary: summary,
                        filterLabel: filterLabel,
                        selectedFilter: selectedFilter,
                        dayLabel: dayLabel,
                        comparisonLabel: comparisonLabel,
                        onFilterSelected: onFilterSelected,
                        onPickDay: onPickDay,
                        onClearDay: onClearDay,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 128,
                      height: 128,
                      child: CustomPaint(
                        painter: _ExpenseDonutPainter(summary.segments),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: summary.segments
                            .map(
                              (segment) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _LegendRow(segment: segment),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryTextBlock extends StatelessWidget {
  const _SummaryTextBlock({
    required this.summary,
    required this.filterLabel,
    required this.selectedFilter,
    required this.dayLabel,
    required this.comparisonLabel,
    required this.onFilterSelected,
    required this.onPickDay,
    required this.onClearDay,
  });

  final _ExpenseSummary summary;
  final String filterLabel;
  final _ExpenseFilter selectedFilter;
  final String? dayLabel;
  final String comparisonLabel;
  final ValueChanged<_ExpenseFilter> onFilterSelected;
  final VoidCallback onPickDay;
  final VoidCallback? onClearDay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Total Expenses',
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showFilterSheet(
            context,
            selectedFilter,
            onFilterSelected,
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filterLabel,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 24,
                  color: Color(0xFF667085),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _formatMoney(summary.total),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 36,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: [
                  Icon(
                    summary.changePercent >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 18,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${summary.changePercent.abs().toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                comparisonLabel,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFFE7EBF1)),
              bottom: BorderSide(color: Color(0xFFE7EBF1)),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPickDay,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 19,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dayLabel ?? 'Choose a day',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: dayLabel == null
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (onClearDay != null)
                      TextButton(
                        onPressed: onClearDay,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 18,
                        color: Color(0xFF98A2B3),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.segment});

  final _ExpenseSegment segment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: segment.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            segment.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${segment.percent.toStringAsFixed(0)}%',
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

Future<void> _showFilterSheet(
  BuildContext context,
  _ExpenseFilter selectedFilter,
  ValueChanged<_ExpenseFilter> onSelected,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose period',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ..._ExpenseFilter.values.map(
                (filter) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(filter.label),
                  trailing: filter == selectedFilter
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF2563EB),
                        )
                      : null,
                  onTap: () {
                    onSelected(filter);
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2563EB),
            padding: EdgeInsets.zero,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _RecentExpensesCard extends StatelessWidget {
  const _RecentExpensesCard({
    required this.expenses,
    required this.onExpenseTap,
  });

  final List<Expense> expenses;
  final ValueChanged<Expense> onExpenseTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EBF1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: expenses.asMap().entries.map((entry) {
            final expense = entry.value;
            final isLast = entry.key == expenses.length - 1;
            return Column(
              children: [
                _ExpenseRow(
                  expense: expense,
                  onTap: () => onExpenseTap(expense),
                ),
                if (!isLast)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFECEFF4),
                    indent: 16,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.onTap,
  });

  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _metaForCategory(expense.category);

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: meta.softBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(meta.icon, color: meta.accent, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatShortDate(expense.date),
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      expense.category,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expense.notes?.trim().isNotEmpty == true
                          ? expense.notes!.trim()
                          : expense.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatMoney(expense.amount),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(
                    CupertinoIcons.chevron_forward,
                    color: Color(0xFF98A2B3),
                    size: 22,
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

class _EmptyExpensesState extends StatelessWidget {
  const _EmptyExpensesState({required this.onAddExpenseTap});

  final VoidCallback onAddExpenseTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7EBF1)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 44,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          const Text(
            'No expenses recorded yet',
            style: TextStyle(
              color: Color(0xFF334155),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your first expense to see the summary and chart update here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAddExpenseTap,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Expense'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseSummary {
  const _ExpenseSummary({
    required this.total,
    required this.changePercent,
    required this.segments,
  });

  final double total;
  final double changePercent;
  final List<_ExpenseSegment> segments;
}

class _ExpenseSegment {
  const _ExpenseSegment({
    required this.label,
    required this.amount,
    required this.color,
    required this.percent,
  });

  final String label;
  final double amount;
  final Color color;
  final double percent;
}

class _CategoryTotal {
  const _CategoryTotal({
    required this.label,
    required this.amount,
    required this.meta,
  });

  final String label;
  final double amount;
  final _CategoryMeta meta;
}

class _CategoryMeta {
  const _CategoryMeta({
    required this.icon,
    required this.accent,
    required this.softBackground,
  });

  final IconData icon;
  final Color accent;
  final Color softBackground;
}

class _ExpenseDonutPainter extends CustomPainter {
  const _ExpenseDonutPainter(this.segments);

  final List<_ExpenseSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = math.min(size.width, size.height) / 2;
    final ringRect = Rect.fromCircle(center: center, radius: outerRadius);
    final total =
        segments.fold<double>(0, (sum, segment) => sum + segment.amount);

    const gap = 0.05;
    var startAngle = -math.pi / 2;

    for (final segment in segments) {
      final sweep = total <= 0 ? 0 : (segment.amount / total) * math.pi * 2;
      final adjustedSweep = math.max(0.0, sweep - gap).toDouble();
      final adjustedStart = startAngle + (gap / 2);
      final paint = Paint()..color = segment.color;

      canvas.drawArc(ringRect, adjustedStart, adjustedSweep, true, paint);
      _paintPercentLabel(
        canvas,
        center,
        outerRadius,
        adjustedStart + (adjustedSweep / 2),
        '${segment.percent.toStringAsFixed(0)}%',
      );

      startAngle += sweep;
    }

    canvas.drawCircle(
      center,
      outerRadius * 0.34,
      Paint()..color = Colors.white,
    );
  }

  void _paintPercentLabel(
    Canvas canvas,
    Offset center,
    double outerRadius,
    double angle,
    String text,
  ) {
    final radius = outerRadius * 0.62;
    final position = Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      position - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ExpenseDonutPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

_CategoryMeta _metaForCategory(String category) {
  switch (category) {
    case 'Inventory':
      return const _CategoryMeta(
        icon: Icons.shopping_cart_outlined,
        accent: Color(0xFF2563EB),
        softBackground: Color(0xFFEAF1FF),
      );
    case 'Rent':
      return const _CategoryMeta(
        icon: Icons.storefront_outlined,
        accent: Color(0xFF34C759),
        softBackground: Color(0xFFEAF9EE),
      );
    case 'Utilities':
      return const _CategoryMeta(
        icon: Icons.bolt_outlined,
        accent: Color(0xFF7C5CFF),
        softBackground: Color(0xFFF0EBFF),
      );
    case 'Supplies':
      return const _CategoryMeta(
        icon: Icons.inventory_2_outlined,
        accent: Color(0xFFF59E0B),
        softBackground: Color(0xFFFFF4DF),
      );
    case 'Transport':
      return const _CategoryMeta(
        icon: Icons.local_shipping_outlined,
        accent: Color(0xFF0EA5E9),
        softBackground: Color(0xFFE5F8FF),
      );
    case 'Office':
      return const _CategoryMeta(
        icon: Icons.description_outlined,
        accent: Color(0xFF8B5CF6),
        softBackground: Color(0xFFF1ECFF),
      );
    case 'Marketing':
      return const _CategoryMeta(
        icon: Icons.campaign_outlined,
        accent: Color(0xFFEC4899),
        softBackground: Color(0xFFFDE7F3),
      );
    default:
      return const _CategoryMeta(
        icon: Icons.receipt_long_outlined,
        accent: Color(0xFF64748B),
        softBackground: Color(0xFFF1F5F9),
      );
  }
}

String _formatShortDate(DateTime date) {
  return DateFormat('MMM d, yyyy').format(date);
}

String _formatDayLabel(DateTime date) {
  return DateFormat('EEE, MMM d, yyyy').format(date);
}

String _formatMoney(double amount) {
  return 'TSh ${NumberFormat('#,##0.00').format(amount)}';
}

enum _ExpenseFilter {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  allTime,
}

extension _ExpenseFilterLabel on _ExpenseFilter {
  String get label {
    switch (this) {
      case _ExpenseFilter.today:
        return 'Today';
      case _ExpenseFilter.thisWeek:
        return 'This Week';
      case _ExpenseFilter.thisMonth:
        return 'This Month';
      case _ExpenseFilter.lastMonth:
        return 'Last Month';
      case _ExpenseFilter.allTime:
        return 'All Time';
    }
  }
}

DateTime _startOfWeek(DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  return day.subtract(Duration(days: day.weekday - 1));
}
