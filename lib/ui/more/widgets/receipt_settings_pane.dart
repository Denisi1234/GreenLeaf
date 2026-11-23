import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/esc_pos_receipt_builder.dart';
import '../../../service/pos_local_store.dart';
import '../../../service/receipt_settings.dart';
import '../../../service/thermal_printer_service.dart';
import '../../receipt/thermal_printer_picker_sheet.dart';
import '../../widgets/app_design.dart';
import '../../widgets/app_theme_palette.dart';
import '../settings_layout.dart';

/// Clean, native Android/iOS Receipt & Bluetooth Thermal Printer settings pane.
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

  InputDecoration _inputDecoration(AppThemePalette palette, {String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: palette.textMuted, fontSize: 14),
      filled: true,
      fillColor: palette.pageBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
    );
  }

  Widget _switchRow(
    AppThemePalette palette,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: AppTypography.bodyMain.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: palette.ink,
        ),
      ),
      value: value,
      activeTrackColor: palette.primary,
      onChanged: _saving ? null : onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final palette = AppThemePalette.of(context);
    final lang = store.languageCode;
    String t(String en, String sw) => settingsText(lang, en, sw);
    final saved = store.receiptSettings;
    if (_loaded != saved && !_saving) _load(saved);
    final dirty = _loaded != _draft;

    final prefs = store.storePreferences;
    final hasPrinter = prefs.thermalPrinterAddress.trim().isNotEmpty;
    final printerLabel = hasPrinter
        ? (prefs.thermalPrinterName.isEmpty
            ? prefs.thermalPrinterAddress
            : prefs.thermalPrinterName)
        : t('Not connected', 'Haijaunganishwa');

    final toggles = <(String, bool, ValueChanged<bool>)>[
      (
        t('Store contact', 'Mawasiliano ya duka'),
        _draft.showStoreContact,
        (v) => _update(_draft.copyWith(showStoreContact: v)),
      ),
      (
        t('Tax ID (TIN)', 'Namba ya kodi (TIN)'),
        _draft.showTaxId,
        (v) => _update(_draft.copyWith(showTaxId: v)),
      ),
      (
        t('Receipt number', 'Namba ya risiti'),
        _draft.showOrderNumber,
        (v) => _update(_draft.copyWith(showOrderNumber: v)),
      ),
      (
        t('Date and time', 'Tarehe na muda'),
        _draft.showDateTime,
        (v) => _update(_draft.copyWith(showDateTime: v)),
      ),
      (
        t('Cashier name', 'Jina la muhudumu'),
        _draft.showCashier,
        (v) => _update(_draft.copyWith(showCashier: v)),
      ),
      (
        t('Customer name', 'Jina la mteja'),
        _draft.showCustomer,
        (v) => _update(_draft.copyWith(showCustomer: v)),
      ),
      (
        t('Payment method', 'Njia ya malipo'),
        _draft.showPaymentMethod,
        (v) => _update(_draft.copyWith(showPaymentMethod: v)),
      ),
      (
        t('Item count', 'Idadi ya bidhaa'),
        _draft.showItemCount,
        (v) => _update(_draft.copyWith(showItemCount: v)),
      ),
      (
        t('Discount line', 'Mstari wa punguzo'),
        _draft.showDiscount,
        (v) => _update(_draft.copyWith(showDiscount: v)),
      ),
    ];

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 28),
            children: [
              // 1. Bluetooth Thermal Printer
              _SectionLabel(t('BLUETOOTH PRINTER', 'PRINTA YA BLUETOOTH'), palette),
              _NativeGroupCard(
                palette: palette,
                children: [
                  InkWell(
                    onTap: _saving ? null : () => _selectThermalPrinter(store),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 54),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.print_outlined,
                              size: 22,
                              color: palette.textMuted,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                t('Thermal printer', 'Printa ya risiti'),
                                style: AppTypography.bodyMain.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: palette.ink,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                printerLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: palette.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: palette.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 16, color: palette.divider),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t('Paper width', 'Upana wa karatasi'),
                          style: AppTypography.caption.copyWith(
                            color: palette.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          initialValue: prefs.thermalPaperWidthMm >= 80 ? 80 : 58,
                          isExpanded: true,
                          dropdownColor: palette.surface,
                          style: TextStyle(color: palette.ink, fontSize: 15),
                          decoration: _inputDecoration(palette),
                          items: const [
                            DropdownMenuItem(
                              value: 58,
                              child: Text(
                                '58mm (32 columns)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 80,
                              child: Text(
                                '80mm (48 columns)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                      ],
                    ),
                  ),
                  Divider(height: 1, indent: 16, color: palette.divider),
                  _switchRow(
                    palette,
                    t('Open cash drawer on print', 'Fungua droo ya pesa'),
                    prefs.openCashDrawerOnPrint,
                    (v) => store.setStorePreferences(
                      prefs.copyWith(openCashDrawerOnPrint: v),
                    ),
                  ),
                  if (hasPrinter) ...[
                    Divider(height: 1, indent: 16, color: palette.divider),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _testThermalPrinter(store),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.ink,
                            backgroundColor: palette.surface,
                            side: BorderSide(color: palette.border),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                          icon: const Icon(Icons.print_rounded, size: 18),
                          label: Text(
                            t('Test print', 'Jaribu kuchapisha'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 22),

              // 2. Printed Messages
              _SectionLabel(t('PRINTED MESSAGES', 'UJUMBE WA RISITI'), palette),
              _NativeGroupCard(
                palette: palette,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          t('Header message', 'Ujumbe wa kichwa'),
                          style: AppTypography.caption.copyWith(
                            color: palette.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _header,
                          enabled: !_saving,
                          maxLength: ReceiptSettings.headerLimit,
                          style: TextStyle(color: palette.ink, fontSize: 15),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(
                            palette,
                            hint: t('Welcome to our store', 'Karibu dukani kwetu'),
                          ),
                          onChanged: (value) =>
                              _update(_draft.copyWith(header: value.trim())),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t('Footer message', 'Ujumbe wa chini'),
                          style: AppTypography.caption.copyWith(
                            color: palette.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _footer,
                          enabled: !_saving,
                          minLines: 2,
                          maxLines: 3,
                          maxLength: ReceiptSettings.footerLimit,
                          style: TextStyle(color: palette.ink, fontSize: 15),
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration(
                            palette,
                            hint: t(
                              'Thank you for shopping with us!',
                              'Asante kwa kununua kwetu!',
                            ),
                          ),
                          onChanged: (value) =>
                              _update(_draft.copyWith(footer: value.trim())),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // 3. Receipt Content Toggles
              _SectionLabel(t('RECEIPT CONTENT', 'MAUDHUI YA RISITI'), palette),
              _NativeGroupCard(
                palette: palette,
                children: [
                  for (var i = 0; i < toggles.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, indent: 16, color: palette.divider),
                    _switchRow(
                      palette,
                      toggles[i].$1,
                      toggles[i].$2,
                      toggles[i].$3,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (dirty || _saving)
          Container(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 12),
            decoration: BoxDecoration(
              color: palette.pageBackground,
              border: Border(top: BorderSide(color: palette.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => setState(() => _load(saved)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.ink,
                        backgroundColor: palette.surface,
                        side: BorderSide(color: palette.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: Text(
                        t('Discard', 'Acha'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : () => _save(store),
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: Text(
                        _saving
                            ? t('Saving...', 'Inahifadhi...')
                            : t('Save changes', 'Hifadhi'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.palette);
  final String text;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        text,
        style: AppTypography.label.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: palette.textMuted,
        ),
      ),
    );
  }
}

class _NativeGroupCard extends StatelessWidget {
  const _NativeGroupCard({required this.palette, required this.children});
  final AppThemePalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: palette.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(children: children),
      ),
    );
  }
}
