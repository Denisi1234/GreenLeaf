import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
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
  });

  String productName;
  int quantity;
  double unitCost;
  double sellingPrice;

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

  String _t(String en, String swahili) => widget.isSwahili ? swahili : en;

  double get _lineTotal =>
      (int.tryParse(_qtyController.text.trim()) ?? 0) *
      (double.tryParse(_costController.text.trim().replaceAll(',', '')) ?? 0);

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _costController.dispose();
    _priceController.dispose();
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
        if (_costController.text.trim().isEmpty) {
          _costController.text = item.purchasePrice.toStringAsFixed(0);
        }
        if (_priceController.text.trim().isEmpty) {
          _priceController.text = item.sellingPrice.toStringAsFixed(0);
        }
      }
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    if (name.isEmpty || qty <= 0) {
      showMarketNotice(
        context,
        title: _t('Item required', 'Bidhaa inahitajika'),
        message: _t('Enter product name and a valid quantity.',
            'Weka jina la bidhaa na idadi sahihi.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    Navigator.of(context).pop(
      DraftReceivingLine(
        productName: name,
        quantity: qty,
        unitCost:
            double.tryParse(_costController.text.trim().replaceAll(',', '')) ??
                0,
        sellingPrice:
            double.tryParse(_priceController.text.trim().replaceAll(',', '')) ??
                0,
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
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.inventory_2_outlined,
                                        size: 16, color: AppColors.primaryDeep),
                                    const SizedBox(width: 6),
                                    Text(
                                      _t('Pick from existing stock',
                                          'Chagua kutoka hifadhi iliyopo'),
                                      style: AppTypography.helperText.copyWith(
                                        color: AppColors.primaryDeep,
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
                            Text(
                              _t('Quantity and cost', 'Idadi na gharama'),
                              style: AppTypography.sectionHeader
                                  .copyWith(color: AppColors.ink),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: MarketFormField(
                                    label: _t('Quantity received',
                                        'Idadi iliyopokelewa'),
                                    hintText: '1',
                                    controller: _qtyController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: MarketFormField(
                                    label: _t('Unit cost (TSh)',
                                        'Gharama ya kipande (TSh)'),
                                    hintText: '0',
                                    controller: _costController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            MarketFormField(
                              label: _t('Selling price (optional)',
                                  'Bei ya kuuza (hiari)'),
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
                      const SizedBox(height: 20),
                      MarketButton(
                        label: _t('Add to receiving', 'Ongeza kwenye upokeaji'),
                        icon: Icons.check_rounded,
                        onTap: _save,
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
                                                    '${items[i].category} • ${t('In stock', 'Iliyopo')}: ${items[i].stockCount} • ${t('Cost', 'Gharama')} ${_money(items[i].purchasePrice)}',
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
                                                  '${items[i].stockCount}',
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
          )),
    );
  }
}
