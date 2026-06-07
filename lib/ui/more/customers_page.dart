import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../models/customer_data.dart';
import '../widgets/market_shared_widgets.dart';
import 'create_customer_page.dart';
import 'package:possystem/ui/more/customer_details_page.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({
    super.key,
    this.isSelectionMode = false,
  });

  final bool isSelectionMode;

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  static const List<int> _fallbackPoints = <int>[
    450,
    320,
    780,
    560,
    240,
    610,
    180,
    400,
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CustomerData> _filteredCustomers(List<CustomerData> customers) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return customers;
    return customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query);
    }).toList();
  }

  int _loyaltyPointsFor(CustomerData customer, int index) {
    if (customer.totalSpent > 0) {
      return (customer.totalSpent / 10).round().clamp(100, 9999).toInt();
    }
    if (customer.totalOrders > 0) {
      return (customer.totalOrders * 90).clamp(100, 9999).toInt();
    }
    return _fallbackPoints[index % _fallbackPoints.length];
  }

  void _openCustomer(CustomerData customer) {
    if (widget.isSelectionMode) {
      Navigator.of(context).pop(customer.name);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CustomerDetailsPage(customerId: customer.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers =
        _filteredCustomers(context.watch<PosLocalStore>().customers);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: const Color(0xFF0F172A),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Customers',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                if (!widget.isSelectionMode)
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const CreateCustomerPage(),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    color: const Color(0xFF0F172A),
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: customers.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: customers.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                      indent: 84,
                    ),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final points = _loyaltyPointsFor(customer, index);

                      return InkWell(
                        onTap: () => _openCustomer(customer),
                        child: _CustomerListItem(
                          customer: customer,
                          loyaltyPoints: points,
                          debitBalance: customer.debitBalance,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded,
                color: Color(0xFF94A3B8), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Search customers...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: MarketSurfaceCard(
        padding: const EdgeInsets.all(20),
        borderColor: const Color(0xFFE2E8F0),
        radius: 12,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty
                  ? Icons.people_outline_rounded
                  : Icons.search_off_rounded,
              size: 48,
              color: const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No Customers' : 'No matches found',
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Add your first customer to get started.'
                  : 'Try a different name or phone number.',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerListItem extends StatelessWidget {
  const _CustomerListItem({
    required this.customer,
    required this.loyaltyPoints,
    required this.debitBalance,
  });

  final CustomerData customer;
  final int loyaltyPoints;
  final double debitBalance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFF1F5F9),
            child: Text(
              customer.initials,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.phone.isNotEmpty ? customer.phone : 'No phone',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                if (debitBalance > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Debit due: TSh ${debitBalance.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$loyaltyPoints pts',
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Loyalty',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1), size: 20),
        ],
      ),
    );
  }
}


