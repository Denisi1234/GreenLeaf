import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/accounting_model.dart';
import '../../service/pos_local_store.dart';
import '../../utils/currency_formatter.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'asset_form_page.dart';
import 'widgets/asset_row_tile.dart';
import 'widgets/fixed_assets_kpi_metrics.dart';

export 'asset_form_page.dart';

/// Fixed asset register with straight-line depreciation.
class FixedAssetsPage extends StatelessWidget {
  const FixedAssetsPage({super.key});

  static String formatMoney(double value) {
    final negative = value < 0;
    return '${negative ? '-' : ''}TSh ${formatCurrency(value.abs())}';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final sw = store.languageCode.trim().toLowerCase() == 'sw';
    String t(String en, String swahili) => sw ? swahili : en;

    final assets = store.fixedAssets;
    final totalCost = assets.fold<double>(0, (sum, a) => sum + a.cost);
    final totalDep =
        assets.fold<double>(0, (sum, a) => sum + a.accumulatedDepreciation());
    final totalNbv = assets.fold<double>(0, (sum, a) => sum + a.netBookValue());

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: t('Fixed assets', 'Mali za kudumu'),
                  subtitle: t('Register and track depreciation',
                      'Sajili na fuatilia uchakavu'),
                  transparentBackButton: true,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      FixedAssetsKpiMetrics(
                        totalNbv: totalNbv,
                        totalCost: totalCost,
                        totalDepreciation: totalDep,
                        assetCount: assets.length,
                        isSwahili: sw,
                      ),
                      const SizedBox(height: 16),
                      MarketButton(
                        label: t('Add asset', 'Ongeza mali'),
                        icon: Icons.add_rounded,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const AssetFormPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t('Asset register', 'Daftari la mali'),
                        style: AppTypography.sectionHeader
                            .copyWith(color: AppColors.ink),
                      ),
                      const SizedBox(height: 8),
                      if (assets.isEmpty)
                        MarketSurfaceCard(
                          radius: 0,
                          showShadow: false,
                          borderColor: AppColors.border,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 36),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 72,
                                    height: 72,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: AppColors.surfaceSecondary,
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: const Icon(
                                      Icons.domain_rounded,
                                      color: AppColors.primary,
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    t('No fixed assets registered',
                                        'Hakuna mali za kudumu'),
                                    textAlign: TextAlign.center,
                                    style: AppTypography.cardHeader.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    t(
                                      'Register equipment, machinery, furniture, and vehicles to calculate straight-line depreciation and monitor net book values.',
                                      'Sajili vifaa, mashine, samani, na magari kukokotoa uchakavu na kufuatilia thamani halisi.',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  MarketButton(
                                    label: t('Register first asset',
                                        'Sajili mali ya kwanza'),
                                    icon: Icons.add_rounded,
                                    isFullWidth: false,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (context) =>
                                            const AssetFormPage(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        MarketSurfaceCard(
                          radius: 0,
                          showShadow: false,
                          borderColor: AppColors.border,
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              _tableHeader(t),
                              const Divider(
                                  height: 1, color: AppColors.divider),
                              for (var i = 0; i < assets.length; i++) ...[
                                AssetRowTile(
                                  asset: assets[i],
                                  isSwahili: sw,
                                  onEdit: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (context) =>
                                          AssetFormPage(asset: assets[i]),
                                    ),
                                  ),
                                  onDelete: () =>
                                      _confirmDelete(context, assets[i], sw),
                                ),
                                if (i != assets.length - 1)
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

  static Widget _tableHeader(String Function(String, String) t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(t('Asset', 'Mali'),
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 3,
            child: Text(t('Cost', 'Gharama'),
                textAlign: TextAlign.right,
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            flex: 3,
            child: Text(t('NBV', 'Thamani'),
                textAlign: TextAlign.right,
                style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  static Future<void> _confirmDelete(
      BuildContext context, FixedAsset asset, bool isSwahili) async {
    if (asset.id == null) return;
    final store = context.read<PosLocalStore>();
    final confirmed = await showMarketConfirmDialog(
      context,
      title: isSwahili ? 'Futa mali?' : 'Delete asset?',
      message: isSwahili
          ? 'Mali hii na rekodi yake ya uchakavu vitaondolewa.'
          : 'This asset and its depreciation record will be removed.',
      confirmLabel: isSwahili ? 'Futa' : 'Delete',
      cancelLabel: isSwahili ? 'Ghairi' : 'Cancel',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed) return;
    await store.deleteFixedAsset(asset.id!);
    if (!context.mounted) return;
    showMarketNotice(
      context,
      title: isSwahili ? 'Mali Imefutwa' : 'Asset Deleted',
      message: isSwahili
          ? 'Mali imefutwa kikamilifu'
          : 'Asset deleted successfully',
      type: MarketNoticeType.success,
    );
  }
}
