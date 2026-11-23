import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../reports/report_hub_page.dart';
import '../sales/order_history_page.dart';
import '../widgets/app_design.dart';
import '../widgets/app_image.dart';
import '../widgets/app_theme_palette.dart';
import '../widgets/market_shared_widgets.dart';
import 'advanced_features_page.dart';
import 'customers_page.dart';
import 'debtors_page.dart';
import 'expenses_tracking_page.dart';
import 'settings_page.dart';
import 'widgets/rate_app_dialog.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key, this.useSharedShell = false});
  final bool useSharedShell;

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await showLogoutConfirmationDialog(context);
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  String _formatMemberSince(String raw, String lang) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return DateFormat('MMMM yyyy', lang).format(DateTime.now());
    }
    // Try parsing common stored formats like "Nov 13, 2026" or ISO dates
    final parsed = DateTime.tryParse(trimmed) ??
        (() {
          for (final pattern in const [
            'MMM d, yyyy',
            'MMMM d, yyyy',
            'd MMM yyyy',
            'MMMM yyyy',
            'MMM yyyy',
          ]) {
            try {
              return DateFormat(pattern, 'en').parse(trimmed);
            } catch (_) {}
          }
          return null;
        })();
    if (parsed != null) {
      return DateFormat('MMMM yyyy', lang).format(parsed);
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final palette = AppThemePalette.of(context);
    final strings = AppStrings.of(store.languageCode);
    final lang = store.languageCode;
    String t(String en, String sw) => lang == 'sw' ? sw : en;
    final hasAdvancedAccess = const [
      'Manage Inventory',
      'Manage Payments',
      'View Reports',
      'System Settings',
      'Manage Staff',
    ].any(store.hasPermission);

    final rawStoreName = store.profile.storeName.trim().isNotEmpty
        ? store.profile.storeName.trim()
        : store.activeStoreName.trim();
    final storeName = rawStoreName.isNotEmpty
        ? rawStoreName
        : t('My Store', 'Duka Langu');
    final memberSince = _formatMemberSince(store.profile.memberSince, lang);
    final initial = storeName.isNotEmpty ? storeName[0].toUpperCase() : 'S';

    final sections = <_MenuGroup>[
      _MenuGroup(
        t('Operations', 'Biashara'),
        [
          _MenuItem(
            id: 'orders',
            icon: Icons.receipt_long_outlined,
            title: t('Orders & receipts', 'Oda na risiti'),
            page: () => const OrderHistoryPage(),
          ),
          _MenuItem(
            id: 'customers',
            icon: Icons.people_outline_rounded,
            title: strings.customers,
            page: () => const CustomersPage(),
          ),
          _MenuItem(
            id: 'debtors',
            icon: Icons.account_balance_wallet_outlined,
            title: strings.debitLedger,
            page: () => const DebtorsPage(),
            permission: 'Manage Payments',
          ),
          _MenuItem(
            id: 'expenses',
            icon: Icons.payments_outlined,
            title: strings.expensesTracking,
            page: () => const ExpensesTrackingPage(),
            permission: 'Manage Payments',
          ),
          _MenuItem(
            id: 'reports',
            icon: Icons.bar_chart_rounded,
            title: strings.reports,
            page: () => const ReportHubPage(),
            permission: 'View Reports',
          ),
        ],
      ),
      _MenuGroup(
        t('Workspace', 'Mfumo'),
        [
          if (hasAdvancedAccess)
            _MenuItem(
              id: 'advanced',
              icon: Icons.tune_rounded,
              title: t('Advanced tools', 'Vipengele vya juu'),
              page: () => const AdvancedFeaturesPage(),
            ),
          _MenuItem(
            id: 'settings',
            icon: Icons.settings_outlined,
            title: strings.settings,
            page: () => const SettingsPage(),
            permission: 'System Settings',
          ),
          _MenuItem(
            id: 'rate-app',
            icon: Icons.star_outline_rounded,
            title: t('Rate & review app', 'Kadiria programu'),
            onTap: () => showRateAppDialog(context),
          ),
        ],
      ),
    ];

    final visibleSections = sections
        .map(
          (group) => _MenuGroup(
            group.label,
            group.items
                .where(
                  (item) =>
                      item.permission == null ||
                      store.hasPermission(item.permission!),
                )
                .toList(),
          ),
        )
        .where((group) => group.items.isNotEmpty)
        .toList();

    return Scaffold(
      drawer: widget.useSharedShell ? null : const MarketAppDrawer(),
      backgroundColor: palette.pageBackground,
      body: SafeArea(
        top: !widget.useSharedShell,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                // Native Material 3 Android store identity card: Logo/Avatar, Store Name, Member Since badge & edit shortcut
                Material(
                  color: palette.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    side: BorderSide(color: palette.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsPage(
                            initialSection: SettingsSection.business,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: palette.primaryLight,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: palette.border.withValues(alpha: 0.5),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            alignment: Alignment.center,
                            child: store.profile.logoPath != null &&
                                    store.profile.logoPath!.isNotEmpty
                                ? Image(
                                    image: appImageProvider(
                                      context,
                                      store.profile.logoPath!,
                                    ),
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Text(
                                      initial,
                                      style: AppTypography.bodyMain.copyWith(
                                        color: palette.primary,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                : Text(
                                    initial,
                                    style: AppTypography.bodyMain.copyWith(
                                      color: palette.primary,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  storeName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.bodyMain.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: palette.ink,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.verified_outlined,
                                      size: 13,
                                      color: palette.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        t(
                                          'Member since $memberSince',
                                          'Mwanachama tangu $memberSince',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.caption.copyWith(
                                          color: palette.textMuted,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: palette.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                for (var i = 0; i < visibleSections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 22),
                  _MenuGroupCard(
                    group: visibleSections[i],
                    palette: palette,
                  ),
                ],
                const SizedBox(height: 28),
                // Native Material 3 tonal destructive sign-out button
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    key: const ValueKey('more-sign-out'),
                    onPressed: _signingOut ? null : _signOut,
                    style: FilledButton.styleFrom(
                      foregroundColor: AppColors.dangerDeep,
                      backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.standard),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: Text(
                      _signingOut
                          ? t('Signing out…', 'Inaondoka…')
                          : strings.logout,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuGroupCard extends StatelessWidget {
  const _MenuGroupCard({
    required this.group,
    required this.palette,
  });

  final _MenuGroup group;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
          child: Text(
            group.label.toUpperCase(),
            style: AppTypography.label.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: palette.textMuted,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: palette.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                for (var i = 0; i < group.items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 62,
                      color: palette.divider,
                    ),
                  _MenuRow(item: group.items[i], palette: palette),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.palette,
  });

  final _MenuItem item;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('more-${item.id}'),
      onTap: () {
        HapticFeedback.lightImpact();
        if (item.onTap != null) {
          item.onTap!();
          return;
        }
        if (item.page != null) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => item.page!()),
          );
        }
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.sharp),
                ),
                alignment: Alignment.center,
                child: Icon(
                  item.icon,
                  size: 20,
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.bodyMain.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: palette.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuGroup {
  const _MenuGroup(this.label, this.items);
  final String label;
  final List<_MenuItem> items;
}

class _MenuItem {
  const _MenuItem({
    required this.id,
    required this.icon,
    required this.title,
    this.page,
    this.permission,
    this.onTap,
  });

  final String id;
  final IconData icon;
  final String title;
  final Widget Function()? page;
  final String? permission;
  final VoidCallback? onTap;
}
