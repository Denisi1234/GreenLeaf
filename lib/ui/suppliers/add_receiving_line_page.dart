import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/quantity_formatter.dart';
import '../products/inventory_product_item.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';

String _money(double value) {
  final negative = value < 0;
  return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
}

/// Model for draft items added during a goods received note.
class DraftReceivingLine {
  DraftReceivingLine({
    required this.productName,
    required this.quantity,
    required this.unitCost,
    this.sellingPrice = 0,
    this.unit = 'Pcs',
  });

  String productName;
  double quantity;
  double unitCost;
  double sellingPrice;
  String unit;

  double get total => quantity * unitCost;
}

/// Full-page add receiving line (replaces modal).
class AddReceivingLinePage extends StatefulWidget {
  const AddReceivingLinePage({super.key, required this.isSwahili});
  final bool isSwahili;

  @override
  State<AddReceivingLinePage> createState() => _AddReceivingLinePageState();
}

class _AddReceivingLinePageState extends State<AddReceivingLinePage> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _costController = TextEditingController();
  final _priceController = TextEditingController();
  final _packSizeController = TextEditingController(text: '100');
  final _packQtyController = TextEditingController(text: '1');
  final _packCostController = TextEditingController();

  InventoryProductItem? _pickedItem;
  String _unit = 'Pcs';
  bool _receiveByPack = false;
  String _packName = 'Mfuko';

  String _t(String en, String swahili) => widget.isSwahili ? swahili : en;

  double _parseNum(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '')) ?? 0;

  double get _packSize => _parseNum(_packSizeController);
  double get _packQty => _parseNum(_packQtyController);
  double get _packCost => _parseNum(_packCostController);

  double get _effectiveQty => _receiveByPack
      ? roundQuantity(_packQty * _packSize)
      : roundQuantity(_parseNum(_qtyController));

  double get _effectiveUnitCost => _receiveByPack
      ? (_packSize > 0 ? _packCost / _packSize : 0)
      : _parseNum(_costController);

  double get _lineTotal => _receiveByPack
      ? (_packQty * _packCost)
      : (_effectiveQty * _effectiveUnitCost);

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _packSizeController.dispose();
    _packQtyController.dispose();
    _packCostController.dispose();
    super.dispose();
  }

  Future<void> _pickFromStock() async {
    final name = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => StockPickerPage(isSwahili: widget.isSwahili),
      ),
    );
    if (name == null || !mounted) return;
    final store = context.read<PosLocalStore>();
    setState(() {
      _nameController.text = name;
      final match = store.inventory.where((item) => item.name == name).toList();
      if (match.isNotEmpty) {
        final item = match.first;
        _pickedItem = item;
        _unit = item.unit;
        if (_costController.text.trim().isEmpty && item.purchasePrice > 0) {
          _costController.text = item.purchasePrice.toStringAsFixed(0);
        }
        if (_priceController.text.trim().isEmpty && item.sellingPrice > 0) {
          _priceController.text = item.sellingPrice.toStringAsFixed(0);
        }
        if (item.hasBulkPack) {
          _packName = item.packName!;
          _packSizeController.text = formatQuantity(item.packSize!);
          _receiveByPack = true;
          if (_packCostController.text.trim().isEmpty &&
              item.purchasePrice > 0) {
            _packCostController.text =
                (item.purchasePrice * item.packSize!).toStringAsFixed(0);
          }
        } else {
          _packName = defaultPackNameForUnit(item.unit);
        }
      }
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final qty = _effectiveQty;
    if (name.isEmpty || qty <= 0) {
      showMarketNotice(
        context,
        title: _t('Item required', 'Bidhaa inahitajika'),
        message: _t(
            _receiveByPack
                ? 'Enter product name, pack count, and pack size.'
                : 'Enter product name and a valid quantity.',
            _receiveByPack
                ? 'Weka jina la bidhaa, idadi ya mafungu, na ukubwa wa fungu.'
                : 'Weka jina la bidhaa na idadi sahihi.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    Navigator.of(context).pop(
      DraftReceivingLine(
        productName: name,
        quantity: qty,
        unitCost: _effectiveUnitCost,
        sellingPrice: _parseNum(_priceController),
        unit: _unit,
      ),
    );
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
                  title: _t('Add item line', 'Ongeza mstari wa bidhaa'),
                  subtitle: _t('Product, quantity, and purchase cost',
                      'Bidhaa, idadi, na gharama ya ununuzi'),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      MarketSurfaceCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MarketFormField(
                              label: _t('Product name', 'Jina la bidhaa'),
                              hintText: _t('Enter or pick product',
                                  'Weka au chagua bidhaa'),
                              controller: _nameController,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: _pickFromStock,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.kpiSkyBg,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.inventory_2_outlined,
                                        size: 16, color: AppColors.kpiSky),
                                    const SizedBox(width: 6),
                                    Text(
                                      _t('Pick from existing stock',
                                          'Chagua kutoka hifadhi iliyopo'),
                                      style: AppTypography.helperText.copyWith(
                                        color: AppColors.kpiSky,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _t('Quantity and cost', 'Idadi na gharama'),
                                    style: AppTypography.sectionHeader
                                        .copyWith(color: AppColors.ink),
                                  ),
                                ),
                                if (_pickedItem != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      border: Border.all(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      _unit,
                                      style: AppTypography.helperText.copyWith(
                                        color: AppColors.primaryDeep,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              activeThumbColor: AppColors.primaryDeep,
                              title: Text(
                                _t('Receive by bulk pack',
                                    'Pokea kwa fungu / mfuko'),
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              subtitle: Text(
                                _t('E.g., 1 $_packName = 100 $_unit',
                                    'Mfano: 1 $_packName = 100 $_unit'),
                                style: AppTypography.helperText
                                    .copyWith(color: AppColors.textMuted),
                              ),
                              value: _receiveByPack,
                              onChanged: (value) {
                                setState(() {
                                  _receiveByPack = value;
                                  if (value &&
                                      _packCostController.text.trim().isEmpty &&
                                      _packSize > 0 &&
                                      _parseNum(_costController) > 0) {
                                    _packCostController.text =
                                        (_parseNum(_costController) * _packSize)
                                            .toStringAsFixed(0);
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            if (!_receiveByPack)
                              Row(
                                children: [
                                  Expanded(
                                    child: MarketFormField(
                                      label: _t('Quantity received ($_unit)',
                                          'Idadi iliyopokelewa ($_unit)'),
                                      hintText: '1',
                                      controller: _qtyController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: MarketFormField(
                                      label: _t('Cost per $_unit (TSh)',
                                          'Gharama kwa $_unit (TSh)'),
                                      hintText: '0',
                                      controller: _costController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              )
                            else ...[
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: const [
                                  'Mfuko',
                                  'Gunia',
                                  'Debe',
                                  'Katoni',
                                  'Bokisi',
                                ]
                                    .map((name) => ChoiceChip(
                                          label: Text(name),
                                          selected: _packName == name,
                                          selectedColor: AppColors.primaryLight,
                                          labelStyle:
                                              AppTypography.helperText.copyWith(
                                            color: _packName == name
                                                ? AppColors.primaryDeep
                                                : AppColors.ink,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          onSelected: (_) =>
                                              setState(() => _packName = name),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: MarketFormField(
                                      label: _t('${_packName}s received',
                                          'Idadi ya $_packName'),
                                      hintText: '1',
                                      controller: _packQtyController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: MarketFormField(
                                      label: _t('$_unit per $_packName',
                                          '$_unit kwa 1 $_packName'),
                                      hintText: '100',
                                      controller: _packSizeController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              MarketFormField(
                                label: _t('Cost per $_packName (TSh)',
                                    'Gharama ya 1 $_packName (TSh)'),
                                hintText: '0',
                                controller: _packCostController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                onChanged: (_) => setState(() {}),
                              ),
                              if (_effectiveQty > 0) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    _t(
                                      'Adds ${formatStockWithUnit(_effectiveQty, _unit)} (${_money(_effectiveUnitCost)} / $_unit)',
                                      'Inaongeza ${formatStockWithUnit(_effectiveQty, _unit)} (${_money(_effectiveUnitCost)} / $_unit)',
                                    ),
                                    style: AppTypography.helperText.copyWith(
                                      color: AppColors.primaryDeep,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 14),
                            MarketFormField(
                              label: _t('Selling price per $_unit (optional)',
                                  'Bei ya kuuza kwa $_unit (hiari)'),
                              hintText: '0',
                              controller: _priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      MarketSurfaceCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _t('Line total', 'Jumla ya mstari'),
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              _money(_lineTotal),
                              style: AppTypography.h3.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: _lineTotal > 0
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
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
                          radius: AppRadius.input,
                          onTap: () => Navigator.of(context).maybePop(),
                          height: 48,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: MarketButton(
                          label:
                              _t('Add to receiving', 'Ongeza kwenye upokeaji'),
                          icon: Icons.check_rounded,
                          variant: MarketButtonVariant.primary,
                          borderColor: null,
                          radius: AppRadius.input,
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
}

/// Full-page stock picker.
class StockPickerPage extends StatelessWidget {
  const StockPickerPage({super.key, required this.isSwahili});
  final bool isSwahili;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final items = store.inventory;
    String t(String en, String swahili) => isSwahili ? swahili : en;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: t('Pick from stock', 'Chagua kutoka hifadhi'),
                  subtitle: t('Select a product to prefill item details',
                      'Chagua bidhaa kujaza taarifa za mstari'),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: items.isEmpty
                      ? ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          children: [
                            MarketSurfaceCard(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                t('No stock items available.',
                                    'Hakuna bidhaa kwenye hifadhi.'),
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          children: [
                            MarketSurfaceCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  for (var i = 0; i < items.length; i++) ...[
                                    InkWell(
                                      onTap: () => Navigator.of(context)
                                          .pop(items[i].name),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 12, 16, 12),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 40,
                                              color: items[i].stockCount <= 0
                                                  ? AppColors.danger
                                                  : AppColors.success,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    items[i].name,
                                                    style: AppTypography
                                                        .bodySmall
                                                        .copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                AppColors.ink),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${items[i].category} • ${t('In stock', 'Iliyopo')}: ${formatStockWithUnit(items[i].stockCount, items[i].unit)} • ${t('Cost', 'Gharama')} ${_money(items[i].purchasePrice)}',
                                                    style: AppTypography
                                                        .helperText
                                                        .copyWith(
                                                            color: AppColors
                                                                .textMuted),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  formatStockWithUnit(
                                                      items[i].stockCount,
                                                      items[i].unit),
                                                  style: AppTypography.bodySmall
                                                      .copyWith(
                                                    color:
                                                        items[i].stockCount <= 0
                                                            ? AppColors.danger
                                                            : AppColors.success,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  t('in stock', 'hifadhini'),
                                                  style: AppTypography
                                                      .helperText
                                                      .copyWith(
                                                          color: AppColors
                                                              .textMuted),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (i != items.length - 1)
                                      Divider(
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
          )),
    );
  }
}
