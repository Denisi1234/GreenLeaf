import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../service/app_update_service.dart';
import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import '../about_app_page.dart';
import '../help_support_page.dart';
import '../settings_layout.dart';
import '../terms_of_service_page.dart';
import 'rate_app_dialog.dart';

/// About app, legal, and license links pane.
class AboutSettingsPane extends StatelessWidget {
  const AboutSettingsPane({super.key});

  static const _privacyPolicyUrl = 'https://api.azagroup.co.tz/privacy.html';
  static const _deleteAccountUrl =
      'https://api.azagroup.co.tz/delete-account.html';

  Future<void> _checkForUpdates(BuildContext context, String lang) async {
    final res = await AppUpdateService.instance
        .checkForAutoUpdate(bypassThrottle: true);
    if (!context.mounted) return;
    final (String title, String message, MarketNoticeType type) = switch (res) {
      AppUpdateCheckResult.upToDate => (
          settingsText(lang, 'Up to date', 'Imesasishwa'),
          settingsText(
            lang,
            'You are already using the latest version.',
            'Tayari unatumia toleo la hivi karibuni.',
          ),
          MarketNoticeType.success,
        ),
      AppUpdateCheckResult.downloading => (
          settingsText(lang, 'Downloading update', 'Inapakua sasisho'),
          settingsText(
            lang,
            'A new version is downloading automatically in the background.',
            'Toleo jipya linapakuliwa moja kwa moja chinichini.',
          ),
          MarketNoticeType.info,
        ),
      AppUpdateCheckResult.installing => (
          settingsText(lang, 'Installing update', 'Inaweka sasisho'),
          settingsText(
            lang,
            'Update installation has started.',
            'Uwekaji wa sasisho umeanza.',
          ),
          MarketNoticeType.success,
        ),
      AppUpdateCheckResult.unavailable => (
          settingsText(lang, 'Updates unavailable', 'Masasisho hayapatikani'),
          settingsText(
            lang,
            'Automatic updates require Google Play on an Android device.',
            'Masasisho otomatiki yanahitaji Google Play kwenye simu ya Android.',
          ),
          MarketNoticeType.warning,
        ),
    };
    showMarketNotice(context, title: title, message: message, type: type);
  }

  Future<void> _openExternalLink(
    BuildContext context,
    String url,
    String lang,
  ) async {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      showMarketNotice(
        context,
        title: settingsText(lang, 'Error', 'Hitilafu'),
        message: settingsText(
          lang,
          'Could not open browser.',
          'Imeshindwa kufungua kivinjari.',
        ),
        type: MarketNoticeType.error,
      );
    }
  }

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
          title: 'Aza POS',
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
                  : t('Saved on this device', 'Hifadhi ya kifaa'),
            ),
          ],
        ),
        SettingsCard(
          icon: Icons.support_agent_outlined,
          title: t('Help & legal', 'Msaada na sheria'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          children: [
            AboutLink(
              icon: Icons.system_update_outlined,
              label: t('Check for updates', 'Angalia masasisho'),
              onTap: () => _checkForUpdates(context, lang),
            ),
            AboutLink(
              icon: Icons.star_outline_rounded,
              label: t('Rate & review Aza POS', 'Kadiria Aza POS'),
              onTap: () => showRateAppDialog(context),
            ),
            link(Icons.help_outline_rounded, t('Help & support', 'Msaada'),
                const HelpSupportPage()),
            link(
                Icons.description_outlined,
                t('Terms of service', 'Masharti ya huduma'),
                const TermsOfServicePage()),
            AboutLink(
              icon: Icons.privacy_tip_outlined,
              label: t('Privacy policy', 'Sera ya faragha'),
              onTap: () => _openExternalLink(context, _privacyPolicyUrl, lang),
            ),
            AboutLink(
              icon: Icons.delete_outline_rounded,
              label: t('Delete account & data', 'Futa akaunti na data'),
              onTap: () => _openExternalLink(context, _deleteAccountUrl, lang),
            ),
            link(Icons.apps_rounded, t('About the app', 'Kuhusu programu'),
                const AboutAppPage()),
            AboutLink(
              icon: Icons.article_outlined,
              label: t('Open-source licenses', 'Leseni za programu'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'Aza POS',
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
        color: AppColors.pageBackground,
        borderRadius: AppCorners.control,
        child: InkWell(
          borderRadius: AppCorners.control,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
