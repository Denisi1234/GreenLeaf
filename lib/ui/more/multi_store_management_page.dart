import 'dart:io';

import 'package:flutter/material.dart';

import 'add_edit_store_page.dart';
import '../widgets/market_shared_widgets.dart';

class MultiStoreManagementPage extends StatefulWidget {
  const MultiStoreManagementPage({super.key});

  @override
  State<MultiStoreManagementPage> createState() => _MultiStoreManagementPageState();
}

class _MultiStoreManagementPageState extends State<MultiStoreManagementPage> {
  late final List<_StoreItem> _stores = [
    const _StoreItem(
      name: 'Main Branch',
      category: 'Retail',
      address: '123 Business Ave, New York, NY 10001',
      contactNumber: '0712 345 678',
      taxId: '12-3456789',
      sales: 'TSH 11,401,875',
      transactions: '128',
      avgOrder: 'TSH 89,075',
      icon: Icons.storefront_rounded,
      weekdayOpen: '09:00 AM',
      weekdayClose: '09:00 PM',
      saturdayOpen: '10:00 AM',
      saturdayClose: '08:00 PM',
      sundaySchedule: 'Closed',
      open24Hours: false,
    ),
    const _StoreItem(
      name: 'Downtown Shop',
      category: 'Restaurant',
      address: '456 Market St, New York, NY 10013',
      contactNumber: '0713 220 441',
      taxId: '22-1456781',
      sales: 'TSH 5,788,500',
      transactions: '78',
      avgOrder: 'TSH 74,200',
      icon: Icons.store_mall_directory_rounded,
      weekdayOpen: '09:00 AM',
      weekdayClose: '09:00 PM',
      saturdayOpen: '10:00 AM',
      saturdayClose: '08:00 PM',
      sundaySchedule: 'Closed',
      open24Hours: false,
    ),
    const _StoreItem(
      name: 'Warehouse',
      category: 'Warehouse',
      address: '789 Industrial Rd, Brooklyn, NY 11232',
      contactNumber: '0715 908 332',
      taxId: '33-2458710',
      sales: 'TSH 4,725,500',
      transactions: '54',
      avgOrder: 'TSH 87,500',
      icon: Icons.warehouse_rounded,
      weekdayOpen: '09:00 AM',
      weekdayClose: '09:00 PM',
      saturdayOpen: '10:00 AM',
      saturdayClose: '08:00 PM',
      sundaySchedule: 'Closed',
      open24Hours: false,
    ),
  ];

  Future<void> _openCreateStore() async {
    final created = await Navigator.of(context).push<StoreFormResult>(
      MaterialPageRoute<StoreFormResult>(
        builder: (context) => const AddEditStorePage(),
      ),
    );

    if (created == null || !mounted) {
      return;
    }

    setState(() {
      _stores.insert(0, _StoreItem.fromFormResult(created));
    });

    showMarketNotice(
      context,
      title: 'Store Added',
      message: '${created.name} is now part of multi-store management',
    );
  }

  Future<void> _openEditStore(int index) async {
    final updated = await Navigator.of(context).push<StoreFormResult>(
      MaterialPageRoute<StoreFormResult>(
        builder: (context) => AddEditStorePage(
          initialStore: _stores[index].toFormResult(),
        ),
      ),
    );

    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _stores[index] = _stores[index].copyWith(
        name: updated.name,
        category: updated.category,
        address: updated.address,
        contactNumber: updated.contactNumber,
        taxId: updated.taxId,
        weekdayOpen: updated.weekdayOpen,
        weekdayClose: updated.weekdayClose,
        saturdayOpen: updated.saturdayOpen,
        saturdayClose: updated.saturdayClose,
        sundaySchedule: updated.sundaySchedule,
        open24Hours: updated.open24Hours,
        logoPath: updated.logoPath,
        icon: _StoreItem.iconForCategory(updated.category),
      );
    });

    showMarketNotice(
      context,
      title: 'Store Updated',
      message: '${updated.name} details were saved',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1562E8), Color(0xFF0C56D7)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Multi-Store Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.store_mall_directory_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                children: [
                  GestureDetector(
                    onTap: _openCreateStore,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF2B6FF3),
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Color(0xFF1562E8),
                            child: Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          SizedBox(width: 20),
                          Text(
                            'Add New Store',
                            style: TextStyle(
                              color: Color(0xFF1562E8),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._stores.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _StoreCard(
                        store: entry.value,
                        onEdit: () => _openEditStore(entry.key),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StoreBottomItem(
                    icon: Icons.pie_chart_outline_rounded,
                    label: 'Dashboard',
                  ),
                  _StoreBottomItem(
                    icon: Icons.shopping_cart_outlined,
                    label: 'Sales',
                  ),
                  _StoreBottomItem(
                    icon: Icons.storefront_rounded,
                    label: 'Stores',
                    active: true,
                  ),
                  _StoreBottomItem(
                    icon: Icons.more_horiz_rounded,
                    label: 'More',
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

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.onEdit,
  });

  final _StoreItem store;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE7EBF0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                store.logoPath == null
                    ? Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF0FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          store.icon,
                          color: const Color(0xFF1562E8),
                          size: 50,
                        ),
                      )
                    : Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          image: DecorationImage(
                            image: FileImage(File(store.logoPath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.name,
                        style: const TextStyle(
                          color: Color(0xFF202938),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF6F7887),
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              store.address,
                              style: const TextStyle(
                                color: Color(0xFF6F7887),
                                fontSize: 13.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8EE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Color(0xFF2FA45B),
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF1562E8),
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFE7EBF0)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StoreMetricBlock(
                    label: "TODAY'S SALES",
                    value: store.sales,
                  ),
                ),
                const SizedBox(
                  height: 52,
                  child: VerticalDivider(color: Color(0xFFE4E8EF)),
                ),
                Expanded(
                  child: _StoreMetricBlock(
                    label: 'TRANSACTIONS',
                    value: store.transactions,
                    valueIcon: Icons.receipt_long_outlined,
                  ),
                ),
                const SizedBox(
                  height: 52,
                  child: VerticalDivider(color: Color(0xFFE4E8EF)),
                ),
                Expanded(
                  child: _StoreMetricBlock(
                    label: 'AVG ORDER',
                    value: store.avgOrder,
                    valueIcon: Icons.shopping_cart_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                showMarketNotice(
                  context,
                  title: 'Store Switched',
                  message: '${store.name} is ready to become the active branch',
                );
              },
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1562E8), Color(0xFF0C56D7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Switch to Store',
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
          ],
        ),
      ),
    );
  }
}

class _StoreMetricBlock extends StatelessWidget {
  const _StoreMetricBlock({
    required this.label,
    required this.value,
    this.valueIcon,
  });

  final String label;
  final String value;
  final IconData? valueIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6F7887),
            fontSize: 11.8,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        if (valueIcon == null)
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          )
        else
          Row(
            children: [
              Icon(valueIcon, color: const Color(0xFF1562E8), size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _StoreBottomItem extends StatelessWidget {
  const _StoreBottomItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF1562E8) : const Color(0xFF6B7280);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12.8,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StoreItem {
  const _StoreItem({
    required this.name,
    required this.category,
    required this.address,
    required this.contactNumber,
    required this.taxId,
    required this.sales,
    required this.transactions,
    required this.avgOrder,
    required this.icon,
    required this.weekdayOpen,
    required this.weekdayClose,
    required this.saturdayOpen,
    required this.saturdayClose,
    required this.sundaySchedule,
    required this.open24Hours,
    this.logoPath,
  });

  factory _StoreItem.fromFormResult(StoreFormResult result) {
    return _StoreItem(
      name: result.name,
      category: result.category,
      address: result.address,
      contactNumber: result.contactNumber,
      taxId: result.taxId,
      sales: 'TSH 0',
      transactions: '0',
      avgOrder: 'TSH 0',
      icon: iconForCategory(result.category),
      weekdayOpen: result.weekdayOpen,
      weekdayClose: result.weekdayClose,
      saturdayOpen: result.saturdayOpen,
      saturdayClose: result.saturdayClose,
      sundaySchedule: result.sundaySchedule,
      open24Hours: result.open24Hours,
      logoPath: result.logoPath,
    );
  }

  final String name;
  final String category;
  final String address;
  final String contactNumber;
  final String taxId;
  final String sales;
  final String transactions;
  final String avgOrder;
  final IconData icon;
  final String weekdayOpen;
  final String weekdayClose;
  final String saturdayOpen;
  final String saturdayClose;
  final String sundaySchedule;
  final bool open24Hours;
  final String? logoPath;

  StoreFormResult toFormResult() {
    return StoreFormResult(
      name: name,
      category: category,
      address: address,
      contactNumber: contactNumber,
      taxId: taxId,
      weekdayOpen: weekdayOpen,
      weekdayClose: weekdayClose,
      saturdayOpen: saturdayOpen,
      saturdayClose: saturdayClose,
      sundaySchedule: sundaySchedule,
      open24Hours: open24Hours,
      logoPath: logoPath,
    );
  }

  _StoreItem copyWith({
    String? name,
    String? category,
    String? address,
    String? contactNumber,
    String? taxId,
    String? sales,
    String? transactions,
    String? avgOrder,
    IconData? icon,
    String? weekdayOpen,
    String? weekdayClose,
    String? saturdayOpen,
    String? saturdayClose,
    String? sundaySchedule,
    bool? open24Hours,
    String? logoPath,
  }) {
    return _StoreItem(
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      taxId: taxId ?? this.taxId,
      sales: sales ?? this.sales,
      transactions: transactions ?? this.transactions,
      avgOrder: avgOrder ?? this.avgOrder,
      icon: icon ?? this.icon,
      weekdayOpen: weekdayOpen ?? this.weekdayOpen,
      weekdayClose: weekdayClose ?? this.weekdayClose,
      saturdayOpen: saturdayOpen ?? this.saturdayOpen,
      saturdayClose: saturdayClose ?? this.saturdayClose,
      sundaySchedule: sundaySchedule ?? this.sundaySchedule,
      open24Hours: open24Hours ?? this.open24Hours,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  static IconData iconForCategory(String category) {
    switch (category) {
      case 'Warehouse':
        return Icons.warehouse_rounded;
      case 'Restaurant':
        return Icons.store_mall_directory_rounded;
      case 'Pharmacy':
        return Icons.local_hospital_outlined;
      case 'Electronics':
        return Icons.devices_other_rounded;
      case 'Supermarket':
        return Icons.shopping_basket_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }
}
