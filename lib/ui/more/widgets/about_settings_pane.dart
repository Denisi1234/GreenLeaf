import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import '../about_app_page.dart';
import '../help_support_page.dart';
import '../privacy_policy_page.dart';
import '../settings_layout.dart';
import '../terms_of_service_page.dart';

/// About app, legal, and license links pane.
class AboutSettingsPane extends StatelessWidget {
  const AboutSettingsPane({super.key});

  String get _platform {
    try {
      final os = Platform.operatingSystem;
      final version = Platform.operatingSystemVersion.split(' ').first;
      return '${os[0].toUpperCase()}${os.substring(1)} $version';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);
    final connected = store.cloudApi != null;

    void open(Widget page) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));

    Widget link(IconData icon, String label, Widget page) => AboutLink(
          icon: icon,
          label: label,
          onTap: () => open(page),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        SettingsCard(
          icon: Icons.info_outline_rounded,
          title: 'TrackMauzo',
          description: t(
            'Point of sale for small shops — the B2C edition of Open Source POS.',
            'Mfumo wa mauzo kwa maduka madogo — toleo la B2C la Open Source POS.',
          ),
          children: [
            SettingsInfoRow(label: t('Version', 'Toleo'), value: '1.0.0 (1)'),
            const Divider(height: 1),
            SettingsInfoRow(
                label: t('Edition', 'Toleo la'), value: 'B2C · Mini'),
            const Divider(height: 1),
            SettingsInfoRow(label: t('Platform', 'Mfumo'), value: _platform),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Language', 'Lugha'),
              value: lang == 'sw' ? 'Kiswahili' : 'English',
            ),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Storage', 'Hifadhi'),
              value: connected
                  ? t('Cloud + local cache', 'Wingu + hifadhi ya ndani')
                  : t('On-device database', 'Hifadhi ya kifaa'),
            ),
          ],
        ),
        SettingsCard(
          icon: Icons.support_agent_outlined,
          title: t('Help & legal', 'Msaada na sheria'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          children: [
            link(Icons.help_outline_rounded, t('Help & support', 'Msaada'),
                const HelpSupportPage()),
            link(
                Icons.description_outlined,
                t('Terms of service', 'Masharti ya huduma'),
                const TermsOfServicePage()),
            link(
                Icons.privacy_tip_outlined,
                t('Privacy policy', 'Sera ya faragha'),
                const PrivacyPolicyPage()),
            link(Icons.apps_rounded, t('About the app', 'Kuhusu programu'),
                const AboutAppPage()),
            AboutLink(
              icon: Icons.article_outlined,
              label: t('Open-source licenses', 'Leseni za programu'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'TrackMauzo',
                applicationVersion: '1.0.0 (1)',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AboutLink extends StatelessWidget {
  const AboutLink({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
        child: InkWell(
          borderRadius: BorderRadius.zero,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                SettingsIconBox(icon: icon, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
