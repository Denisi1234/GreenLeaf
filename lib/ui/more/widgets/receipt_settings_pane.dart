import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/esc_pos_receipt_builder.dart';
import '../../../service/pos_local_store.dart';
import '../../../service/receipt_settings.dart';
import '../../../service/thermal_printer_service.dart';
import '../../receipt/thermal_printer_picker_sheet.dart';
import '../../widgets/app_design.dart';
import '../settings_layout.dart';

/// Receipt configuration pane.
class ReceiptSettingsPane extends StatefulWidget {
  const ReceiptSettingsPane({super.key});

  @override
  State<ReceiptSettingsPane> createState() => _ReceiptSettingsPaneState();
}

class _ReceiptSettingsPaneState extends State<ReceiptSettingsPane> {
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

  Future<void> _selectThermalPrinter(PosLocalStore store) async {
    final lang = store.languageCode;
    final selected = await showThermalPrinterPicker(context);
    if (selected == null || !mounted) return;
    await store.setStorePreferences(
      store.storePreferences.copyWith(
        thermalPrinterName: selected.name,
        thermalPrinterAddress: selected.address,
      ),
    );
    if (!mounted) return;
    showSettingsResult(
      context,
      settingsText(
        lang,
        'Printer saved: ${selected.name}',
        'Printa imehifadhiwa: ${selected.name}',
      ),
    );
  }

  Future<void> _testThermalPrinter(PosLocalStore store) async {
    final lang = store.languageCode;
    final prefs = store.storePreferences;
    if (prefs.thermalPrinterAddress.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await ThermalPrinterService.instance.printTestTicket(
        address: prefs.thermalPrinterAddress,
        storeName: store.activeStoreName,
        paperWidth: ThermalPaperWidth.fromMm(prefs.thermalPaperWidthMm),
      );
      if (!mounted) return;
      showSettingsResult(
        context,
        settingsText(
          lang,
          'Test receipt sent to printer',
          'Risiti ya majaribio imetumwa',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      showSettingsResult(context, error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

    final prefs = store.storePreferences;
    final hasPrinter = prefs.thermalPrinterAddress.trim().isNotEmpty;
    final printerLabel = hasPrinter
        ? '${prefs.thermalPrinterName.isEmpty ? 'Bluetooth' : prefs.thermalPrinterName} (${prefs.thermalPrinterAddress})'
        : t('Not configured', 'Haijawekwa');

    final printerCard = SettingsCard(
      icon: Icons.print_outlined,
      title: t('Bluetooth thermal printer', 'Printa ya Bluetooth (58mm / 80mm)'),
      description: t(
        'Print receipts directly to a paired 58mm or 80mm ESC/POS printer.',
        'Chapisha risiti moja kwa moja kwenda printa ya Bluetooth (58mm au 80mm).',
      ),
      children: [
        SettingsField(
          label: t('Selected printer', 'Printa iliyochaguliwa'),
          hint: printerLabel,
          child: const SizedBox.shrink(),
        ),
        SettingsField(
          label: t('Paper width', 'Upana wa karatasi'),
          child: DropdownButtonFormField<int>(
            initialValue: prefs.thermalPaperWidthMm >= 80 ? 80 : 58,
            items: const [
              DropdownMenuItem(value: 58, child: Text('58mm (32 columns)')),
              DropdownMenuItem(value: 80, child: Text('80mm (48 columns)')),
            ],
            onChanged: _saving
                ? null
                : (value) {
                    if (value == null) return;
                    store.setStorePreferences(
                      prefs.copyWith(thermalPaperWidthMm: value),
                    );
                  },
          ),
        ),
        SettingsSwitchTile(
          title: t('Open cash drawer on print', 'Fungua droo ya pesa'),
          subtitle: t(
            'Send drawer kick pulse after receipt cut',
            'Tuma amri ya kufungua droo baada ya kuchapisha',
          ),
          value: prefs.openCashDrawerOnPrint,
          onChanged: _saving
              ? null
              : (value) => store.setStorePreferences(
                    prefs.copyWith(openCashDrawerOnPrint: value),
                  ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: _saving ? null : () => _selectThermalPrinter(store),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kpiSkyBg,
                foregroundColor: AppColors.kpiSky,
                side: BorderSide.none,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.bluetooth_searching_rounded, size: 18),
              label: Text(
                t('Select printer', 'Chagua printa'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.icon(
              onPressed:
                  _saving || !hasPrinter ? null : () => _testThermalPrinter(store),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                side: BorderSide.none,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
              icon: const Icon(Icons.print_rounded, size: 18),
              label: Text(
                t('Test print', 'Jaribu kuchapisha'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
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
              printerCard,
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
