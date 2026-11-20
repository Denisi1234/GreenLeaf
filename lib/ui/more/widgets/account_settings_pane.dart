import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import '../change_password_page.dart';
import '../settings_layout.dart';

/// User account and device session settings pane.
class AccountSettingsPane extends StatefulWidget {
  const AccountSettingsPane({super.key});

  @override
  State<AccountSettingsPane> createState() => _AccountSettingsPaneState();
}

class _AccountSettingsPaneState extends State<AccountSettingsPane> {
  bool _busy = false;

  Future<void> _confirmSignOut(PosLocalStore store) async {
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
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);
    final profile = store.profile;
    final owner = profile.ownerName.trim().isEmpty
        ? t('Not set', 'Haijawekwa')
        : profile.ownerName;
    final role = profile.roleTitle.trim().isEmpty
        ? t('Business owner', 'Mmiliki wa biashara')
        : profile.roleTitle;
    final storeName = profile.storeName.trim().isEmpty
        ? t('Not set', 'Haijawekwa')
        : profile.storeName;
    final phone = profile.contactNumber.trim().isEmpty
        ? t('Not set', 'Haijawekwa')
        : profile.contactNumber;
    final email = profile.emailAddress.trim().isEmpty
        ? t('Not set', 'Haijawekwa')
        : profile.emailAddress;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        SettingsCard(
          icon: Icons.badge_outlined,
          title: t('Signed-in profile', 'Wasifu uliounganishwa'),
          description: t('Details linked to this device session.',
              'Taarifa zinazohusiana na kikao cha kifaa hiki.'),
          children: [
            SettingsInfoRow(label: t('Owner', 'Mmiliki'), value: owner),
            const Divider(height: 1),
            SettingsInfoRow(label: t('Role', 'Wajibu'), value: role),
            const Divider(height: 1),
            SettingsInfoRow(label: t('Store', 'Duka'), value: storeName),
            const Divider(height: 1),
            SettingsInfoRow(label: t('Phone', 'Simu'), value: phone),
            const Divider(height: 1),
            SettingsInfoRow(label: t('Email', 'Barua pepe'), value: email),
          ],
        ),
        SettingsCard(
          icon: Icons.lock_outline_rounded,
          title: t('Password & security', 'Nenosiri na usalama'),
          description: t(
            'Use a password with at least 6 characters.',
            'Tumia nenosiri lenye herufi 6 au zaidi.',
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => _changePassword(store),
                style: OutlinedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                icon: const Icon(Icons.key_rounded, size: 18),
                label: Text(t('Change password', 'Badilisha nenosiri')),
              ),
            ),
          ],
        ),
        SettingsCard(
          icon: Icons.logout_rounded,
          title: t('Session', 'Kikao'),
          description: t('End your session on this device.',
              'Maliza kikao chako kwenye kifaa hiki.'),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  backgroundColor: AppColors.surfaceSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: _busy ? null : () => _confirmSignOut(store),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.ink),
                      )
                    : const Icon(Icons.logout_rounded, size: 18),
                label: Text(t('Sign out', 'Ondoka')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
