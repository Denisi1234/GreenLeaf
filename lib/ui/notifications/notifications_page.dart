import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/pos_local_store.dart';
import '../../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final Set<String> _readIds = <String>{};

  void _markAllAsRead(List<_NotificationItem> items) {
    setState(() {
      for (final item in items) {
        _readIds.add(item.id);
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      if (difference.inMinutes <= 1) return 'Just now';
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && dateTime.day == now.day) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (difference.inDays < 2) {
      return 'Yesterday, ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  List<_NotificationItem> _generateRealNotifications(PosLocalStore store) {
    final list = <_NotificationItem>[];

    // 1. Real completed sales (up to 15 recent sales)
    final recentOrders = store.orders.take(15).toList();
    for (final order in recentOrders) {
      final parsedDate = DateTime.tryParse(order.dateTime) ?? DateTime.now();
      final id = 'sale-${order.id}';
      final isUnread = !_readIds.contains(id);

      list.add(
        _NotificationItem(
          id: id,
          icon: Icons.payments_outlined,
          iconColor: const Color(0xFF10B981),
          iconBackground: const Color(0xFFD1FAE5),
          title: 'Sale #${order.id}',
          message: 'Sh ${formatCurrency(order.total)} completed by ${order.cashierName}',
          timeLabel: _formatTime(parsedDate),
          dateTime: parsedDate,
          unread: isUnread,
        ),
      );
    }

    // 2. Real Out of Stock alerts
    final outOfStockProducts = store.inventory.where((p) => p.stockCount <= 0).take(5).toList();
    for (final item in outOfStockProducts) {
      final id = 'stock-out-${item.code}';
      final isUnread = !_readIds.contains(id);

      list.add(
        _NotificationItem(
          id: id,
          icon: Icons.cancel_outlined,
          iconColor: const Color(0xFFEF4444),
          iconBackground: const Color(0xFFFEE2E2),
          title: 'Out of Stock: ${item.name}',
          message: '${item.name} has reached 0 units in stock. Restock needed.',
          timeLabel: 'Alert',
          dateTime: DateTime.now().subtract(const Duration(minutes: 5)),
          unread: isUnread,
        ),
      );
    }

    // 3. Real Low Stock alerts (items with <= 5 stock)
    final lowStockProducts = store.inventory.where((p) => p.stockCount > 0 && p.stockCount <= 5).take(5).toList();
    for (final item in lowStockProducts) {
      final id = 'stock-low-${item.code}';
      final isUnread = !_readIds.contains(id);

      list.add(
        _NotificationItem(
          id: id,
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFF59E0B),
          iconBackground: const Color(0xFFFEF3C7),
          title: 'Low Stock: ${item.name}',
          message: 'Only ${item.stockCount} unit(s) remaining for ${item.name}.',
          timeLabel: 'Warning',
          dateTime: DateTime.now().subtract(const Duration(minutes: 15)),
          unread: isUnread,
        ),
      );
    }

    // 4. Real Outstanding Debt / Customer Credit
    final owingCustomers = store.customers.where((c) => c.debitBalance > 0).take(5).toList();
    for (final customer in owingCustomers) {
      final id = 'credit-${customer.id}';
      final isUnread = !_readIds.contains(id);

      list.add(
        _NotificationItem(
          id: id,
          icon: Icons.account_balance_wallet_outlined,
          iconColor: const Color(0xFF0284C7),
          iconBackground: const Color(0xFFE0F2FE),
          title: 'Pending Debt: ${customer.name}',
          message: '${customer.name} owes Sh ${formatCurrency(customer.debitBalance)} in unpaid credit.',
          timeLabel: 'Pending',
          dateTime: customer.createdAt,
          unread: isUnread,
        ),
      );
    }

    // Sort by timestamp descending
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final items = _generateRealNotifications(store);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF2F9),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarketPageHeader(
              title: strings.notifications,
              onBack: () => Navigator.of(context).pop(),
              actions: [
                if (items.isNotEmpty)
                  IconButton(
                    onPressed: () => _markAllAsRead(items),
                    tooltip: strings.markAllAsRead,
                    icon: const Icon(
                      Icons.done_all_rounded,
                      color: Color(0xFF0284C7),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: items.isEmpty
                  ? _EmptyNotificationsState(strings: strings)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _NotificationCard(
                            item: item,
                            onTap: () {
                              setState(() {
                                _readIds.add(item.id);
                              });
                            },
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
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  final _NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10), // Clean rounded card
        border: Border.all(
          color: item.unread ? const Color(0xFFBAE6FD) : const Color(0xFFD6E4F0),
          width: item.unread ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.iconBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: item.unread ? FontWeight.w800 : FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text(
                            item.timeLabel,
                            style: GoogleFonts.manrope(
                              color: const Color(0xFF94A3B8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.message,
                        style: GoogleFonts.manrope(
                          color: const Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.unread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF10B981),
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'All Caught Up',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No new store alerts or transactions to review right now.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.dateTime,
    this.unread = false,
  });

  final String id;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String message;
  final String timeLabel;
  final DateTime dateTime;
  final bool unread;
}
