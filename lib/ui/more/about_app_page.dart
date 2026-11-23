import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/app_theme_palette.dart';
import '../widgets/market_shared_widgets.dart';
import 'terms_of_service_page.dart';

/// Clean, native Android/iOS About screen supporting all app themes and
/// linking externally to the hosted Privacy Policy and Account Deletion pages.
class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  static const _version = '1.0.0 (1)';
  static const _privacyPolicyUrl = 'https://api.azagroup.co.tz/privacy.html';
  static const _deleteAccountUrl =
      'https://api.azagroup.co.tz/delete-account.html';

  String _platformLabel() {
    try {
      final os = Platform.operatingSystem;
      final ver = Platform.operatingSystemVersion.split(' ').first;
      return '${os[0].toUpperCase()}${os.substring(1)} $ver';
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<void> _openExternal(
    BuildContext context,
    String url,
    bool isSwahili,
  ) async {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      showMarketNotice(
        context,
        title: isSwahili ? 'Hitilafu' : 'Error',
        message: isSwahili
            ? 'Imeshindwa kufungua kivinjari.'
            : 'Could not open browser.',
        type: MarketNoticeType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final palette = AppThemePalette.of(context);
    final isSwahili = store.languageCode == 'sw';
    String t(String en, String sw) => isSwahili ? sw : en;

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: Column(
        children: [
          MarketPageHeader(
            title: t('About', 'Kuhusu'),
            showBackButton: true,
            centerTitle: false,
            titleSize: 20,
            titleWeight: FontWeight.w800,
            showBorder: true,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    children: [
                      // Clean centered app identity
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.point_of_sale_rounded,
                                size: 52,
                                color: palette.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aza POS',
                            style: AppTypography.h3.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${t('Version', 'Toleo')} $_version',
                            style: AppTypography.caption.copyWith(
                              color: palette.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // App Info section
                      _GroupHeader(t('APPLICATION', 'PROGRAMU'), palette),
                      _NativeCard(
                        palette: palette,
                        children: [
                          _InfoRow(
                            palette: palette,
                            label: t('Developer', 'Mtengenezaji'),
                            value: 'Azmur Group Limited',
                          ),
                          Divider(height: 1, indent: 16, color: palette.divider),
                          _InfoRow(
                            palette: palette,
                            label: t('Version', 'Toleo'),
                            value: _version,
                          ),
                          Divider(height: 1, indent: 16, color: palette.divider),
                          _InfoRow(
                            palette: palette,
                            label: t('Platform', 'Mfumo'),
                            value: _platformLabel(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Legal & Privacy external links
                      _GroupHeader(
                        t('LEGAL & PRIVACY', 'SHERIA NA FARAGHA'),
                        palette,
                      ),
                      _NativeCard(
                        palette: palette,
                        children: [
                          _LinkRow(
                            palette: palette,
                            icon: Icons.privacy_tip_outlined,
                            title: t('Privacy Policy', 'Sera ya Faragha'),
                            external: true,
                            onTap: () => _openExternal(
                              context,
                              _privacyPolicyUrl,
                              isSwahili,
                            ),
                          ),
                          Divider(height: 1, indent: 52, color: palette.divider),
                          _LinkRow(
                            palette: palette,
                            icon: Icons.delete_outline_rounded,
                            title: t(
                              'Delete Account & Data',
                              'Futa Akaunti na Data',
                            ),
                            external: true,
                            onTap: () => _openExternal(
                              context,
                              _deleteAccountUrl,
                              isSwahili,
                            ),
                          ),
                          Divider(height: 1, indent: 52, color: palette.divider),
                          _LinkRow(
                            palette: palette,
                            icon: Icons.description_outlined,
                            title: t('Terms of Service', 'Masharti ya Huduma'),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const TermsOfServicePage(),
                              ),
                            ),
                          ),
                          Divider(height: 1, indent: 52, color: palette.divider),
                          _LinkRow(
                            palette: palette,
                            icon: Icons.article_outlined,
                            title: t(
                              'Open-Source Licenses',
                              'Leseni za Programu',
                            ),
                            onTap: () => showLicensePage(
                              context: context,
                              applicationName: 'Aza POS',
                              applicationVersion: _version,
                              applicationLegalese:
                                  '© 2026 Azmur Group Limited. All rights reserved.',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      Text(
                        '© 2026 Azmur Group Limited',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label, this.palette);
  final String label;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: palette.textMuted,
        ),
      ),
    );
  }
}

class _NativeCard extends StatelessWidget {
  const _NativeCard({required this.palette, required this.children});
  final AppThemePalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: palette.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.palette,
    required this.label,
    required this.value,
  });

  final AppThemePalette palette;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMain.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: palette.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: palette.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.palette,
    required this.icon,
    required this.title,
    required this.onTap,
    this.external = false,
  });

  final AppThemePalette palette;
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool external;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 22, color: palette.textMuted),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMain.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: palette.ink,
                  ),
                ),
              ),
              Icon(
                external
                    ? Icons.open_in_new_rounded
                    : Icons.chevron_right_rounded,
                size: external ? 18 : 20,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
