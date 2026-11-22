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

class MorePage extends StatefulWidget {
  const MorePage({super.key, this.useSharedShell = false});
  final bool useSharedShell;

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final _searchController = TextEditingController();
  final _queryNotifier = ValueNotifier<String>('');
  bool _signingOut = false;

  @override
  void dispose() {
    _searchController.dispose();
    _queryNotifier.dispose();
    super.dispose();
  }

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

    final sections = <_ToolSection>[
      _ToolSection(t('Essentials', 'Muhimu'), [
        _Tool(
          'orders',
          Icons.receipt_outlined,
          AppColors.primaryDeep, // Cyan
          AppColors.primaryLight,
          t('Orders & receipts', 'Oda na risiti'),
          t('Sales history, receipts and returns',
              'Historia ya mauzo, risiti na marejesho'),
          () => const OrderHistoryPage(),
        ),
        _Tool(
          'customers',
          Icons.people_outline_rounded,
          AppColors.kpiSky, // Blue
          AppColors.kpiSkyBg,
          strings.customers,
          t('Customer details and purchase history',
              'Taarifa za wateja na historia ya manunuzi'),
          () => const CustomersPage(),
        ),
        _Tool(
          'debtors',
          Icons.account_balance_wallet_outlined,
          AppColors.kpiAmber, // Amber
          AppColors.kpiAmberBg,
          strings.debitLedger,
          t('Outstanding balances and repayments',
              'Madeni na malipo ya wateja'),
          () => const DebtorsPage(),
          permission: 'Manage Payments',
        ),
        _Tool(
          'expenses',
          Icons.receipt_long_outlined,
          AppColors.kpiRose, // Rose
          AppColors.kpiRoseBg,
          strings.expensesTracking,
          t('Record and review business spending',
              'Rekodi na kagua matumizi ya biashara'),
          () => const ExpensesTrackingPage(),
          permission: 'Manage Payments',
        ),
        _Tool(
          'reports',
          Icons.analytics_outlined,
          AppColors.kpiSuccess, // Teal
          AppColors.kpiSuccessBg,
          strings.reports,
          t('Sales, stock and financial reports',
              'Ripoti za mauzo, hifadhi na fedha'),
          () => const ReportHubPage(),
          permission: 'View Reports',
        ),
      ]),
      _ToolSection(t('System & more', 'Mfumo na zaidi'), [
        if (hasAdvancedAccess)
          _Tool(
            'advanced',
            Icons.tune_rounded,
            AppColors.kpiViolet, // Violet
            AppColors.kpiVioletBg,
            t('Advanced features', 'Vipengele vya juu'),
            t('Suppliers, register, accounting, stores & staff',
                'Wasambazaji, kasha, uhasibu, maduka na wafanyakazi'),
            () => const AdvancedFeaturesPage(),
          ),
        _Tool(
          'settings',
          Icons.settings_outlined,
          AppColors.textBody, // Slate
          AppColors.surfaceSecondary,
          strings.settings,
          t('Business, receipt and account preferences',
              'Mapendeleo ya biashara, risiti na akaunti'),
          () => const SettingsPage(),
          permission: 'System Settings',
        ),
      ]),
    ];

    return Scaffold(
      drawer: widget.useSharedShell ? null : const MarketAppDrawer(),
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        top: !widget.useSharedShell,
        child: Column(
          children: [
            // Consistent sharp search bar matching Items & Sales pages
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
                      .map((s) => _ToolSection(
                            s.title,
                            s.tools.where((tool) {
                              final allowed = tool.permission == null ||
                                  store.hasPermission(tool.permission!);
                              if (!allowed) return false;
                              if (needle.isEmpty) return true;
                              return tool.title
                                      .toLowerCase()
                                      .contains(needle) ||
                                  tool.description
                                      .toLowerCase()
                                      .contains(needle);
                            }).toList(),
                          ))
                      .where((s) => s.tools.isNotEmpty)
                      .toList();

                  return ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    children: [
                      if (visibleSections.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: MarketEmptyState(
                            icon: Icons.search_off_rounded,
                            title: t('No matching tools',
                                'Hakuna zana zinazolingana'),
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
                        )
                      else
                        for (var sIdx = 0;
                            sIdx < visibleSections.length;
                            sIdx++) ...[
                          if (sIdx > 0) const SizedBox(height: 18),
                          _FullWidthToolSection(
                            section: visibleSections[sIdx],
                            onBeforeNavigate: () =>
                                FocusScope.of(context).unfocus(),
                          ),
                        ],
                      const SizedBox(height: 20),
                      // Rounded Sign Out card matching section cards
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
                          child: InkWell(
                            key: const ValueKey('more-sign-out'),
                            onTap: _signingOut ? null : _signOut,
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
                                      color: AppColors.kpiDangerBg,
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.sharp),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      color: AppColors.dangerDeep,
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      _signingOut
                                          ? t('Signing out…', 'Inaondoka…')
                                          : strings.logout,
                                      style: AppTypography.bodyMain.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.dangerDeep,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _FullWidthToolSection extends StatelessWidget {
  const _FullWidthToolSection({
    required this.section,
    required this.onBeforeNavigate,
  });

  final _ToolSection section;
  final VoidCallback onBeforeNavigate;

  @override
  Widget build(BuildContext context) {
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
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: AppColors.border),
          ),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                for (var i = 0; i < section.tools.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 66,
                      color: AppColors.border,
                    ),
                InkWell(
                  key: ValueKey('more-${section.tools[i].id}'),
                  onTap: () {
                    onBeforeNavigate();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => section.tools[i].page(),
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
                            borderRadius: BorderRadius.circular(8),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.tools[i].title,
                                style: AppTypography.bodyMain.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                section.tools[i].description,
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
  }
}

class _ToolSection {
  const _ToolSection(this.title, this.tools);
  final String title;
  final List<_Tool> tools;
}

class _Tool {
  const _Tool(
    this.id,
    this.icon,
    this.iconColor,
    this.badgeBg,
    this.title,
    this.description,
    this.page, {
    this.permission,
  });
  final String id;
  final IconData icon;
  final Color iconColor;
  final Color badgeBg;
  final String title;
  final String description;
  final Widget Function() page;
  final String? permission;
}
