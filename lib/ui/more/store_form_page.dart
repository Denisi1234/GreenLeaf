import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/store_models.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';

/// Form page for creating or updating store/branch details.
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
                        padding: const EdgeInsets.all(18),
                        showShadow: false,
                        borderColor: AppColors.border,
                        radius: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('Outlet Information', 'Taarifa ya Tawi'),
                              style: AppTypography.label.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            MarketFormField(
                              label: _t('Store name', 'Jina la duka'),
                              hintText:
                                  _t('e.g. Main branch, Town outlet', 'mf. Tawi kuu, Duka la mjini'),
                              controller: _name,
                              radius: 0,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? _t('Enter store name', 'Weka jina la duka')
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            MarketFormField(
                              label: _t('Address / location', 'Anwani / eneo'),
                              hintText: _t('Street, city or physical location', 'Mtaa, jiji au eneo'),
                              controller: _address,
                              radius: 0,
                            ),
                            const SizedBox(height: 14),
                            MarketFormField(
                              label: _t('Contact details', 'Mawasiliano'),
                              hintText: _t('Phone number or email',
                                  'Namba ya simu au barua pepe'),
                              controller: _contact,
                              radius: 0,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
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
                        radius: 0,
                        onTap: _saving
                            ? null
                            : () => Navigator.of(context).maybePop(),
                        height: 48,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: MarketButton(
                        label: _saving
                            ? _t('Saving...', 'Inahifadhi...')
                            : _t('Save store', 'Hifadhi duka'),
                        icon: Icons.check_rounded,
                        variant: MarketButtonVariant.primary,
                        borderColor: null,
                        radius: 0,
                        height: 48,
                        onTap: _saving ? null : _save,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final pos = context.read<PosLocalStore>();
    final navigator = Navigator.of(context);
    try {
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
            ? _t('Store added successfully', 'Duka limeongezwa kikamilifu')
            : _t('Store updated successfully', 'Duka limesasishwa kikamilifu'),
        type: MarketNoticeType.success,
      );
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: _t('Stores', 'Maduka'),
        message: _t('Failed to save store', 'Imeshindwa kuhifadhi duka'),
        type: MarketNoticeType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
