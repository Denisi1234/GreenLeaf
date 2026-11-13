import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/supplier_model.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'receiving_page.dart';

/// Supplier directory with payables, balances, and goods-received access.
class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;

    final suppliers = store.suppliers;
    final filtered = _query.isEmpty
        ? suppliers
        : suppliers.where((s) {
            final q = _query.toLowerCase();
            return s.name.toLowerCase().contains(q) ||
                s.phone.toLowerCase().contains(q) ||
                s.email.toLowerCase().contains(q) ||
                s.address.toLowerCase().contains(q);
          }).toList();

    final totalPayable = suppliers.fold<double>(
      0,
      (sum, s) => sum + store.supplierBalance(s.id ?? 0),
    );
    final owingCount = suppliers
        .where((s) => store.supplierBalance(s.id ?? 0) > 0)
        .length;
    final totalReceived = store.receivings.fold<double>(
      0,
      (sum, r) => sum + r.total,
    );

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _sharpCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('Total payable', 'Jumla ya deni'),
                style:
                    AppTypography.label.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 4),
              Text(
                _money(totalPayable),
                style: AppTypography.h1.copyWith(
                  fontSize: 30,
                  color:
                      totalPayable > 0 ? AppColors.danger : AppColors.success,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                totalPayable > 0
                    ? t(
                        '$owingCount supplier${owingCount == 1 ? '' : 's'} with outstanding balance',
                        'Wasambazaji $owingCount wana deni lililosalia',
                      )
                    : t('All supplier balances are clear',
                        'Madeni yote ya wasambazaji yamesafishwa'),
                style: AppTypography.bodySmall.copyWith(
                  color: totalPayable > 0
                      ? AppColors.danger
                      : AppColors.success,
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
                label: t('Suppliers', 'Wasambazaji'),
                value: '${suppliers.length}',
                valueColor: AppColors.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                label: t('Received records', 'Rekodi za upokeaji'),
                value: '${store.receivings.length}',
                valueColor: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _metricCard(
          label: t('Total received value', 'Jumla ya thamani iliyopokelewa'),
          value: _money(totalReceived),
          valueColor:
              totalReceived > 0 ? AppColors.success : AppColors.textMuted,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MarketButton(
                label: t('Add supplier', 'Ongeza msambazaji'),
                icon: Icons.add_rounded,
                onTap: () => _openForm(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MarketButton(
                label: t('Receive goods', 'Pokea bidhaa'),
                icon: Icons.move_to_inbox_rounded,
                isPrimary: false,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const ReceivingPage(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _sectionHeader(t('Supplier list', 'Orodha ya wasambazaji')),
        const SizedBox(height: 8),
        _sharpCard(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: MarketSearchField(
            controller: _searchController,
            hintText: t('Search by name, phone, email, address...',
                'Tafuta kwa jina, simu, barua pepe, anwani...'),
            onChanged: (value) => setState(() => _query = value.trim()),
            onClear: () {
              _searchController.clear();
              setState(() => _query = '');
            },
            showShadow: false,
            backgroundColor: AppColors.surface,
          ),
        ),
        const SizedBox(height: 12),
        if (suppliers.isEmpty)
          _sharpCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('No suppliers yet', 'Hakuna wasambazaji bado'),
                  style: AppTypography.bodyMain
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  t(
                    'Add suppliers to record purchases, track payables, and receive goods into stock.',
                    'Ongeza wasambazaji kurekodi manunuzi, kufuatilia madeni, na kupokea bidhaa kwenye hifadhi.',
                  ),
                  style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted, height: 1.45),
                ),
              ],
            ),
          )
        else if (filtered.isEmpty)
          _sharpCard(
            child: Text(
              t('No suppliers match your search.',
                  'Hakuna msambazaji anayelingana na utafutaji.'),
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textMuted),
            ),
          )
        else
          _sharpCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < filtered.length; i++) ...[
                  _SupplierRow(
                    supplier: filtered[i],
                    balance: store.supplierBalance(filtered[i].id ?? 0),
                    isSwahili: sw,
                    onTap: () => _openDetail(context, filtered[i]),
                    onReceive: () => _receiveFor(context, filtered[i]),
                  ),
                  if (i != filtered.length - 1)
                    const Divider(height: 1, color: AppColors.divider),
                ],
              ],
            ),
          ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: t('Suppliers', 'Wasambazaji'),
              subtitle:
                  t('Purchases, payables, and goods received',
                      'Manunuzi, madeni, na bidhaa zilizopokelewa'),
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, [Supplier? supplier]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SupplierFormPage(supplier: supplier),
      ),
    );
  }

  void _openDetail(BuildContext context, Supplier supplier) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SupplierDetailPage(supplierId: supplier.id),
      ),
    );
  }

  void _receiveFor(BuildContext context, Supplier supplier) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReceivingPage(presetSupplier: supplier),
      ),
    );
  }

  static Widget _sectionHeader(String text) {
    return Text(
      text,
      style: AppTypography.sectionHeader.copyWith(color: AppColors.ink),
    );
  }

  static Widget _sharpCard({
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

  static Widget _metricCard({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return _sharpCard(
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
              fontSize: 18,
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static String _money(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }
}

class _SupplierRow extends StatelessWidget {
  const _SupplierRow({
    required this.supplier,
    required this.balance,
    required this.isSwahili,
    required this.onTap,
    required this.onReceive,
  });

  final Supplier supplier;
  final double balance;
  final bool isSwahili;
  final VoidCallback onTap;
  final VoidCallback onReceive;

  @override
  Widget build(BuildContext context) {
    final contact = <String>[
      if (supplier.phone.trim().isNotEmpty) supplier.phone.trim(),
      if (supplier.email.trim().isNotEmpty) supplier.email.trim(),
    ].join(' • ');
    final hasBalance = balance > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 42,
              color: hasBalance ? AppColors.danger : AppColors.success,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    style: AppTypography.bodyMain
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (contact.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      contact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                  if (supplier.address.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      supplier.address.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textLight),
                    ),
                  ],
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: onReceive,
                    child: Text(
                      isSwahili ? 'Pokea bidhaa' : 'Receive goods',
                      style: AppTypography.helperText.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isSwahili ? 'Deni' : 'Payable',
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  _SuppliersPageState._money(balance),
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: hasBalance ? AppColors.danger : AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Supplier detail: profile, balance, and receiving history.
class SupplierDetailPage extends StatelessWidget {
  const SupplierDetailPage({super.key, required this.supplierId});

  final int? supplierId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;

    Supplier? supplier;
    if (supplierId != null) {
      for (final s in store.suppliers) {
        if (s.id == supplierId) {
          supplier = s;
          break;
        }
      }
    }

    if (supplier == null) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              MarketPageHeader(
                title: t('Supplier', 'Msambazaji'),
                transparentBackButton: true,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SuppliersPageState._sharpCard(
                      child: Text(
                        t('Supplier not found.', 'Msambazaji hajapatikana.'),
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
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

    final s = supplier;
    final balance = store.supplierBalance(s.id ?? 0);
    final history = store.receivings
        .where((r) => r.supplierId == s.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final receivedTotal =
        history.fold<double>(0, (sum, r) => sum + r.total);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: s.name,
              subtitle: t('Supplier details', 'Taarifa za msambazaji'),
              transparentBackButton: true,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _SuppliersPageState._sharpCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('Current payable', 'Deni la sasa'),
                            style: AppTypography.label
                                .copyWith(color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(
                          _SuppliersPageState._money(balance),
                          style: AppTypography.h1.copyWith(
                            fontSize: 28,
                            color: balance > 0
                                ? AppColors.danger
                                : AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _kv(
                                t('Opening balance', 'Deni la kuanzia'),
                                _SuppliersPageState._money(
                                    s.openingBalance),
                                s.openingBalance > 0
                                    ? AppColors.danger
                                    : AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _kv(
                                t('Goods received', 'Zilizopokelewa'),
                                _SuppliersPageState._money(receivedTotal),
                                receivedTotal > 0
                                    ? AppColors.success
                                    : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _kv(
                          t('Receiving records', 'Rekodi za upokeaji'),
                          '${history.length}',
                          AppColors.ink,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SuppliersPageState._sharpCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _info(t('Phone', 'Simu'),
                            s.phone.trim().isEmpty ? '—' : s.phone.trim()),
                        _info(t('Email', 'Barua pepe'),
                            s.email.trim().isEmpty ? '—' : s.email.trim()),
                        _info(t('Address', 'Anwani'),
                            s.address.trim().isEmpty ? '—' : s.address.trim()),
                        if (s.notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 8),
                          Text(t('Notes', 'Maelezo'),
                              style: AppTypography.label
                                  .copyWith(color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            s.notes.trim(),
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textBody, height: 1.45),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: MarketButton(
                          label: t('Edit', 'Hariri'),
                          icon: Icons.edit_outlined,
                          isPrimary: false,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  SupplierFormPage(supplier: s),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MarketButton(
                          label: t('Receive goods', 'Pokea bidhaa'),
                          icon: Icons.move_to_inbox_rounded,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  ReceivingPage(presetSupplier: s),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    t('Receiving history', 'Historia ya upokeaji'),
                    style: AppTypography.sectionHeader
                        .copyWith(color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  if (history.isEmpty)
                    _SuppliersPageState._sharpCard(
                      child: Text(
                        t('No goods received from this supplier yet.',
                            'Hakuna bidhaa zilizopokelewa kutoka kwa msambazaji huyu bado.'),
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    )
                  else
                    _SuppliersPageState._sharpCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (var i = 0; i < history.length; i++) ...[
                            _HistoryRow(
                                receiving: history[i], isSwahili: sw),
                            if (i != history.length - 1)
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

  static Widget _kv(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.helperText
                .copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  static Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.bodySmall.copyWith(
                    color: AppColors.ink, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.receiving, required this.isSwahili});
  final Receiving receiving;
  final bool isSwahili;

  @override
  Widget build(BuildContext context) {
    final d = receiving.date.toLocal();
    final stamp =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receiving.invoiceNo.trim().isEmpty
                      ? (isSwahili ? 'Upokeaji' : 'Receiving')
                      : receiving.invoiceNo.trim(),
                  style: AppTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '$stamp • ${receiving.itemCount} ${isSwahili ? 'vipande' : 'units'} • ${receiving.lines.length} ${isSwahili ? 'bidhaa' : 'items'}',
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            _SuppliersPageState._money(receiving.total),
            style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

/// Create or edit a supplier.
class SupplierFormPage extends StatefulWidget {
  const SupplierFormPage({super.key, this.supplier});

  final Supplier? supplier;

  @override
  State<SupplierFormPage> createState() => _SupplierFormPageState();
}

class _SupplierFormPageState extends State<SupplierFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _balance;
  late final TextEditingController _notes;

  bool get _isEdit => widget.supplier != null;

  bool get _isSwahili =>
      context.watch<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void initState() {
    super.initState();
    final supplier = widget.supplier;
    _name = TextEditingController(text: supplier?.name ?? '');
    _phone = TextEditingController(text: supplier?.phone ?? '');
    _email = TextEditingController(text: supplier?.email ?? '');
    _address = TextEditingController(text: supplier?.address ?? '');
    _balance = TextEditingController(
      text: supplier == null || supplier.openingBalance == 0
          ? ''
          : supplier.openingBalance.toStringAsFixed(0),
    );
    _notes = TextEditingController(text: supplier?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _balance.dispose();
    _notes.dispose();
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
              title: _isEdit
                  ? _t('Edit supplier', 'Hariri msambazaji')
                  : _t('Add supplier', 'Ongeza msambazaji'),
              subtitle: _t('Supplier details and payable balance',
                  'Taarifa za msambazaji na deni'),
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
                      showShadow: false,
                      borderColor: AppColors.border,
                      radius: 0,
                      child: Column(
                        children: [
                          MarketFormField(
                            label: _t('Supplier name', 'Jina la msambazaji'),
                            hintText:
                                _t('e.g. Coca Cola Tanzania', 'mf. Coca Cola'),
                            controller: _name,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? _t('Enter a name', 'Weka jina')
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          MarketFormField(
                            label: _t('Phone', 'Simu'),
                            hintText: '0700 000 000',
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          MarketFormField(
                            label: _t('Email', 'Barua pepe'),
                            hintText: 'supplier@example.com',
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          MarketFormField(
                            label: _t('Address', 'Anwani'),
                            hintText: _t('City, area', 'Mji, eneo'),
                            controller: _address,
                          ),
                          const SizedBox(height: 14),
                          MarketFormField(
                            label: _t('Opening balance payable (TSh)',
                                'Deni la kuanzia (TSh)'),
                            hintText: '0',
                            controller: _balance,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                          const SizedBox(height: 14),
                          MarketFormField(
                            label: _t('Notes', 'Maelezo'),
                            hintText: _t('Payment terms, contact person...',
                                'Masharti ya malipo, mtu wa mawasiliano...'),
                            controller: _notes,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    MarketButton(
                      label: _isEdit
                          ? _t('Save changes', 'Hifadhi mabadiliko')
                          : _t('Save supplier', 'Hifadhi msambazaji'),
                      icon: Icons.check_rounded,
                      onTap: _save,
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: 12),
                      MarketButton(
                        label: _t('Delete supplier', 'Futa msambazaji'),
                        icon: Icons.delete_outline_rounded,
                        isPrimary: false,
                        foregroundColor: AppColors.danger,
                        borderColor: AppColors.border,
                        color: AppColors.surface,
                        onTap: _confirmDelete,
                      ),
                    ],
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
    final balance = double.tryParse(_balance.text.trim()) ?? 0;
    final supplier = Supplier(
      id: widget.supplier?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      address: _address.text.trim(),
      openingBalance: balance,
      notes: _notes.text.trim(),
    );
    final saved = await store.saveSupplier(supplier);
    if (!mounted) return;
    showMarketNotice(
      context,
      title: _t('Suppliers', 'Wasambazaji'),
      message: _isEdit
          ? _t('Supplier updated', 'Msambazaji amesasishwa')
          : _t('Supplier created', 'Msambazaji ameongezwa'),
      type: MarketNoticeType.success,
    );
    Navigator.of(context).pop(saved);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(_t('Delete supplier?', 'Futa msambazaji?')),
        content: Text(
          _t(
            'Supplier will be removed. Goods received records remain in reports.',
            'Msambazaji ataondolewa. Rekodi za upokeaji zitabaki kwenye ripoti.',
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
    if (confirmed != true || !mounted) return;
    await context.read<PosLocalStore>().deleteSupplier(widget.supplier!.id!);
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }
}
