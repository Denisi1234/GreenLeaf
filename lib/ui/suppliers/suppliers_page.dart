import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/supplier_model.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'receiving_page.dart';

/// Supplier directory with payables and a shortcut to goods received.
class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;

    final suppliers = store.suppliers;
    final totalPayable = suppliers.fold<double>(
      0,
      (sum, supplier) => sum + store.supplierBalance(supplier.id ?? 0),
    );

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: t('Suppliers', 'Wasambazaji'),
                value: '${suppliers.length}',
                icon: Icons.local_shipping_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: t('Goods received', 'Bidhaa zilizopokelewa'),
                value: '${store.receivings.length}',
                icon: Icons.move_to_inbox_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatTile(
          label: t('Total payable', 'Jumla ya madeni'),
          value: 'TZS ${totalPayable.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet_outlined,
          danger: totalPayable > 0,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: MarketButton(
                label: t('Add supplier', 'Ongeza msambazaji'),
                icon: Icons.add_rounded,
                onTap: () => _openForm(context),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
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
        const SizedBox(height: AppSpacing.lg),
        if (suppliers.isEmpty)
          MarketSurfaceCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.local_shipping_outlined,
                    size: 34, color: AppColors.textLight),
                const SizedBox(height: 10),
                Text(
                  t('No suppliers yet', 'Hakuna wasambazaji bado'),
                  style: AppTypography.h3.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  t(
                    'Add suppliers to record purchases and goods received.',
                    'Ongeza wasambazaji ili kurekodi manunuzi na bidhaa '
                        'zinazopokelewa.',
                  ),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          )
        else
          for (final supplier in suppliers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MarketSurfaceCard(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            supplier.name,
                            style: AppTypography.bodyMain
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          'TZS ${store.supplierBalance(supplier.id ?? 0).toStringAsFixed(0)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (supplier.phone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          supplier.phone,
                          style: AppTypography.helperText
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    if (supplier.address.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          supplier.address,
                          style: AppTypography.helperText
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _openForm(context, supplier),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: Text(t('Edit', 'Badilisha')),
                        ),
                        TextButton.icon(
                          onPressed: () => _receiveFor(context, supplier),
                          icon:
                              const Icon(Icons.move_to_inbox_rounded, size: 16),
                          label: Text(t('Receive', 'Pokea')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );

    if (embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            MarketPageHeader(
              title: t('Suppliers', 'Wasambazaji'),
              subtitle: t('Purchases and goods received', 'Manunuzi na bidhaa'),
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

  void _receiveFor(BuildContext context, Supplier supplier) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReceivingPage(presetSupplier: supplier),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.danger = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: danger ? AppColors.dangerLight : AppColors.surfaceHover,
              borderRadius: BorderRadius.circular(AppRadius.standard),
            ),
            child: Icon(
              icon,
              size: 18,
              color: danger ? AppColors.danger : AppColors.ink,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.helperText
                      .copyWith(color: AppColors.textMuted),
                ),
                Text(
                  value,
                  style: AppTypography.bodyMain
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
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
      text: supplier == null ? '' : supplier.openingBalance.toStringAsFixed(0),
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
                  ? _t('Edit supplier', 'Badilisha msambazaji')
                  : _t('Add supplier', 'Ongeza msambazaji'),
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
                            label: _t('Supplier name', 'Jina la msambazaji'),
                            hintText:
                                _t('e.g. Coca Cola Tanzania', 'mf. Coca Cola'),
                            controller: _name,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? _t('Enter a name', 'Weka jina')
                                    : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Phone', 'Simu'),
                            hintText: '0700 000 000',
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Email', 'Barua pepe'),
                            hintText: 'supplier@example.com',
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Address', 'Anwani'),
                            hintText: _t('Dar es Salaam', 'Dar es Salaam'),
                            controller: _address,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Opening balance (TZS)',
                                'Denim ya kuanzia (TZS)'),
                            hintText: '0',
                            controller: _balance,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          MarketFormField(
                            label: _t('Notes', 'Maelezo'),
                            hintText: _t('Payment terms, contacts...',
                                'Masharti ya malipo...'),
                            controller: _notes,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MarketButton(
                      label: _isEdit
                          ? _t('Save changes', 'Hifadhi mabadiliko')
                          : _t('Add supplier', 'Ongeza msambazaji'),
                      icon: Icons.check_rounded,
                      onTap: _save,
                    ),
                    if (_isEdit) ...[
                      const SizedBox(height: AppSpacing.md),
                      MarketButton(
                        label: _t('Delete supplier', 'Futa msambazaji'),
                        icon: Icons.delete_outline_rounded,
                        isPrimary: false,
                        color: AppColors.dangerLight,
                        foregroundColor: AppColors.danger,
                        borderColor: AppColors.dangerLight,
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
    await store.saveSupplier(supplier);
    if (!mounted) return;
    showMarketNotice(
      context,
      title: _t('Suppliers', 'Wasambazaji'),
      message: _t('Supplier saved', 'Msambazaji amehifadhiwa'),
    );
    Navigator.of(context).maybePop();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(_t('Delete supplier?', 'Futa msambazaji?')),
        content: Text(
          _t(
            'Goods received records are kept for your reports.',
            'Rekodi za bidhaa zilizopokelewa zitabaki kwa ripoti.',
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
