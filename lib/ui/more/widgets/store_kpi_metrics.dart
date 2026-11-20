import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
import '../../widgets/workspace_widgets.dart';

/// Clean operational KPI metrics for Multi-Store Management.
class StoreKpiMetrics extends StatelessWidget {
  const StoreKpiMetrics({
    super.key,
    required this.totalStores,
    required this.activeStoreName,
    required this.isSwahili,
  });

  final int totalStores;
  final String activeStoreName;
  final bool isSwahili;

  @override
  Widget build(BuildContext context) {
    String t(String en, String sw) => isSwahili ? sw : en;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 3 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Active branch', 'Tawi linalotumika'),
                value: activeStoreName.isEmpty ? t('Default store', 'Duka la kawaida') : activeStoreName,
                icon: Icons.store_rounded,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFD1FAE5),
                color: const Color(0xFF047857),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Total outlets', 'Jumla ya matawi'),
                value: '$totalStores',
                icon: Icons.storefront_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFE0F2FE),
                color: const Color(0xFF0369A1),
              ),
            ),
            SizedBox(
              width: width,
              child: WorkspaceMetric(
                label: t('Multi-branch tracking', 'Ufuatiliaji wa matawi'),
                value: t('Isolated stock & sales', 'Mauzo & stoo tofauti'),
                icon: Icons.hub_outlined,
                sharp: true,
                borderless: true,
                backgroundColor: const Color(0xFFFEF3C7),
                color: const Color(0xFFB45309),
              ),
            ),
          ],
        );
      },
    );
  }
}
