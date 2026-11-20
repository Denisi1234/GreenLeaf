import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/supplier_model.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'supplier_form_page.dart';

/// Full-page supplier picker for receiving flow.
class SupplierPickerPage extends StatelessWidget {
  const SupplierPickerPage({super.key, required this.isSwahili});
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
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
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
                            MarketSurfaceCard(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t('No suppliers found',
                                        'Hakuna wasambazaji'),
                                    style: AppTypography.bodyMain
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t('Create a supplier to continue with goods received.',
                                        'Unda msambazaji ili kuendelea na upokeaji wa bidhaa.'),
                                    style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textMuted,
                                        height: 1.45),
                                  ),
                                  const SizedBox(height: 14),
                                  MarketButton(
                                    label:
                                        t('Add supplier', 'Ongeza msambazaji'),
                                    icon: Icons.add_rounded,
                                    onTap: () => _createSupplier(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                          children: [
                            MarketButton(
                              label: t('New supplier', 'Msambazaji mpya'),
                              icon: Icons.person_add_alt_1_rounded,
                              isPrimary: false,
                              onTap: () => _createSupplier(context),
                            ),
                            const SizedBox(height: 12),
                            MarketSurfaceCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < suppliers.length;
                                      i++) ...[
                                    InkWell(
                                      onTap: () => Navigator.of(context)
                                          .pop(suppliers[i]),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 14, 16, 14),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 36,
                                              color: store.supplierBalance(
                                                          suppliers[i].id ??
                                                              0) >
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
                                                    style: AppTypography
                                                        .bodyMain
                                                        .copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700),
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
                                                      padding:
                                                          const EdgeInsets.only(
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
          )),
    );
  }
}
