import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../service/daily_sales_report_service.dart';
import '../../service/pos_local_store.dart';
import '../../service/receipt_settings.dart';
import '../../service/store_preferences.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/workspace_widgets.dart';
import '../widgets/market_shared_widgets.dart';
import 'about_app_page.dart';
import 'help_support_page.dart';
import 'privacy_policy_page.dart';
import 'settings_layout.dart';
import 'change_password_page.dart';
import 'store_profile_page.dart';
import 'terms_of_service_page.dart';

/// Professional settings workspace.
///
/// Six sections in a searchable sidebar on desktop and a section list on mobile.
/// Section state is preserved while switching tabs, including unsaved edits.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

enum _Section { business, receipt, language, data, account, about }

class _SectionInfo {
  const _SectionInfo(this.section, this.icon, this.label);
  final _Section section;
  final IconData icon;
  final String label;
}

List<_SectionInfo> _tabs(String lang) {
  String t(String en, String sw) => settingsText(lang, en, sw);
  return [
    _SectionInfo(
      _Section.business,
      Icons.storefront_outlined,
      t('Business', 'Biashara'),
    ),
    _SectionInfo(
      _Section.receipt,
      Icons.receipt_long_outlined,
      t('Receipts', 'Risiti'),
    ),
    _SectionInfo(
      _Section.language,
      Icons.translate_rounded,
      t('Language', 'Lugha'),
    ),
    _SectionInfo(
      _Section.data,
      Icons.cloud_sync_outlined,
      t('Data', 'Data'),
    ),
    _SectionInfo(
      _Section.account,
      Icons.manage_accounts_outlined,
      t('Account', 'Akaunti'),
    ),
    _SectionInfo(
      _Section.about,
      Icons.info_outline_rounded,
      t('About', 'Kuhusu'),
    ),
  ];
}

class _SettingsPageState extends State<SettingsPage> {
  _Section? _selectedSection;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<_Section> _visited = {_Section.business};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDetail(_Section section) {
    setState(() {
      _selectedSection = section;
      _visited.add(section);
    });
  }

  Widget _buildPane(_Section section) {
    switch (section) {
      case _Section.business:
        return const _BusinessPane();
      case _Section.receipt:
        return const _ReceiptForm();
      case _Section.language:
        return const _LanguagePane();
      case _Section.data:
        return const _DataSyncPane();
      case _Section.account:
        return const _AccountPane();
      case _Section.about:
        return const _AboutPane();
    }
  }

  String _description(_Section section, String lang) {
    final (en, sw) = switch (section) {
      _Section.business => (
          'Business details, currency and daily reports',
          'Taarifa za biashara, sarafu na ripoti za kila siku'
        ),
      _Section.receipt => (
          'Receipt layout, branding and printing',
          'Mpangilio wa risiti, nembo na uchapishaji'
        ),
      _Section.language => (
          'Language and regional preferences',
          'Lugha na mapendeleo ya eneo'
        ),
      _Section.data => (
          'Cloud connection, sync and backups',
          'Muunganisho wa wingu, usawazishaji na nakala'
        ),
      _Section.account => (
          'Profile, password and security',
          'Wasifu, nenosiri na usalama'
        ),
      _Section.about => (
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
    final selected = _selectedSection ?? _Section.business;
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
    final search = TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: settingsText(lang, 'Search settings', 'Tafuta mipangilio'),
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: settingsText(lang, 'Clear search', 'Futa utafutaji'),
                onPressed: () => setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                }),
                icon: const Icon(Icons.close_rounded),
              ),
      ),
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
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tab = filtered[index];
                        final active = wide && tab.section == selected;
                        return Material(
                          color: active
                              ? AppColors.primaryLight
                              : AppColors.surface,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                  color: active
                                      ? AppColors.primaryDeep
                                      : AppColors.border)),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: Icon(tab.icon,
                                color: active
                                    ? AppColors.primaryDeep
                                    : AppColors.textMuted),
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
                                    size: 20),
                            onTap: () => _openDetail(tab.section),
                          ),
                        );
                      },
                    )),
          const SizedBox(height: 12),
          const _ConnectionBadge(),
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
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return PopScope(
          canPop: wide || _selectedSection == null,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && !wide) setState(() => _selectedSection = null);
          },
          child: Column(children: [
            MarketPageHeader(
              title: settingsText(lang, 'Settings', 'Mipangilio'),
              subtitle: settingsText(lang, 'Manage your business preferences',
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
                              enabled: _selectedSection != null, child: detail)
                        ]),
            )),
          ]),
        );
      })),
    );
  }
}

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lang = store.languageCode;
    final connected = store.cloudApi != null;
    final fg = connected ? AppColors.successDeep : AppColors.textSecondary;
    final bg = connected ? AppColors.successLight : AppColors.surfaceHover;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: connected ? AppColors.successBright : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: connected ? AppColors.successBright : AppColors.textLight,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            connected
                ? settingsText(lang, 'Cloud connected', 'Imeunganishwa')
                : settingsText(lang, 'Offline mode', 'Hali ya nje ya mtandao'),
            style: AppTypography.label.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Business â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Business tab: a summary strip followed by the editable profile form.
class _BusinessPane extends StatelessWidget {
  const _BusinessPane();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _BusinessSummaryCard(),
        Expanded(child: StoreProfileForm(showOperations: true)),
      ],
    );
  }
}

class _BusinessSummaryCard extends StatelessWidget {
  const _BusinessSummaryCard();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);
    final profile = store.profile;
    final connected = store.cloudApi != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.zero,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.zero,
            ),
            child: Text(
              _initials(profile.storeName),
              style: AppTypography.cardHeader.copyWith(
                color: AppColors.primaryDeep,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.storeName.trim().isEmpty
                      ? t('Your store', 'Duka lako')
                      : profile.storeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMain.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (profile.ownerName.trim().isNotEmpty) profile.ownerName,
                    if (profile.contactNumber.trim().isNotEmpty)
                      profile.contactNumber,
                  ].join(' Â· '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            connected ? t('Cloud', 'Wingu') : t('On-device', 'Kifaa hiki'),
            style: AppTypography.helperText.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'SB';
    if (parts.length == 1) {
      final name = parts.first;
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Receipt â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ReceiptForm extends StatefulWidget {
  const _ReceiptForm();

  @override
  State<_ReceiptForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends State<_ReceiptForm> {
  final _header = TextEditingController();
  final _footer = TextEditingController();
  ReceiptSettings? _loaded;
  ReceiptSettings _draft = const ReceiptSettings();
  bool _saving = false;

  void _load(ReceiptSettings settings) {
    _loaded = settings;
    _draft = settings;
    _header.text = settings.header;
    _footer.text = settings.footer;
  }

  @override
  void dispose() {
    _header.dispose();
    _footer.dispose();
    super.dispose();
  }

  void _update(ReceiptSettings settings) {
    setState(() => _draft = settings);
  }

  Future<void> _save(PosLocalStore store) async {
    final lang = store.languageCode;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final next = _draft.copyWith(
        header: _header.text.trim(),
        footer: _footer.text.trim(),
      );
      await store.updateReceiptSettings(next);
      if (!mounted) return;
      _load(store.receiptSettings);
      showSettingsResult(
        context,
        settingsText(
          lang,
          'Receipt settings saved',
          'Mipangilio ya risiti imehifadhiwa',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      showSettingsResult(
        context,
        settingsText(
          lang,
          'Could not save settings',
          'Imeshindikana kuhifadhi',
        ),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _toggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SettingsSwitchTile(
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: _saving ? null : onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);
    final saved = store.receiptSettings;
    if (_loaded != saved && !_saving) _load(saved);
    final dirty = _loaded != _draft;

    final toggles = <Widget>[
      _toggle(
        t('Store contact', 'Mawasiliano ya duka'),
        t('Phone and address under the store name',
            'Simu na anwani chini ya jina la duka'),
        _draft.showStoreContact,
        (value) => _update(_draft.copyWith(showStoreContact: value)),
      ),
      _toggle(
        t('Tax registration (TIN)', 'Usajili wa kodi (TIN)'),
        t('Show your business tax number', 'Onyesha namba ya kodi ya biashara'),
        _draft.showTaxId,
        (value) => _update(_draft.copyWith(showTaxId: value)),
      ),
      _toggle(
        t('Receipt number', 'Namba ya risiti'),
        t('Print the unique sale reference', 'Chapisha kumbukumbu ya mauzo'),
        _draft.showOrderNumber,
        (value) => _update(_draft.copyWith(showOrderNumber: value)),
      ),
      _toggle(
        t('Date and time', 'Tarehe na muda'),
        t('When the sale was completed', 'Mauzo yalipokamilika'),
        _draft.showDateTime,
        (value) => _update(_draft.copyWith(showDateTime: value)),
      ),
      _toggle(
        t('Cashier name', 'Jina la muhudumu'),
        t('Staff member who handled the sale', 'Mfanyakazi aliyefanya mauzo'),
        _draft.showCashier,
        (value) => _update(_draft.copyWith(showCashier: value)),
      ),
      _toggle(
        t('Customer name', 'Jina la mteja'),
        t('Hide this for anonymous walk-in sales',
            'Ficha hii kwa mauzo ya wateja wasiojulikana'),
        _draft.showCustomer,
        (value) => _update(_draft.copyWith(showCustomer: value)),
      ),
      _toggle(
        t('Payment method', 'Njia ya malipo'),
        t('Cash, mobile money or card', 'Fedha, pesa za simu au kadi'),
        _draft.showPaymentMethod,
        (value) => _update(_draft.copyWith(showPaymentMethod: value)),
      ),
      _toggle(
        t('Item count', 'Idadi ya bidhaa'),
        t('Total units in the sale summary',
            'Jumla ya bidhaa kwenye muhtasari'),
        _draft.showItemCount,
        (value) => _update(_draft.copyWith(showItemCount: value)),
      ),
      _toggle(
        t('Discount line', 'Mstari wa punguzo'),
        t('Show the discount label and amount', 'Onyesha punguzo na kiasi'),
        _draft.showDiscount,
        (value) => _update(_draft.copyWith(showDiscount: value)),
      ),
    ];

    final contentCard = SettingsCard(
      icon: Icons.receipt_long_outlined,
      title: t('Receipt content', 'Maudhui ya risiti'),
      description: t(
        'Applies to printed, PDF and shared receipts.',
        'Inahusu risiti za kuchapisha, PDF na kushiriki.',
      ),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 620) {
              return Column(children: toggles);
            }
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              children: [
                for (final toggle in toggles)
                  SizedBox(width: width, child: toggle),
              ],
            );
          },
        ),
      ],
    );

    final messageCard = SettingsCard(
      icon: Icons.edit_note_rounded,
      title: t('Printed messages', 'Ujumbe wa risiti'),
      description: t(
        'Add a short header and closing note for your customers.',
        'Ongeza kichwa na ujumbe wa mwisho kwa wateja wako.',
      ),
      children: [
        SettingsField(
          label: t('Header message', 'Ujumbe wa kichwa'),
          hint: t(
              'e.g. welcome note or branch name', 'mf. karibu au jina la tawi'),
          child: TextField(
            controller: _header,
            enabled: !_saving,
            maxLength: ReceiptSettings.headerLimit,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: t('Welcome to our store', 'Karibu dukani kwetu'),
            ),
            onChanged: (value) =>
                _update(_draft.copyWith(header: value.trim())),
          ),
        ),
        SettingsField(
          label: t('Footer message', 'Ujumbe wa chini'),
          hint: t('e.g. thank-you note or return policy',
              'mf. shukrani au sera ya kurudisha'),
          child: TextField(
            controller: _footer,
            enabled: !_saving,
            minLines: 2,
            maxLines: 4,
            maxLength: ReceiptSettings.footerLimit,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: t('Thank you for shopping with us!',
                  'Asante kwa kununua kwetu!'),
            ),
            onChanged: (value) =>
                _update(_draft.copyWith(footer: value.trim())),
          ),
        ),
      ],
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              contentCard,
              messageCard,
            ],
          ),
        ),
        SettingsSaveBar(
          visible: dirty || _saving,
          busy: _saving,
          message: t('You have unsaved changes',
              'Una mabadiliko ambayo hayajahifadhiwa'),
          saveLabel: t('Save changes', 'Hifadhi'),
          discardLabel: t('Discard', 'Acha'),
          onSave: () => _save(store),
          onDiscard: () => setState(() => _load(saved)),
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Language â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LanguagePane extends StatefulWidget {
  const _LanguagePane();

  @override
  State<_LanguagePane> createState() => _LanguagePaneState();
}

class _LanguagePaneState extends State<_LanguagePane> {
  String? _pending;
  bool _savingPreferences = false;
  int _preferenceRevision = 0;

  Future<void> _apply(PosLocalStore store, String code) async {
    if (code == store.languageCode || _pending != null) return;
    setState(() => _pending = code);
    try {
      await store.setLanguageCode(code);
      if (!mounted) return;
      showSettingsResult(context,
          settingsText(code, 'Language updated', 'Lugha imebadilishwa'));
    } catch (_) {
      if (!mounted) return;
      showSettingsResult(
          context,
          settingsText(store.languageCode, 'Could not change language',
              'Imeshindikana kubadilisha lugha'),
          error: true);
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  Future<void> _updatePreferences(
    PosLocalStore store,
    StorePreferences preferences,
    String message,
  ) async {
    if (_savingPreferences) return;
    setState(() => _savingPreferences = true);
    try {
      await store.setStorePreferences(preferences);
      if (!mounted) return;
      showSettingsResult(context, message);
    } catch (_) {
      if (!mounted) return;
      showSettingsResult(
        context,
        settingsText(
          store.languageCode,
          'Could not save preferences',
          'Imeshindikana kuhifadhi mipangilio',
        ),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingPreferences = false;
          _preferenceRevision++;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);
    final preferences = store.storePreferences;
    const options = [
      ('sw', 'Kiswahili', 'Tanzania Â· Kenya'),
      ('en', 'English', 'International'),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        SettingsCard(
          icon: Icons.translate_rounded,
          title: t('App language', 'Lugha ya programu'),
          description: t('Changes apply immediately across the app.',
              'Mabadiliko yanaanza kutumika mara moja.'),
          children: [
            for (final (code, name, region) in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChoiceTile(
                  selected: lang == code,
                  busy: _pending == code,
                  title: name,
                  subtitle: region,
                  onTap: () => _apply(store, code),
                ),
              ),
          ],
        ),
        SettingsCard(
          icon: Icons.schedule_outlined,
          title: t('Date & time display', 'Tarehe na muda'),
          description: t(
            'Used for new sales, receipts and reports.',
            'Hutumika kwa mauzo mapya, risiti na ripoti.',
          ),
          children: [
            SettingsField(
              label: t('Date format', 'Muundo wa tarehe'),
              hint: t('Example: Nov 13, 2026', 'Mfano: Nov 13, 2026'),
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                    'date-${preferences.dateFormat}-$lang-$_preferenceRevision'),
                initialValue: preferences.dateFormat,
                items: [
                  for (final format in StorePreferences.dateFormatOptions)
                    DropdownMenuItem(
                      value: format,
                      child: Text(_dateSample(format)),
                    ),
                ],
                onChanged: _savingPreferences
                    ? null
                    : (value) {
                        if (value == null) return;
                        _updatePreferences(
                          store,
                          preferences.copyWith(dateFormat: value),
                          t('Date format updated',
                              'Muundo wa tarehe umebadilishwa'),
                        );
                      },
              ),
            ),
            SettingsField(
              label: t('Time format', 'Muundo wa muda'),
              hint: t('Example: 2:05 PM or 14:05', 'Mfano: 2:05 PM au 14:05'),
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                    'time-${preferences.timeFormat}-$lang-$_preferenceRevision'),
                initialValue: preferences.timeFormat,
                items: [
                  DropdownMenuItem(
                    value: '12h',
                    child: Text(t('12-hour (2:05 PM)', 'Saa 12 (2:05 PM)')),
                  ),
                  DropdownMenuItem(
                    value: '24h',
                    child: Text(t('24-hour (14:05)', 'Saa 24 (14:05)')),
                  ),
                ],
                onChanged: _savingPreferences
                    ? null
                    : (value) {
                        if (value == null) return;
                        _updatePreferences(
                          store,
                          preferences.copyWith(timeFormat: value),
                          t('Time format updated',
                              'Muundo wa muda umebadilishwa'),
                        );
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _dateSample(String format) {
  const month = 'Nov';
  const day = '13';
  const monthNumber = '11';
  const year = '2026';
  return switch (format) {
    'd MMM yyyy' => '13 $month $year',
    'dd/MM/yyyy' => '$day/$monthNumber/$year',
    'MM/dd/yyyy' => '$monthNumber/$day/$year',
    'yyyy-MM-dd' => '$year-$monthNumber-$day',
    _ => '$month $day, $year',
  };
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.busy = false,
  });

  final bool selected;
  final bool busy;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.successLight : AppColors.surfaceSecondary,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: selected ? AppColors.successBright : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.successDeep
                            : AppColors.textMain,
                      ),
                    ),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
              if (busy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color:
                      selected ? AppColors.successBright : AppColors.textLight,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Data & backup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DataSyncPane extends StatefulWidget {
  const _DataSyncPane();

  @override
  State<_DataSyncPane> createState() => _DataSyncPaneState();
}

class _DataSyncPaneState extends State<_DataSyncPane> {
  bool _busy = false;
  bool _loadingHealth = true;
  int _pending = 0;
  int _failed = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHealth());
  }

  Future<void> _loadHealth() async {
    if (!mounted) return;
    final store = context.read<PosLocalStore>();
    try {
      final health = await store.syncHealth();
      if (!mounted) return;
      setState(() {
        _pending = health.pending;
        _failed = health.failed;
        _loadingHealth = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingHealth = false);
    }
  }

  Future<void> _sendTestSms(PosLocalStore store) async {
    setState(() => _busy = true);
    final DailySmsResult result;
    try {
      result = await store.sendDailySmsNow();
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSettingsResult(context, error.toString(), error: true);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    showSettingsResult(context, result.message, error: !result.success);
  }

  Future<void> _run(
    Future<void> Function() action,
    String okMessage, {
    bool refreshHealth = true,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      if (refreshHealth) await _loadHealth();
      if (mounted) showSettingsResult(context, okMessage);
    } catch (error) {
      if (mounted) showSettingsResult(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportBackup(PosLocalStore store) async {
    final lang = store.languageCode;
    setState(() => _busy = true);
    try {
      final payload = <String, dynamic>{
        'app': 'TrackMauzo',
        'exported_at': DateTime.now().toIso8601String(),
        'profile': {
          'store_name': store.profile.storeName,
          'owner_name': store.profile.ownerName,
          'role_title': store.profile.roleTitle,
          'phone': store.profile.contactNumber,
          'email': store.profile.emailAddress,
          'address': store.profile.physicalAddress,
          'tax_id': store.profile.taxId,
        },
        'receipt_settings': {
          'header': store.receiptSettings.header,
          'footer': store.receiptSettings.footer,
        },
        'customers': store.customers
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'phone': c.phone,
                  'email': c.email,
                  'address': c.address,
                  'debit_balance': c.debitBalance,
                  'created_at': c.createdAt.toIso8601String(),
                })
            .toList(),
        'debit_ledger': store.debitEntries
            .map((e) => {
                  'id': e.id,
                  'customer': e.customerName,
                  'type': e.type.value,
                  'amount': e.amount,
                  'note': e.note,
                  'created_at': e.createdAt.toIso8601String(),
                })
            .toList(),
        'sales': store.orders
            .map((o) => {
                  'id': o.id,
                  'date_time': o.dateTime,
                  'total': o.total,
                  'payment_method': o.paymentMethod,
                  'customer': o.customerName,
                })
            .toList(),
        'inventory': store.inventory
            .map((i) => {
                  'code': i.code,
                  'name': i.name,
                  'stock': i.stockCount,
                  'price': i.sellingPrice,
                })
            .toList(),
        'expenses': store.expenses
            .map((e) => {
                  'id': e.id,
                  'title': e.title,
                  'amount': e.amount,
                  'category': e.category,
                  'date': e.date,
                })
            .toList(),
        'staff': store.staffMembers
            .map((s) => {'id': s.id, 'name': s.name, 'phone': s.phone})
            .toList(),
      };

      final bytes = Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
      );
      final directory = await getApplicationDocumentsDirectory();
      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = File('${directory.path}/trackmauzo_backup_$stamp.json');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path, mimeType: 'application/json')]),
      );
      if (!mounted) return;
      showSettingsResult(
        context,
        settingsText(lang, 'Backup exported', 'Nakala imehamishwa'),
      );
    } catch (error) {
      if (!mounted) return;
      showSettingsResult(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);
    final connected = store.cloudApi != null;
    final error = store.lastPersistenceError;
    final inventoryUnits =
        store.inventory.fold<int>(0, (sum, item) => sum + item.stockCount);
    final recordedRevenue =
        store.orders.fold<double>(0, (sum, order) => sum + order.total);
    final hasQueue = connected || _pending > 0 || _failed > 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        SettingsCard(
          icon: Icons.cloud_sync_outlined,
          title: t('Storage & sync', 'Hifadhi na usawazishaji'),
          description: connected
              ? t('Your data is saved to your TrackMauzo server.',
                  'Data yako inahifadhiwa kwenye seva ya TrackMauzo.')
              : t('Your data is saved on this device only.',
                  'Data yako inahifadhiwa kwenye kifaa hiki pekee.'),
          trailing: SettingsStatusPill(
            label: connected
                ? t('Connected', 'Imeunganishwa')
                : t('Offline', 'Nje ya mtandao'),
            positive: connected,
          ),
          children: [
            SettingsInfoRow(
              label: t('Storage mode', 'Aina ya hifadhi'),
              value: connected
                  ? t('Cloud server', 'Seva ya mtandaoni')
                  : t('This device', 'Kifaa hiki'),
            ),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Sync queue', 'Foleni ya usawazishaji'),
              value: _loadingHealth
                  ? t('Checking...', 'Inakagua...')
                  : hasQueue
                      ? t(
                          '$_pending pending Â· $_failed failed',
                          '$_pending zinasubiri Â· $_failed zimeshindikana',
                        )
                      : t('No pending changes',
                          'Hakuna mabadiliko yanayosubiri'),
            ),
            if (hasQueue) ...[
              const Divider(height: 1),
              SettingsInfoRow(
                label: t('Queue health', 'Afya ya foleni'),
                value: _failed == 0
                    ? t('Healthy', 'Nzuri')
                    : t('Needs attention', 'Inahitaji uangalizi'),
                valueColor: _failed == 0
                    ? AppColors.successDeep
                    : AppColors.warningDeep,
              ),
            ],
            if (error != null && error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.zero,
                  border: Border.all(color: AppColors.dangerBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        error,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.dangerDeep),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (connected) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _run(
                              store.refreshFromServer,
                              t('Data synced', 'Data imesawazishwa'),
                            ),
                    style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(t('Sync now', 'Sawazisha sasa')),
                  ),
                  if (_failed > 0)
                    OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(
                                store.retryFailedSync,
                                t('Failed changes retried',
                                    'Mabadiliko yameshawazishwa tena'),
                              ),
                      style: OutlinedButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      icon: const Icon(Icons.replay_rounded, size: 18),
                      label: Text(t('Retry failed', 'Jaribu tena')),
                    ),
                ],
              ),
            ],
          ],
        ),
        SettingsCard(
          icon: Icons.sms_outlined,
          title: t('Daily SMS report', 'Ripoti ya SMS ya kila siku'),
          description: t(
            'Send an end-of-day sales summary to the owner by SMS.',
            'Tuma muhtasari wa mauzo wa jioni kwa mmiliki kwa SMS.',
          ),
          trailing: SettingsStatusPill(
            label: store.storePreferences.autoDailySmsReport
                ? t('On', 'Imewashwa')
                : t('Off', 'Imezimwa'),
            positive: store.storePreferences.autoDailySmsReport,
          ),
          children: [
            SettingsSwitchTile(
              title: t('Send automatically', 'Tuma kiotomatiki'),
              subtitle: t(
                'Runs every evening in East Africa Time (UTC+3).',
                'Hufanya kazi kila jioni kwa saa za Afrika Mashariki (UTC+3).',
              ),
              value: store.storePreferences.autoDailySmsReport,
              onChanged: _busy
                  ? null
                  : (value) async {
                      setState(() => _busy = true);
                      try {
                        await store.setStorePreferences(
                          store.storePreferences.copyWith(
                            autoDailySmsReport: value,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
            ),
            const Divider(height: 1),
            SettingsField(
              label: t('Delivery time', 'Muda wa kutuma'),
              hint: t('24-hour clock, e.g. 21:00', 'Saa 24, mf. 21:00'),
              child: DropdownButtonFormField<String>(
                key: ValueKey(
                    'sms-${store.storePreferences.dailySmsTime}-$lang'),
                initialValue: store.storePreferences.dailySmsTime,
                items: [
                  for (final time in const [
                    '18:00',
                    '19:00',
                    '20:00',
                    '21:00',
                    '22:00',
                  ])
                    DropdownMenuItem(value: time, child: Text(time)),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value == null) return;
                        store.setStorePreferences(
                          store.storePreferences.copyWith(dailySmsTime: value),
                        );
                      },
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _sendTestSms(store),
                style: OutlinedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(t('Send test report now', 'Tuma ripoti sasa')),
              ),
            ),
          ],
        ),
        SettingsCard(
          icon: Icons.storage_outlined,
          title: t('Data summary', 'Muhtasari wa data'),
          description: t('What is currently available on this device.',
              'Kilichopo kwenye kifaa hiki kwa sasa.'),
          children: [
            SettingsInfoRow(
              label: t('Products', 'Bidhaa'),
              value: '${store.inventory.length}',
            ),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Stock units', 'Vipimo vya bidhaa'),
              value: '$inventoryUnits',
            ),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Sales recorded', 'Mauzo yaliyorekodiwa'),
              value: '${store.orders.length}',
            ),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Sales value', 'Thamani ya mauzo'),
              value: formatCurrencyWithPrefix(recordedRevenue),
            ),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Customers', 'Wateja'),
              value: '${store.customers.length}',
            ),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Debtors', 'Wadaiwa'),
              value: '${store.debtorCount}',
            ),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Staff members', 'Wafanyakazi'),
              value: '${store.staffMembers.length}',
            ),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Expenses', 'Matumizi'),
              value: '${store.expenses.length}',
            ),
          ],
        ),
        SettingsCard(
          icon: Icons.backup_outlined,
          title: t('Backup & export', 'Hifadhi nakala na hamisha'),
          description: t(
            'Download a snapshot of this device data as a JSON file.',
            'Pakua nakala ya data ya kifaa hiki kama faili la JSON.',
          ),
          children: [
            SettingsInfoRow(
              label: t('Records in backup', 'Rekodi kwenye nakala'),
              value: t(
                '${store.orders.length} sales Â· ${store.customers.length} customers Â· ${store.inventory.length} products',
                'mauzo ${store.orders.length} Â· wateja ${store.customers.length} Â· bidhaa ${store.inventory.length}',
              ),
            ),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Includes', 'Inajumuisha'),
              value: t(
                'Profile, sales, stock, customers, credit ledger, expenses, staff',
                'Wasifu, mauzo, hisa, wateja, madeni, matumizi, wafanyakazi',
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _exportBackup(store),
                style: OutlinedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(t('Export backup (JSON)', 'Hamisha nakala (JSON)')),
              ),
            ),
          ],
        ),
        SettingsCard(
          icon: Icons.build_circle_outlined,
          title: t('Maintenance', 'Matengenezo'),
          description: t(
            'Refresh local records without changing your saved data.',
            'Sasisha kumbukumbu za ndani bila kubadilisha data yako.',
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () => _run(
                          store.reloadFromLocal,
                          t('Local data refreshed',
                              'Data ya ndani imesasishwa'),
                        ),
                style: OutlinedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(t('Reload local data', 'Pakia data upya')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Account â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AccountPane extends StatefulWidget {
  const _AccountPane();

  @override
  State<_AccountPane> createState() => _AccountPaneState();
}

class _AccountPaneState extends State<_AccountPane> {
  bool _busy = false;

  Future<void> _confirmSignOut(PosLocalStore store) async {
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(t('Sign out?', 'Ondoka?')),
        content: Text(t(
          'You will need your username and password to sign in again.',
          'Utahitaji jina la mtumiaji na nenosiri kuingia tena.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('Cancel', 'Ghairi')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('Sign out', 'Ondoka')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await store.logout();
      if (!mounted) return;
      showSettingsResult(context, t('Signed out', 'Umeondoka'));
      Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (error) {
      if (!mounted) return;
      showSettingsResult(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword(PosLocalStore store) async {
    final lang = store.languageCode;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ChangePasswordPage(),
      ),
    );
    if (changed == true && mounted) {
      showSettingsResult(
        context,
        settingsText(lang, 'Password updated', 'Nenosiri limebadilishwa'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);
    final profile = store.profile;
    final owner = profile.ownerName.trim().isEmpty
        ? t('Not set', 'Haijawekwa')
        : profile.ownerName;
    final role = profile.roleTitle.trim().isEmpty
        ? t('Business owner', 'Mmiliki wa biashara')
        : profile.roleTitle;
    final storeName = profile.storeName.trim().isEmpty
        ? t('Not set', 'Haijawekwa')
        : profile.storeName;
    final phone = profile.contactNumber.trim().isEmpty
        ? t('Not set', 'Haijawekwa')
        : profile.contactNumber;
    final email = profile.emailAddress.trim().isEmpty
        ? t('Not set', 'Haijawekwa')
        : profile.emailAddress;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        SettingsCard(
          icon: Icons.badge_outlined,
          title: t('Signed-in profile', 'Wasifu uliounganishwa'),
          description: t('Details linked to this device session.',
              'Taarifa zinazohusiana na kikao cha kifaa hiki.'),
          children: [
            SettingsInfoRow(label: t('Owner', 'Mmiliki'), value: owner),
            const Divider(height: 1),
            SettingsInfoRow(label: t('Role', 'Wajibu'), value: role),
            const Divider(height: 1),
            SettingsInfoRow(label: t('Store', 'Duka'), value: storeName),
            const Divider(height: 1),
            SettingsInfoRow(label: t('Phone', 'Simu'), value: phone),
            const Divider(height: 1),
            SettingsInfoRow(label: t('Email', 'Barua pepe'), value: email),
          ],
        ),
        SettingsCard(
          icon: Icons.lock_outline_rounded,
          title: t('Password & security', 'Nenosiri na usalama'),
          description: t(
            'Use a password with at least 6 characters.',
            'Tumia nenosiri lenye herufi 6 au zaidi.',
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => _changePassword(store),
                style: OutlinedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                icon: const Icon(Icons.key_rounded, size: 18),
                label: Text(t('Change password', 'Badilisha nenosiri')),
              ),
            ),
          ],
        ),
        SettingsCard(
          icon: Icons.logout_rounded,
          title: t('Session', 'Kikao'),
          description: t('End your session on this device.',
              'Maliza kikao chako kwenye kifaa hiki.'),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  backgroundColor: AppColors.surfaceSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: _busy ? null : () => _confirmSignOut(store),
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.ink),
                      )
                    : const Icon(Icons.logout_rounded, size: 18),
                label: Text(t('Sign out', 'Ondoka')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------------- About -------------------------

class _AboutPane extends StatelessWidget {
  const _AboutPane();

  String get _platform {
    try {
      final os = Platform.operatingSystem;
      final version = Platform.operatingSystemVersion.split(' ').first;
      return '${os[0].toUpperCase()}${os.substring(1)} $version';
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);
    final connected = store.cloudApi != null;

    void open(Widget page) => Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));

    Widget link(IconData icon, String label, Widget page) => _AboutLink(
          icon: icon,
          label: label,
          onTap: () => open(page),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        SettingsCard(
          icon: Icons.info_outline_rounded,
          title: 'TrackMauzo',
          description: t(
            'Point of sale for small shops — the B2C edition of Open Source POS.',
            'Mfumo wa mauzo kwa maduka madogo — toleo la B2C la Open Source POS.',
          ),
          children: [
            SettingsInfoRow(label: t('Version', 'Toleo'), value: '1.0.0 (1)'),
            const Divider(height: 1),
            SettingsInfoRow(
                label: t('Edition', 'Toleo la'), value: 'B2C · Mini'),
            const Divider(height: 1),
            SettingsInfoRow(label: t('Platform', 'Mfumo'), value: _platform),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Language', 'Lugha'),
              value: lang == 'sw' ? 'Kiswahili' : 'English',
            ),
            const Divider(height: 1),
            SettingsInfoRow(
              label: t('Storage', 'Hifadhi'),
              value: connected
                  ? t('Cloud + local cache', 'Wingu + hifadhi ya ndani')
                  : t('On-device database', 'Hifadhi ya kifaa'),
            ),
          ],
        ),
        SettingsCard(
          icon: Icons.support_agent_outlined,
          title: t('Help & legal', 'Msaada na sheria'),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          children: [
            link(Icons.help_outline_rounded, t('Help & support', 'Msaada'),
                const HelpSupportPage()),
            link(
                Icons.description_outlined,
                t('Terms of service', 'Masharti ya huduma'),
                const TermsOfServicePage()),
            link(
                Icons.privacy_tip_outlined,
                t('Privacy policy', 'Sera ya faragha'),
                const PrivacyPolicyPage()),
            link(Icons.apps_rounded, t('About the app', 'Kuhusu programu'),
                const AboutAppPage()),
            _AboutLink(
              icon: Icons.article_outlined,
              label: t('Open-source licenses', 'Leseni za programu'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'TrackMauzo',
                applicationVersion: '1.0.0 (1)',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AboutLink extends StatelessWidget {
  const _AboutLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
        child: InkWell(
          borderRadius: BorderRadius.zero,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.zero,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                SettingsIconBox(icon: icon, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
