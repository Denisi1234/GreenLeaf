import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../accounting/accounts_page.dart';
import '../accounting/bank_reconciliation_page.dart';
import '../accounting/fixed_assets_page.dart';
import '../payment/cash_register_page.dart';
import '../reports/report_hub_page.dart';
import '../settings/tax_settings_page.dart';
import '../suppliers/receiving_page.dart';
import '../suppliers/suppliers_page.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'about_app_page.dart';
import 'customers_page.dart';
import 'debtors_page.dart';
import 'expenses_tracking_page.dart';
import 'help_support_page.dart';
import 'privacy_policy_page.dart';
import 'settings_page.dart';
import 'staff_management_page.dart';
import 'stores_page.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key, this.useSharedShell = false});
  final bool useSharedShell;

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final _searchController = TextEditingController();
  String _query = '';
  bool _signingOut = false;

  @override
  void dispose() {
    _searchController.dispose();
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
    final sections = [
      _ToolSection(t('Daily operations', 'Shughuli za kila siku'), [
        _Tool(
            'customers',
            Icons.people_outline_rounded,
            strings.customers,
            t('Customer details and purchase history',
                'Taarifa za wateja na historia ya manunuzi'),
            () => const CustomersPage()),
        _Tool(
            'debtors',
            Icons.account_balance_wallet_outlined,
            strings.debitLedger,
            t('Outstanding balances and repayments',
                'Madeni na malipo ya wateja'),
            () => const DebtorsPage()),
        _Tool(
            'suppliers',
            Icons.local_shipping_outlined,
            t('Suppliers', 'Wasambazaji'),
            t('Supplier contacts and purchase records',
                'Mawasiliano na rekodi za manunuzi'),
            () => const SuppliersPage()),
        _Tool(
            'receiving',
            Icons.move_to_inbox_outlined,
            t('Goods received', 'Bidhaa zilizopokelewa'),
            t('Record deliveries and update stock',
                'Rekodi usambazaji na sasisha hifadhi'),
            () => const ReceivingPage()),
        _Tool(
            'register',
            Icons.point_of_sale_outlined,
            t('Cash register', 'Kasha la pesa'),
            t('Open shifts, cash movements and closing',
                'Zamu, miamala na kufunga kasha'),
            () => const CashRegisterPage()),
        _Tool(
            'expenses',
            Icons.receipt_long_outlined,
            strings.expensesTracking,
            t('Record and review business spending',
                'Rekodi na kagua matumizi ya biashara'),
            () => const ExpensesTrackingPage()),
      ]),
      _ToolSection(t('Reports & finance', 'Ripoti na fedha'), [
        _Tool(
            'reports',
            Icons.analytics_outlined,
            strings.reports,
            t('Sales, stock and financial reports',
                'Ripoti za mauzo, hifadhi na fedha'),
            () => const ReportHubPage()),
        _Tool(
            'accounts',
            Icons.account_balance_outlined,
            t('Accounts & ledger', 'Akaunti na daftari'),
            t('Accounts, entries and balances', 'Akaunti, miamala na salio'),
            () => const AccountsPage()),
        _Tool(
            'assets',
            Icons.chair_outlined,
            t('Fixed assets', 'Mali za kudumu'),
            t('Business assets and depreciation',
                'Mali za biashara na uchakavu'),
            () => const FixedAssetsPage()),
        _Tool(
            'bank',
            Icons.fact_check_outlined,
            t('Bank reconciliation', 'Upatanishi wa benki'),
            t('Match statements with recorded payments',
                'Linganisha taarifa za benki na malipo'),
            () => const BankReconciliationPage()),
        _Tool(
            'tax',
            Icons.percent_rounded,
            t('Tax settings', 'Mipangilio ya kodi'),
            t('Tax rates and reporting preferences',
                'Viwango vya kodi na mapendeleo ya ripoti'),
            () => const TaxSettingsPage()),
      ]),
      _ToolSection(t('Business management', 'Usimamizi wa biashara'), [
        _Tool(
            'stores',
            Icons.storefront_outlined,
            t('Stores', 'Maduka'),
            t('Manage locations and switch stores',
                'Dhibiti maeneo na badilisha duka'),
            () => const StoresPage()),
        _Tool(
            'staff',
            Icons.badge_outlined,
            strings.staffManagement,
            t('Team members, roles and permissions',
                'Wafanyakazi, majukumu na ruhusa'),
            () => const StaffManagementPage()),
        _Tool(
            'settings',
            Icons.settings_outlined,
            strings.settings,
            t('Business, receipt and account preferences',
                'Mapendeleo ya biashara, risiti na akaunti'),
            () => const SettingsPage()),
      ]),
    ];
    final query = _query.trim().toLowerCase();
    final filtered = [
      for (final section in sections)
        _ToolSection(
            section.title,
            section.tools
                .where((tool) =>
                    query.isEmpty ||
                    '${section.title} ${tool.title} ${tool.description}'
                        .toLowerCase()
                        .contains(query))
                .toList())
    ].where((section) => section.tools.isNotEmpty).toList();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      drawer: widget.useSharedShell
          ? null
          : MarketAppDrawer(selectedItem: strings.more),
      appBar: widget.useSharedShell ? null : AppBar(title: Text(strings.more)),
      body: SafeArea(
          top: !widget.useSharedShell,
          child: LayoutBuilder(builder: (context, constraints) {
            final padding = constraints.maxWidth >= 900 ? 24.0 : 16.0;
            return CustomScrollView(slivers: [
              SliverPadding(
                  padding: EdgeInsets.all(padding),
                  sliver: SliverList.list(children: [
                    Row(children: [
                      const Icon(Icons.storefront_outlined,
                          size: 20, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(store.activeStoreName,
                              style: AppTypography.bodyMedium
                                  .copyWith(fontWeight: FontWeight.w700)))
                    ]),
                    const SizedBox(height: 16),
                    MarketSearchField(
                      controller: _searchController,
                      hintText: t('Find a tool or setting', 'Tafuta zana au mpangilio'),
                      onChanged: (value) => setState(() => _query = value),
                      onClear: () => setState(() {
                        _searchController.clear();
                        _query = '';
                      }),
                    ),
                    const SizedBox(height: 24),
                    if (filtered.isEmpty)
                      WorkspacePanel(
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Column(children: [
                                const Icon(Icons.search_off_rounded,
                                    size: 36, color: AppColors.textMuted),
                                const SizedBox(height: 16),
                                Text(
                                    t('No matching tools',
                                        'Hakuna zana zinazolingana'),
                                    style: AppTypography.h3),
                                const SizedBox(height: 8),
                                Text(
                                    t('Try a different search.',
                                        'Jaribu utafutaji mwingine.'),
                                    style: AppTypography.bodySmall),
                                const SizedBox(height: 12),
                                TextButton(
                                    onPressed: () => setState(() {
                                          _searchController.clear();
                                          _query = '';
                                        }),
                                    child: Text(
                                        t('Clear search', 'Futa utafutaji'))),
                              ])))
                    else
                      LayoutBuilder(builder: (context, contentConstraints) {
                        final columns = contentConstraints.maxWidth >= 1300
                            ? 3
                            : contentConstraints.maxWidth >= 800
                                ? 2
                                : 1;
                        final width =
                            (contentConstraints.maxWidth - (columns - 1) * 20) /
                                columns;
                        final groups =
                            List.generate(columns, (_) => <_ToolSection>[]);
                        final weights = List.filled(columns, 0);
                        for (final section in filtered) {
                          var target = 0;
                          for (var index = 1; index < columns; index++) {
                            if (weights[index] < weights[target]) {
                              target = index;
                            }
                          }
                          groups[target].add(section);
                          weights[target] += section.tools.length + 1;
                        }
                        return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var column = 0;
                                  column < columns;
                                  column++) ...[
                                if (column > 0) const SizedBox(width: 20),
                                SizedBox(
                                    width: width,
                                    child: Column(children: [
                                      for (final section in groups[column])
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 20),
                                            child:
                                                _ToolPanel(section: section)),
                                    ])),
                              ]
                            ]);
                      }),
                    const Divider(height: 32, color: AppColors.border),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          key: const ValueKey('more-sign-out'),
                          onPressed: _signingOut ? null : _signOut,
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.dangerDeep),
                          icon: const Icon(Icons.logout_rounded, size: 19),
                          label: Text(_signingOut
                              ? t('Signing out…', 'Inaondoka…')
                              : strings.logout),
                        )),
                  ]))
            ]);
          })),
    );
  }
}

class _ToolSection {
  const _ToolSection(this.title, this.tools);
  final String title;
  final List<_Tool> tools;
}

class _Tool {
  const _Tool(this.id, this.icon, this.title, this.description, this.page);
  final String id;
  final IconData icon;
  final String title;
  final String description;
  final Widget Function() page;
}

class _ToolPanel extends StatelessWidget {
  const _ToolPanel({required this.section});
  final _ToolSection section;

  @override
  Widget build(BuildContext context) => WorkspacePanel(
      padding: EdgeInsets.zero,
      child: Column(children: [
        Container(
            width: double.infinity,
            color: AppColors.surfaceSecondary,
            padding: const EdgeInsets.all(18),
            child: Text(section.title, style: AppTypography.sectionHeader)),
        for (var index = 0; index < section.tools.length; index++) ...[
          if (index > 0) const Divider(height: 1, color: AppColors.borderLight),
          Builder(builder: (context) {
            const palettes = [
              (Color(0xFFFCE7F3), Color(0xFFBE185D)), // Rose / Sales
              (Color(0xFFE0F2FE), Color(0xFF0369A1)), // Sky / Stock
              (Color(0xFFFEF3C7), Color(0xFFB45309)), // Amber / Warning
              (Color(0xFFFEE2E2), Color(0xFFB91C1C)), // Red / Out
            ];
            final palette = palettes[index % palettes.length];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                key: ValueKey('more-${section.tools[index].id}'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => section.tools[index].page())),
                child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: palette.$1,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              section.tools[index].icon,
                              size: 20,
                              color: palette.$2,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(section.tools[index].title,
                                    style: AppTypography.bodyMedium
                                        .copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(section.tools[index].description,
                                    style: AppTypography.label
                                        .copyWith(height: 1.4)),
                              ])),
                          const SizedBox(width: 12),
                          const Icon(Icons.chevron_right_rounded,
                              size: 19, color: AppColors.textMuted),
                        ])),
              ),
            );
          }),
        ],
      ]));
}
