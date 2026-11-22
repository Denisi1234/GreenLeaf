import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/supplier_model.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/quantity_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'add_receiving_line_page.dart';
import 'supplier_picker_page.dart';
import 'widgets/draft_line_row.dart';

String _money(double value) {
  final negative = value < 0;
  return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
}

/// New goods received note; saving adds stock and records purchase cost.
class NewReceivingPage extends StatefulWidget {
  const NewReceivingPage({super.key, this.presetSupplier});

  final Supplier? presetSupplier;

  @override
  State<NewReceivingPage> createState() => _NewReceivingPageState();
}

class _NewReceivingPageState extends State<NewReceivingPage> {
  final List<DraftReceivingLine> _lines = [];
  final TextEditingController _invoiceController = TextEditingController();
  Supplier? _supplier;
  bool _saving = false;

  bool get _isSwahili =>
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void initState() {
    super.initState();
    _supplier = widget.presetSupplier;
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  double get _total => _lines.fold<double>(0, (sum, line) => sum + line.total);
  double get _units =>
      roundQuantity(_lines.fold<double>(0, (sum, line) => sum + line.quantity));

  @override
  Widget build(BuildContext context) {
    final supplierName = _supplier?.name ?? '';
    final items =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader(_t('Items received', 'Bidhaa zilizopokelewa'),
          trailing:
              '${_lines.length} ${_t('items', 'bidhaa')} • ${formatQuantity(_units)} ${_t('units', 'vipimo')}'),
      const SizedBox(height: 12),
      _linesCard(),
      const SizedBox(height: 12),
      OutlinedButton.icon(
          onPressed: _saving ? null : _addLine,
          style: OutlinedButton.styleFrom(
            backgroundColor: AppColors.kpiSkyBg,
            foregroundColor: AppColors.kpiSky,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(
            _t('Add item', 'Ongeza bidhaa'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          )),
    ]);
    final save = FilledButton.icon(
      onPressed: _saving ? null : _save,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      icon: _saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.check_rounded),
      label: Text(
        _saving
            ? _t('Saving...', 'Inahifadhi...')
            : _t('Save and add to stock', 'Hifadhi na ongeza hifadhini'),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 1280,
          child: Stack(
            children: [
              SafeArea(
                  child: Column(children: [
                MarketPageHeader(
                  title: _t('New receiving', 'Upokeaji mpya'),
                  subtitle: _t('Record a supplier delivery and update inventory',
                      'Rekodi usambazaji na sasisha hifadhi'),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(child: LayoutBuilder(builder: (context, constraints) {
                  if (constraints.maxWidth >= 1050) {
                    return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: ListView(children: [items])),
                              const SizedBox(width: 24),
                              SizedBox(
                                  width: 360,
                                  child: Column(children: [
                                    Expanded(
                                        child: ListView(children: [
                                      _deliveryDetailsCard(supplierName),
                                      const SizedBox(height: 16),
                                      _summaryCard()
                                    ])),
                                    const SizedBox(height: 16),
                                    save,
                                  ])),
                            ]));
                  }
                  return Column(children: [
                    Expanded(
                        child:
                            ListView(padding: const EdgeInsets.all(16), children: [
                      _deliveryDetailsCard(supplierName),
                      const SizedBox(height: 24),
                      items,
                      const SizedBox(height: 20),
                      _summaryCard(),
                    ])),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: const BoxDecoration(
                          color: AppColors.surface,
                          border: Border(top: BorderSide(color: AppColors.border))),
                      child: save,
                    ),
                  ]);
                })),
              ])),
              if (_saving)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: MarketLoadingView(
                    message: _t('Updating Inventory…', 'Inasasisha Hifadhi…'),
                    subMessage: _t(
                      'Recording supplier receiving and recalculating stock levels',
                      'Inarekodi upokeaji na kupitia upya idadi ya bidhaa',
                    ),
                    color: AppColors.successDeep,
                  ),
                ),
            ],
          )),
    );
  }

  Widget _deliveryDetailsCard(String supplierName) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Delivery details', 'Taarifa za usambazaji'),
            style: AppTypography.sectionHeader.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          Text(_t('Supplier', 'Msambazaji'), style: AppTypography.label),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickSupplier,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(
                  color: AppColors.border,
                ),
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      supplierName.isEmpty
                          ? _t('Select supplier (required)',
                              'Chagua msambazaji (inahitajika)')
                          : supplierName,
                      style: AppTypography.bodyMain.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    supplierName.isEmpty
                        ? _t('Choose', 'Chagua')
                        : _t('Change', 'Badili'),
                    style: AppTypography.helperText.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          MarketFormField(
            label: _t('Invoice / delivery note no.',
                'Namba ya ankara / hati ya usambazaji'),
            hintText: _t('Optional reference', 'Rejea ya hiari'),
            controller: _invoiceController,
          ),
        ],
      ),
    );
  }

  Widget _linesCard() {
    if (_lines.isEmpty) {
      return MarketSurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('No items added', 'Hakuna bidhaa zilizoongezwa'),
              style:
                  AppTypography.bodyMain.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _t(
                'Add each product received. Quantity and unit cost will update stock and purchase value.',
                'Ongeza kila bidhaa iliyopokelewa. Idadi na gharama vitaongeza hifadhi na thamani ya ununuzi.',
              ),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted, height: 1.45),
            ),
          ],
        ),
      );
    }

    return MarketSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            color: AppColors.surfaceSecondary,
            child: Text(
                _t('Product • Quantity • Unit cost • Line total',
                    'Bidhaa • Idadi • Gharama • Jumla'),
                style: AppTypography.label),
          ),
          for (var i = 0; i < _lines.length; i++) ...[
            DraftLineRow(
              key: ObjectKey(_lines[i]),
              index: i + 1,
              line: _lines[i],
              isSwahili: _isSwahili,
              onChanged: () => setState(() {}),
              onDelete: () => setState(() => _lines.removeAt(i)),
            ),
            if (i != _lines.length - 1)
              const Divider(height: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return MarketSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _t('Items / units', 'Bidhaa / vipande'),
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                ),
                Text(
                  '${_lines.length} / ${formatQuantity(_units)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _t('Total purchase value', 'Jumla ya thamani ya ununuzi'),
                    style: AppTypography.bodyMain
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _money(_total),
                  style: AppTypography.h3.copyWith(
                    fontSize: 20,
                    color: _total > 0 ? AppColors.success : AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text, {String? trailing}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: AppTypography.sectionHeader.copyWith(color: AppColors.ink),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: AppTypography.helperText.copyWith(
                color: AppColors.textMuted, fontWeight: FontWeight.w700),
          ),
      ],
    );
  }

  Future<void> _pickSupplier() async {
    final selected = await Navigator.of(context).push<Supplier>(
      MaterialPageRoute<Supplier>(
        builder: (_) => SupplierPickerPage(isSwahili: _isSwahili),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _supplier = selected);
  }

  Future<void> _addLine() async {
    final draft = await Navigator.of(context).push<DraftReceivingLine>(
      MaterialPageRoute<DraftReceivingLine>(
        builder: (_) => AddReceivingLinePage(isSwahili: _isSwahili),
      ),
    );
    if (draft == null) return;
    setState(() => _lines.add(draft));
  }

  Future<void> _save() async {
    if (_supplier?.id == null) {
      showMarketNotice(
        context,
        title: _t('Supplier required', 'Msambazaji anahitajika'),
        message: _t('Select a supplier before saving.',
            'Chagua msambazaji kabla ya kuhifadhi.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    final validLines = _lines;
    if (validLines.isEmpty ||
        validLines.any((line) =>
            line.productName.trim().isEmpty ||
            line.quantity <= 0 ||
            !line.unitCost.isFinite ||
            line.unitCost < 0 ||
            !line.sellingPrice.isFinite ||
            line.sellingPrice < 0)) {
      showMarketNotice(context,
          title: _t('Check received items', 'Kagua bidhaa zilizopokelewa'),
          message: _t(
              'Every item needs a name, a positive quantity and valid non-negative prices.',
              'Kila bidhaa inahitaji jina, idadi sahihi na bei halali.'),
          type: MarketNoticeType.warning);
      return;
    }
    setState(() => _saving = true);
    try {
      final store = context.read<PosLocalStore>();
      final total = validLines.fold<double>(0, (sum, line) => sum + line.total);
      await store.saveReceiving(
        Receiving(
          supplierId: _supplier!.id,
          supplierName: _supplier!.name,
          date: DateTime.now(),
          invoiceNo: _invoiceController.text.trim(),
          total: total,
          receivedBy: store.profile.ownerName,
          lines: [
            for (final line in validLines)
              ReceivingLine(
                productName: line.productName.trim(),
                quantity: line.quantity,
                unitCost: line.unitCost,
                sellingPrice: line.sellingPrice,
              ),
          ],
        ),
      );
      if (!mounted) return;
      showMarketNotice(
        context,
        title: _t('Goods received', 'Bidhaa zimepokelewa'),
        message: _t('Stock quantities and purchase cost updated.',
            'Idadi ya hifadhi na gharama ya ununuzi zimesasishwa.'),
        type: MarketNoticeType.success,
      );
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

