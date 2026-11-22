import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'fixed_assets_page.dart';

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
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;
    _name = TextEditingController(text: asset?.name ?? '');
    _category = TextEditingController(text: asset?.category ?? '');
    _cost = TextEditingController(
      text:
          asset == null || asset.cost == 0 ? '' : asset.cost.toStringAsFixed(0),
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

  double get _previewNbv {
    final cost = double.tryParse(_cost.text.trim()) ?? 0;
    final salvage = double.tryParse(_salvage.text.trim()) ?? 0;
    final life = int.tryParse(_life.text.trim()) ?? 0;
    if (cost <= 0 || life <= 0) return 0;
    final temp = FixedAsset(
      name: '',
      category: '',
      purchaseDate: _purchaseDate,
      cost: cost,
      salvageValue: salvage,
      usefulLifeYears: life,
    );
    return temp.netBookValue();
  }

  double get _previewDep {
    final cost = double.tryParse(_cost.text.trim()) ?? 0;
    final salvage = double.tryParse(_salvage.text.trim()) ?? 0;
    final life = int.tryParse(_life.text.trim()) ?? 0;
    if (cost <= 0 || life <= 0) return 0;
    final temp = FixedAsset(
      name: '',
      category: '',
      purchaseDate: _purchaseDate,
      cost: cost,
      salvageValue: salvage,
      usefulLifeYears: life,
    );
    return temp.accumulatedDepreciation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 860,
          child: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: widget.asset == null
                      ? _t('Add asset', 'Ongeza mali')
                      : _t('Edit asset', 'Hariri mali'),
                  subtitle: _t('Asset details and depreciation',
                      'Taarifa za mali na uchakavu'),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        MarketSurfaceCard(
                          padding: const EdgeInsets.all(16),
                          radius: 0,
                          showShadow: false,
                          borderColor: AppColors.border,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t('Asset details', 'Taarifa za mali'),
                                style: AppTypography.sectionHeader
                                    .copyWith(color: AppColors.ink),
                              ),
                              const SizedBox(height: 14),
                              MarketFormField(
                                label: _t('Asset name', 'Jina la mali'),
                                hintText: _t('e.g. Delivery motorcycle',
                                    'mf. Pikipiki ya usambazaji'),
                                controller: _name,
                                onChanged: (_) => setState(() {}),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? _t('Enter a name', 'Weka jina')
                                        : null,
                              ),
                              const SizedBox(height: 14),
                              MarketFormField(
                                label: _t('Category', 'Kundi'),
                                hintText: _t('Equipment, furniture, vehicle...',
                                    'Vifaa, samani, gari...'),
                                controller: _category,
                              ),
                              const SizedBox(height: 14),
                              InkWell(
                                onTap: _pickDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide:
                                          BorderSide(color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide:
                                          BorderSide(color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.zero,
                                      borderSide: BorderSide(
                                          color: AppColors.primary, width: 1.4),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.surface,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _t('Purchase date',
                                                  'Tarehe ya ununuzi'),
                                              style: AppTypography.helperText
                                                  .copyWith(
                                                      color:
                                                          AppColors.textMuted),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _purchaseDate
                                                  .toLocal()
                                                  .toString()
                                                  .substring(0, 10),
                                              style: AppTypography.bodyMain
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.calendar_today_outlined,
                                          size: 18, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        MarketSurfaceCard(
                          padding: const EdgeInsets.all(16),
                          radius: 0,
                          showShadow: false,
                          borderColor: AppColors.border,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t('Cost and depreciation',
                                    'Gharama na uchakavu'),
                                style: AppTypography.sectionHeader
                                    .copyWith(color: AppColors.ink),
                              ),
                              const SizedBox(height: 14),
                              MarketFormField(
                                label: _t('Purchase cost (TSh)',
                                    'Gharama ya ununuzi (TSh)'),
                                hintText: '0',
                                controller: _cost,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (_) => setState(() {}),
                                validator: (value) =>
                                    (double.tryParse(value ?? '') ?? 0) <= 0
                                        ? _t('Enter the cost', 'Weka gharama')
                                        : null,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: MarketFormField(
                                      label: _t('Salvage value (TSh)',
                                          'Thamani ya mabaki (TSh)'),
                                      hintText: '0',
                                      controller: _salvage,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: MarketFormField(
                                      label: _t('Useful life (years)',
                                          'Muda wa matumizi (miaka)'),
                                      hintText: '5',
                                      controller: _life,
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        MarketSurfaceCard(
                          padding: EdgeInsets.zero,
                          radius: 0,
                          showShadow: false,
                          borderColor: AppColors.border,
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _t('Accumulated depreciation',
                                            'Uchakavu uliokusanywa'),
                                        style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textMuted),
                                      ),
                                    ),
                                    Text(
                                      FixedAssetsPage.formatMoney(_previewDep),
                                      style: AppTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: _previewDep > 0
                                            ? AppColors.danger
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                  height: 1, color: AppColors.divider),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _t('Net book value', 'Thamani halisi'),
                                        style: AppTypography.bodyMain.copyWith(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    Text(
                                      FixedAssetsPage.formatMoney(_previewNbv),
                                      style: AppTypography.h3.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: _previewNbv > 0
                                            ? AppColors.successDeep
                                            : AppColors.textMuted,
                                      ),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(
                        top: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: MarketButton(
                          label: _t('Cancel', 'Ghairi'),
                          color: AppColors.kpiDangerBg,
                          foregroundColor: AppColors.kpiDanger,
                          borderColor: null,
                          radius: 0,
                          onTap: () => Navigator.of(context).maybePop(),
                          height: 48,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: MarketButton(
                          label: _t('Save asset', 'Hifadhi mali'),
                          icon: Icons.check_rounded,
                          variant: MarketButtonVariant.primary,
                          borderColor: null,
                          radius: 0,
                          height: 48,
                          onTap: _save,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _purchaseDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cost = double.tryParse(_cost.text.trim());
    final salvage = double.tryParse(_salvage.text.trim());
    final life = int.tryParse(_life.text.trim());
    if (cost == null ||
        !cost.isFinite ||
        cost <= 0 ||
        salvage == null ||
        !salvage.isFinite ||
        salvage < 0 ||
        salvage > cost ||
        life == null ||
        life <= 0) {
      showMarketNotice(context,
          title: _t('Check asset values', 'Kagua thamani za mali'),
          message: _t(
              'Enter a positive cost and useful life. Salvage value must be between zero and the purchase cost.',
              'Weka gharama na muda halali. Thamani ya mabaki isizidi gharama ya ununuzi.'),
          type: MarketNoticeType.warning);
      return;
    }
    final store = context.read<PosLocalStore>();
    final nav = Navigator.of(context);
    final isNew = widget.asset == null;
    final assetName = _name.text.trim();

    await store.saveFixedAsset(
      FixedAsset(
        id: widget.asset?.id,
        name: assetName,
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
      title: isNew
          ? _t('Asset Added', 'Mali Imeongezwa')
          : _t('Asset Updated', 'Mali Imesasishwa'),
      message: isNew
          ? _t('$assetName added successfully', '$assetName imeongezwa kikamilifu')
          : _t('$assetName updated successfully', '$assetName imesasishwa kikamilifu'),
      type: MarketNoticeType.success,
    );
    nav.maybePop();
  }
}
