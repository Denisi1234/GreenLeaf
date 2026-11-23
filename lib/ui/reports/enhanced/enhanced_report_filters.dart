part of '../enhanced_report_page.dart';

extension _EnhancedReportFilters on _EnhancedReportPageState {
  List<int> _visibleColumnIndexes(ReportTable table) => [
        for (var i = 0; i < table.columns.length; i++)
          if (!_hiddenColumns.contains(table.columns[i].label)) i,
      ];

  bool _isCostProfit(String label) =>
      RegExp(r'cost|profit', caseSensitive: false).hasMatch(label);

  bool _hasCostProfitColumns(ReportTable table) =>
      table.columns.any((column) => _isCostProfit(column.label));

  List<String> _costProfitLabels(ReportTable table) => [
        for (final column in table.columns)
          if (_isCostProfit(column.label)) column.label,
      ];

  bool _costProfitHidden(ReportTable table) {
    final labels = _costProfitLabels(table);
    return labels.isNotEmpty && labels.every(_hiddenColumns.contains);
  }

  List<List<Object?>> _processedRows(ReportTable table) {
    var rows = table.rows;
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      rows = rows
          .where((row) => row.any((cell) =>
              cell?.toString().toLowerCase().contains(query) ?? false))
          .toList();
    }
    final sort = _sortColumn;
    if (sort != null) {
      final sorted = [...rows];
      sorted.sort((a, b) {
        final av = sort < a.length ? a[sort] : null;
        final bv = sort < b.length ? b[sort] : null;
        final int cmp;
        if (av is num && bv is num) {
          cmp = av.compareTo(bv);
        } else if (av == null && bv == null) {
          cmp = 0;
        } else if (av == null) {
          cmp = -1;
        } else if (bv == null) {
          cmp = 1;
        } else {
          cmp = av
              .toString()
              .toLowerCase()
              .compareTo(bv.toString().toLowerCase());
        }
        return _sortAscending ? cmp : -cmp;
      });
      rows = sorted;
    }
    return rows;
  }

  DateTime _earliestActivityDate() {
    final store = context.read<PosLocalStore>();
    DateTime? earliest;

    void checkDate(DateTime? d) {
      if (d == null) return;
      final day = DateTime(d.year, d.month, d.day);
      if (earliest == null || day.isBefore(earliest!)) {
        earliest = day;
      }
    }

    for (final order in store.orders) {
      checkDate(DateTime.tryParse(order.dateTime)?.toLocal());
    }
    for (final expense in store.expenses) {
      checkDate(expense.date);
    }
    for (final shift in store.registerShifts) {
      checkDate(shift.openedAt.toLocal());
    }
    for (final customer in store.customers) {
      checkDate(customer.createdAt.toLocal());
    }
    for (final receiving in store.receivings) {
      checkDate(receiving.date);
    }
    for (final tx in store.bankTransactions) {
      checkDate(tx.date);
    }

    final now = DateTime.now();
    return earliest ?? DateTime(now.year, 1, 1);
  }

  Future<void> _chooseRange() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final earliest = _earliestActivityDate();
    final firstDate = earliest.isBefore(today)
        ? earliest
        : today.subtract(const Duration(days: 365));

    final range = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate:
          today.isAfter(_range?.end ?? today) ? today : (_range?.end ?? today),
      initialDateRange: _range,
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
    if (!mounted || range == null) return;
    _updateState(() {
      _range = range;
      _selectedPreset = null;
      _selection = null;
      _page = 0;
    });
  }

  void _applyPreset(PresetPeriod preset) {
    _updateState(() => _selectedPreset = preset);
    final today = DateUtils.dateOnly(DateTime.now());
    DateTime start;
    DateTime end = today;
    switch (preset) {
      case PresetPeriod.today:
        start = today;
        break;
      case PresetPeriod.yesterday:
        start = today.subtract(const Duration(days: 1));
        end = start;
        break;
      case PresetPeriod.last7Days:
        start = today.subtract(const Duration(days: 6));
        break;
      case PresetPeriod.last30Days:
        start = today.subtract(const Duration(days: 29));
        break;
      case PresetPeriod.thisMonth:
        start = DateTime(today.year, today.month, 1);
        break;
      case PresetPeriod.lastMonth:
        final firstThisMonth = DateTime(today.year, today.month, 1);
        start = DateTime(firstThisMonth.year, firstThisMonth.month - 1, 1);
        end = DateTime(firstThisMonth.year, firstThisMonth.month, 0);
        break;
      case PresetPeriod.thisQuarter:
        final quarter = ((today.month - 1) ~/ 3) + 1;
        start = DateTime(today.year, (quarter - 1) * 3 + 1, 1);
        break;
      case PresetPeriod.lastQuarter:
        final quarter = ((today.month - 1) ~/ 3) + 1;
        final firstThisQuarter = DateTime(today.year, (quarter - 1) * 3 + 1, 1);
        start = DateTime(firstThisQuarter.year, firstThisQuarter.month - 3, 1);
        end = DateTime(firstThisQuarter.year, firstThisQuarter.month, 0);
        break;
      case PresetPeriod.thisYear:
        start = DateTime(today.year, 1, 1);
        break;
      case PresetPeriod.lastYear:
        start = DateTime(today.year - 1, 1, 1);
        end = DateTime(today.year - 1, 12, 31);
        break;
      case PresetPeriod.allTime:
        start = _earliestActivityDate();
        break;
    }
    _updateState(() {
      _range = DateTimeRange(start: start, end: end);
      _selection = null;
      _page = 0;
    });
  }

  void _clearFilters() {
    _searchController.clear();
    _updateState(() {
      _searchQuery = '';
      _selection = null;
      _range = null;
      _selectedPreset = PresetPeriod.allTime;
      _page = 0;
    });
  }

  (Widget Function(), String, IconData)? get _setupAction {
    final data = widget.report.data;
    switch (data) {
      case ReportData.cashUp:
      case ReportData.shifts:
        return (
          () => const CashRegisterPage(),
          'Open cash register',
          Icons.point_of_sale_outlined
        );
      case ReportData.suppliers:
      case ReportData.supplierDetail:
      case ReportData.receivings:
        return (
          () => const SuppliersPage(),
          'Add supplier',
          Icons.local_shipping_outlined
        );
      case ReportData.taxes:
      case ReportData.salesTaxes:
      case ReportData.taxCompliance:
        return (
          () => const TaxSettingsPage(),
          'Open tax settings',
          Icons.percent_rounded
        );
      case ReportData.trialBalance:
      case ReportData.balanceSheet:
      case ReportData.cashFlow:
        return (
          () => const AccountsPage(),
          'Open chart of accounts',
          Icons.account_balance_outlined
        );
      case ReportData.assets:
        return (
          () => const FixedAssetsPage(),
          'Add fixed asset',
          Icons.chair_outlined
        );
      case ReportData.bank:
      case ReportData.reconciliation:
        return (
          () => const BankReconciliationPage(),
          'Import statement',
          Icons.account_balance_wallet_outlined
        );
      default:
        return null;
    }
  }
}
