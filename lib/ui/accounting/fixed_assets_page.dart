import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
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
    final totalCost = assets.fold<double>(0, (sum, a) => sum + a.cost);
    final totalDep =
        assets.fold<double>(0, (sum, a) => sum + a.accumulatedDepreciation());
    final totalNbv = assets.fold<double>(0, (sum, a) => sum + a.netBookValue());

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: t('Fixed assets', 'Mali za kudumu'),
              subtitle: t('Register and track depreciation',
                  'Sajili na fuatilia uchakavu'),
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _flatCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('Net book value', 'Thamani halisi ya kitabu'),
                          style: AppTypography.label
                              .copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _money(totalNbv),
                          style: AppTypography.h1.copyWith(
                            fontSize: 30,
                            color: totalNbv > 0
                                ? AppColors.ink
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t(
                            '${assets.length} asset${assets.length == 1 ? '' : 's'} registered',
                            'Mali ${assets.length} zimesajiliwa',
                          ),
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          label: t('Total cost', 'Jumla ya gharama'),
                          value: _money(totalCost),
                          valueColor:
                              totalCost > 0 ? AppColors.danger : AppColors.textMuted,
                          hint: t('Purchase value', 'Thamani ya ununuzi'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          label: t('Depreciation', 'Uchakavu'),
                          value: _money(totalDep),
                          valueColor: totalDep > 0
                              ? AppColors.danger
                              : AppColors.textMuted,
                          hint: t('Accumulated', 'Imekusanywa'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MarketButton(
                    label: t('Add asset', 'Ongeza mali'),
                    icon: Icons.add_rounded,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const AssetFormPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionHeader(t('Asset register', 'Daftari la mali')),
                  const SizedBox(height: 8),
                  if (assets.isEmpty)
                    _flatCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.inventory_2_outlined,
                                color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            t('No fixed assets', 'Hakuna mali za kudumu'),
                            style: AppTypography.bodyMain
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t(
                              'Register equipment, furniture and vehicles to track cost, depreciation and net book value.',
                              'Sajili vifaa, samani na magari kufuatilia gharama, uchakavu na thamani halisi.',
                            ),
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted, height: 1.45),
                          ),
                        ],
                      ),
                    )
                  else
                    _flatCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _tableHeader(t),
                          const Divider(height: 1, color: AppColors.divider),
                          for (var i = 0; i < assets.length; i++) ...[
                            _AssetRow(asset: assets[i], isSwahili: sw),
                            if (i != assets.length - 1)
                              const Divider(
                                  height: 1, color: AppColors.divider),
                          ],
                        ],
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

  static Widget _tableHeader(String Function(String, String) t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(t('Asset', 'Mali'),
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 3,
            child: Text(t('Cost', 'Gharama'),
                textAlign: TextAlign.right,
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 3,
            child: Text(t('NBV', 'Thamani'),
                textAlign: TextAlign.right,
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static Widget _flatCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return MarketSurfaceCard(
      padding: padding,
      showShadow: false,
      borderColor: AppColors.border,
      radius: 0,
      child: child,
    );
  }

  static Widget _sectionHeader(String text) {
    return Text(
      text,
      style: AppTypography.sectionHeader.copyWith(color: AppColors.ink),
    );
  }

  static Widget _metricCard({
    required String label,
    required String value,
    required Color valueColor,
    required String hint,
  }) {
    return _flatCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.helperText
                  .copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h3.copyWith(
              fontSize: 17,
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(hint,
              style: AppTypography.helperText
                  .copyWith(color: AppColors.textLight)),
        ],
      ),
    );
  }

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.asset, required this.isSwahili});
  final FixedAsset asset;
  final bool isSwahili;

  String _t(String en, String swahili) => isSwahili ? swahili : en;

  @override
  Widget build(BuildContext context) {
    final dep = asset.accumulatedDepreciation();
    final nbv = asset.netBookValue();
    final fullyDep = nbv <= 0.01 && asset.cost > 0;
    final date = asset.purchaseDate.toLocal().toString().substring(0, 10);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 42,
                color: fullyDep ? AppColors.textMuted : AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (asset.category.trim().isNotEmpty)
                          asset.category.trim(),
                        date,
                      ].join(' • '),
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  FixedAssetsPage._money(asset.cost),
                  textAlign: TextAlign.right,
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textBody,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  FixedAssetsPage._money(nbv),
                  textAlign: TextAlign.right,
                  style: AppTypography.bodySmall.copyWith(
                    color: fullyDep ? AppColors.textMuted : AppColors.successDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_t('Depreciation', 'Uchakavu')}: ${FixedAssetsPage._money(dep)} • ${_t('Life', 'Muda')}: ${asset.usefulLifeYears} ${_t('yrs', 'miaka')}',
                    style: AppTypography.helperText
                        .copyWith(color: AppColors.textMuted),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => AssetFormPage(asset: asset),
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      _t('Edit', 'Hariri'),
                      style: AppTypography.helperText.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _confirmDelete(context),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      _t('Delete', 'Futa'),
                      style: AppTypography.helperText.copyWith(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (asset.id == null) return;
    final store = context.read<PosLocalStore>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(_t('Delete asset?', 'Futa mali?')),
        content: Text(
          _t(
            'This asset and its depreciation record will be removed.',
            'Mali hii na rekodi yake ya uchakavu vitaondolewa.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t('Cancel', 'Ghairi')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_t('Delete', 'Futa')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await store.deleteFixedAsset(asset.id!);
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
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;
    _name = TextEditingController(text: asset?.name ?? '');
    _category = TextEditingController(text: asset?.category ?? '');
    _cost = TextEditingController(
      text: asset == null || asset.cost == 0 ? '' : asset.cost.toStringAsFixed(0),
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
      body: SafeArea(
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
                    FixedAssetsPage._flatCard(
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
                            hintText: _t(
                                'e.g. Delivery motorcycle', 'mf. Pikipiki ya usambazaji'),
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
                                          _t('Purchase date', 'Tarehe ya ununuzi'),
                                          style: AppTypography.helperText
                                              .copyWith(
                                                  color: AppColors.textMuted),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _purchaseDate
                                              .toLocal()
                                              .toString()
                                              .substring(0, 10),
                                          style: AppTypography.bodyMain
                                              .copyWith(
                                                  fontWeight: FontWeight.w600),
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
                    FixedAssetsPage._flatCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _t('Cost and depreciation', 'Gharama na uchakavu'),
                            style: AppTypography.sectionHeader
                                .copyWith(color: AppColors.ink),
                          ),
                          const SizedBox(height: 14),
                          MarketFormField(
                            label: _t('Purchase cost (TSh)', 'Gharama ya ununuzi (TSh)'),
                            hintText: '0',
                            controller: _cost,
                            keyboardType: const TextInputType.numberWithOptions(
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
                    FixedAssetsPage._flatCard(
                      padding: EdgeInsets.zero,
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
                                  FixedAssetsPage._money(_previewDep),
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
                          const Divider(height: 1, color: AppColors.divider),
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
                                  FixedAssetsPage._money(_previewNbv),
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
                    const SizedBox(height: 20),
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
      message: widget.asset == null
          ? _t('Asset added', 'Mali imeongezwa')
          : _t('Asset updated', 'Mali imesasishwa'),
      type: MarketNoticeType.success,
    );
    Navigator.of(context).maybePop();
  }
}
