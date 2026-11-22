import '../../../l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../../auth/auth_wrapper.dart';
import '../app_design.dart';

/// Shows a professional, unified logout confirmation dialog matching the app's clean flat theme.
/// Returns true if the user confirmed sign out and successfully logged out.
Future<bool> showLogoutConfirmationDialog(
  BuildContext context, {
  String? username,
}) async {
  final store = context.read<PosLocalStore>();
  final effectiveUser = username ?? store.currentUser?.name ?? store.profile.ownerName;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: AppShadows.soft,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.kpiDangerBg, // Soft red badge
                        borderRadius: BorderRadius.circular(AppRadius.standard),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.dangerDeep,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Sign Out'),
                            style: AppTypography.sectionHeader.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            effectiveUser.isNotEmpty
                                ? '${context.tr('Active session')}: $effectiveUser'
                                : (context.tr('Active session')),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Are you sure you want to end your session? You will need your login credentials to sign in again.'),
                      style: AppTypography.bodyMain.copyWith(
                        color: AppColors.textBody,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.surfaceSecondary,
                          foregroundColor: AppColors.textBody,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        child: Text(
                          context.tr('Cancel'),
                          style: AppTypography.label.copyWith(
                            color: AppColors.textBody,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: AppColors.dangerDeep,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        child: Text(
                          context.tr('Sign Out'),
                          style: AppTypography.label.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (confirmed == true && context.mounted) {
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
