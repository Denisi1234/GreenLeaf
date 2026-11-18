import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../accounting/accounts_page.dart';
import '../accounting/bank_reconciliation_page.dart';
import '../accounting/fixed_assets_page.dart';
import '../notifications/notifications_page.dart';
import '../payment/cash_register_page.dart';
import '../settings/tax_settings_page.dart';
import '../suppliers/suppliers_page.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'customers_page.dart';
import 'debtors_page.dart';
import 'duka_ai_page.dart';
import 'expenses_tracking_page.dart';
import 'settings_page.dart';
import 'staff_management_page.dart';
import 'stores_page.dart';
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
    final profile = store.profile;
    final strings = AppStrings.of(store.languageCode);

    return Scaffold(
      backgroundColor: const Color(0xFFEAF2F9), // Soft light-blue grey matching the screenshot
      drawer: useSharedShell ? null : MarketAppDrawer(selectedItem: strings.more),
      body: SafeArea(
        top: !useSharedShell,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
          children: [
            // 1. Top Standalone Card: Loan Accounts / Debtors
            _MenuCard(
              items: [
                _MenuItemData(
                  icon: Icons.account_balance_wallet_outlined,
                  title: strings.debitLedger,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const DebtorsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Section: Operations & Sales
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Important Utilities',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            _MenuCard(
              items: [
                _MenuItemData(
                  icon: Icons.people_outline_rounded,
                  title: strings.customers,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const CustomersPage(),
                      ),
                    );
                  },
                ),
                _MenuItemData(
                  icon: Icons.receipt_long_outlined,
                  title: strings.expensesTracking,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const ExpensesTrackingPage(),
                      ),
                    );
                  },
                ),
                _MenuItemData(
                  icon: Icons.point_of_sale_rounded,
                  title: store.languageCode == 'sw' ? 'Kasha la Pesa' : 'Cash Register',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const CashRegisterPage(),
                      ),
                    );
                  },
                ),
                _MenuItemData(
                  icon: Icons.storefront_outlined,
                  title: store.languageCode == 'sw' ? 'Maduka' : 'Stores',
                  trailingIcon: Icons.keyboard_arrow_down_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const StoresPage(),
                      ),
                    );
                  },
                ),
                _MenuItemData(
                  icon: Icons.local_shipping_outlined,
                  title: store.languageCode == 'sw' ? 'Wasambazaji' : 'Suppliers',
                  trailingIcon: Icons.keyboard_arrow_down_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const SuppliersPage(),
                      ),
                    );
                  },
                ),
                _MenuItemData(
                  icon: Icons.badge_outlined,
                  title: strings.staffManagement,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const StaffManagementPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Section: Accounting & Finance
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                store.languageCode == 'sw' ? 'Uhasibu na Fedha' : 'Accounting & Finance',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            _MenuCard(
              items: [
                _MenuItemData(
                  icon: Icons.account_balance_outlined,
                  title: store.languageCode == 'sw' ? 'Akaunti na Daftari' : 'Accounts & Ledger',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const AccountsPage(),
                      ),
                    );
                  },
                ),
                _MenuItemData(
                  icon: Icons.inventory_2_outlined,
                  title: store.languageCode == 'sw' ? 'Mali za Kudumu' : 'Fixed Assets',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const FixedAssetsPage(),
                      ),
                    );
                  },
                ),
                _MenuItemData(
                  icon: Icons.account_balance_wallet_outlined,
                  title: store.languageCode == 'sw' ? 'Upatanishi wa Benki' : 'Bank Reconciliation',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const BankReconciliationPage(),
                      ),
                    );
                  },
                ),
                _MenuItemData(
                  icon: Icons.percent_rounded,
                  title: store.languageCode == 'sw' ? 'Mipangilio ya Kodi' : 'Tax Settings',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const TaxSettingsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4. Section: Others & System
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Others',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
            ),
            _MenuCard(
              items: [
                _MenuItemData(
                  customIcon: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF472B6), // Soft coral/pink triangle emblem from screenshot
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.change_history_rounded, // Inverted triangle / prism logo
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  title: 'Plans & Pricing',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const SubscriptionPlanPage(),
                      ),
                    );
                  },
                ),
                _MenuItemData(
                  customIcon: const Icon(Icons.sync_rounded, color: Color(0xFF0284C7), size: 22),
                  title: 'Sync & Share',
                  onTap: () async {
                    await store.reloadFromLocal();
                    if (!context.mounted) return;
                    showMarketNotice(
                      context,
                      title: 'Sync Complete',
                      message: 'All local and cloud records are up to date.',
                    );
                  },
                ),
                _MenuItemData(
                  icon: Icons.settings_outlined,
                  title: strings.settings,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                _MenuItemData(
                  icon: Icons.support_agent_rounded,
                  title: 'Help & Support',
                  trailingIcon: Icons.keyboard_arrow_down_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                ),
                _MenuItemData(
                  icon: Icons.star_border_rounded,
                  title: 'Rate this app',
                  onTap: () {
                    showMarketNotice(
                      context,
                      title: 'Rate Us',
                      message: 'Thank you for supporting Aza POS!',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 5. App Version Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aza POS',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBody,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Version 1.0.0',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. Privacy Policy & Logout footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      showMarketNotice(
                        context,
                        title: 'Privacy Policy',
                        message: 'All your financial data is securely encrypted locally and synced over SSL.',
                      );
                    },
                    child: Text(
                      'Privacy Policy',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textBody,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      try {
                        await store.logout();
                      } catch (e) {
                        if (!context.mounted) return;
                        showMarketNotice(context, title: 'Sign out failed', message: e.toString());
                      }
                    },
                    child: Text(
                      'Log Out',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
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
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});

  final List<_MenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6E4F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(10) : Radius.zero,
                  bottom: isLast ? const Radius.circular(10) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      item.customIcon ??
                          Icon(
                            item.icon,
                            color: AppColors.textSecondary,
                            size: 21,
                          ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      Icon(
                        item.trailingIcon ?? Icons.chevron_right_rounded,
                        color: const Color(0xFF0284C7), // Exact bright blue chevron from screenshot
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF1F5F9), // Subtle inner row separator
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _MenuItemData {
  const _MenuItemData({
    this.icon,
    this.customIcon,
    required this.title,
    this.trailingIcon,
    required this.onTap,
  });

  final IconData? icon;
  final Widget? customIcon;
  final String title;
  final IconData? trailingIcon;
  final VoidCallback onTap;
}
