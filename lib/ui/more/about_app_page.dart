import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _AboutItem('Terms of Service', Icons.description_outlined),
      _AboutItem('Privacy Policy', Icons.shield_outlined),
      _AboutItem('Licenses', Icons.info_outline_rounded),
    ];

    final baseTheme = Theme.of(context);
    final interTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const MarketPageHeader(title: 'App Info'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  children: [
                    const Text(
                      'Green Leaf',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Version 2.4.1',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Green Leaf helps businesses manage sales, records, and daily operations with confidence anytime, anywhere.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.pageBackground,
                        borderRadius: BorderRadius.circular(AppRadius.rounded),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          ...items.asMap().entries.map(
                            (entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Column(
                                children: [
                                  _AboutTile(item: item),
                                  if (index != items.length - 1)
                                    const Divider(
                                      height: 1,
                                      color: AppColors.divider,
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '© 2026 Green Leaf. All rights reserved.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

class _AboutTile extends StatelessWidget {
  const _AboutTile({required this.item});

  final _AboutItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.label == 'Terms of Service') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const TermsOfServicePage(),
            ),
          );
          return;
        }

        if (item.label == 'Privacy Policy') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const PrivacyPolicyPage(),
            ),
          );
          return;
        }

        if (item.label == 'Licenses') {
          showLicensePage(
            context: context,
            applicationName: 'Green Leaf',
            applicationVersion: '2.4.1',
            applicationLegalese: '© 2026 Green Leaf. All rights reserved.',
          );
          return;
        }

        showMarketNotice(
          context,
          title: item.label,
          message: '${item.label} can be connected to the full document next',
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(AppRadius.standard),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                item.icon,
                color: AppColors.ink,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutItem {
  const _AboutItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
