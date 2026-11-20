import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../l10n/app_strings.dart';
import '../../widgets/app_design.dart';
import '../../widgets/app_image.dart';
import '../../widgets/market_shared_widgets.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

class ExpenseReceiptCard extends StatelessWidget {
  const ExpenseReceiptCard({
    super.key,
    required this.path,
    required this.strings,
    required this.onPick,
    required this.onRemove,
  });

  final String? path;
  final AppStrings strings;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasReceipt = path != null && path!.isNotEmpty;
    return MarketSurfaceCard(
      radius: 0,
      borderColor: AppColors.border,
      showShadow: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_dual(strings, 'Receipt attachment', 'Kiambatisho cha risiti'),
              style: AppTypography.cardHeader),
          const SizedBox(height: 4),
          Text(
            _dual(strings, 'Optional photo of the paper receipt',
                'Picha ya hiari ya risiti ya karatasi'),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (hasReceipt)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: Image(
                    image: appImageProvider(context, path!),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 64,
                      height: 64,
                      color: AppColors.surfaceSecondary,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: AppColors.textLight),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dual(strings, 'Receipt attached', 'Risiti imeambatishwa'),
                    style: AppTypography.bodySmall
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: onRemove,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(_dual(strings, 'Remove', 'Ondoa')),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPick,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                label:
                    Text(_dual(strings, 'Attach receipt', 'Ambatisha risiti')),
              ),
            ),
        ],
      ),
    );
  }
}

class ExpenseFormDropdown extends StatelessWidget {
  const ExpenseFormDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    required this.strings,
  });

  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textLight),
                items: items
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e, style: AppTypography.bodySmall)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpenseChoicePill extends StatelessWidget {
  const ExpenseChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: selected ? AppColors.primaryDeep : AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
