import 'package:flutter/material.dart';

import 'add_expense_page.dart';
import '../widgets/market_shared_widgets.dart';

class ExpensesTrackingPage extends StatelessWidget {
  const ExpensesTrackingPage({super.key});

  static const _dailyExpenses = <_ExpenseDayGroup>[
    _ExpenseDayGroup(
      label: 'Today',
      dateLabel: 'May 20, 2025',
      total: 'TSH 1,850,000',
      items: <_ExpenseItem>[
        _ExpenseItem(
          title: 'Supplier payment - Fresh Foods',
          category: 'Inventory',
          time: '9:20 AM',
          amount: 'TSH 1,250,000',
          icon: Icons.local_shipping_outlined,
        ),
        _ExpenseItem(
          title: 'Office refreshments',
          category: 'Operations',
          time: '1:45 PM',
          amount: 'TSH 120,000',
          icon: Icons.local_cafe_outlined,
        ),
        _ExpenseItem(
          title: 'Fuel reimbursement',
          category: 'Logistics',
          time: '4:10 PM',
          amount: 'TSH 480,000',
          icon: Icons.local_gas_station_outlined,
        ),
      ],
    ),
    _ExpenseDayGroup(
      label: 'Yesterday',
      dateLabel: 'May 19, 2025',
      total: 'TSH 920,000',
      items: <_ExpenseItem>[
        _ExpenseItem(
          title: 'Utility bill - Store electricity',
          category: 'Utilities',
          time: '10:15 AM',
          amount: 'TSH 420,000',
          icon: Icons.bolt_outlined,
        ),
        _ExpenseItem(
          title: 'Marketing flyer printing',
          category: 'Marketing',
          time: '2:30 PM',
          amount: 'TSH 180,000',
          icon: Icons.campaign_outlined,
        ),
        _ExpenseItem(
          title: 'Packaging materials',
          category: 'Operations',
          time: '5:05 PM',
          amount: 'TSH 320,000',
          icon: Icons.inventory_2_outlined,
        ),
      ],
    ),
    _ExpenseDayGroup(
      label: 'May 18, 2025',
      dateLabel: 'Saturday',
      total: 'TSH 405,000',
      items: <_ExpenseItem>[
        _ExpenseItem(
          title: 'Stationery restock',
          category: 'Office',
          time: '11:10 AM',
          amount: 'TSH 105,000',
          icon: Icons.edit_outlined,
        ),
        _ExpenseItem(
          title: 'Courier charges',
          category: 'Delivery',
          time: '3:00 PM',
          amount: 'TSH 300,000',
          icon: Icons.local_post_office_outlined,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF1E273A),
                        size: 30,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Expenses Tracking',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1E273A),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddExpensePage(),
                      ),
                    ),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        color: Color(0xFF1E273A),
                        size: 27,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDE2EA)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Color(0xFF7A8393),
                            size: 28,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Search expenses...',
                              style: TextStyle(
                                color: Color(0xFFABB2BF),
                                fontSize: 15.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => showMarketNotice(
                      context,
                      title: 'Filter',
                      message: 'Expense filters can be connected next',
                    ),
                    child: Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDDE2EA)),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Color(0xFF1E273A),
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E7EF)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: _DaySummaryCard(
                            label: 'Today',
                            value: 'TSH 1.85M',
                            icon: Icons.today_outlined,
                            iconColor: Color(0xFF2B5FCE),
                            iconBackground: Color(0xFFE8F0FF),
                          ),
                        ),
                        _SummaryDivider(),
                        Expanded(
                          child: _DaySummaryCard(
                            label: 'This Week',
                            value: 'TSH 3.17M',
                            icon: Icons.date_range_outlined,
                            iconColor: Color(0xFF2B8A3E),
                            iconBackground: Color(0xFFE8F7EA),
                          ),
                        ),
                        _SummaryDivider(),
                        Expanded(
                          child: _DaySummaryCard(
                            label: 'This Month',
                            value: 'TSH 8.24M',
                            icon: Icons.calendar_month_outlined,
                            iconColor: Color(0xFFD68A00),
                            iconBackground: Color(0xFFFFF3D8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._dailyExpenses.map(
                    (group) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ExpenseDaySection(group: group),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _ExpensesFooter(),
    );
  }
}

class _ExpenseDaySection extends StatelessWidget {
  const _ExpenseDaySection({required this.group});

  final _ExpenseDayGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.label,
                        style: const TextStyle(
                          color: Color(0xFF1E273A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        group.dateLabel,
                        style: const TextStyle(
                          color: Color(0xFF667085),
                          fontSize: 13.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Daily total',
                      style: TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.total,
                      style: const TextStyle(
                        color: Color(0xFF1E273A),
                        fontSize: 15.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE7EAF0)),
          ...group.items.asMap().entries.map(
                (entry) => Column(
                  children: [
                    _ExpenseCard(expense: entry.value),
                    if (entry.key != group.items.length - 1)
                      const Divider(height: 1, color: Color(0xFFE7EAF0)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.expense});

  final _ExpenseItem expense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              expense.icon,
              color: const Color(0xFF2B5FCE),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(
                    color: Color(0xFF1E273A),
                    fontSize: 15.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expense.category} • ${expense.time}',
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 13.1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            expense.amount,
            style: const TextStyle(
              color: Color(0xFF1E273A),
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF667085),
            size: 26,
          ),
        ],
      ),
    );
  }
}

class _DaySummaryCard extends StatelessWidget {
  const _DaySummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 12.8,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1E273A),
            fontSize: 15.3,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFE2E7EF),
    );
  }
}

class _ExpensesFooter extends StatelessWidget {
  const _ExpensesFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7EAF0))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddExpensePage(),
              ),
            ),
            child: Container(
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF356BD8), Color(0xFF2B5FCE)],
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Add Expense',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseItem {
  const _ExpenseItem({
    required this.title,
    required this.category,
    required this.time,
    required this.amount,
    required this.icon,
  });

  final String title;
  final String category;
  final String time;
  final String amount;
  final IconData icon;
}

class _ExpenseDayGroup {
  const _ExpenseDayGroup({
    required this.label,
    required this.dateLabel,
    required this.total,
    required this.items,
  });

  final String label;
  final String dateLabel;
  final String total;
  final List<_ExpenseItem> items;
}
