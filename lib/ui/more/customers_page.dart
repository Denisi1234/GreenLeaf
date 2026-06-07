import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../models/customer_data.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'create_customer_page.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({
    super.key,
    this.isSelectionMode = false,
  });

  final bool isSelectionMode;

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
            Expanded(
              child: ListenableBuilder(
                listenable: context.watch<PosLocalStore>(),
                builder: (context, _) {
                  final customers = context.watch<PosLocalStore>().customers;
                  if (customers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 64,
                            color: Color(0xFFE2E8F0),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Customers Added',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add your first customer to get started',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    children: [
                      const SizedBox(height: 14),
                      ...customers.map(
                        (customer) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: isSelectionMode
                                ? () => Navigator.of(context).pop(customer.name)
                                : null,
                            child: _CustomerCard(customer: customer),
                          ),
                        ),
                      ),
                    ],
                  );
                },
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

  final CustomerData customer;

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFFE8EEF8); 

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color,
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
                  customer.phone,
                  style: const TextStyle(
                    color: Color(0xFF717B8C),
                    fontSize: 13.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
