import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../reports/report_hub_page.dart';
import '../sales/order_history_page.dart';
import '../widgets/app_design.dart';
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

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    String t(String en, String sw) => store.languageCode == 'sw' ? sw : en;
    final hasAdvancedAccess = const [
      'Manage Inventory',
      'Manage Payments',
      'View Reports',
      'System Settings',
      'Manage Staff',
    ].any(store.hasPermission);

    final storeName = store.profile.storeName.trim().isNotEmpty
        ? store.profile.storeName.trim()
        : 'Aza POS';
    final ownerName = store.profile.ownerName.trim();
    final roleTitle = store.profile.roleTitle.trim();
    final isCloudConnected = store.cloudApi != null;
    final initial = storeName.isNotEmpty ? storeName[0].toUpperCase() : 'A';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        top: !widget.useSharedShell,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                // Calm merchant identity strip (Square / Shopify POS style)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.standard),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initial,
                          style: AppTypography.bodyMain.copyWith(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMain.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: isCloudConnected
                                        ? AppColors.success
                                        : AppColors.textMuted,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    [
                                      if (ownerName.isNotEmpty) ownerName,
                                      if (roleTitle.isNotEmpty) roleTitle,
                                      isCloudConnected
                                          ? t('Cloud synced', 'Wingu hai')
                                          : t('Local device', 'Hifadhi kifaa'),
                                    ].join(' · '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                for (var i = 0; i < visibleSections.length; i++) ...[
                  if (i > 0) const SizedBox(height: 22),
                  _MenuGroupCard(group: visibleSections[i]),
                ],
                const SizedBox(height: 26),
                // Signature full-width pill Sign Out button
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const ValueKey('more-sign-out'),
                    onPressed: _signingOut ? null : _signOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerDeep,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 19),
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
  const _MenuGroupCard({required this.group});

  final _MenuGroup group;

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
              color: AppColors.textMuted,
            ),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.soft,
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                for (var i = 0; i < group.items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: AppColors.divider,
                    ),
                  _MenuRow(item: group.items[i]),
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
  const _MenuRow({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('more-${item.id}'),
      onTap: () {
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
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 22,
                color: AppColors.textMain,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.title,
                  style: AppTypography.bodyMain.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textLight,
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
