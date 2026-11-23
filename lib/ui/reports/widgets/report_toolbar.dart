import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import '../pos_report_data.dart';
import 'preset_period_menu.dart';

class ReportToolbar extends StatelessWidget {
  const ReportToolbar({
    super.key,
    required this.table,
    required this.choices,
    required this.selection,
    required this.range,
    required this.selectedPreset,
    required this.searchController,
    required this.searchQuery,
    required this.isSnapshot,
    required this.onSearchChanged,
    required this.onSearchCleared,
    required this.onShowColumns,
    required this.onChooseRange,
    required this.onPresetSelected,
    required this.onClearFilters,
    required this.onSelectionChanged,
  });

  final ReportTable table;
  final List<String> choices;
  final String? selection;
  final DateTimeRange? range;
  final PresetPeriod? selectedPreset;
  final TextEditingController searchController;
  final String searchQuery;
  final bool isSnapshot;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchCleared;
  final VoidCallback onShowColumns;
  final VoidCallback onChooseRange;
  final ValueChanged<PresetPeriod> onPresetSelected;
  final VoidCallback onClearFilters;
  final ValueChanged<String?> onSelectionChanged;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final mobile = constraints.maxWidth < 700;
        final localization = MaterialLocalizations.of(context);
        final dateLabel = range == null
            ? context.tr('All dates')
            : range!.start.year == range!.end.year
                ? '${localization.formatShortDate(range!.start)} – ${localization.formatShortDate(range!.end)}, ${range!.end.year}'
                : '${localization.formatCompactDate(range!.start)} – ${localization.formatCompactDate(range!.end)}';
        final hasFilters = searchQuery.isNotEmpty ||
            selection != null ||
            (!isSnapshot && range != null);

        final period = PopupMenuButton<String>(
          tooltip: context.tr('Quick date ranges'),
          onSelected: (value) {
            if (value == 'custom') {
              onChooseRange();
            } else {
              onPresetSelected(PresetPeriod.values
                  .firstWhere((preset) => preset.name == value));
            }
          },
          itemBuilder: (_) => [
            for (final preset in PresetPeriod.values)
              CheckedPopupMenuItem(
                  value: preset.name,
                  checked: selectedPreset == preset,
                  child: Text(context.tr(preset.label))),
            const PopupMenuDivider(),
            PopupMenuItem(
                value: 'custom', child: Text(context.tr('Custom range'))),
          ],
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined,
                  size: 19, color: AppColors.ink),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(context.tr(selectedPreset?.label ?? 'Custom range'),
                        style: AppTypography.bodySmall
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(dateLabel, style: AppTypography.label),
                  ])),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded,
                  size: 18, color: AppColors.textMuted),
            ]),
          ),
        );
        final recordFilter = PopupMenuButton<int>(
          tooltip: context.tr('Filter records'),
          onSelected: (index) =>
              onSelectionChanged(index < 0 ? null : choices[index]),
          itemBuilder: (_) => [
            CheckedPopupMenuItem(
                value: -1,
                checked: selection == null,
                child: Text(context.tr('All records'))),
            for (var i = 0; i < choices.length; i++)
              CheckedPopupMenuItem(
                  value: i,
                  checked: choices[i] == selection,
                  child: Text(choices[i],
                      maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: EdgeInsets.symmetric(
                horizontal: mobile ? 12 : 14, vertical: 12),
            decoration: BoxDecoration(
                color: selection != null
                    ? AppColors.primaryLight
                    : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                  selection != null
                      ? Icons.filter_alt_rounded
                      : Icons.filter_alt_outlined,
                  size: 22,
                  color: AppColors.ink),
              if (!mobile) ...[
                const SizedBox(width: 8),
                Flexible(
                    child: Text(selection ?? context.tr('All records'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall)),
              ],
            ]),
          ),
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.divider))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Expanded(
                  child: MarketSearchField(
                controller: searchController,
                radius: 12,
                backgroundColor: AppColors.surfaceSecondary,
                borderColor: Colors.transparent,
                hintText: context.tr('Search this report'),
                onChanged: onSearchChanged,
                onClear: onSearchCleared,
              )),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                  tooltip: context.tr('Show columns'),
                  onPressed: onShowColumns,
                  style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      backgroundColor: AppColors.surfaceSecondary,
                      foregroundColor: AppColors.ink),
                  icon: const Icon(Icons.view_column_outlined, size: 23)),
            ]),
            if (!isSnapshot || choices.isNotEmpty || hasFilters) ...[
              const SizedBox(height: 10),
              Row(children: [
                if (!isSnapshot)
                  Expanded(flex: mobile ? 1 : 2, child: period)
                else
                  Expanded(
                      child: Text(context.tr('Current snapshot'),
                          style: AppTypography.label)),
                if (choices.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  if (mobile) recordFilter else Expanded(child: recordFilter),
                ],
                if (hasFilters) ...[
                  const SizedBox(width: 4),
                  IconButton(
                      tooltip: context.tr('Clear filters'),
                      onPressed: onClearFilters,
                      color: AppColors.dangerDeep,
                      icon: const Icon(Icons.filter_alt_off_outlined)),
                ],
              ]),
            ],
          ]),
        );
      });
}
