import 'package:flutter/material.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFD),
      body: Column(
        children: [
          const MarketPageHeader(title: 'App Info'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
              child: Column(
                children: [
                  const Text(
                    'Green Leaf',
                    style: TextStyle(
                      color: Color(0xFF1554C8),
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Version 2.4.1',
                    style: TextStyle(
                      color: Color(0xFF3D4B67),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Green Leaf helps businesses manage sales, records, and daily operations with confidence anytime, anywhere.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF3D4B67),
                        fontSize: 16,
                        height: 1.9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFE4E8EF)),
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
                                    color: Color(0xFFE7EBF0),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    '© 2026 Green Leaf. All rights reserved.',
                    style: TextStyle(
                      color: Color(0xFF6F7887),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: Icon(
                item.icon,
                color: const Color(0xFF1554C8),
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(
                  color: Color(0xFF1B2A4A),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF1554C8),
              size: 34,
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
