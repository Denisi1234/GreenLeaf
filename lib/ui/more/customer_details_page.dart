import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../service/pos_local_store.dart';
import '../../service/pos_order_models.dart';
import '../models/customer_data.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'create_customer_page.dart';

class CustomerDetailsPage extends StatelessWidget {
  const CustomerDetailsPage({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return Selector<PosLocalStore, CustomerData?>(
      selector: (_, store) {
        for (final customer in store.customers) {
          if (customer.id == customerId) return customer;
        }
        return null;
      },
      builder: (context, customer, _) {
        if (customer == null) {
          return const Scaffold(
            backgroundColor: AppColors.pageBackground,
            body: SafeArea(
              child: Column(
                children: [
                  MarketPageHeader(title: 'Customer Details'),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Customer no longer exists',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return _CustomerDetailsView(customer: customer);
      },
    );
  }
}

class _CustomerDetailsView extends StatelessWidget {
  const _CustomerDetailsView({required this.customer});

  final CustomerData customer;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final orders = store.ordersForCustomer(customer.name);
    final totalSpent =
        orders.fold<double>(0, (sum, order) => sum + order.total);
    final averageOrder = orders.isEmpty ? 0.0 : totalSpent / orders.length;
    final lastOrder = orders.isEmpty ? null : orders.first;
    final lastOrderDate =
        lastOrder == null ? null : DateTime.tryParse(lastOrder.dateTime);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: 'Customer Details',
              actions: [
                IconButton(
                  tooltip: 'Edit',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CreateCustomerPage(existing: customer),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context, customer, store),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _HeroCard(customer: customer),
                  if (customer.debitBalance > 0) ...[
                    const SizedBox(height: 12),
                    _DueBanner(amount: customer.debitBalance),
                  ],
                  const SizedBox(height: 12),
                  _ContactActions(customer: customer),
                  const SizedBox(height: 16),
                  _StatsGrid(
                    totalSpent: totalSpent,
                    orderCount: orders.length,
                    averageOrder: averageOrder,
                    lastOrder: lastOrderDate,
                  ),
                  if (customer.address.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _InfoBlock(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: customer.address,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _OrdersSection(orders: orders),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomerData customer,
    PosLocalStore store,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Customer?'),
        content: Text(
          'Remove ${customer.name} from your customer list. '
          'This will not delete their past orders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await store.deleteCustomer(customer.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.customer});

  final CustomerData customer;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: AppColors.surface,
      borderColor: AppColors.border,
      radius: 14,
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.pageBackground,
              shape: BoxShape.circle,
            ),
            child: Text(
              customer.initials,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 19,
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
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  customer.phone,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (customer.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    customer.email,
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Customer since ${_formatDate(customer.createdAt)}',
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DueBanner extends StatelessWidget {
  const _DueBanner({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: AppColors.surface,
      borderColor: AppColors.border,
      radius: 12,
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Outstanding debit due: TSh ${amount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactActions extends StatelessWidget {
  const _ContactActions({required this.customer});

  final CustomerData customer;

  Future<void> _open(
    BuildContext context,
    String scheme,
    String fallbackMsg,
  ) async {
    final uri = Uri.parse(scheme);
    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        showMarketNotice(
          context,
          title: 'Cannot Open',
          message: fallbackMsg,
          type: MarketNoticeType.warning,
        );
      }
    } catch (_) {
      if (context.mounted) {
        showMarketNotice(
          context,
          title: 'Cannot Open',
          message: fallbackMsg,
          type: MarketNoticeType.warning,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = customer.phone.replaceAll(RegExp(r'\s+'), '');
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.call_rounded,
            label: 'Call',
            onTap: () =>
                _open(context, 'tel:$phone', 'Phone dialer unavailable'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.message_rounded,
            label: 'SMS',
            onTap: () => _open(context, 'sms:$phone', 'SMS app unavailable'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.chat_bubble_rounded,
            label: 'WhatsApp',
            onTap: () {
              final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
              _open(
                context,
                'https://wa.me/$cleaned',
                'WhatsApp unavailable',
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MarketSurfaceCard(
        backgroundColor: AppColors.surface,
        borderColor: AppColors.border,
        radius: 12,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.ink, size: 21),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.totalSpent,
    required this.orderCount,
    required this.averageOrder,
    required this.lastOrder,
  });

  final double totalSpent;
  final int orderCount;
  final double averageOrder;
  final DateTime? lastOrder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        const gap = 10.0;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            SizedBox(
              width: itemWidth,
              child: _StatCard(
                label: 'Total Spent',
                value: 'TSh ${_formatMoney(totalSpent)}',
                icon: Icons.payments_outlined,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _StatCard(
                label: 'Orders',
                value: orderCount.toString(),
                icon: Icons.receipt_long_outlined,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _StatCard(
                label: 'Avg Order',
                value: 'TSh ${_formatMoney(averageOrder)}',
                icon: Icons.trending_up_rounded,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _StatCard(
                label: 'Last Visit',
                value: lastOrder == null ? '—' : _formatDate(lastOrder!),
                icon: Icons.event_outlined,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      borderColor: AppColors.border,
      radius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.ink, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: AppColors.border,
      radius: 12,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.mutedText, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
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

class _OrdersSection extends StatelessWidget {
  const _OrdersSection({required this.orders});

  final List<CompletedOrder> orders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Order History',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (orders.isEmpty)
          const MarketSurfaceCard(
            padding: EdgeInsets.all(20),
            backgroundColor: AppColors.surface,
            borderColor: AppColors.border,
            radius: 12,
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.mutedText,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'No orders yet',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Completed sales linked to this customer will appear here',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ...orders.take(25).map((order) => _OrderTile(order: order)),
        if (orders.length > 25)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '+ ${orders.length - 25} more orders',
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12.5,
              ),
            ),
          ),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final CompletedOrder order;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MarketSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderColor: AppColors.border,
        radius: 12,
        child: Row(
          children: [
            const Icon(
              Icons.receipt_rounded,
              color: AppColors.mutedText,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.id}',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.date} · ${order.time}',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'TSh ${_formatMoney(order.total)}',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}K';
  }
  return value.toStringAsFixed(0);
}

String _formatDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
