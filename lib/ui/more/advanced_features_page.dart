import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../accounting/accounts_page.dart';
import '../accounting/bank_reconciliation_page.dart';
import '../accounting/fixed_assets_page.dart';
import '../payment/cash_register_page.dart';
import '../settings/tax_settings_page.dart';
import '../suppliers/receiving_page.dart';
import '../suppliers/suppliers_page.dart';
import '../widgets/app_design.dart';
import '../widgets/common/market_empty_state.dart';
import '../widgets/common/market_page_header.dart';
import '../widgets/common/market_search_field.dart';
import 'staff_management_page.dart';
import 'stores_page.dart';

/// Sharp, borderless ERP module directory for back-office & advanced tools.
class AdvancedFeaturesPage extends StatefulWidget {
  const AdvancedFeaturesPage({super.key});

  @override
  State<AdvancedFeaturesPage> createState() => _AdvancedFeaturesPageState();
}

class _AdvancedFeaturesPageState extends State<AdvancedFeaturesPage> {
  final _searchController = TextEditingController();
  final _queryNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchController.dispose();
    _queryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    String t(String en, String sw) => store.languageCode == 'sw' ? sw : en;

    final sections = <_AdvSection>[
      _AdvSection(t('Stock & register', 'Hifadhi na kasha'), [
        _AdvTool(
          Icons.local_shipping_outlined,
          AppColors.kpiSky, // Blue
          AppColors.kpiSkyBg,
          t('Suppliers', 'Wasambazaji'),
          t('Supplier contacts and purchase records',
              'Mawasiliano na rekodi za manunuzi'),
          () => const SuppliersPage(),
          permission: 'Manage Inventory',
        ),
        _AdvTool(
          Icons.move_to_inbox_outlined,
          AppColors.kpiSuccess, // Teal
          AppColors.kpiSuccessBg,
          t('Goods received', 'Bidhaa zilizopokelewa'),
          t('Record deliveries and update stock',
              'Rekodi usambazaji na sasisha hifadhi'),
          () => const ReceivingPage(),
          permission: 'Manage Inventory',
        ),
        _AdvTool(
          Icons.point_of_sale_outlined,
          AppColors.kpiAmber, // Amber
          AppColors.kpiAmberBg,
          t('Cash register', 'Kasha la pesa'),
          t('Open shifts, cash movements and closing',
              'Zamu, miamala na kufunga kasha'),
          () => const CashRegisterPage(),
          permission: 'Manage Payments',
        ),
      ]),
      _AdvSection(t('Accounting & tax', 'Uhasibu na kodi'), [
        _AdvTool(
          Icons.account_balance_outlined,
          AppColors.primaryDeep, // Cyan
          AppColors.primaryLight,
          t('Accounts & ledger', 'Akaunti na daftari'),
          t('Accounts, entries and balances', 'Akaunti, miamala na salio'),
          () => const AccountsPage(),
          permission: 'View Reports',
        ),
        _AdvTool(
          Icons.chair_outlined,
          AppColors.kpiViolet, // Violet
          AppColors.kpiVioletBg,
          t('Fixed assets', 'Mali za kudumu'),
          t('Business assets and depreciation',
              'Mali za biashara na uchakavu'),
          () => const FixedAssetsPage(),
          permission: 'View Reports',
        ),
        _AdvTool(
          Icons.fact_check_outlined,
          AppColors.kpiSky, // Sky
          AppColors.kpiSkyBg,
          t('Bank reconciliation', 'Upatanishi wa benki'),
          t('Match statements with recorded payments',
              'Linganisha taarifa za benki na malipo'),
          () => const BankReconciliationPage(),
          permission: 'Manage Payments',
        ),
        _AdvTool(
          Icons.percent_rounded,
          AppColors.kpiRose, // Rose
          AppColors.kpiRoseBg,
          t('Tax settings', 'Mipangilio ya kodi'),
          t('Tax rates and reporting preferences',
              'Viwango vya kodi na mapendeleo ya ripoti'),
          () => const TaxSettingsPage(),
          permission: 'System Settings',
        ),
      ]),
      _AdvSection(t('Multi-store & team', 'Maduka na timu'), [
        _AdvTool(
          Icons.storefront_outlined,
          AppColors.kpiSuccess, // Green
          AppColors.kpiSuccessBg,
          t('Stores', 'Maduka'),
          t('Manage locations and switch stores',
              'Dhibiti maeneo na badilisha duka'),
          () => const StoresPage(),
          permission: 'System Settings',
        ),
        _AdvTool(
          Icons.badge_outlined,
          AppColors.textBody, // Slate
          AppColors.surfaceSecondary,
          strings.staffManagement,
          t('Team members, roles and permissions',
              'Wafanyakazi, majukumu na ruhusa'),
          () => const StaffManagementPage(),
          permission: 'Manage Staff',
        ),
      ]),
    ];

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          MarketPageHeader(
            title: t('Advanced features', 'Vipengele vya juu'),
            subtitle: t(
              'Suppliers, register, accounting, stores & staff',
              'Wasambazaji, kasha, uhasibu, maduka na wafanyakazi',
            ),
            showBackButton: true,
            centerTitle: false,
            titleSize: 22,
            titleWeight: FontWeight.w800,
            showBorder: true,
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
          children: [
            // Consistent sharp search bar matching Items, Sales & More pages
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: MarketSearchField(
                controller: _searchController,
                hintText: t('Filter modules...', 'Tafuta moduli...'),
                onChanged: (v) => _queryNotifier.value = v,
                onClear: () {
                  _searchController.clear();
                  _queryNotifier.value = '';
                },
                height: 48,
                radius: 0,
                backgroundColor: AppColors.surface,
                borderColor: AppColors.border,
                paddingHorizontal: 14,
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<String>(
                valueListenable: _queryNotifier,
                builder: (context, query, _) {
                  final needle = query.trim().toLowerCase();
                  final visibleSections = sections
                      .map((s) => _AdvSection(
                            s.title,
                            s.tools.where((tool) {
                              final allowed = tool.permission == null ||
                                  store.hasPermission(tool.permission!);
                              if (!allowed) return false;
                              if (needle.isEmpty) return true;
                              return tool.title
                                      .toLowerCase()
                                      .contains(needle) ||
                                  tool.subtitle.toLowerCase().contains(needle);
                            }).toList(),
                          ))
                      .where((s) => s.tools.isNotEmpty)
                      .toList();

                  if (visibleSections.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 24,
                      ),
                      child: MarketEmptyState(
                        icon: Icons.search_off_rounded,
                        title: t(
                            'No matching modules', 'Hakuna moduli iliyopatikana'),
                        message: t(
                          'Try a different keyword or clear your search.',
                          'Jaribu neno lingine au ondoa utafutaji.',
                        ),
                        actionLabel: t('Clear search', 'Ondoa utafutaji'),
                        actionIcon: Icons.filter_alt_off_rounded,
                        onAction: () {
                          _searchController.clear();
                          _queryNotifier.value = '';
                        },
                      ),
                    );
                  }

                  return ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    itemCount: visibleSections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 18),
                    itemBuilder: (context, index) {
                      final section = visibleSections[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                            child: Row(
                              children: [
                                Text(
                                  section.title.toUpperCase(),
                                  style: AppTypography.label.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.7,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${section.tools.length}',
                                  style: AppTypography.label.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rounded bordered card matching More & Dashboard
                          Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.standard),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < section.tools.length;
                                      i++) ...[
                                    if (i > 0)
                                      const Divider(
                                        height: 1,
                                        indent: 66,
                                        color: AppColors.border,
                                      ),
                                    InkWell(
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                section.tools[i].builder(),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: section.tools[i].badgeBg,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        AppRadius.sharp),
                                              ),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                section.tools[i].icon,
                                                color:
                                                    section.tools[i].iconColor,
                                                size: 19,
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    section.tools[i].title,
                                                    style: AppTypography
                                                        .bodyMain
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppColors.ink,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    section.tools[i].subtitle,
                                                    style: AppTypography.label,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              size: 20,
                                              color: AppColors.textMuted,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
          ),
        ],
      ),
    );
  }
}

class _AdvSection {
  const _AdvSection(this.title, this.tools);
  final String title;
  final List<_AdvTool> tools;
}

class _AdvTool {
  const _AdvTool(
    this.icon,
    this.iconColor,
    this.badgeBg,
    this.title,
    this.subtitle,
    this.builder, {
    this.permission,
  });

  final IconData icon;
  final Color iconColor;
  final Color badgeBg;
  final String title;
  final String subtitle;
  final Widget Function() builder;
  final String? permission;
}
