import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../../../service/store_models.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

/// Clean row tile for an individual store/outlet.
class StoreRowTile extends StatelessWidget {
  const StoreRowTile({
    super.key,
    required this.store,
    required this.active,
    required this.canDelete,
    required this.isSwahili,
    required this.onEdit,
  });

  final Store store;
  final bool active;
  final bool canDelete;
  final bool isSwahili;
  final VoidCallback onEdit;

  String _t(String en, String swahili) => isSwahili ? swahili : en;

  @override
  Widget build(BuildContext context) {
    final name = store.name.trim().isEmpty ? store.id : store.name.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
                              color: AppColors.kpiSuccessBg,
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(AppRadius.pill)),
                            ),
                            child: Text(
                              _t('ACTIVE', 'INATUMIKA'),
                              style: AppTypography.helperText.copyWith(
                                color: AppColors.kpiSuccess,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (store.address.trim().isNotEmpty) store.address.trim(),
                        if (store.contact.trim().isNotEmpty) store.contact.trim(),
                        if (store.address.trim().isEmpty && store.contact.trim().isEmpty)
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
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                if (!active)
                  _action(
                    label: _t('Switch to this store', 'Tumia duka hili'),
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.primary,
                    onTap: () => _switchStore(context),
                  ),
                _action(
                  label: _t('Edit details', 'Hariri taarifa'),
                  icon: Icons.edit_outlined,
                  color: AppColors.ink,
                  onTap: onEdit,
                ),
                if (canDelete && !active)
                  _action(
                    label: _t('Delete', 'Futa'),
                    icon: Icons.delete_outline_rounded,
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
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sharp),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.helperText.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.modal)),
        ),
        title: Text(_t('Delete store?', 'Futa duka?')),
        content: Text(
          _t(
            'Remove this store from the list. Its records stay saved on this device, but it will no longer appear in your list.',
            'Ondoa duka hili kwenye orodha. Data yake ya ndani itabaki lakini halitachaguliwa tena.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(_t('Cancel', 'Ghairi')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_t('Delete', 'Futa')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await pos.deleteStore(store.id);
    if (!context.mounted) return;
    showMarketNotice(
      context,
      title: _t('Stores', 'Maduka'),
      message: _t('Store removed', 'Duka limeondolewa'),
      type: MarketNoticeType.info,
    );
  }
}
