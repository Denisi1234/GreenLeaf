import '../widgets/workspace_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/store_models.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class StoresPage extends StatelessWidget {
  const StoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;
    final stores = store.stores;
    final activeId = store.activeStoreId;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: t('Stores', 'Maduka'),
                  subtitle: t(
                    'Manage outlets and switch active store',
                    'Dhibiti matawi na badili duka linalotumika',
                  ),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                  actions: [
                    IconButton(
                      tooltip: t('Add store', 'Ongeza duka'),
                      onPressed: () => _openStoreForm(context),
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
                              t('Active store', 'Duka linalotumika'),
                              style: AppTypography.label
                                  .copyWith(color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              store.activeStoreName,
                              style: AppTypography.h1.copyWith(
                                fontSize: 24,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t(
                                'Sales, stock, customers and accounting are tracked per store. Reports can compare all stores.',
                                'Mauzo, hifadhi, wateja na uhasibu vinafuatiliwa kwa kila duka. Ripoti zinaweza kulinganisha maduka yote.',
                              ),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                height: 1.45,
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
                              label: t('Total stores', 'Jumla ya maduka'),
                              value: '${stores.length}',
                              valueColor: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              label:
                                  t('Multi-store reports', 'Ripoti za maduka'),
                              value: '23+',
                              valueColor: AppColors.primaryDeep,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      MarketButton(
                        label: t('Add store', 'Ongeza duka'),
                        icon: Icons.add_business_outlined,
                        onTap: () => _openStoreForm(context),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t('All stores', 'Maduka yote'),
                        style: AppTypography.sectionHeader
                            .copyWith(color: AppColors.ink),
                      ),
                      const SizedBox(height: 8),
                      _flatCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < stores.length; i++) ...[
                              _StoreRow(
                                store: stores[i],
                                active: stores[i].id == activeId,
                                canDelete: stores[i].id != 'store-default' &&
                                    stores.length > 1,
                                isSwahili: sw,
                              ),
                              if (i != stores.length - 1)
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

  static void _openStoreForm(BuildContext context, [Store? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StoreFormPage(store: existing),
      ),
    );
  }

  static Widget _flatCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return MarketSurfaceCard(
      padding: padding,
      showShadow: true,
      borderColor: const Color(0xFFD6E4F0),
      radius: 10,
      child: child,
    );
  }

  static Widget _metricCard({
    required String label,
    required String value,
    required Color valueColor,
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
            style: AppTypography.h3.copyWith(
              fontSize: 20,
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreRow extends StatelessWidget {
  const _StoreRow({
    required this.store,
    required this.active,
    required this.canDelete,
    required this.isSwahili,
  });

  final Store store;
  final bool active;
  final bool canDelete;
  final bool isSwahili;

  String _t(String en, String swahili) => isSwahili ? swahili : en;

  @override
  Widget build(BuildContext context) {
    final name = store.name.trim().isEmpty ? store.id : store.name.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 40,
                color: active ? AppColors.success : AppColors.border,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTypography.bodyMain.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (active)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.successLight,
                              border: Border.all(
                                  color:
                                      AppColors.success.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _t('Active', 'Inatumika'),
                              style: AppTypography.helperText.copyWith(
                                color: AppColors.successDeep,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (store.address.trim().isNotEmpty)
                          store.address.trim(),
                        if (store.contact.trim().isNotEmpty)
                          store.contact.trim(),
                        if (store.address.trim().isEmpty &&
                            store.contact.trim().isEmpty)
                          store.id,
                      ].join(' • '),
                      style: AppTypography.helperText
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                if (!active)
                  _action(
                    label: _t('Switch to this store', 'Tumia duka hili'),
                    color: AppColors.primaryDeep,
                    onTap: () => _switchStore(context),
                  ),
                _action(
                  label: _t('Edit', 'Hariri'),
                  color: AppColors.ink,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => StoreFormPage(store: store),
                    ),
                  ),
                ),
                if (canDelete && !active)
                  _action(
                    label: _t('Delete', 'Futa'),
                    color: AppColors.danger,
                    onTap: () => _confirmDelete(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: AppTypography.helperText.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _switchStore(BuildContext context) async {
    final pos = context.read<PosLocalStore>();
    await pos.switchStore(store.id);
    if (!context.mounted) return;
    showMarketNotice(
      context,
      title: _t('Stores', 'Maduka'),
      message: _t('Switched to ${store.name}', 'Umehamia ${store.name}'),
      type: MarketNoticeType.success,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final pos = context.read<PosLocalStore>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(_t('Delete store?', 'Futa duka?')),
        content: Text(
          _t(
            'Remove this store from the list. Its local data remains in the database but will no longer be selectable.',
            'Ondoa duka hili kwenye orodha. Data yake ya ndani itabaki lakini halitachaguliwa tena.',
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
    await pos.deleteStore(store.id);
  }
}

class StoreFormPage extends StatefulWidget {
  const StoreFormPage({super.key, this.store});
  final Store? store;

  @override
  State<StoreFormPage> createState() => _StoreFormPageState();
}

class _StoreFormPageState extends State<StoreFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _contact;
  bool _saving = false;

  bool get _isSwahili =>
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';
  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.store?.name ?? '');
    _address = TextEditingController(text: widget.store?.address ?? '');
    _contact = TextEditingController(text: widget.store?.contact ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.store != null;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 860,
          child: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: isEdit
                      ? _t('Edit store', 'Hariri duka')
                      : _t('Add store', 'Ongeza duka'),
                  subtitle:
                      _t('Store name and details', 'Jina na taarifa za duka'),
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
                          radius: AppRadius.standard,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MarketFormField(
                                label: _t('Store name', 'Jina la duka'),
                                hintText:
                                    _t('e.g. Main branch', 'mf. Tawi kuu'),
                                controller: _name,
                                validator: (v) => (v == null ||
                                        v.trim().isEmpty)
                                    ? _t(
                                        'Enter store name', 'Weka jina la duka')
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              MarketFormField(
                                label:
                                    _t('Address / location', 'Anwani / eneo'),
                                hintText: _t('Optional', 'Hiari'),
                                controller: _address,
                              ),
                              const SizedBox(height: 14),
                              MarketFormField(
                                label: _t('Contact', 'Mawasiliano'),
                                hintText: _t('Phone or email (optional)',
                                    'Simu au barua pepe (hiari)'),
                                controller: _contact,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        MarketButton(
                          label: _saving
                              ? _t('Saving...', 'Inahifadhi...')
                              : _t('Save store', 'Hifadhi duka'),
                          icon: Icons.check_rounded,
                          onTap: _saving ? null : _save,
                        ),
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
    setState(() => _saving = true);
    try {
      final pos = context.read<PosLocalStore>();
      if (widget.store == null) {
        await pos.createStore(
          name: _name.text.trim(),
          address: _address.text.trim(),
          contact: _contact.text.trim(),
        );
      } else {
        await pos.saveStore(
          widget.store!.copyWith(
            name: _name.text.trim(),
            address: _address.text.trim(),
            contact: _contact.text.trim(),
          ),
        );
      }
      if (!mounted) return;
      showMarketNotice(
        context,
        title: _t('Stores', 'Maduka'),
        message: widget.store == null
            ? _t('Store added', 'Duka limeongezwa')
            : _t('Store updated', 'Duka limesasishwa'),
        type: MarketNoticeType.success,
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
