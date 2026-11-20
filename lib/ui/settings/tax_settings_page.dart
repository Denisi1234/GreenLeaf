import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_mauzo/l10n/app_localization.dart';

import '../../service/pos_local_store.dart';
import '../../service/tax_settings.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'widgets/tax_overview_kpi_metrics.dart';

/// Tax configuration used by tax reports and receipts.
class TaxSettingsPage extends StatefulWidget {
  const TaxSettingsPage({super.key});

  @override
  State<TaxSettingsPage> createState() => _TaxSettingsPageState();
}

class _TaxSettingsPageState extends State<TaxSettingsPage> {
  late TaxSettings _draft;
  bool _saving = false;

  bool get _isSwahili =>
      context.watch<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void initState() {
    super.initState();
    _draft = context.read<PosLocalStore>().taxSettings;
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final tax = store.taxSettings;
    final taxableSales = store.orders
        .where((order) => order.status.trim().toLowerCase() == 'completed')
        .fold<double>(0, (sum, order) => sum + order.total);
    final taxCollected = tax.enabled
        ? store.orders
            .where((order) => order.status.trim().toLowerCase() == 'completed')
            .fold<double>(
                0, (sum, order) => sum + tax.taxFromGross(order.total))
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
        maxWidth: 1280,
        child: SafeArea(
          child: Column(
            children: [
              MarketPageHeader(
                title: _t('Tax settings', 'Mipangilio ya kodi'),
                subtitle: tax.enabled
                    ? '${tax.taxLabel} ${tax.ratePercent.toStringAsFixed(1)}%'
                    : _t('Tax disabled', 'Kodi imezimwa'),
                transparentBackButton: true,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    // Overview KPI Cards
                    TaxOverviewKpiMetrics(
                      taxableSales: taxableSales,
                      taxCollected: taxCollected,
                      taxRatePercent: _draft.ratePercent,
                      taxLabel: _draft.taxLabel.isEmpty ? 'VAT' : _draft.taxLabel,
                      isEnabled: _draft.enabled,
                      isSwahili: _isSwahili,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Primary Tax Toggle Card
                    MarketSurfaceCard(
                      padding: const EdgeInsets.all(16),
                      radius: 0,
                      showShadow: false,
                      borderColor: AppColors.border,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _draft.enabled
                                  ? const Color(0xFFD1FAE5)
                                  : AppColors.surfaceSecondary,
                              borderRadius: BorderRadius.zero,
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: _draft.enabled
                                  ? const Color(0xFF047857)
                                  : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _t('Charge tax on sales',
                                      'Toza kodi kwenye mauzo'),
                                  style: AppTypography.bodySmall
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _t(
                                    'Required for tax reports, receipts and compliance.',
                                    'Inahitajika kwa ripoti za kodi, risiti na uzingatiaji wa sheria.',
                                  ),
                                  style: AppTypography.helperText
                                      .copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _draft.enabled,
                            activeColor: AppColors.primary,
                            onChanged: (value) => setState(() =>
                                _draft = _draft.copyWith(enabled: value)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (_draft.enabled) ...[
                      // Form fields card
                      MarketSurfaceCard(
                        padding: const EdgeInsets.all(18),
                        radius: 0,
                        showShadow: false,
                        borderColor: AppColors.border,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('Tax identification & rate',
                                  'Utambulisho wa kodi na kiwango'),
                              style: AppTypography.label.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            MarketFormField(
                              label: _t('Tax name', 'Jina la kodi'),
                              hintText: context.tr('VAT'),
                              initialValue: _draft.taxLabel,
                              radius: 0,
                              onChanged: (value) => _draft =
                                  _draft.copyWith(taxLabel: value.trim()),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            MarketFormField(
                              label:
                                  _t('Tax rate (%)', 'Kiwango cha kodi (%)'),
                              hintText: '18',
                              radius: 0,
                              initialValue: _draft.ratePercent == 0
                                  ? ''
                                  : _draft.ratePercent.toStringAsFixed(2),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              onChanged: (value) => _draft = _draft.copyWith(
                                ratePercent: double.tryParse(value) ?? 0,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            MarketFormField(
                              label: _t('Tax identification number (TIN)',
                                  'Namba ya mlipa kodi (TIN)'),
                              hintText:
                                  _t('e.g. 123-456-789', 'mf. 123-456-789'),
                              radius: 0,
                              initialValue: _draft.taxId,
                              onChanged: (value) => _draft =
                                  _draft.copyWith(taxId: value.trim()),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Rules & calculation modes
                      MarketSurfaceCard(
                        padding: const EdgeInsets.all(16),
                        radius: 0,
                        showShadow: false,
                        borderColor: AppColors.border,
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _draft.pricesIncludeTax,
                              activeColor: AppColors.primary,
                              onChanged: (value) => setState(() => _draft =
                                  _draft.copyWith(pricesIncludeTax: value)),
                              title: Text(
                                _t('Prices include tax (Inclusive)',
                                    'Bei zinajumuisha kodi (Inclusive)'),
                                style: AppTypography.bodySmall
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                _draft.pricesIncludeTax
                                    ? _t(
                                        'Tax is extracted directly from item shelf price.',
                                        'Kodi inatolewa moja kwa moja kutoka kwenye bei ya rafu.',
                                      )
                                    : _t(
                                        'Tax is added on top of the selling price at checkout.',
                                        'Kodi inaongezwa juu ya bei wakati wa malipo.',
                                      ),
                                style: AppTypography.helperText
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.divider),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _draft.trackExpenseTax,
                              activeColor: AppColors.primary,
                              onChanged: (value) => setState(() => _draft =
                                  _draft.copyWith(trackExpenseTax: value)),
                              title: Text(
                                _t('Include tax paid on expenses (Input Tax)',
                                    'Jumuisha kodi ya matumizi (Input Tax)'),
                                style: AppTypography.bodySmall
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                _t(
                                  'Tracks input tax from expenses for offsetting output tax.',
                                  'Hufuatilia kodi ya matumizi ili kurekebisha kodi ya mauzo.',
                                ),
                                style: AppTypography.helperText
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    MarketButton(
                      label: _saving
                          ? _t('Saving...', 'Inahifadhi...')
                          : _t('Save tax settings',
                              'Hifadhi mipangilio ya kodi'),
                      icon: Icons.check_rounded,
                      radius: 0,
                      onTap: _saving ? null : _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final store = context.read<PosLocalStore>();
    final navigator = Navigator.of(context);
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    try {
      await store.updateTaxSettings(_draft);
      if (!mounted) return;
      showMarketNotice(
        context,
        title: sw ? 'Mipangilio ya kodi' : 'Tax settings',
        message: sw ? 'Mipangilio ya kodi imehifadhiwa kikamilifu' : 'Tax settings saved successfully',
        type: MarketNoticeType.success,
      );
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMarketNotice(
        context,
        title: sw ? 'Mipangilio ya kodi' : 'Tax settings',
        message: sw
            ? 'Imeshindwa kuhifadhi mipangilio ya kodi'
            : 'Failed to save tax settings',
        type: MarketNoticeType.error,
      );
    }
  }
}
