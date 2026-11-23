import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import '../../widgets/app_theme_palette.dart';
import '../../widgets/market_shared_widgets.dart';
import '../change_password_page.dart';
import '../settings_layout.dart';

/// Clean, native Android/iOS Account settings pane supporting all app themes.
class AccountSettingsPane extends StatefulWidget {
  const AccountSettingsPane({super.key});

  @override
  State<AccountSettingsPane> createState() => _AccountSettingsPaneState();
}

class _AccountSettingsPaneState extends State<AccountSettingsPane> {
  static const _deleteAccountUrl =
      'https://api.azagroup.co.tz/delete-account.html';
  bool _busy = false;

  Future<void> _openDeleteAccount(String lang) async {
    final launched = await launchUrl(
      Uri.parse(_deleteAccountUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
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

  Future<void> _confirmSignOut() async {
    setState(() => _busy = true);
    try {
      final success = await showLogoutConfirmationDialog(context);
      if (success && mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword(PosLocalStore store) async {
    final lang = store.languageCode;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ChangePasswordPage(),
      ),
    );
    if (changed == true && mounted) {
      showSettingsResult(
        context,
        settingsText(lang, 'Password updated', 'Nenosiri limebadilishwa'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final palette = AppThemePalette.of(context);
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);
    final profile = store.profile;

    final owner = profile.ownerName.trim().isEmpty
        ? t('Not set', 'Haijawekwa')
        : profile.ownerName;
    final storeName = profile.storeName.trim().isEmpty
        ? t('Not set', 'Haijawekwa')
        : profile.storeName;
    final phone = profile.contactNumber.trim().isEmpty
        ? t('Not set', 'Haijawekwa')
        : profile.contactNumber;
    final email = profile.emailAddress.trim().isEmpty
        ? t('Not set', 'Haijawekwa')
        : profile.emailAddress;

    final dangerColor =
        palette.isDark ? const Color(0xFFF87171) : AppColors.dangerDeep;

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 28),
      children: [
        _SectionLabel(t('PROFILE', 'WASIFU'), palette),
        _NativeGroupCard(
          palette: palette,
          children: [
            _InfoRow(palette: palette, label: t('Owner', 'Mmiliki'), value: owner),
            Divider(height: 1, indent: 16, color: palette.divider),
            _InfoRow(palette: palette, label: t('Store', 'Duka'), value: storeName),
            Divider(height: 1, indent: 16, color: palette.divider),
            _InfoRow(palette: palette, label: t('Phone', 'Simu'), value: phone),
            Divider(height: 1, indent: 16, color: palette.divider),
            _InfoRow(palette: palette, label: t('Email', 'Barua pepe'), value: email),
          ],
        ),

        const SizedBox(height: 22),

        _SectionLabel(t('SECURITY', 'USALAMA'), palette),
        _NativeGroupCard(
          palette: palette,
          children: [
            _ActionRow(
              palette: palette,
              icon: Icons.key_outlined,
              title: t('Change password', 'Badilisha nenosiri'),
              onTap: () => _changePassword(store),
            ),
          ],
        ),

        const SizedBox(height: 22),

        _SectionLabel(t('SESSION & ACCOUNT', 'KIKAO NA AKAUNTI'), palette),
        _NativeGroupCard(
          palette: palette,
          children: [
            _ActionRow(
              palette: palette,
              icon: Icons.logout_rounded,
              title: t('Sign out', 'Ondoka'),
              textColor: dangerColor,
              iconColor: dangerColor,
              busy: _busy,
              onTap: _busy ? null : _confirmSignOut,
            ),
            Divider(height: 1, indent: 52, color: palette.divider),
            _ActionRow(
              palette: palette,
              icon: Icons.delete_outline_rounded,
              title: t('Delete account & data', 'Futa akaunti na data'),
              textColor: dangerColor,
              iconColor: dangerColor,
              external: true,
              onTap: () => _openDeleteAccount(lang),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.palette);
  final String text;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        text,
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

class _NativeGroupCard extends StatelessWidget {
  const _NativeGroupCard({required this.palette, required this.children});
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
            Text(
              label,
              style: AppTypography.bodyMain.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: palette.ink,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.palette,
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
    this.external = false,
    this.busy = false,
  });

  final AppThemePalette palette;
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? iconColor;
  final bool external;
  final bool busy;

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
              Icon(icon, size: 22, color: iconColor ?? palette.textMuted),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMain.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? palette.ink,
                  ),
                ),
              ),
              if (busy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor ?? palette.primary,
                  ),
                )
              else
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
