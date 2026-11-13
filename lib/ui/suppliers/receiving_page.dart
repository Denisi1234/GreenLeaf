import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/supplier_model.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'suppliers_page.dart';

/// Goods received register: lists stock-in documents and opens receiving flow.
class ReceivingPage extends StatelessWidget {
  const ReceivingPage({super.key, this.presetSupplier});

  final Supplier? presetSupplier;

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
                  '${t('Total', 'Jumla')} ${_money(totalValue)} • ${receivings.length} ${t('records', 'rekodi')}',
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
              actions: [
                IconButton(
                  tooltip: t('New receiving', 'Upokeaji mpya'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          NewReceivingPage(presetSupplier: presetSupplier),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, color: AppColors.ink),
                ),
              ],
            ),
            Expanded(
              child: receivings.isEmpty
                  ? _EmptyState(
                      onNew: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              NewReceivingPage(presetSupplier: presetSupplier),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        _flatCard(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                          child: Column(
                            children: [
                              for (var i = 0; i < receivings.length; i++) ...[
                                _ReceivingRow(
                                  receiving: receivings[i],
                                  isSwahili: sw,
                                  onDelete: () =>
                                      _confirmDelete(context, receivings[i]),
                                ),
                                if (i != receivings.length - 1)
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

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
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

  Future<void> _confirmDelete(
      BuildContext context, Receiving receiving) async {
    if (receiving.id == null) return;
    final store = context.read<PosLocalStore>();
    final sw = store.languageCode == 'sw';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(sw ? 'Futa upokeaji?' : 'Delete receiving record?'),
        content: Text(
          sw
              ? 'Rekodi itaondolewa. Hifadhi iliyoongezwa haitarejeshwa kiotomatiki.'
              : 'The record will be removed. Stock added by this delivery will not be reversed automatically.',
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
    await store.deleteReceiving(receiving.id!);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final sw = context.read<PosLocalStore>().languageCode == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        ReceivingPage._flatCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('No goods received yet', 'Hakuna bidhaa zilizopokelewa bado'),
                style: AppTypography.bodyMain
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                t(
                  'Record supplier deliveries to increase stock quantities and update purchase costs.',
                  'Rekodi usambazaji ili kuongeza hifadhi na kusasisha gharama za ununuzi.',
                ),
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted, height: 1.45),
              ),
              const SizedBox(height: 16),
              MarketButton(
                label: t('New receiving', 'Upokeaji mpya'),
                icon: Icons.add_rounded,
                onTap: onNew,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceivingRow extends StatelessWidget {
  const _ReceivingRow({
    required this.receiving,
    required this.isSwahili,
    required this.onDelete,
  });

  final Receiving receiving;
  final bool isSwahili;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final supplier = receiving.supplierName.isEmpty
        ? (isSwahili ? 'Msambazaji hajulikani' : 'Unknown supplier')
        : receiving.supplierName;
    final date = receiving.date.toLocal();
    final stamp =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final meta = <String>[
      stamp,
      '${receiving.itemCount} ${isSwahili ? 'vipande' : 'units'}',
      if (receiving.invoiceNo.trim().isNotEmpty) receiving.invoiceNo.trim(),
    ].join(' • ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier,
                      style: AppTypography.bodyMain
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ReceivingPage._money(receiving.total),
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onDelete,
                    child: Text(
                      isSwahili ? 'Futa' : 'Delete',
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (receiving.lines.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final line in receiving.lines.take(4))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${line.quantity} × ${line.productName} — ${ReceivingPage._money(line.unitCost)}',
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textBody),
                ),
              ),
            if (receiving.lines.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+${receiving.lines.length - 4} ${isSwahili ? 'bidhaa zaidi' : 'more items'}',
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                ),
              ),
          ],
        ],
      ),
    );
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
  int get _units => _lines.fold<int>(0, (sum, line) => sum + line.quantity);

  @override
  Widget build(BuildContext context) {
    final supplierName = _supplier?.name ?? '';
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: _t('New receiving', 'Upokeaji mpya'),
              subtitle: supplierName.isEmpty
                  ? _t('Record supplier delivery and increase stock',
                      'Rekodi usambazaji na ongeza hifadhi')
                  : supplierName,
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _deliveryDetailsCard(supplierName),
                  const SizedBox(height: 16),
                  _sectionHeader(
                    _t('Items received', 'Bidhaa zilizopokelewa'),
                    trailing:
                        '${_lines.length} ${_t('lines', 'mistari')} • $_units ${_t('units', 'vipande')}',
                  ),
                  const SizedBox(height: 8),
                  _linesCard(),
                  const SizedBox(height: 10),
                  MarketButton(
                    label: _t('Add item line', 'Ongeza mstari wa bidhaa'),
                    icon: Icons.add_rounded,
                    isPrimary: false,
                    onTap: _addLine,
                  ),
                  const SizedBox(height: 16),
                  _summaryCard(),
                  const SizedBox(height: 20),
                  MarketButton(
                    label: _saving
                        ? _t('Saving...', 'Inahifadhi...')
                        : _t('Save and add to stock', 'Hifadhi na ongeza hifadhini'),
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

  Widget _deliveryDetailsCard(String supplierName) {
    return ReceivingPage._flatCard(
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(
                  color: supplierName.isEmpty
                      ? AppColors.danger
                      : AppColors.border,
                ),
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 18,
                    color: supplierName.isEmpty
                        ? AppColors.danger
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      supplierName.isEmpty
                          ? _t('Select supplier (required)',
                              'Chagua msambazaji (inahitajika)')
                          : supplierName,
                      style: AppTypography.bodyMain.copyWith(
                        color: supplierName.isEmpty
                            ? AppColors.danger
                            : AppColors.ink,
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
      return ReceivingPage._flatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('No items added', 'Hakuna bidhaa zilizoongezwa'),
              style: AppTypography.bodyMain
                  .copyWith(fontWeight: FontWeight.w700),
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

    return ReceivingPage._flatCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(_t('Item', 'Bidhaa'),
                      style: AppTypography.helperText.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(_t('Qty', 'Idadi'),
                      textAlign: TextAlign.right,
                      style: AppTypography.helperText.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(_t('Unit cost', 'Gharama'),
                      textAlign: TextAlign.right,
                      style: AppTypography.helperText.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  flex: 3,
                  child: Text(_t('Total', 'Jumla'),
                      textAlign: TextAlign.right,
                      style: AppTypography.helperText.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),
          for (var i = 0; i < _lines.length; i++) ...[
            _DraftLineRow(
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
    return ReceivingPage._flatCard(
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
                  '${_lines.length} / $_units',
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
                  ReceivingPage._money(_total),
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
            style: AppTypography.helperText
                .copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w700),
          ),
      ],
    );
  }

  Future<void> _pickSupplier() async {
    final selected = await Navigator.of(context).push<Supplier>(
      MaterialPageRoute<Supplier>(
        builder: (_) => _SupplierPickerPage(isSwahili: _isSwahili),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _supplier = selected);
  }

  Future<void> _addLine() async {
    final draft = await Navigator.of(context).push<_DraftLine>(
      MaterialPageRoute<_DraftLine>(
        builder: (_) => _AddReceivingLinePage(isSwahili: _isSwahili),
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
    final validLines = _lines
        .where((line) => line.productName.trim().isNotEmpty && line.quantity > 0)
        .toList();
    if (validLines.isEmpty) {
      showMarketNotice(
        context,
        title: _t('Items required', 'Bidhaa zinahitajika'),
        message: _t('Add at least one valid item with quantity.',
            'Ongeza angalau bidhaa moja yenye idadi sahihi.'),
        type: MarketNoticeType.warning,
      );
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

class _DraftLineRow extends StatelessWidget {
  const _DraftLineRow({
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

  InputDecoration _cellDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$index. ${line.productName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              InkWell(
                onTap: onDelete,
                child: Text(
                  isSwahili ? 'Ondoa' : 'Remove',
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: line.quantity == 0 ? '' : line.quantity.toString(),
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _cellDecoration(isSwahili ? 'Idadi' : 'Qty'),
                  onChanged: (value) {
                    line.quantity = int.tryParse(value.trim()) ?? 0;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: line.unitCost <= 0 ? '' : line.unitCost.toStringAsFixed(0),
                  textAlign: TextAlign.right,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _cellDecoration('TSh'),
                  onChanged: (value) {
                    line.unitCost =
                        double.tryParse(value.trim().replaceAll(',', '')) ?? 0;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.divider),
                    color: AppColors.surfaceSecondary,
                  ),
                  alignment: Alignment.centerRight,
                  child: Text(
                    ReceivingPage._money(line.total),
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color:
                          line.total > 0 ? AppColors.success : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full-page supplier picker (replaces modal).
class _SupplierPickerPage extends StatelessWidget {
  const _SupplierPickerPage({required this.isSwahili});
  final bool isSwahili;

  Future<void> _createSupplier(BuildContext context) async {
    final created = await Navigator.of(context).push<Supplier>(
      MaterialPageRoute<Supplier>(
        builder: (_) => const SupplierFormPage(),
      ),
    );
    if (created == null || !context.mounted) return;
    Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final suppliers = store.suppliers;
    String t(String en, String swahili) => isSwahili ? swahili : en;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: t('Select supplier', 'Chagua msambazaji'),
              subtitle: t('Choose who delivered these goods',
                  'Chagua aliyesambaza bidhaa hizi'),
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
              actions: [
                IconButton(
                  tooltip: t('Add supplier', 'Ongeza msambazaji'),
                  onPressed: () => _createSupplier(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded,
                      color: AppColors.ink),
                ),
              ],
            ),
            Expanded(
              child: suppliers.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        ReceivingPage._flatCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('No suppliers found', 'Hakuna wasambazaji'),
                                style: AppTypography.bodyMain
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t('Create a supplier to continue with goods received.',
                                    'Unda msambazaji ili kuendelea na upokeaji wa bidhaa.'),
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted, height: 1.45),
                              ),
                              const SizedBox(height: 14),
                              MarketButton(
                                label: t('Add supplier', 'Ongeza msambazaji'),
                                icon: Icons.add_rounded,
                                onTap: () => _createSupplier(context),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        MarketButton(
                          label: t('New supplier', 'Msambazaji mpya'),
                          icon: Icons.person_add_alt_1_rounded,
                          isPrimary: false,
                          onTap: () => _createSupplier(context),
                        ),
                        const SizedBox(height: 12),
                        ReceivingPage._flatCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              for (var i = 0; i < suppliers.length; i++) ...[
                                InkWell(
                                  onTap: () =>
                                      Navigator.of(context).pop(suppliers[i]),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 14, 16, 14),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 36,
                                          color: store.supplierBalance(
                                                      suppliers[i].id ?? 0) >
                                                  0
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
                                                suppliers[i].name,
                                                style: AppTypography.bodyMain
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700),
                                              ),
                                              if (suppliers[i]
                                                      .phone
                                                      .trim()
                                                      .isNotEmpty ||
                                                  suppliers[i]
                                                      .email
                                                      .trim()
                                                      .isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                      top: 2),
                                                  child: Text(
                                                    [
                                                      if (suppliers[i]
                                                          .phone
                                                          .trim()
                                                          .isNotEmpty)
                                                        suppliers[i]
                                                            .phone
                                                            .trim(),
                                                      if (suppliers[i]
                                                          .email
                                                          .trim()
                                                          .isNotEmpty)
                                                        suppliers[i]
                                                            .email
                                                            .trim(),
                                                    ].join(' • '),
                                                    style: AppTypography
                                                        .helperText
                                                        .copyWith(
                                                            color: AppColors
                                                                .textMuted),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                            Icons.chevron_right_rounded,
                                            color: AppColors.textLight,
                                            size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                                if (i != suppliers.length - 1)
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
}

/// Full-page add receiving line (replaces modal).
class _AddReceivingLinePage extends StatefulWidget {
  const _AddReceivingLinePage({required this.isSwahili});
  final bool isSwahili;

  @override
  State<_AddReceivingLinePage> createState() => _AddReceivingLinePageState();
}

class _AddReceivingLinePageState extends State<_AddReceivingLinePage> {
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
        builder: (_) => _StockPickerPage(isSwahili: widget.isSwahili),
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
      _DraftLine(
        productName: name,
        quantity: qty,
        unitCost:
            double.tryParse(_costController.text.trim().replaceAll(',', '')) ?? 0,
        sellingPrice:
            double.tryParse(_priceController.text.trim().replaceAll(',', '')) ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  ReceivingPage._flatCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarketFormField(
                          label: _t('Product name', 'Jina la bidhaa'),
                          hintText:
                              _t('Enter or pick product', 'Weka au chagua bidhaa'),
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
                  ReceivingPage._flatCard(
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
                                label: _t('Quantity received', 'Idadi iliyopokelewa'),
                                hintText: '1',
                                controller: _qtyController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: MarketFormField(
                                label: _t('Unit cost (TSh)', 'Gharama ya kipande (TSh)'),
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
                  ReceivingPage._flatCard(
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
                          ReceivingPage._money(_lineTotal),
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
      ),
    );
  }
}

/// Full-page stock picker (replaces modal).
class _StockPickerPage extends StatelessWidget {
  const _StockPickerPage({required this.isSwahili});
  final bool isSwahili;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final items = store.inventory;
    String t(String en, String swahili) => isSwahili ? swahili : en;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
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
                        ReceivingPage._flatCard(
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        ReceivingPage._flatCard(
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
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: AppColors.ink),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${items[i].category} • ${t('Cost', 'Gharama')} ${ReceivingPage._money(items[i].purchasePrice)}',
                                                style: AppTypography.helperText
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
                                                color: items[i].stockCount <= 0
                                                    ? AppColors.danger
                                                    : AppColors.success,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            Text(
                                              t('in stock', 'hifadhini'),
                                              style: AppTypography.helperText
                                                  .copyWith(
                                                      color:
                                                          AppColors.textMuted),
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
      ),
    );
  }
}
