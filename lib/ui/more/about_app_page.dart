import 'package:flutter/material.dart';

import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'privacy_policy_page.dart';
import 'settings_layout.dart';
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
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            const MarketPageHeader(title: 'App Info'),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    children: [
                      const SettingsCard(
                        icon: Icons.storefront_rounded,
                        title: 'TrackMauzo',
                        description:
                            'Point of sale for small shops — the B2C edition of Open Source POS.',
                        children: [
                          SettingsInfoRow(
                            label: 'Version',
                            value: '1.0.0 (1)',
                          ),
                          Divider(height: 1),
                          SettingsInfoRow(
                            label: 'Edition',
                            value: 'B2C · Mini',
                          ),
                        ],
                      ),
                      Container(
                        decoration: AppDecorations.tile(),
                        clipBehavior: Clip.antiAlias,
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              for (var index = 0;
                                  index < items.length;
                                  index++) ...[
                                _AboutTile(item: items[index]),
                                if (index != items.length - 1)
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
                      const SizedBox(height: 24),
                      Text(
                        '© 2026 TrackMauzo. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption,
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

class _AboutTile extends StatelessWidget {
  const _AboutTile({required this.item});

  final _AboutItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
            applicationName: 'TrackMauzo',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2026 TrackMauzo. All rights reserved.',
          );
          return;
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SettingsIconBox(icon: item.icon),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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

class _AboutItem {
  const _AboutItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
