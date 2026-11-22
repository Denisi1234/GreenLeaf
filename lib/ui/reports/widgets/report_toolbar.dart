import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import '../../widgets/workspace_widgets.dart';
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
  final PresetPeriod selectedPreset;
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
  Widget build(BuildContext context) {
    final localization = MaterialLocalizations.of(context);
    final dateLabel = range == null
        ? context.tr('All dates')
        : '${localization.formatCompactDate(range!.start)} – ${localization.formatCompactDate(range!.end)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: MarketSearchField(
                  controller: searchController,
                  hintText: context.tr('Search this report'),
                  onChanged: onSearchChanged,
                  onClear: onSearchCleared,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSecondary,
                  borderRadius:
                      BorderRadius.all(Radius.circular(AppRadius.input)),
                ),
                child: IconButton(
                  tooltip: context.tr('Show columns'),
                  onPressed: onShowColumns,
                  icon: SvgPicture.asset(
                    'assets/images/column_toggle.svg',
                    width: 20,
                    height: 20,
                    colorFilter:
                        ColorFilter.mode(AppColors.ink, BlendMode.srcIn),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!isSnapshot) ...[
                  InkWell(
                    onTap: onChooseRange,
                    child: Container(
                      height: AppSpacing.touchTarget,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSecondary,
                        borderRadius:
                            BorderRadius.all(Radius.circular(AppRadius.input)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            dateLabel,
                            style: AppTypography.label.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PresetPeriodMenu(
                    selectedPreset: selectedPreset,
                    onPresetSelected: onPresetSelected,
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: WorkspaceStatus(
                      label: context.tr('Current snapshot'),
                      color: AppColors.textBody,
                    ),
                  ),
                if (searchQuery.isNotEmpty ||
                    selection != null ||
                    (!isSnapshot && range != null)) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onClearFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.dangerDeep,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(context.tr('Clear filters')),
                  ),
                ],
                if (choices.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey(selection),
                      initialValue: selection,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('Filter records'),
                        border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                                Radius.circular(AppRadius.input))),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                              Radius.circular(AppRadius.input)),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text(context.tr('All records'),
                              overflow: TextOverflow.ellipsis),
                        ),
                        ...choices.map((value) => DropdownMenuItem(
                              value: value,
                              child:
                                  Text(value, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: onSelectionChanged,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
