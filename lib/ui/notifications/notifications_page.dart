import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final List<_NotificationItem> _items = <_NotificationItem>[
    const _NotificationItem(
      icon: Icons.attach_money_rounded,
      iconColor: Color(0xFF15803D),
      iconBackground: Color(0xFFEAF7F1),
      title: 'New sale recorded',
      message: 'TSh 150,000.00 from Table 4',
      timeLabel: '9:35 AM',
      unread: true,
    ),
    const _NotificationItem(
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFF97316),
      iconBackground: Color(0xFFFFF2E8),
      title: 'Low stock alert',
      message: 'Coffee Beans is under the reorder level',
      timeLabel: '8:15 AM',
      unread: true,
    ),
    const _NotificationItem(
      icon: Icons.description_outlined,
      iconColor: Color(0xFF1D4ED8),
      iconBackground: Color(0xFFEAF1FF),
      title: 'Monthly statement ready',
      message: 'Your April 2025 statement is ready to view',
      timeLabel: '7:30 AM',
    ),
    const _NotificationItem(
      icon: Icons.attach_money_rounded,
      iconColor: Color(0xFF15803D),
      iconBackground: Color(0xFFEAF7F1),
      title: 'New sale recorded',
      message: 'TSh 85,500.00 from Table 2',
      timeLabel: 'Yesterday, 9:45 PM',
    ),
    const _NotificationItem(
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFF97316),
      iconBackground: Color(0xFFFFF2E8),
      title: 'Low stock alert',
      message: 'Oat Milk is under the reorder level',
      timeLabel: 'Yesterday, 6:20 PM',
    ),
    const _NotificationItem(
      icon: Icons.settings_outlined,
      iconColor: Color(0xFF6B7280),
      iconBackground: Color(0xFFF1F5F9),
      title: 'System update completed',
      message: 'Your POS system was updated successfully',
      timeLabel: 'Yesterday, 3:10 PM',
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(unread: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        centerTitle: false,
        titleSpacing: 20,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
            icon: const Icon(
              Icons.done_all_rounded,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _items.isEmpty
                ? const _EmptyNotificationsState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFEDEFF2),
                      indent: 72,
                      endIndent: 20,
                    ),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _NotificationTile(
                        item: item,
                        onTap: () {
                          setState(() {
                            _items[index] = _items[index].copyWith(
                              unread: false,
                            );
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  final _NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        minLeadingWidth: 0,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: item.iconBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: item.iconColor, size: 21),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: const Color(0xFF0F172A),
            fontSize: 15.5,
            fontWeight: item.unread ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            item.message,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13.5,
              height: 1.25,
            ),
          ),
        ),
        trailing: Text(
          item.timeLabel,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _EmptyNotificationsState extends StatelessWidget {
  const _EmptyNotificationsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.96, end: 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF7F1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF15803D),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No notifications',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Nothing to show right now.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13.5,
                height: 1.4,
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
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.unread = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String message;
  final String timeLabel;
  final bool unread;

  _NotificationItem copyWith({
    IconData? icon,
    Color? iconColor,
    Color? iconBackground,
    String? title,
    String? message,
    String? timeLabel,
    bool? unread,
  }) {
    return _NotificationItem(
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      iconBackground: iconBackground ?? this.iconBackground,
      title: title ?? this.title,
      message: message ?? this.message,
      timeLabel: timeLabel ?? this.timeLabel,
      unread: unread ?? this.unread,
    );
  }
}
