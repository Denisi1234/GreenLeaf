import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const _supportPhone = '0624105850';
  static const _supportEmail = 'fm328432@gmail.com';

  @override
  Widget build(BuildContext context) {
    const supportItems = [
      _SupportItem(
        title: 'Chat with Us',
        subtitle: 'Get real-time help from our support team',
        icon: Icons.chat_bubble_rounded,
      ),
      _SupportItem(
        title: 'Email Support',
        subtitle: 'Send us an email and we will get back to you',
        icon: Icons.email_rounded,
      ),
      _SupportItem(
        title: 'Call Help Center',
        subtitle: 'Speak with our support team',
        icon: Icons.call_rounded,
      ),
      _SupportItem(
        title: 'User Guide',
        subtitle: 'Step-by-step guides and resources',
        icon: Icons.menu_book_rounded,
      ),
    ];

    final baseTheme = Theme.of(context);
    final interTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const MarketPageHeader(title: 'Help & Support'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  children: [
                    const Text(
                      'Find answers fast',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.pageBackground,
                        borderRadius: BorderRadius.circular(AppRadius.rounded),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: AppColors.ink,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search FAQs',
                              style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    MarketSurfaceCard(
                      radius: AppRadius.rounded,
                      borderColor: AppColors.border,
                      child: Column(
                        children: [
                          ...supportItems.asMap().entries.map(
                            (entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Column(
                                children: [
                                  _SupportTile(item: item),
                                  if (index != supportItems.length - 1)
                                    const Divider(
                                        height: 1, color: AppColors.divider),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const MarketSurfaceCard(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      backgroundColor: AppColors.pageBackground,
                      radius: AppRadius.rounded,
                      borderColor: AppColors.border,
                      child: Row(
                        children: [
                          _ShieldSupportIcon(),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'We are here to help',
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Your satisfaction is our priority.',
                                  style: TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
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
            ],
          ),
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
    return MarketSurfaceCard(
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      child: GestureDetector(
        onTap: () {
          switch (item.title) {
            case 'Chat with Us':
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
            case 'User Guide':
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('User Guide'),
                  content: const Text(
                      'The comprehensive user guide is being prepared. It will cover sales management, inventory tracking, and reporting in detail.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
              return;
            default:
              showMarketNotice(
                context,
                title: item.title,
                message:
                    '${item.title} can be connected to the live support flow next',
              );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.pageBackground,
                  borderRadius: BorderRadius.circular(AppRadius.standard),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(item.icon, color: AppColors.ink, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShieldSupportIcon extends StatelessWidget {
  const _ShieldSupportIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: AppColors.border),
      ),
      child: const Icon(
        Icons.shield_outlined,
        color: AppColors.ink,
        size: 22,
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
