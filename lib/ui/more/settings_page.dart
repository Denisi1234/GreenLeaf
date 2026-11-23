import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/app_theme_palette.dart';
import '../widgets/market_shared_widgets.dart';
import 'settings_layout.dart';
import 'widgets/account_settings_pane.dart';
import 'widgets/business_settings_pane.dart';
import 'widgets/data_sync_settings_pane.dart';
import 'widgets/language_settings_pane.dart';
import 'widgets/receipt_settings_pane.dart';

/// Clean, native Android/iOS Settings screen supporting all app themes.
///
/// Five focused sections in a clean grouped list on mobile and a split sidebar
/// on tablets/desktops. Section state is preserved across tab switches.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.initialSection});

  final SettingsSection? initialSection;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum SettingsSection { business, receipt, language, data, account }

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
      Icons.palette_outlined,
      t('Theme & language', 'Mandhari na lugha'),
    ),
    _SectionInfo(
      SettingsSection.data,
      Icons.sms_outlined,
      t('Data & SMS', 'Data na SMS'),
    ),
    _SectionInfo(
      SettingsSection.account,
      Icons.manage_accounts_outlined,
      t('Account', 'Akaunti'),
    ),
  ];
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsSection? _selectedSection;
  final Set<SettingsSection> _visited = {SettingsSection.business};

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection;
    if (widget.initialSection != null) _visited.add(widget.initialSection!);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<PosLocalStore>().languageCode;
    final palette = AppThemePalette.of(context);
    final tabs = _tabs(lang);
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
                    child: _buildPane(tab.section),
                  ),
                )
              : const SizedBox.shrink(),
      ],
    );

    Widget buildMenu(bool wide) {
      final listCard = Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(AppRadius.standard),
          border: Border.all(color: palette.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 52,
                    color: palette.divider,
                  ),
                _SettingsMenuRow(
                  tab: tabs[i],
                  palette: palette,
                  active: wide && tabs[i].section == selected,
                  showChevron: !wide,
                  onTap: () => _openDetail(tabs[i].section),
                ),
              ],
            ],
          ),
        ),
      );

      if (wide) {
        return SingleChildScrollView(child: listCard);
      }
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            children: [listCard],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.pageBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final showingDetailOnMobile = !wide && _selectedSection != null;
          final headerTitle = showingDetailOnMobile
              ? current.label
              : settingsText(lang, 'Settings', 'Mipangilio');

          return PopScope(
            canPop: wide || _selectedSection == null,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && !wide) {
                setState(() => _selectedSection = null);
              }
            },
            child: Column(
              children: [
                MarketPageHeader(
                  title: headerTitle,
                  showBackButton: true,
                  centerTitle: false,
                  titleSize: 20,
                  titleWeight: FontWeight.w800,
                  showBorder: true,
                  onBack: () {
                    if (showingDetailOnMobile) {
                      setState(() => _selectedSection = null);
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
                Expanded(
                  child: SafeArea(
                    top: false,
                    child: wide
                        ? Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1120),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 260,
                                      child: buildMenu(true),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(child: panes),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : IndexedStack(
                            index: _selectedSection == null ? 0 : 1,
                            children: [
                              buildMenu(false),
                              TickerMode(
                                enabled: _selectedSection != null,
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints:
                                        const BoxConstraints(maxWidth: 640),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        14,
                                        12,
                                        0,
                                      ),
                                      child: panes,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingsMenuRow extends StatelessWidget {
  const _SettingsMenuRow({
    required this.tab,
    required this.palette,
    required this.active,
    required this.showChevron,
    required this.onTap,
  });

  final _SectionInfo tab;
  final AppThemePalette palette;
  final bool active;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        color: active ? palette.primaryLight : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(
              tab.icon,
              size: 22,
              color: active ? palette.primary : palette.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                tab.label,
                style: AppTypography.bodyMain.copyWith(
                  fontSize: 15,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? palette.primary : palette.ink,
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: palette.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
