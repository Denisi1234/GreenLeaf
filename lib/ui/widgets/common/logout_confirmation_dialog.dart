import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localization.dart';
import '../../../service/pos_local_store.dart';
import '../../auth/auth_wrapper.dart';
import 'market_confirm_dialog.dart';

/// Shows a clean, unified logout confirmation dialog matching Aza POS's
/// pill-button design. Returns `true` if the user signed out.
Future<bool> showLogoutConfirmationDialog(
  BuildContext context, {
  String? username,
}) async {
  final store = context.read<PosLocalStore>();
  final effectiveUser =
      (username ?? store.currentUser?.name ?? store.profile.ownerName).trim();

  final confirmed = await showMarketConfirmDialog(
    context,
    title: context.tr('Sign Out'),
    subtitle: effectiveUser.isNotEmpty
        ? '${context.tr('Active session')}: $effectiveUser'
        : null,
    message: context.tr(
      'Are you sure you want to end your session? You will need your login credentials to sign in again.',
    ),
    confirmLabel: context.tr('Sign Out'),
    cancelLabel: context.tr('Cancel'),
    isDestructive: true,
    icon: Icons.logout_rounded,
  );

  if (confirmed && context.mounted) {
    try {
      await store.logout();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const AuthWrapper()),
          (_) => false,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Logout failed: $e');
    }
  }

  return false;
}
