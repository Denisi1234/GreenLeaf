import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';

enum PresetPeriod {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  thisQuarter,
  lastQuarter,
  thisYear,
  lastYear,
  allTime,
}

extension PresetPeriodLabel on PresetPeriod {
  String get label {
    switch (this) {
      case PresetPeriod.today:
        return 'Today';
      case PresetPeriod.yesterday:
        return 'Yesterday';
      case PresetPeriod.last7Days:
        return 'Last 7 days';
      case PresetPeriod.last30Days:
        return 'Last 30 days';
      case PresetPeriod.thisMonth:
        return 'This month';
      case PresetPeriod.lastMonth:
        return 'Last month';
      case PresetPeriod.thisQuarter:
        return 'This quarter';
      case PresetPeriod.lastQuarter:
        return 'Last quarter';
      case PresetPeriod.thisYear:
        return 'This year';
      case PresetPeriod.lastYear:
        return 'Last year';
      case PresetPeriod.allTime:
        return 'All time';
    }
  }
}

class PresetPeriodMenu extends StatelessWidget {
  const PresetPeriodMenu({
    super.key,
    required this.onPresetSelected,
    this.selectedPreset,
  });

  final void Function(PresetPeriod) onPresetSelected;
  final PresetPeriod? selectedPreset;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PresetPeriod>(
      tooltip: context.tr('Quick date ranges'),
      onSelected: onPresetSelected,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.input))),
      itemBuilder: (context) => [
        for (final preset in PresetPeriod.values)
          PopupMenuItem(
            value: preset,
            child: Row(
              children: [
                if (selectedPreset == preset)
                  Icon(Icons.check_rounded,
                      size: 16, color: AppColors.primary)
                else
                  const SizedBox(width: 16),
                const SizedBox(width: 8),
                Text(
                  context.tr(preset.label),
                  style: AppTypography.bodySmall.copyWith(
                    color: selectedPreset == preset
                        ? AppColors.primary
                        : AppColors.ink,
                    fontWeight: selectedPreset == preset
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: AppSpacing.touchTarget,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius:
              const BorderRadius.all(Radius.circular(AppRadius.input)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              context.tr(selectedPreset?.label ?? 'Quick'),
              style: AppTypography.label.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
