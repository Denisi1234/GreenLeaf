import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'settings_layout.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const _supportPhone = '0624105850';
  static const _supportEmail = 'fm328432@gmail.com';

  @override
  Widget build(BuildContext context) {
    const supportItems = [
      _SupportItem(
        title: 'Call Help Center',
        subtitle: 'Speak directly with our support team ($_supportPhone)',
        icon: Icons.call_rounded,
      ),
      _SupportItem(
        title: 'Email Support',
        subtitle: 'Send us an email ($_supportEmail)',
        icon: Icons.email_rounded,
      ),
      _SupportItem(
        title: 'Quick Start Guide',
        subtitle: 'Overview of sales, inventory and reports',
        icon: Icons.menu_book_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const MarketPageHeader(title: 'Help & Support'),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    children: [
                      Container(
                        decoration: AppDecorations.tile(),
                        clipBehavior: Clip.antiAlias,
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              for (var index = 0;
                                  index < supportItems.length;
                                  index++) ...[
                                _SupportTile(item: supportItems[index]),
                                if (index != supportItems.length - 1)
                                  const Divider(
                                    height: 1,
                                    indent: 66,
                                    color: AppColors.divider,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.tile),
                          border: Border.all(color: AppColors.primarySoft),
                        ),
                        child: Row(
                          children: [
                            const SettingsIconBox(
                              icon: Icons.shield_outlined,
                              color: AppColors.primaryDeep,
                              background: AppColors.surface,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'We are here to help',
                                    style: AppTypography.bodyMain.copyWith(
                                      color: AppColors.primaryDeep,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Support is available Monday – Saturday, 08:00 – 20:00 EAT.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.primaryDeep,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({required this.item});

  final _SupportItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        switch (item.title) {
          case 'Call Help Center':
            launchUrl(
              Uri.parse('tel:${HelpSupportPage._supportPhone}'),
              mode: LaunchMode.externalApplication,
            );
            return;
          case 'Email Support':
            launchUrl(
              Uri.parse('mailto:${HelpSupportPage._supportEmail}'),
              mode: LaunchMode.externalApplication,
            );
            return;
          case 'Quick Start Guide':
            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Quick Start Guide'),
                content: const Text(
                  '1. Add your products and stock in the Products tab.\n'
                  '2. Ring up customer orders from the Sales register.\n'
                  '3. Track daily revenue, expenses, and stock alerts in Reports.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
            return;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            SettingsIconBox(icon: item.icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTypography.bodyMain.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportItem {
  const _SupportItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
