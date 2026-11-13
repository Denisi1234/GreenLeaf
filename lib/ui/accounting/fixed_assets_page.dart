import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

/// Fixed asset register with straight-line depreciation.
class FixedAssetsPage extends StatelessWidget {
  const FixedAssetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;

    final assets = store.fixedAssets;
    final totalCost = assets.fold<double>(0, (sum, asset) => sum + asset.cost);
    final totalNbv =
        assets.fold<double>(0, (sum, asset) => sum + asset.netBookValue());

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: t('Fixed assets', 'Mali za kudumu'),
              subtitle:
                  'TZS ${totalNbv.toStringAsFixed(0)} ${t('net book value', 'thamani halisi')}',
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
              actions: [
                IconButton(
                  tooltip: t('Add asset', 'Ongeza mali'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const AssetFormPage(),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, color: AppColors.ink),
                ),
              ],
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
                          child: Text(
                            t('Cost', 'Gharama'),
                            style: AppTypography.helperText
                                .copyWith(color: AppColors.textMuted),
                          ),
                        ),
                        Text(
                          'TZS ${totalCost.toStringAsFixed(0)}',
                          style: AppTypography.bodySmall
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (assets.isEmpty)
                    MarketSurfaceCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Icon(Icons.chair_outlined,
                              size: 32, color: AppColors.textLight),
                          const SizedBox(height: 10),
                          Text(
                            t('No fixed assets', 'Hakuna mali za kudumu'),
                            style: AppTypography.h3.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t(
                              'Register equipment, furniture and vehicles to track depreciation.',
                              'Sajili vifaa, samani na magari kufuatilia uchakavu.',
                            ),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted, height: 1.4),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final asset in assets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MarketSurfaceCard(
                          padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      asset.name,
                                      style: AppTypography.bodyMain.copyWith(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Text(
                                    'TZS ${asset.netBookValue().toStringAsFixed(0)}',
                                    style: AppTypography.bodySmall
                                        .copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              Text(
                                '${asset.category} • ${asset.purchaseDate.toLocal().toString().substring(0, 10)}',
                                style: AppTypography.helperText
                                    .copyWith(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                '${t('Cost', 'Gharama')}: TZS ${asset.cost.toStringAsFixed(0)}  •  '
                                '${t('Depreciation', 'Uchakavu')}: TZS ${asset.accumulatedDepreciation().toStringAsFixed(0)}',
                                style: AppTypography.helperText
                                    .copyWith(color: AppColors.textMuted),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () =>
                                          Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (context) =>
                                              AssetFormPage(asset: asset),
                                        ),
                                      ),
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 16),
                                      label: Text(t('Edit', 'Badilisha')),
                                    ),
                                    TextButton.icon(
                                      onPressed: () async {
                                        await context
                                            .read<PosLocalStore>()
                                            .deleteFixedAsset(asset.id!);
                                      },
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16),
                                      label: Text(t('Delete', 'Futa')),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssetFormPage extends StatefulWidget {
  const AssetFormPage({super.key, this.asset});

  final FixedAsset? asset;

  @override
  State<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends State<AssetFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _cost;
  late final TextEditingController _salvage;
  late final TextEditingController _life;
  late DateTime _purchaseDate;

  bool get _isSwahili =>
      context.watch<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;
    _name = TextEditingController(text: asset?.name ?? '');
    _category = TextEditingController(text: asset?.category ?? '');
    _cost = TextEditingController(
      text: asset == null ? '' : asset.cost.toStringAsFixed(0),
    );
    _salvage = TextEditingController(
      text: asset == null || asset.salvageValue == 0
          ? ''
          : asset.salvageValue.toStringAsFixed(0),
    );
    _life = TextEditingController(
      text: (asset?.usefulLifeYears ?? 5).toString(),
    );
    _purchaseDate = asset?.purchaseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _cost.dispose();
    _salvage.dispose();
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: widget.asset == null
                  ? _t('Add asset', 'Ongeza mali')
                  : _t('Edit asset', 'Badilisha mali'),
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    MarketSurfaceCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          MarketFormField(
                            label: _t('Asset name', 'Jina la mali'),
                            hintText:
                                _t('e.g. Delivery motorcycle', 'mf. Pikipiki'),
                            controller: _name,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? _t('Enter a name', 'Weka jina')
                                    : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Category', 'Aina'),
                            hintText: _t(
                                'Equipment, furniture...', 'Vifaa, samani...'),
                            controller: _category,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Purchase date', 'Tarehe ya ununuzi'),
                            hintText: _purchaseDate
                                .toLocal()
                                .toString()
                                .substring(0, 10),
                            readOnly: true,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _purchaseDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked == null) return;
                              if (!mounted) return;
                              setState(() {
                                _purchaseDate = picked;
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Cost (TZS)', 'Gharama (TZS)'),
                            hintText: '0',
                            controller: _cost,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (value) =>
                                (double.tryParse(value ?? '') ?? 0) <= 0
                                    ? _t('Enter the cost', 'Weka gharama')
                                    : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Salvage value (TZS)',
                                'Thamani ya mabaki (TZS)'),
                            hintText: '0',
                            controller: _salvage,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t(
                                'Useful life (years)', 'Muda wa kazi (miaka)'),
                            hintText: '5',
                            controller: _life,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MarketButton(
                      label: _t('Save asset', 'Hifadhi mali'),
                      icon: Icons.check_rounded,
                      onTap: _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final store = context.read<PosLocalStore>();
    await store.saveFixedAsset(
      FixedAsset(
        id: widget.asset?.id,
        name: _name.text.trim(),
        category: _category.text.trim(),
        purchaseDate: _purchaseDate,
        cost: double.tryParse(_cost.text.trim()) ?? 0,
        salvageValue: double.tryParse(_salvage.text.trim()) ?? 0,
        usefulLifeYears: int.tryParse(_life.text.trim()) ?? 5,
      ),
    );
    if (!mounted) return;
    showMarketNotice(
      context,
      title: _t('Fixed assets', 'Mali za kudumu'),
      message: _t('Asset saved', 'Mali imehifadhiwa'),
    );
    Navigator.of(context).maybePop();
  }
}
