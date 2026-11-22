import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'widgets/accounting_common_widgets.dart';

class AccountFormPage extends StatefulWidget {
  const AccountFormPage({super.key, this.account});

  final Account? account;

  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late AccountType _type;

  bool get _isSwahili =>
      context.read<PosLocalStore>().languageCode.trim().toLowerCase() == 'sw';

  String _t(String en, String swahili) => _isSwahili ? swahili : en;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _code = TextEditingController(text: account?.code ?? '');
    _name = TextEditingController(text: account?.name ?? '');
    _balance = TextEditingController(
      text: account == null ? '' : account.openingBalance.toStringAsFixed(0),
    );
    _type = account?.type ?? AccountType.asset;
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _balance.dispose();
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
                title: widget.account == null
                    ? _t('Add account', 'Ongeza akaunti')
                    : _t('Edit account', 'Badilisha akaunti'),
                transparentBackButton: true,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      LedgerCard(
                        child: Column(
                          children: [
                            MarketFormField(
                              label: _t('Code', 'Msimbo'),
                              hintText: '1000',
                              controller: _code,
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? _t('Enter a code', 'Weka msimbo')
                                      : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            MarketFormField(
                              label: _t('Name', 'Jina'),
                              hintText: _t('Cash on hand', 'Pesa taslimu'),
                              controller: _name,
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                      ? _t('Enter a name', 'Weka jina')
                                      : null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            DropdownButtonFormField<AccountType>(
                              initialValue: _type,
                              decoration: InputDecoration(
                                labelText: _t('Type', 'Aina'),
                                border: const OutlineInputBorder(
                                  borderRadius: AppCorners.control,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: AppCorners.control,
                                  borderSide:
                                      BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: AppCorners.control,
                                  borderSide: BorderSide(
                                      color: AppColors.primary, width: 1.4),
                                ),
                              ),
                              items: [
                                for (final type in AccountType.values)
                                  DropdownMenuItem(
                                    value: type,
                                    child: Text(type.localized(_isSwahili)),
                                  ),
                              ],
                              onChanged: (value) => setState(
                                  () => _type = value ?? AccountType.asset),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            MarketFormField(
                              label: _t('Opening balance (TZS)',
                                  'Mizania ya kuanzia (TZS)'),
                              hintText: '0',
                              controller: _balance,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ],
                        ),
                      ),
                      if (widget.account != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        MarketButton(
                          label: _t('Delete account', 'Futa akaunti'),
                          icon: Icons.delete_outline_rounded,
                          color: AppColors.kpiDangerBg,
                          foregroundColor: AppColors.kpiDanger,
                          borderColor: null,
                          onTap: () async {
                            final store = context.read<PosLocalStore>();
                            final navigator = Navigator.of(context);
                            final deletedName = widget.account!.name;
                            await store.deleteAccount(widget.account!.id!);
                            if (!context.mounted) return;
                            showMarketNotice(
                              context,
                              title: _t('Account Deleted', 'Akaunti Imefutwa'),
                              message: _t(
                                '$deletedName was removed.',
                                '$deletedName imeondolewa.',
                              ),
                              type: MarketNoticeType.success,
                            );
                            navigator.maybePop();
                          },
                        ),
                      ],
                    ],
                  ),
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
                        label: _t('Save account', 'Hifadhi akaunti'),
                        icon: Icons.check_rounded,
                        variant: MarketButtonVariant.primary,
                        borderColor: null,
                        radius: AppRadius.input,
                        height: 48,
                        onTap: () {
                          if (!_formKey.currentState!.validate()) return;
                          Navigator.of(context).pop(
                            Account(
                              id: widget.account?.id,
                              code: _code.text.trim(),
                              name: _name.text.trim(),
                              type: _type,
                              openingBalance:
                                  double.tryParse(_balance.text.trim()) ?? 0,
                            ),
                          );
                        },
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
}
