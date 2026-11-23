import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../accounting/accounts_page.dart';
import '../accounting/bank_reconciliation_page.dart';
import '../accounting/fixed_assets_page.dart';
import '../audit/audit_trail_page.dart';
import '../payment/cash_register_page.dart';
import '../settings/tax_settings_page.dart';
import '../suppliers/receiving_page.dart';
import '../suppliers/suppliers_page.dart';
import '../widgets/app_design.dart';
import '../widgets/app_theme_palette.dart';
import '../widgets/common/market_page_header.dart';
import 'staff_management_page.dart';
import 'stores_page.dart';

/// Clean, restrained back-office tools directory matching MorePage.
class AdvancedFeaturesPage extends StatelessWidget {
  const AdvancedFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    String t(String en, String sw) => store.languageCode == 'sw' ? sw : en;

    final sections = <_AdvGroup>[
      _AdvGroup(
        t('Stock & register', 'Hifadhi na kasha'),
        [
          _AdvItem(
            icon: Icons.local_shipping_outlined,
            title: t('Suppliers', 'Wasambazaji'),
            builder: () => const SuppliersPage(),
            permission: 'Manage Inventory',
          ),
          _AdvItem(
            icon: Icons.move_to_inbox_outlined,
            title: t('Goods received', 'Bidhaa zilizopokelewa'),
            builder: () => const ReceivingPage(),
            permission: 'Manage Inventory',
          ),
          _AdvItem(
            icon: Icons.point_of_sale_outlined,
            title: t('Cash register', 'Kasha la pesa'),
            builder: () => const CashRegisterPage(),
            permission: 'Manage Payments',
          ),
        ],
      ),
      _AdvGroup(
        t('Accounting & tax', 'Uhasibu na kodi'),
        [
          _AdvItem(
            icon: Icons.account_balance_outlined,
            title: t('Accounts & ledger', 'Akaunti na daftari'),
            builder: () => const AccountsPage(),
            permission: 'View Reports',
          ),
          _AdvItem(
            icon: Icons.chair_outlined,
            title: t('Fixed assets', 'Mali za kudumu'),
            builder: () => const FixedAssetsPage(),
            permission: 'View Reports',
          ),
          _AdvItem(
            icon: Icons.fact_check_outlined,
            title: t('Bank reconciliation', 'Upatanishi wa benki'),
            builder: () => const BankReconciliationPage(),
            permission: 'Manage Payments',
          ),
          _AdvItem(
            icon: Icons.percent_rounded,
            title: t('Tax settings', 'Mipangilio ya kodi'),
            builder: () => const TaxSettingsPage(),
            permission: 'System Settings',
          ),
        ],
      ),
      _AdvGroup(
        t('Multi-store & team', 'Maduka na timu'),
        [
          _AdvItem(
            icon: Icons.storefront_outlined,
            title: t('Stores', 'Maduka'),
            builder: () => const StoresPage(),
            permission: 'System Settings',
          ),
          _AdvItem(
            icon: Icons.badge_outlined,
            title: strings.staffManagement,
            builder: () => const StaffManagementPage(),
            permission: 'Manage Staff',
          ),
        ],
      ),
      _AdvGroup(
        t('Security & audit', 'Usalama na ukaguzi'),
        [
          _AdvItem(
            icon: Icons.verified_user_outlined,
            title: t('Audit & trail', 'Kumbukumbu za ukaguzi'),
            builder: () => const AuditTrailPage(),
            permission: 'View Reports',
          ),
        ],
      ),
    ];

    final visibleSections = sections
        .map(
          (group) => _AdvGroup(
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

    final palette = AppThemePalette.of(context);

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: Column(
        children: [
          MarketPageHeader(
            title: t('Advanced tools', 'Vipengele vya juu'),
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
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    itemCount: visibleSections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 22),
                    itemBuilder: (context, index) =>
                        _AdvGroupCard(group: visibleSections[index]),
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

class _AdvGroupCard extends StatelessWidget {
  const _AdvGroupCard({required this.group});

  final _AdvGroup group;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
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
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: palette.border),
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
                      color: palette.divider,
                    ),
                  _AdvRow(item: group.items[i]),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdvRow extends StatelessWidget {
  const _AdvRow({required this.item});

  final _AdvItem item;

  @override
  Widget build(BuildContext context) {
    final palette = AppThemePalette.of(context);
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => item.builder()),
        );
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
                color: palette.textBody,
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

class _AdvGroup {
  const _AdvGroup(this.label, this.items);
  final String label;
  final List<_AdvItem> items;
}

class _AdvItem {
  const _AdvItem({
    required this.icon,
    required this.title,
    required this.builder,
    this.permission,
  });

  final IconData icon;
  final String title;
  final Widget Function() builder;
  final String? permission;
}
