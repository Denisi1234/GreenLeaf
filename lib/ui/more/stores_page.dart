import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../../service/store_models.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'store_form_page.dart';
import 'widgets/store_kpi_metrics.dart';
import 'widgets/store_row_tile.dart';

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
                title: t('Stores & Branches', 'Maduka na Matawi'),
                subtitle: t(
                  'Manage retail outlets and switch active branch',
                  'Dhibiti matawi ya biashara na badili duka linalotumika',
                ),
                transparentBackButton: true,
                onBack: () => Navigator.of(context).maybePop(),
                actions: [
                  IconButton(
                    tooltip: t('Add store', 'Ongeza duka'),
                    onPressed: () => _openStoreForm(context),
                    icon: const Icon(Icons.add_business_outlined, color: AppColors.ink),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    // Operational KPI metrics
                    StoreKpiMetrics(
                      totalStores: stores.length,
                      activeStoreName: store.activeStoreName,
                      isSwahili: sw,
                    ),
                    const SizedBox(height: 16),

                    // Primary Add Action
                    MarketButton(
                      label: t('Add new branch / store', 'Ongeza duka au tawi jipya'),
                      icon: Icons.add_business_outlined,
                      radius: 0,
                      onTap: () => _openStoreForm(context),
                    ),
                    const SizedBox(height: 20),

                    // Store list header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            t('All retail locations', 'Matawi yote'),
                            style: AppTypography.sectionHeader.copyWith(color: AppColors.ink),
                          ),
                        ),
                        Text(
                          '${stores.length} ${t('stores', 'maduka')}',
                          style: AppTypography.helperText.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Stores list container
                    MarketSurfaceCard(
                      padding: EdgeInsets.zero,
                      radius: 0,
                      showShadow: false,
                      borderColor: AppColors.border,
                      child: Column(
                        children: [
                          for (var i = 0; i < stores.length; i++) ...[
                            StoreRowTile(
                              store: stores[i],
                              active: stores[i].id == activeId,
                              canDelete: stores[i].id != 'store-default' && stores.length > 1,
                              isSwahili: sw,
                              onEdit: () => _openStoreForm(context, stores[i]),
                            ),
                            if (i != stores.length - 1)
                              const Divider(height: 1, color: AppColors.divider),
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
      ),
    );
  }

  static void _openStoreForm(BuildContext context, [Store? existing]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StoreFormPage(store: existing),
      ),
    );
  }
}
