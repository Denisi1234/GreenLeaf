import 'package:flutter/material.dart';

import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'create_customer_page.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  static const _customers = <_CustomerItem>[
    _CustomerItem(
      name: 'Emma Johnson',
      phone: '+1 (555) 401-2201',
      email: 'emma.johnson@example.com',
      totalOrders: '24',
      totalSpent: 'TSH 1,240,000',
      statusLabel: 'VIP',
      avatarColor: Color(0xFFF0D9D2),
    ),
    _CustomerItem(
      name: 'Liam Smith',
      phone: '+1 (555) 406-9802',
      email: 'liam.smith@example.com',
      totalOrders: '18',
      totalSpent: 'TSH 845,500',
      statusLabel: 'Regular',
      avatarColor: Color(0xFFD9E8F7),
    ),
    _CustomerItem(
      name: 'Ava Brown',
      phone: '+1 (555) 389-1130',
      email: 'ava.brown@example.com',
      totalOrders: '12',
      totalSpent: 'TSH 522,300',
      statusLabel: 'New',
      avatarColor: Color(0xFFEAE2FF),
    ),
    _CustomerItem(
      name: 'Noah Davis',
      phone: '+1 (555) 418-5550',
      email: 'noah.davis@example.com',
      totalOrders: '33',
      totalSpent: 'TSH 2,018,750',
      statusLabel: 'VIP',
      avatarColor: Color(0xFFE8F7EA),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: 'Customers',
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const CreateCustomerPage(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: AppColors.ink,
                    size: 26,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
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
                              'Search customers...',
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
                      message: 'Customer filters can be connected next',
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
                          child: _CustomerStat(
                            label: 'Total Customers',
                            value: '1,248',
                          ),
                        ),
                        _StatDivider(),
                        Expanded(
                          child: _CustomerStat(
                            label: 'VIP Customers',
                            value: '84',
                          ),
                        ),
                        _StatDivider(),
                        Expanded(
                          child: _CustomerStat(
                            label: 'New This Month',
                            value: '37',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ..._customers.map(
                    (customer) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CustomerCard(customer: customer),
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer});

  final _CustomerItem customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: customer.avatarColor,
            child: Text(
              customer.initials,
              style: const TextStyle(
                color: Color(0xFF1E273A),
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    color: Color(0xFF1E273A),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.email,
                  style: const TextStyle(
                    color: Color(0xFF717B8C),
                    fontSize: 13.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customer.phone,
                  style: const TextStyle(
                    color: Color(0xFF717B8C),
                    fontSize: 13.2,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusChip(label: customer.statusLabel),
              const SizedBox(height: 10),
              Text(
                customer.totalOrders,
                style: const TextStyle(
                  color: Color(0xFF1E273A),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                customer.totalSpent,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerStat extends StatelessWidget {
  const _CustomerStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF1E273A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFE2E7EF),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final background = switch (label) {
      'VIP' => const Color(0xFFE8F4FF),
      'New' => const Color(0xFFF3EAFE),
      _ => const Color(0xFFEAF7EE),
    };
    final foreground = switch (label) {
      'VIP' => const Color(0xFF2B5FCE),
      'New' => const Color(0xFF7A4BD8),
      _ => const Color(0xFF2D6B42),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CustomerItem {
  const _CustomerItem({
    required this.name,
    required this.phone,
    required this.email,
    required this.totalOrders,
    required this.totalSpent,
    required this.statusLabel,
    required this.avatarColor,
  });

  final String name;
  final String phone;
  final String email;
  final String totalOrders;
  final String totalSpent;
  final String statusLabel;
  final Color avatarColor;

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
          .toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
