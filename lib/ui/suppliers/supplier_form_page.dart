import 'package:track_mauzo/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/supplier_model.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';

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
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

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
      body: ManagementViewport(
          maxWidth: 860,
          child: SafeArea(
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
                          child: Column(
                            children: [
                              MarketFormField(
                                label:
                                    _t('Supplier name', 'Jina la msambazaji'),
                                hintText: _t(
                                    'e.g. Coca Cola Tanzania', 'mf. Coca Cola'),
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
                                hintText: context.tr('supplier@example.com'),
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
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
          )),
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

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final isEdit = _isEdit;
    final successMsg = isEdit
        ? _t('Supplier updated successfully', 'Msambazaji amesasishwa kikamilifu')
        : _t('Supplier added successfully', 'Msambazaji ameongezwa kikamilifu');

    final saved = await store.saveSupplier(supplier);

    messenger.showSnackBar(
      SnackBar(
        content: Text(successMsg),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    nav.pop(saved);
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
    final messenger = ScaffoldMessenger.of(context);
    final deleteMsg = _t('Supplier deleted successfully', 'Msambazaji amefutwa kikamilifu');
    await context.read<PosLocalStore>().deleteSupplier(widget.supplier!.id!);
    messenger.showSnackBar(
      SnackBar(
        content: Text(deleteMsg),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).maybePop();
  }
}
