import 'package:flutter/material.dart';

import 'create_customer_page.dart';
import '../widgets/market_shared_widgets.dart';

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
        child: Stack(
          children: [
            Column(
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
                          'Customers',
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
                          MaterialPageRoute<void>(
                            builder: (context) => const CreateCustomerPage(),
                          ),
                        ),
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Color(0xFF1E273A),
                            size: 26,
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
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.email,
                  style: const TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 13.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.phone,
                  style: const TextStyle(
                    color: Color(0xFF8A93A3),
                    fontSize: 12.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  customer.statusLabel,
                  style: const TextStyle(
                    color: Color(0xFF2B5FCE),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF667085),
                size: 28,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerStat extends StatelessWidget {
  const _CustomerStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1E273A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 13.2,
            fontWeight: FontWeight.w500,
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
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFE2E7EF),
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
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}
