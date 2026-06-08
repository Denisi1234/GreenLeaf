import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../models/customer_data.dart';
import '../widgets/app_design.dart';
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
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: 'Customers',
              showBackButton: true,
              centerTitle: false,
              actions: !widget.isSelectionMode
                  ? [
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const CreateCustomerPage(),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        color: AppColors.ink,
                        iconSize: 28,
                      ),
                    ]
                  : null,
            ),
            _buildSearchBar(),
            Expanded(
              child: customers.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      itemCount: customers.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.divider,
                        indent: 80,
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: MarketSearchField(
        controller: _searchController,
        hintText: 'Search customers...',
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        onClear: () {
          _searchController.clear();
          setState(() {
            _searchQuery = '';
          });
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: MarketSurfaceCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          radius: AppRadius.standard,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _searchQuery.isEmpty
                    ? Icons.people_outline_rounded
                    : Icons.search_off_rounded,
                size: 48,
                color: AppColors.textLight,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                _searchQuery.isEmpty ? 'No Customers' : 'No matches found',
                style: AppTypography.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _searchQuery.isEmpty
                    ? 'Add your first customer to get started.'
                    : 'Try a different name or phone number.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
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
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.surfaceSecondary,
            child: Text(
              customer.initials,
              style: AppTypography.cardHeader.copyWith(
                color: AppColors.textMuted,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: AppTypography.bodyMain.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customer.phone.isNotEmpty
                      ? customer.phone
                      : 'No phone provided',
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (debitBalance > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DEBIT: TSh ${debitBalance.toStringAsFixed(0)}',
                      style: AppTypography.helperText.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$loyaltyPoints',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'POINTS',
                style: AppTypography.helperText.copyWith(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textLight, size: 20),
        ],
      ),
    );
  }
}
