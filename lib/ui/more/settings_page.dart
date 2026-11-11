import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../../service/receipt_settings.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'settings_layout.dart';
import 'store_profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    return Theme(
      data: settingsTheme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              MarketPageHeader(
                title: strings.settings,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: _SettingsTabs(
                            labels: [
                              strings.businessInfo,
                              strings.localeSettings,
                              strings.receiptSettings,
                              strings.systemSettings,
                            ],
                            selected: _selectedTab,
                            onSelected: (index) {
                              FocusScope.of(context).unfocus();
                              setState(() => _selectedTab = index);
                            },
                          ),
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: _selectedTab,
                            sizing: StackFit.expand,
                            children: [
                              const _SettingsPane(child: StoreProfileForm()),
                              _SettingsPane(child: _LocaleForm(store: store)),
                              _SettingsPane(child: _ReceiptForm(store: store)),
                              _SettingsPane(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SettingsField(
                                      label: strings.appVersion,
                                      child: const Text('1.0.0'),
                                    ),
                                    SettingsField(
                                      label: strings.dataStorage,
                                      child: Text(strings.localStorage),
                                    ),
                                    SettingsField(
                                      label: strings.cloudSync,
                                      child: Text(strings.disconnected),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTabs extends StatelessWidget {
  const _SettingsTabs({
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 736;
        final tabs = List.generate(labels.length, (index) {
          final active = selected == index;
          return Semantics(
            selected: active,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                foregroundColor:
                    compact && active ? const Color(0xFF0F766E) : settingsInk,
                backgroundColor: compact
                    ? (active
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFF8FAFC))
                    : Colors.white,
                side: BorderSide(
                  color: compact && active
                      ? const Color(0xFF14B8A6)
                      : (active || compact
                          ? settingsBorder
                          : Colors.transparent),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: compact
                      ? BorderRadius.circular(10)
                      : const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              onPressed: () => onSelected(index),
              child: Text(labels[index], textAlign: TextAlign.center),
            ),
          );
        });

        if (compact) {
          final width = (constraints.maxWidth - 6) / 2;
          return Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tab in tabs) SizedBox(width: width, child: tab)
            ],
          );
        }
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: settingsBorder)),
          ),
          child: Wrap(children: tabs),
        );
      },
    );
  }
}

class _SettingsPane extends StatelessWidget {
  const _SettingsPane({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [child],
    );
  }
}

class _LocaleForm extends StatefulWidget {
  const _LocaleForm({required this.store});

  final PosLocalStore store;

  @override
  State<_LocaleForm> createState() => _LocaleFormState();
}

class _LocaleFormState extends State<_LocaleForm> {
  late String _language = widget.store.languageCode;
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.store.setLanguageCode(_language);
      if (!mounted) return;
      _showResult(
          context, AppStrings.of(widget.store.languageCode).settingsSaved);
    } catch (_) {
      if (!mounted) return;
      _showResult(
          context, AppStrings.of(widget.store.languageCode).settingsSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(widget.store.languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsField(
          label: strings.language,
          child: DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: InputDecoration(helperText: strings.preferredLanguage),
            isExpanded: true,
            items: [
              DropdownMenuItem(value: 'en', child: Text(strings.english)),
              DropdownMenuItem(value: 'sw', child: Text(strings.swahili)),
            ],
            onChanged:
                _saving ? null : (value) => setState(() => _language = value!),
          ),
        ),
        SettingsSaveButton(
          label: _saving ? strings.saving : strings.save,
          onPressed:
              _saving || _language == widget.store.languageCode ? null : _save,
        ),
      ],
    );
  }
}

class _ReceiptForm extends StatefulWidget {
  const _ReceiptForm({required this.store});

  final PosLocalStore store;

  @override
  State<_ReceiptForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends State<_ReceiptForm> {
  late final _footer =
      TextEditingController(text: widget.store.receiptSettings.footer);
  late bool _showStoreContact = widget.store.receiptSettings.showStoreContact;
  bool _saving = false;

  @override
  void dispose() {
    _footer.dispose();
    super.dispose();
  }

  Future<void> _save(AppStrings strings) async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.store.updateReceiptSettings(
        ReceiptSettings(
            showStoreContact: _showStoreContact, footer: _footer.text.trim()),
      );
      if (!mounted) return;
      _footer.text = widget.store.receiptSettings.footer;
      _showResult(context, strings.settingsSaved);
    } catch (_) {
      if (!mounted) return;
      _showResult(context, strings.settingsSaveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(widget.store.languageCode);
    final saved = widget.store.receiptSettings;
    final dirty = _showStoreContact != saved.showStoreContact ||
        _footer.text.trim() != saved.footer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            strings.receiptSettingsHint,
            style: const TextStyle(color: settingsMuted),
          ),
        ),
        SettingsField(
          label: strings.showStoreContact,
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(strings.receiptContactHint),
            value: _showStoreContact,
            onChanged: _saving
                ? null
                : (value) => setState(() => _showStoreContact = value!),
          ),
        ),
        SettingsField(
          label: strings.receiptFooter,
          child: TextField(
            controller: _footer,
            enabled: !_saving,
            minLines: 2,
            maxLines: 4,
            maxLength: ReceiptSettings.footerLimit,
            decoration: InputDecoration(hintText: strings.receiptFooterHint),
            onChanged: (_) => setState(() {}),
          ),
        ),
        SettingsSaveButton(
          label: _saving ? strings.saving : strings.save,
          onPressed: _saving || !dirty ? null : () => _save(strings),
        ),
      ],
    );
  }
}

void _showResult(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
