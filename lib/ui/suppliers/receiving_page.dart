import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/supplier_model.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

/// Goods received register: lists stock-in documents and opens the form.
class ReceivingPage extends StatefulWidget {
  const ReceivingPage({super.key, this.presetSupplier});

  final Supplier? presetSupplier;

  @override
  State<ReceivingPage> createState() => _ReceivingPageState();
}

class _ReceivingPageState extends State<ReceivingPage> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;

    final receivings = store.receivings;
    final totalValue = receivings.fold<double>(
      0,
      (sum, receiving) => sum + receiving.total,
    );

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: t('Goods received', 'Bidhaa zilizopokelewa'),
              subtitle:
                  'TZS ${totalValue.toStringAsFixed(0)} • ${receivings.length}',
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
              actions: [
                IconButton(
                  tooltip: t('New receiving', 'Upokeaji mpya'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => NewReceivingPage(
                          presetSupplier: widget.presetSupplier),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, color: AppColors.ink),
                ),
              ],
            ),
            Expanded(
              child: receivings.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.move_to_inbox_outlined,
                                size: 40, color: AppColors.textLight),
                            const SizedBox(height: 12),
                            Text(
                              t('No goods received yet',
                                  'Hakuna bidhaa zilizopokelewa'),
                              style: AppTypography.h3.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t(
                                'Record deliveries from suppliers to update stock and purchase costs.',
                                'Rekodi usambazaji kutoka kwa wasambazaji ili kusasisha '
                                    'hifadhi na gharama za manunuzi.',
                              ),
                              textAlign: TextAlign.center,
                              style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted, height: 1.4),
                            ),
                            const SizedBox(height: 18),
                            MarketButton(
                              label: t('New receiving', 'Upokeaji mpya'),
                              icon: Icons.add_rounded,
                              isFullWidth: false,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => NewReceivingPage(
                                      presetSupplier: widget.presetSupplier),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        for (final receiving in receivings)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: MarketSurfaceCard(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 14, 12, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          receiving.supplierName.isEmpty
                                              ? t('Unknown supplier',
                                                  'Msambazaji hajulikani')
                                              : receiving.supplierName,
                                          style: AppTypography.bodyMain
                                              .copyWith(
                                                  fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Text(
                                        'TZS ${receiving.total.toStringAsFixed(0)}',
                                        style: AppTypography.bodySmall.copyWith(
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${receiving.date.toLocal().toString().substring(0, 16)} • '
                                    '${receiving.itemCount} ${t('units', 'vipande')}'
                                    '${receiving.invoiceNo.isEmpty ? '' : ' • ${receiving.invoiceNo}'}',
                                    style: AppTypography.helperText
                                        .copyWith(color: AppColors.textMuted),
                                  ),
                                  if (receiving.lines.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    for (final line in receiving.lines.take(4))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '${line.quantity} × ${line.productName} '
                                          '— TZS ${line.unitCost.toStringAsFixed(0)}',
                                          style: AppTypography.helperText
                                              .copyWith(
                                                  color: AppColors.textMuted),
                                        ),
                                      ),
                                    if (receiving.lines.length > 4)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '+${receiving.lines.length - 4} ${t('more items', 'bidhaa zaidi')}',
                                          style: AppTypography.helperText
                                              .copyWith(
                                                  color: AppColors.textLight),
                                        ),
                                      ),
                                  ],
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          _confirmDelete(receiving),
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16),
                                      label: Text(t('Delete', 'Futa')),
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

  Future<void> _confirmDelete(Receiving receiving) async {
    if (receiving.id == null) return;
    final sw = context.read<PosLocalStore>().languageCode == 'sw';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(sw ? 'Futa upokeaji?' : 'Delete receiving?'),
        content: Text(
          sw
              ? 'Stock added by this delivery will not be reversed.'
              : 'Stock added by this delivery will not be reversed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(sw ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(sw ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await context.read<PosLocalStore>().deleteReceiving(receiving.id!);
  }
}

class _DraftLine {
  _DraftLine({
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

/// New goods received note; saving adds stock and records purchase cost.
class NewReceivingPage extends StatefulWidget {
  const NewReceivingPage({super.key, this.presetSupplier});

  final Supplier? presetSupplier;

  @override
  State<NewReceivingPage> createState() => _NewReceivingPageState();
}

class _NewReceivingPageState extends State<NewReceivingPage> {
  final List<_DraftLine> _lines = [];
  final TextEditingController _invoiceController = TextEditingController();
  int? _supplierId;
  String _supplierName = '';
  bool _saving = false;

  bool get _isSwahili =>
      context.watch<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void initState() {
    super.initState();
    final preset = widget.presetSupplier;
    if (preset != null) {
      _supplierId = preset.id;
      _supplierName = preset.name;
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  double get _total => _lines.fold<double>(0, (sum, line) => sum + line.total);

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: _t('New receiving', 'Upokeaji mpya'),
              subtitle: _supplierName.isEmpty
                  ? _t('Choose supplier and items',
                      'Chagua msambazaji na bidhaa')
                  : _supplierName,
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  MarketSurfaceCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _pickSupplier,
                          borderRadius:
                              BorderRadius.circular(AppRadius.standard),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.standard),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_shipping_outlined,
                                    size: 18, color: AppColors.ink),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _supplierName.isEmpty
                                        ? _t('Select supplier',
                                            'Chagua msambazaji')
                                        : _supplierName,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: _supplierName.isEmpty
                                          ? AppColors.textLight
                                          : AppColors.ink,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.expand_more_rounded,
                                    size: 20, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        MarketFormField(
                          label: _t('Invoice / delivery note',
                              'Ankara / hati ya usambazaji'),
                          hintText: _t('e.g. INV-1024', 'mf. INV-1024'),
                          controller: _invoiceController,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _t('Items received', 'Bidhaa zilizopokelewa'),
                          style: AppTypography.label,
                        ),
                      ),
                      Text(
                        '${_lines.length}',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (_lines.isEmpty)
                    MarketSurfaceCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Text(
                            _t(
                              'No items added yet. Add products to increase stock.',
                              'Hakuna bidhaa bado. Ongeza bidhaa ili kuongeza hifadhi.',
                            ),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted, height: 1.4),
                          ),
                        ],
                      ),
                    )
                  else
                    for (var index = 0; index < _lines.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LineCard(
                          index: index + 1,
                          line: _lines[index],
                          isSwahili: _isSwahili,
                          onChanged: () => setState(() {}),
                          onDelete: () =>
                              setState(() => _lines.removeAt(index)),
                        ),
                      ),
                  const SizedBox(height: AppSpacing.sm),
                  MarketButton(
                    label: _t('Add item', 'Ongeza bidhaa'),
                    icon: Icons.add_rounded,
                    isPrimary: false,
                    onTap: _addLine,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MarketSurfaceCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _t('Total purchase value', 'Thamani ya manunuzi'),
                            style: AppTypography.bodySmall
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          'TZS ${_total.toStringAsFixed(0)}',
                          style: AppTypography.bodyMain
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MarketButton(
                    label: _saving
                        ? _t('Saving...', 'Inahifadhi...')
                        : _t('Save receiving', 'Hifadhi upokeaji'),
                    icon: Icons.check_rounded,
                    onTap: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSupplier() async {
    final store = context.read<PosLocalStore>();
    final suppliers = store.suppliers;
    if (suppliers.isEmpty) {
      showMarketNotice(
        context,
        title: _t('Suppliers', 'Wasambazaji'),
        message: _t('Add a supplier first', 'Ongeza msambazaji kwanza'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    final selected = await showModalBottomSheet<Supplier>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Text(
                _t('Select supplier', 'Chagua msambazaji'),
                style: AppTypography.h3.copyWith(fontSize: 16),
              ),
            ),
            for (final supplier in suppliers)
              ListTile(
                leading: const Icon(Icons.local_shipping_outlined, size: 18),
                title: Text(supplier.name),
                subtitle: Text(supplier.phone),
                onTap: () => Navigator.of(context).pop(supplier),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _supplierId = selected.id;
      _supplierName = selected.name;
    });
  }

  Future<void> _addLine() async {
    final draft = await showModalBottomSheet<_DraftLine>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => _AddLineSheet(isSwahili: _isSwahili),
    );
    if (draft == null) return;
    setState(() => _lines.add(draft));
  }

  Future<void> _save() async {
    if (_supplierId == null) {
      showMarketNotice(
        context,
        title: _t('Supplier required', 'Msambazaji anahitajika'),
        message: _t('Choose a supplier', 'Chagua msambazaji'),
        type: MarketNoticeType.error,
      );
      return;
    }
    if (_lines.isEmpty) {
      showMarketNotice(
        context,
        title: _t('Items required', 'Bidhaa zinahitajika'),
        message: _t('Add at least one item', 'Ongeza angalau bidhaa moja'),
        type: MarketNoticeType.error,
      );
      return;
    }
    setState(() => _saving = true);
    final store = context.read<PosLocalStore>();
    await store.saveReceiving(
      Receiving(
        supplierId: _supplierId,
        supplierName: _supplierName,
        date: DateTime.now(),
        invoiceNo: _invoiceController.text.trim(),
        total: _total,
        receivedBy: store.profile.ownerName,
        lines: [
          for (final line in _lines)
            ReceivingLine(
              productName: line.productName,
              quantity: line.quantity,
              unitCost: line.unitCost,
              sellingPrice: line.sellingPrice,
            ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    showMarketNotice(
      context,
      title: _t('Goods received', 'Bidhaa zimepokelewa'),
      message: _t(
          'Stock and purchase cost updated', 'Hifadhi na gharama zimesasishwa'),
    );
    Navigator.of(context).maybePop();
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.index,
    required this.line,
    required this.isSwahili,
    required this.onChanged,
    required this.onDelete,
  });

  final int index;
  final _DraftLine line;
  final bool isSwahili;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final qtyController = TextEditingValue(text: line.quantity.toString());
    final costController =
        TextEditingValue(text: line.unitCost.toStringAsFixed(0));
    return MarketSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$index. ${line.productName}',
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 16),
                color: AppColors.textLight,
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: qtyController.text,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: isSwahili ? 'Idadi' : 'Quantity',
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      line.quantity = int.tryParse(value) ?? 0,
                  onFieldSubmitted: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: costController.text,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: isSwahili ? 'Gharama' : 'Unit cost',
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      line.unitCost = double.tryParse(value) ?? 0,
                  onFieldSubmitted: (_) => onChanged(),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'TZS ${line.total.toStringAsFixed(0)}',
              style: AppTypography.helperText.copyWith(
                  color: AppColors.textMuted, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddLineSheet extends StatefulWidget {
  const _AddLineSheet({required this.isSwahili});

  final bool isSwahili;

  @override
  State<_AddLineSheet> createState() => _AddLineSheetState();
}

class _AddLineSheetState extends State<_AddLineSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController(text: '1');
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String _t(String en, String swahili) => widget.isSwahili ? swahili : en;

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _costController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('Add item', 'Ongeza bidhaa'),
            style: AppTypography.h3.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.md),
          MarketFormField(
            label: _t('Product name', 'Jina la bidhaa'),
            hintText: _t(
                'Type or pick from stock', 'Andika au chagua kwenye hifadhi'),
            controller: _nameController,
            suffixIcon: IconButton(
              icon: const Icon(Icons.list_rounded, size: 18),
              onPressed: () => _pickFromStock(store),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: MarketFormField(
                  label: _t('Quantity', 'Idadi'),
                  hintText: '1',
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MarketFormField(
                  label: _t('Unit cost', 'Gharama'),
                  hintText: '0',
                  controller: _costController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          MarketFormField(
            label: _t('Selling price (optional)', 'Bei ya kuuza (si lazima)'),
            hintText: '0',
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: AppSpacing.lg),
          MarketButton(
            label: _t('Add to receiving', 'Ongeza kwenye upokeaji'),
            icon: Icons.check_rounded,
            onTap: () {
              final name = _nameController.text.trim();
              final quantity = int.tryParse(_qtyController.text.trim()) ?? 0;
              if (name.isEmpty || quantity <= 0) return;
              Navigator.of(context).pop(
                _DraftLine(
                  productName: name,
                  quantity: quantity,
                  unitCost: double.tryParse(_costController.text.trim()) ?? 0,
                  sellingPrice:
                      double.tryParse(_priceController.text.trim()) ?? 0,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromStock(PosLocalStore store) async {
    final items = store.inventory;
    if (items.isEmpty) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
              child: Text(
                _t('Stock items', 'Bidhaa za hifadhi'),
                style: AppTypography.h3.copyWith(fontSize: 16),
              ),
            ),
            for (final item in items)
              ListTile(
                dense: true,
                title: Text(item.name),
                subtitle: Text(
                  '${item.category} • TZS ${item.purchasePrice.toStringAsFixed(0)}',
                ),
                onTap: () => Navigator.of(context).pop(item.name),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _nameController.text = selected;
      if (_costController.text.trim().isEmpty) {
        final match = items.firstWhere(
          (item) => item.name == selected,
          orElse: () => items.first,
        );
        _costController.text = match.purchasePrice.toStringAsFixed(0);
        _priceController.text = match.sellingPrice.toStringAsFixed(0);
      }
    });
  }
}
