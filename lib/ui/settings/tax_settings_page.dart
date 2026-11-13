import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/tax_settings.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

/// Tax configuration used by tax reports and receipts.
class TaxSettingsPage extends StatefulWidget {
  const TaxSettingsPage({super.key});

  @override
  State<TaxSettingsPage> createState() => _TaxSettingsPageState();
}

class _TaxSettingsPageState extends State<TaxSettingsPage> {
  late TaxSettings _draft;

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
      body: SafeArea(
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
                  MarketSurfaceCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
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
                                  'Required for tax reports and tax compliance.',
                                  'Inahitajika kwa ripoti za kodi.',
                                ),
                                style: AppTypography.helperText
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _draft.enabled,
                          onChanged: (value) => setState(
                              () => _draft = _draft.copyWith(enabled: value)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_draft.enabled) ...[
                    MarketSurfaceCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarketFormField(
                            label: _t('Tax name', 'Jina la kodi'),
                            hintText: 'VAT',
                            initialValue: _draft.taxLabel,
                            onChanged: (value) => _draft =
                                _draft.copyWith(taxLabel: value.trim()),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Tax rate (%)', 'Kiwango cha kodi (%)'),
                            hintText: '18',
                            initialValue: _draft.ratePercent == 0
                                ? ''
                                : _draft.ratePercent.toStringAsFixed(2),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            onChanged: (value) => _draft = _draft.copyWith(
                              ratePercent: double.tryParse(value) ?? 0,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Tax identification number',
                                'Namba ya usajili wa kodi'),
                            hintText: _t('e.g. 123-456-789', 'mf. 123-456-789'),
                            initialValue: _draft.taxId,
                            onChanged: (value) =>
                                _draft = _draft.copyWith(taxId: value.trim()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MarketSurfaceCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _draft.pricesIncludeTax,
                            onChanged: (value) => setState(() => _draft =
                                _draft.copyWith(pricesIncludeTax: value)),
                            title: Text(
                              _t('Prices include tax', 'Bei zinajumuisha kodi'),
                              style: AppTypography.bodySmall
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              _draft.pricesIncludeTax
                                  ? _t(
                                      'Tax is extracted from the selling price.',
                                      'Kodi inatolewa kutoka kwenye bei ya kuuza.',
                                    )
                                  : _t(
                                      'Tax is added on top of the selling price.',
                                      'Kodi inaongezwa juu ya bei ya kuuza.',
                                    ),
                              style: AppTypography.helperText
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _draft.trackExpenseTax,
                            onChanged: (value) => setState(() => _draft =
                                _draft.copyWith(trackExpenseTax: value)),
                            title: Text(
                              _t('Include tax paid on expenses',
                                  'Jumuisha kodi ya matumizi'),
                              style: AppTypography.bodySmall
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              _t(
                                'Counts expense tax towards tax compliance.',
                                'Huahesabu kodi ya matumizi kwenye uzingatiaji wa kodi.',
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
                  MarketSurfaceCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('Tax snapshot', 'Muhtasari wa kodi'),
                          style: AppTypography.label,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _TaxRow(
                          label: _t('Taxable sales', 'Mauzo yenye kodi'),
                          value: 'TZS ${taxableSales.toStringAsFixed(0)}',
                        ),
                        _TaxRow(
                          label: _t('Tax collected', 'Kodi iliyokusanywa'),
                          value: 'TZS ${taxCollected.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MarketButton(
                    label:
                        _t('Save tax settings', 'Hifadhi mipangilio ya kodi'),
                    icon: Icons.check_rounded,
                    onTap: _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final store = context.read<PosLocalStore>();
    await store.updateTaxSettings(_draft);
    if (!mounted) return;
    showMarketNotice(
      context,
      title: _t('Tax settings', 'Mipangilio ya kodi'),
      message: _t('Tax settings saved', 'Mipangilio ya kodi imehifadhiwa'),
    );
    Navigator.of(context).maybePop();
  }
}

class _TaxRow extends StatelessWidget {
  const _TaxRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
          Text(
            value,
            style:
                AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
