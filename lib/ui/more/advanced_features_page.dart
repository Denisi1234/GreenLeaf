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
  final _searchFocusNode = FocusNode();
  final _queryNotifier = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
          AppColors.kpiSky, // Indigo
          AppColors.kpiSkyBg,
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
      appBar: AppBar(
        title: Text(
          t('Advanced features', 'Vipengele vya juu'),
          style: AppTypography.cardHeader.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        backgroundColor: AppColors.headerSurface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sharp borderless ERP filter bar
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (v) => _queryNotifier.value = v,
                textInputAction: TextInputAction.search,
                style: AppTypography.bodyMain,
                decoration: InputDecoration(
                  hintText: t('Filter modules...', 'Tafuta moduli...'),
                  hintStyle: AppTypography.label,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: ValueListenableBuilder<String>(
                    valueListenable: _queryNotifier,
                    builder: (_, q, __) => q.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _queryNotifier.value = '';
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                  filled: true,
                  fillColor: AppColors.pageBackground,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.ink, width: 1),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
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
                    return Center(
                      child: Text(
                        t('No matching modules', 'Hakuna moduli iliyopatikana'),
                        style: AppTypography.label,
                      ),
                    );
                  }

                  return ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: visibleSections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final section = visibleSections[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                          // Sharp borderless ERP card surface
                          Material(
                            color: AppColors.sectionSurface,
                            borderRadius: BorderRadius.zero,
                            child: Column(
                              children: [
                                for (var i = 0;
                                    i < section.tools.length;
                                    i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      indent: 68,
                                      color: AppColors.divider,
                                    ),
                                  InkWell(
                                    onTap: () {
                                      _searchFocusNode.unfocus();
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              section.tools[i].builder(),
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
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: section.tools[i].badgeBg,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              section.tools[i].icon,
                                              color: section.tools[i].iconColor,
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
                                                  style: AppTypography.bodyMain
                                                      .copyWith(
                                                    fontWeight: FontWeight.w700,
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
