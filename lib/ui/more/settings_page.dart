import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'settings_layout.dart';
import 'widgets/about_settings_pane.dart';
import 'widgets/account_settings_pane.dart';
import 'widgets/business_settings_pane.dart';
import 'widgets/data_sync_settings_pane.dart';
import 'widgets/language_settings_pane.dart';
import 'widgets/receipt_settings_pane.dart';

/// Professional settings workspace.
///
/// Six sections in a searchable sidebar on desktop and a section list on mobile.
/// Section state is preserved while switching tabs, including unsaved edits.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.initialSection});

  final SettingsSection? initialSection;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum SettingsSection { business, receipt, language, data, account, about }

class _SectionInfo {
  const _SectionInfo(this.section, this.icon, this.label);
  final SettingsSection section;
  final IconData icon;
  final String label;
}

List<_SectionInfo> _tabs(String lang) {
  String t(String en, String sw) => settingsText(lang, en, sw);
  return [
    _SectionInfo(
      SettingsSection.business,
      Icons.storefront_outlined,
      t('Business', 'Biashara'),
    ),
    _SectionInfo(
      SettingsSection.receipt,
      Icons.receipt_long_outlined,
      t('Receipts', 'Risiti'),
    ),
    _SectionInfo(
      SettingsSection.language,
      Icons.translate_rounded,
      t('Language', 'Lugha'),
    ),
    _SectionInfo(
      SettingsSection.data,
      Icons.cloud_sync_outlined,
      t('Data', 'Data'),
    ),
    _SectionInfo(
      SettingsSection.account,
      Icons.manage_accounts_outlined,
      t('Account', 'Akaunti'),
    ),
    _SectionInfo(
      SettingsSection.about,
      Icons.info_outline_rounded,
      t('About', 'Kuhusu'),
    ),
  ];
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsSection? _selectedSection;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<SettingsSection> _visited = {SettingsSection.business};

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection;
    if (widget.initialSection != null) _visited.add(widget.initialSection!);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(SettingsSection section) {
    setState(() {
      _selectedSection = section;
      _visited.add(section);
    });
  }

  Widget _buildPane(SettingsSection section) {
    switch (section) {
      case SettingsSection.business:
        return const BusinessSettingsPane();
      case SettingsSection.receipt:
        return const ReceiptSettingsPane();
      case SettingsSection.language:
        return const LanguageSettingsPane();
      case SettingsSection.data:
        return const DataSyncSettingsPane();
      case SettingsSection.account:
        return const AccountSettingsPane();
      case SettingsSection.about:
        return const AboutSettingsPane();
    }
  }

  String _description(SettingsSection section, String lang) {
    final (en, sw) = switch (section) {
      SettingsSection.business => (
          'Business details, currency and daily reports',
          'Taarifa za biashara, sarafu na ripoti za kila siku'
        ),
      SettingsSection.receipt => (
          'Receipt layout, branding and printing',
          'Mpangilio wa risiti, nembo na uchapishaji'
        ),
      SettingsSection.language => (
          'Language and regional preferences',
          'Lugha na mapendeleo ya eneo'
        ),
      SettingsSection.data => (
          'Cloud connection, sync and backups',
          'Muunganisho wa wingu, usawazishaji na nakala'
        ),
      SettingsSection.account => (
          'Profile, password and security',
          'Wasifu, nenosiri na usalama'
        ),
      SettingsSection.about => (
          'App information, support and policies',
          'Taarifa za programu, msaada na sera'
        ),
    };
    return settingsText(lang, en, sw);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<PosLocalStore>().languageCode;
    final tabs = _tabs(lang);
    final filtered = tabs
        .where((tab) => '${tab.label} ${_description(tab.section, lang)}'
            .toLowerCase()
            .contains(_searchQuery.trim().toLowerCase()))
        .toList();
    final selected = _selectedSection ?? SettingsSection.business;
    final current = tabs.firstWhere((tab) => tab.section == selected);
    final panes = IndexedStack(
      index: selected.index,
      children: [
        for (final tab in tabs)
          _visited.contains(tab.section)
              ? KeyedSubtree(
                  key: ValueKey(tab.section),
                  child: TickerMode(
                      enabled: tab.section == selected,
                      child: _buildPane(tab.section)))
              : const SizedBox.shrink()
      ],
    );
    final search = MarketSearchField(
      controller: _searchController,
      hintText: settingsText(lang, 'Search settings', 'Tafuta mipangilio'),
      onChanged: (value) => setState(() => _searchQuery = value),
      onClear: () => setState(() {
        _searchController.clear();
        _searchQuery = '';
      }),
    );
    Widget menu(bool wide) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          search,
          const SizedBox(height: 16),
          Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                          settingsText(lang, 'No matching settings',
                              'Hakuna mipangilio inayolingana'),
                          style: AppTypography.bodySmall))
                  : WorkspacePanel(
                      padding: EdgeInsets.zero,
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.borderLight),
                        itemBuilder: (context, index) {
                          final tab = filtered[index];
                          final active = wide && tab.section == selected;
                          const palettes = [
                            (AppColors.kpiRoseBg, AppColors.kpiRose),
                            (AppColors.kpiSkyBg, AppColors.kpiSky),
                            (AppColors.kpiAmberBg, AppColors.kpiAmber),
                            (AppColors.kpiDangerBg, AppColors.kpiDanger),
                          ];
                          final palette = palettes[index % palettes.length];
                          return Material(
                            color: active
                                ? AppColors.surfaceSecondary
                                : Colors.transparent,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: palette.$1,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Icon(tab.icon,
                                    size: 20, color: palette.$2),
                              ),
                              title: Text(tab.label,
                                  style: AppTypography.bodyMedium
                                      .copyWith(fontWeight: FontWeight.w700)),
                              subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(_description(tab.section, lang),
                                      style: AppTypography.label)),
                              trailing: wide
                                  ? null
                                  : const Icon(Icons.chevron_right_rounded,
                                      size: 20, color: AppColors.textMuted),
                              onTap: () => _openDetail(tab.section),
                            ),
                          );
                        },
                      ),
                    )),
        ]);
    final detail =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
          child: WorkspaceHeading(
            title: current.label,
            subtitle: _description(selected, lang),
          )),
      Expanded(
          child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: panes,
              ))),
    ]);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return PopScope(
              canPop: wide || _selectedSection == null,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && !wide) setState(() => _selectedSection = null);
              },
              child: Column(children: [
                MarketPageHeader(
                  title: settingsText(lang, 'Settings', 'Mipangilio'),
                  subtitle: settingsText(
                      lang,
                      'Manage your business preferences',
                      'Dhibiti mapendeleo ya biashara yako'),
                  onBack: () {
                    if (!wide && _selectedSection != null) {
                      setState(() => _selectedSection = null);
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
                Expanded(
                    child: Padding(
                  padding: EdgeInsets.all(wide ? 24 : 16),
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              SizedBox(width: 270, child: menu(true)),
                              const SizedBox(width: 24),
                              Expanded(child: detail),
                            ])
                      : IndexedStack(
                          index: _selectedSection == null ? 0 : 1,
                          children: [
                              menu(false),
                              TickerMode(
                                  enabled: _selectedSection != null,
                                  child: detail)
                            ]),
                )),
              ]),
            );
          }))),
    );
  }
}
