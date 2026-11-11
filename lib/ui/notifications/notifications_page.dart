import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final List<_NotificationItem> _items = <_NotificationItem>[
    const _NotificationItem(
      icon: Icons.attach_money_rounded,
      iconColor: AppColors.success,
      iconBackground: AppColors.successLight,
      title: 'New sale recorded',
      message: 'TSh 150,000.00 from Table 4',
      timeLabel: '9:35 AM',
      unread: true,
    ),
    const _NotificationItem(
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warning,
      iconBackground: AppColors.warningLight,
      title: 'Low stock alert',
      message: 'Coffee Beans is under the reorder level',
      timeLabel: '8:15 AM',
      unread: true,
    ),
    const _NotificationItem(
      icon: Icons.description_outlined,
      iconColor: AppColors.primary,
      iconBackground: AppColors.primaryLight,
      title: 'Monthly statement ready',
      message: 'Your April 2025 statement is ready to view',
      timeLabel: '7:30 AM',
    ),
    const _NotificationItem(
      icon: Icons.attach_money_rounded,
      iconColor: AppColors.success,
      iconBackground: AppColors.successLight,
      title: 'New sale recorded',
      message: 'TSh 85,500.00 from Table 2',
      timeLabel: 'Yesterday, 9:45 PM',
    ),
    const _NotificationItem(
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warning,
      iconBackground: AppColors.warningLight,
      title: 'Low stock alert',
      message: 'Oat Milk is under the reorder level',
      timeLabel: 'Yesterday, 6:20 PM',
    ),
    const _NotificationItem(
      icon: Icons.settings_outlined,
      iconColor: AppColors.textMuted,
      iconBackground: AppColors.surfaceSecondary,
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
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarketPageHeader(
              title: strings.notifications,
              onBack: () => Navigator.of(context).pop(),
              actions: [
                IconButton(
                  onPressed: _markAllAsRead,
                  tooltip: strings.markAllAsRead,
                  icon: const Icon(Icons.done_all_rounded,
                      color: AppColors.primary),
                ),
              ],
            ),
            Expanded(
              child: _items.isEmpty
                  ? _EmptyNotificationsState(strings: strings)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(0, 6, 0, 16),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.divider,
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
      child: Container(
        color: item.unread ? AppColors.primaryLight.withValues(alpha: 0.35) : null,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
            style: AppTypography.bodyMain.copyWith(
              fontSize: 15.5,
              fontWeight: item.unread ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              item.message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                height: 1.25,
              ),
            ),
          ),
          trailing: Text(
            item.timeLabel,
            style: AppTypography.helperText.copyWith(
              color: AppColors.textLight,
              fontSize: 12,
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
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.96, end: 1),
              duration: AppDurations.normal,
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.success,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              strings.noNotifications,
              style: AppTypography.cardHeader.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              strings.nothingToShow,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
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
