import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/pos_local_store.dart';
import '../../more/about_app_page.dart';
import '../../more/advanced_features_page.dart';
import '../../more/customers_page.dart';
import '../../more/expenses_tracking_page.dart';
import '../../more/help_support_page.dart';
import '../../more/settings_page.dart';
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

  List<_DrawerItemData> _supportItems(AppStrings strings) {
    return [
      _DrawerItemData(strings.helpSupport, Icons.support_agent_outlined),
      _DrawerItemData(strings.aboutApp, Icons.info_outline_rounded),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth =
        (MediaQuery.sizeOf(context).width * 0.84).clamp(260.0, 340.0);
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final palette = AppThemePalette.of(context);
    final isSwahili = store.languageCode == 'sw';
    final canOpenSettings = store.hasPermission('System Settings');
    final hasAdvancedAccess = const [
      'Manage Inventory',
      'Manage Payments',
      'View Reports',
      'System Settings',
      'Manage Staff',
    ].any(store.hasPermission);

    final navTabs = <(MarketTab, String, IconData)>[
      (MarketTab.dashboard, strings.dashboard, Icons.bar_chart_rounded),
      (MarketTab.products, strings.inventory, Icons.inventory_2_outlined),
      (MarketTab.sales, strings.sales, Icons.point_of_sale_outlined),
      (MarketTab.more, strings.more, Icons.grid_view_outlined),
    ];

    return Drawer(
      width: drawerWidth,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl,
                  AppSpacing.xl, AppSpacing.md),
              child: _DrawerProfileHeader(),
            ),
            Divider(color: palette.divider, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (onSelectTab != null) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                        child: Text(
                          (isSwahili ? 'URAMBAZAJI' : 'NAVIGATION'),
                          style: AppTypography.label.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: palette.textMuted,
                          ),
                        ),
                      ),
                      for (final (tab, label, icon) in navTabs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _DrawerActionTile(
                            icon: icon,
                            label: label,
                            isSelected: selectedTab == tab,
                            onTap: () {
                              Navigator.of(context).pop();
                              onSelectTab!(tab);
                            },
                          ),
                        ),
                      if (hasAdvancedAccess)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _DrawerActionTile(
                            icon: Icons.tune_rounded,
                            label: isSwahili
                                ? 'Vipengele vya juu'
                                : 'Advanced tools',
                            isSelected: false,
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AdvancedFeaturesPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      if (canOpenSettings)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _DrawerActionTile(
                            icon: Icons.settings_outlined,
                            label: strings.settings,
                            isSelected: false,
                            onTap: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SettingsPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      Divider(color: palette.divider, height: 1),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Text(
                        (isSwahili ? 'MANDHARI' : 'THEME'),
                        style: AppTypography.label.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: palette.textMuted,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: AppThemePreset.presets.map((preset) {
                          final active =
                              store.storePreferences.appTheme == preset.id;
                          return ChoiceChip(
                            label: Text(
                              isSwahili ? preset.nameSw : preset.nameEn,
                              style: AppTypography.helperText.copyWith(
                                color: active ? Colors.white : palette.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            avatar: Icon(
                              preset.icon,
                              size: 15,
                              color: active ? Colors.white : palette.textMuted,
                            ),
                            selected: active,
                            showCheckmark: false,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            labelPadding: const EdgeInsets.only(right: 4),
                            selectedColor: palette.primary,
                            backgroundColor: palette.surfaceSecondary,
                            side: BorderSide(
                              color: active ? palette.primary : palette.border,
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            onSelected: (_) {
                              if (active) return;
                              store.setStorePreferences(
                                store.storePreferences
                                    .copyWith(appTheme: preset.id),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Divider(color: palette.divider, height: 1),
                    const SizedBox(height: AppSpacing.md),
                    _DrawerSection(
                      items: _supportItems(strings),
                      selectedItem: selectedItem,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Divider(color: palette.divider, height: 1),
                    const SizedBox(height: AppSpacing.lg),
                    const _LogoutButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerActionTile extends StatelessWidget {
  const _DrawerActionTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.standard),
      onTap: onTap,
      child: Container(
        height: 48,
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
            radius: 44,
            backgroundColor: AppColors.surface,
            child: profile.logoPath == null
                ? Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                    size: 40,
                  )
                : ClipOval(
                    child: Image.file(
                      File(profile.logoPath!),
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ownerName,
                style: AppTypography.h3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              BusinessCategoryBadge(
                category: config.category,
                label: role,
              ),
              if (storeDetail.isNotEmpty) ...[
                const SizedBox(height: 6),
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

class _DrawerSection extends StatelessWidget {
  const _DrawerSection({
    required this.items,
    required this.selectedItem,
  });

  final List<_DrawerItemData> items;
  final String selectedItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _DrawerTile(
                item: item,
                isSelected: item.label == selectedItem,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.isSelected,
  });

  final _DrawerItemData item;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.standard),
      onTap: () {
        Navigator.of(context).pop();
        if (isSelected) {
          return;
        }
        final route = _routeForLabel(item.label);
        if (route != null) {
          Navigator.of(context).push(route);
        }
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Text(
                item.label,
                style: AppTypography.bodyMain.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textMain,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Route<void>? _routeForLabel(String label) {
  switch (label) {
    case 'Customers':
    case 'Wateja':
      return MaterialPageRoute<void>(
        builder: (context) => const CustomersPage(),
      );
    case 'Expenses Tracking':
    case 'Ufuatiliaji wa Matumizi':
      return MaterialPageRoute<void>(
        builder: (context) => const ExpensesTrackingPage(),
      );
    case 'Help & Support':
    case 'Msaada na Usaidizi':
      return MaterialPageRoute<void>(
        builder: (context) => const HelpSupportPage(),
      );
    case 'About App':
    case 'Kuhusu Programu':
      return MaterialPageRoute<void>(
        builder: (context) => const AboutAppPage(),
      );
    default:
      return null;
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.standard),
      onTap: () async {
        Navigator.of(context).pop();
        await showLogoutConfirmationDialog(context);
      },
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
        child: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: AppColors.ink,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              strings.logout,
              style: AppTypography.bodyMain.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItemData {
  const _DrawerItemData(this.label, this.icon);

  final String label;
  final IconData icon;
}
