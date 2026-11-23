import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/pos_local_store.dart';
import '../../more/about_app_page.dart';
import '../../more/help_support_page.dart';
import '../../more/theme_selection_page.dart';
import '../app_design.dart';
import '../app_theme_palette.dart';
import '../business/business_category_widgets.dart';
import '../common/logout_confirmation_dialog.dart';
import '../market_bottom_nav.dart';

class MarketAppDrawer extends StatelessWidget {
  const MarketAppDrawer({
    super.key,
    this.selectedItem = 'Home',
    this.selectedTab,
    this.onSelectTab,
  });

  final String selectedItem;
  final MarketTab? selectedTab;
  final ValueChanged<MarketTab>? onSelectTab;

  @override
  Widget build(BuildContext context) {
    final drawerWidth =
        (MediaQuery.sizeOf(context).width * 0.84).clamp(260.0, 340.0);
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final palette = AppThemePalette.of(context);
    final isSwahili = store.languageCode == 'sw';
    final activePreset = AppThemePreset.byId(store.storePreferences.appTheme);

    return Drawer(
      width: drawerWidth,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: _DrawerProfileHeader(),
            ),
            Divider(color: palette.divider, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  _DrawerMenuTile(
                    icon: Icons.palette_outlined,
                    label: isSwahili ? 'Mandhari' : 'Theme',
                    trailingText:
                        isSwahili ? activePreset.nameSw : activePreset.nameEn,
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ThemeSelectionPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _DrawerMenuTile(
                    icon: Icons.support_agent_outlined,
                    label: strings.helpSupport,
                    isSelected: strings.helpSupport == selectedItem,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (strings.helpSupport == selectedItem) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HelpSupportPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _DrawerMenuTile(
                    icon: Icons.info_outline_rounded,
                    label: strings.aboutApp,
                    isSelected: strings.aboutApp == selectedItem,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (strings.aboutApp == selectedItem) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AboutAppPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(color: palette.divider, height: 1),
                  const SizedBox(height: AppSpacing.lg),
                  const _LogoutButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerProfileHeader extends StatelessWidget {
  const _DrawerProfileHeader();

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<PosLocalStore>().profile;
    final config = context.read<PosLocalStore>().businessCategoryConfig;
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    final ownerName = profile.ownerName.isEmpty
        ? (profile.storeName.isEmpty
            ? strings.setupStoreProfile
            : profile.storeName)
        : profile.ownerName;
    final role =
        profile.roleTitle.isEmpty ? strings.businessOwner : profile.roleTitle;
    final storeDetail =
        profile.storeName.isEmpty || profile.storeName == ownerName
            ? ''
            : profile.storeName;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.surfaceSecondary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.surface,
            child: profile.logoPath == null
                ? Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 34,
                  )
                : ClipOval(
                    child: Image.file(
                      File(profile.logoPath!),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ownerName,
                style: AppTypography.h3.copyWith(fontSize: 17),
              ),
              const SizedBox(height: 2),
              BusinessCategoryBadge(
                category: config.category,
                label: role,
              ),
              if (storeDetail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  storeDetail,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DrawerMenuTile extends StatelessWidget {
  const _DrawerMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingText;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.standard),
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? palette.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? palette.primary : palette.textMuted,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMain.copyWith(
                  color: isSelected ? palette.primary : palette.ink,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 8),
              Text(
                trailingText!,
                style: AppTypography.caption.copyWith(
                  color: palette.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    final palette = AppThemePalette.of(context);
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          Navigator.of(context).pop();
          await showLogoutConfirmationDialog(context);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.dangerDeep,
          backgroundColor: palette.surface,
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 19),
        label: Text(
          strings.logout,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
