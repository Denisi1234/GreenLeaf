import '../widgets/app_image.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../notifications/notifications_page.dart';
import '../widgets/app_design.dart';
import '../accounting/accounts_page.dart';
import '../accounting/bank_reconciliation_page.dart';
import '../accounting/fixed_assets_page.dart';
import '../payment/cash_register_page.dart';
import '../settings/tax_settings_page.dart';
import '../suppliers/suppliers_page.dart';
import '../widgets/market_shared_widgets.dart';
import 'customers_page.dart';
import 'debtors_page.dart';
import 'duka_ai_page.dart';
import 'expenses_tracking_page.dart';
import 'settings_layout.dart';
import 'settings_page.dart';
import 'staff_management_page.dart';
import 'subscription_plan_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({
    super.key,
    this.useSharedShell = false,
  });

  final bool useSharedShell;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final items = [
      _MoreMenuItem(
        label: strings.customers,
        icon: Icons.people_alt_outlined,
        action: _MoreMenuAction.customers,
      ),
      _MoreMenuItem(
        label: strings.debitLedger,
        icon: Icons.account_balance_wallet_outlined,
        action: _MoreMenuAction.debitLedger,
      ),
      _MoreMenuItem(
        label: store.languageCode == 'sw' ? 'Kasha la Pesa' : 'Cash Register',
        icon: Icons.point_of_sale_outlined,
        action: _MoreMenuAction.cashRegister,
      ),
      _MoreMenuItem(
        label: strings.expensesTracking,
        icon: Icons.receipt_long_outlined,
        action: _MoreMenuAction.expenses,
      ),
      _MoreMenuItem(
        label: strings.staffManagement,
        icon: Icons.groups_2_outlined,
        action: _MoreMenuAction.staffManagement,
      ),
      _MoreMenuItem(
        label: store.languageCode == 'sw' ? 'Wasambazaji' : 'Suppliers',
        icon: Icons.local_shipping_outlined,
        action: _MoreMenuAction.suppliers,
      ),
      _MoreMenuItem(
        label: store.languageCode == 'sw'
            ? 'Akaunti na Daftari'
            : 'Accounts & Ledger',
        icon: Icons.account_balance_outlined,
        action: _MoreMenuAction.accounts,
      ),
      _MoreMenuItem(
        label: store.languageCode == 'sw' ? 'Mali za Kudumu' : 'Fixed Assets',
        icon: Icons.chair_outlined,
        action: _MoreMenuAction.fixedAssets,
      ),
      _MoreMenuItem(
        label: store.languageCode == 'sw'
            ? 'Upatanishi wa Benki'
            : 'Bank Reconciliation',
        icon: Icons.account_balance_wallet_outlined,
        action: _MoreMenuAction.bankReconciliation,
      ),
      _MoreMenuItem(
        label:
            store.languageCode == 'sw' ? 'Mipangilio ya Kodi' : 'Tax Settings',
        icon: Icons.percent_rounded,
        action: _MoreMenuAction.taxSettings,
      ),
      _MoreMenuItem(
        label: strings.settings,
        icon: Icons.settings_outlined,
        action: _MoreMenuAction.settings,
      ),
      _MoreMenuItem(
        label: strings.dukaAi,
        icon: Icons.psychology_alt_outlined,
        action: _MoreMenuAction.dukaAi,
      ),
      _MoreMenuItem(
        label: strings.subscriptionPlan,
        icon: Icons.description_outlined,
        action: _MoreMenuAction.subscriptionPlan,
      ),
    ];
    final profile = store.profile;
    final totalSales = store.orders.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );
    final totalSalesLabel = totalSales <= 0
        ? strings.noSalesYet
        : 'TSH ${totalSales.toStringAsFixed(0)}';
    final memberSince =
        profile.memberSince.isEmpty ? strings.notSet : profile.memberSince;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      drawer:
          useSharedShell ? null : MarketAppDrawer(selectedItem: strings.more),
      body: SafeArea(
        top: !useSharedShell,
        child: Column(
          children: [
            if (!useSharedShell)
              MarketPageHeader(
                title: strings.more,
                centerTitle: false,
                leading: const DrawerMenuButton(),
                actions: [
                  MarketHeaderActionButtons(
                    showNotificationDot: true,
                    onDukaAiTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const DukaAiAdvisorPage(),
                        ),
                      );
                    },
                    onNotificationTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  _ProfileSummaryCard(
                    ownerName: profile.ownerName,
                    roleTitle: profile.roleTitle,
                    storeName: profile.storeName,
                    logoPath: profile.logoPath,
                    totalSales: totalSalesLabel,
                    memberSince: memberSince,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const SettingsPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MoreMenuCard(items: items),
                  const SizedBox(height: 12),
                  _LogoutButton(
                    label: strings.logout,
                    onTap: () async {
                      try {
                        await store.logout();
                      } catch (error) {
                        if (!context.mounted) return;
                        showMarketNotice(
                          context,
                          title: 'Sign out failed',
                          message: error.toString(),
                          type: MarketNoticeType.warning,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.ownerName,
    required this.roleTitle,
    required this.storeName,
    required this.logoPath,
    required this.totalSales,
    required this.memberSince,
    this.onTap,
  });

  final String ownerName;
  final String roleTitle;
  final String storeName;
  final String? logoPath;
  final String totalSales;
  final String memberSince;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;

        return MarketSurfaceCard(
          padding: const EdgeInsets.all(14),
          backgroundColor: AppColors.surface,
          borderColor: AppColors.border,
          radius: AppRadius.tile,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.tile),
            child: Column(
              children: [
                if (isNarrow)
                  Column(
                    children: [
                      _ProfileAvatar(logoPath: logoPath),
                      const SizedBox(height: 10),
                      _ProfileDetails(
                        centered: true,
                        ownerName: ownerName,
                        roleTitle: roleTitle,
                        storeName: storeName,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      _ProfileAvatar(logoPath: logoPath),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProfileDetails(
                          ownerName: ownerName,
                          roleTitle: roleTitle,
                          storeName: storeName,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                        size: 26,
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                if (isNarrow)
                  Column(
                    children: [
                      _StatBlock(
                        icon: Icons.receipt_long_outlined,
                        label: 'Total Sales',
                        value: totalSales,
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 10),
                      _StatBlock(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member Since',
                        value: memberSince,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _StatBlock(
                          icon: Icons.receipt_long_outlined,
                          label: 'Total Sales',
                          value: totalSales,
                        ),
                      ),
                      const SizedBox(
                        height: 48,
                        child: VerticalDivider(
                          color: AppColors.divider,
                          thickness: 1,
                        ),
                      ),
                      Expanded(
                        child: _StatBlock(
                          icon: Icons.calendar_today_outlined,
                          label: 'Member Since',
                          value: memberSince,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoreMenuCard extends StatelessWidget {
  const _MoreMenuCard({required this.items});

  final List<_MoreMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      backgroundColor: AppColors.surface,
      borderColor: AppColors.border,
      radius: AppRadius.tile,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _MoreListTile(item: items[index]),
            if (index != items.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 66),
                child: Divider(
                  height: 1,
                  color: AppColors.divider,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.logoPath});

  final String? logoPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppRadius.rounded),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: logoPath == null || logoPath!.isEmpty
          ? const Icon(
              Icons.storefront_rounded,
              color: AppColors.textBody,
              size: 36,
            )
          : Image(
              image: appImageProvider(context, logoPath!),
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.storefront_rounded,
                color: AppColors.textBody,
                size: 36,
              ),
            ),
    );
  }
}

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({
    this.centered = false,
    required this.ownerName,
    required this.roleTitle,
    required this.storeName,
  });

  final bool centered;
  final String ownerName;
  final String roleTitle;
  final String storeName;

  @override
  Widget build(BuildContext context) {
    final displayName = ownerName.isNotEmpty
        ? ownerName
        : (storeName.isEmpty ? 'Store profile not set' : storeName);
    final detailLine = storeName.isNotEmpty
        ? storeName
        : (roleTitle.isEmpty ? 'Business Owner' : roleTitle);

    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: AppTypography.cardHeader,
        ),
        const SizedBox(height: 2),
        Text(
          roleTitle.isEmpty ? 'Business Owner' : roleTitle,
          style: AppTypography.caption,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: centered ? MainAxisSize.min : MainAxisSize.max,
          children: [
            const Icon(
              Icons.storefront_outlined,
              color: AppColors.textBody,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                detailLine,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textBody, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.helperText),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMain,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreListTile extends StatelessWidget {
  const _MoreListTile({required this.item});

  final _MoreMenuItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        switch (item.action) {
          case _MoreMenuAction.customers:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const CustomersPage(),
              ),
            );
            return;
          case _MoreMenuAction.debitLedger:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const DebtorsPage(),
              ),
            );
            return;
          case _MoreMenuAction.suppliers:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const SuppliersPage(),
              ),
            );
            return;
          case _MoreMenuAction.accounts:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const AccountsPage(),
              ),
            );
            return;
          case _MoreMenuAction.fixedAssets:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const FixedAssetsPage(),
              ),
            );
            return;
          case _MoreMenuAction.bankReconciliation:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const BankReconciliationPage(),
              ),
            );
            return;
          case _MoreMenuAction.taxSettings:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const TaxSettingsPage(),
              ),
            );
            return;
          case _MoreMenuAction.cashRegister:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const CashRegisterPage(),
              ),
            );
            return;
          case _MoreMenuAction.expenses:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ExpensesTrackingPage(),
              ),
            );
            return;
          case _MoreMenuAction.staffManagement:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const StaffManagementPage(),
              ),
            );
            return;
          case _MoreMenuAction.subscriptionPlan:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const SubscriptionPlanPage(),
              ),
            );
            return;
          case _MoreMenuAction.settings:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const SettingsPage(),
              ),
            );
            return;
          case _MoreMenuAction.dukaAi:
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const DukaAiPage(),
              ),
            );
            return;
        }
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            SettingsIconBox(icon: item.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(AppRadius.tile),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.tile),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.tile),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppColors.ink,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTypography.bodyMain.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuItem {
  const _MoreMenuItem({
    required this.label,
    required this.icon,
    required this.action,
  });

  final String label;
  final IconData icon;
  final _MoreMenuAction action;
}

enum _MoreMenuAction {
  cashRegister,
  suppliers,
  accounts,
  fixedAssets,
  bankReconciliation,
  taxSettings,
  debitLedger,
  customers,
  expenses,
  staffManagement,
  settings,
  dukaAi,
  subscriptionPlan,
}
