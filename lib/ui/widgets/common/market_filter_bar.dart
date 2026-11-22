import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../app_design.dart';
import 'market_search_field.dart';

/// A single selectable filter chip option for [MarketFilterBar].
class MarketFilterOption<T> {
  const MarketFilterOption({
    required this.value,
    required this.label,
    this.icon,
    this.count,
    this.accentColor,
    this.accentBg,
  });

  final T value;
  final String label;
  final IconData? icon;
  final int? count;
  final Color? accentColor;
  final Color? accentBg;
}

/// Unified, design-system-compliant filter bar for all TrackMauzo sections
/// (Products, Sales, Expenses, Reports, Staff, Customers, Suppliers, Accounting).
///
/// Follows the TrackMauzo design pattern:
/// - `AppColors.surface` (`#F0F9FB`) container with `AppColors.border` (`#D6E4F0`)
/// - 10px control radius (`AppRadius.standard`) and 42px touch targets
/// - Consistent search field, horizontally scrollable filter pills, optional
///   secondary controls (dropdowns / date pickers), and a one-tap Reset action.
class MarketFilterBar<T> extends StatelessWidget {
  const MarketFilterBar({
    super.key,
    this.searchController,
    this.searchFocusNode,
    this.searchHint,
    this.onSearchChanged,
    this.onSearchClear,
    this.options = const [],
    this.selectedValue,
    this.onOptionSelected,
    this.extraControls = const [],
    this.trailing,
    this.hasActiveFilters = false,
    this.onReset,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.bordered = true,
  });

  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClear;
  final List<MarketFilterOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T>? onOptionSelected;
  final List<Widget> extraControls;
  final Widget? trailing;
  final bool hasActiveFilters;
  final VoidCallback? onReset;
  final EdgeInsetsGeometry padding;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final hasSearch = searchController != null;
    final hasOptions = options.isNotEmpty;
    final hasExtras =
        extraControls.isNotEmpty || (hasActiveFilters && onReset != null);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: bordered ? AppCorners.control : BorderRadius.zero,
        border: bordered
            ? Border.all(color: AppColors.border)
            : Border(
                bottom: BorderSide(color: AppColors.border),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSearch || trailing != null)
            Row(
              children: [
                if (hasSearch)
                  Expanded(
                    child: MarketSearchField(
                      controller: searchController!,
                      focusNode: searchFocusNode,
                      hintText: searchHint ?? context.tr('Search'),
                      onChanged: onSearchChanged ?? (_) {},
                      onClear: onSearchClear,
                    ),
                  ),
                if (trailing != null) ...[
                  if (hasSearch) const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          if (hasOptions) ...[
            if (hasSearch || trailing != null)
              const SizedBox(height: AppSpacing.sm + 2),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.sm),
                    _FilterChipPill<T>(
                      option: options[i],
                      selected: options[i].value == selectedValue,
                      onTap: onOptionSelected == null
                          ? null
                          : () => onOptionSelected!(options[i].value),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (hasExtras) ...[
            if (hasSearch || trailing != null || hasOptions)
              const SizedBox(height: AppSpacing.sm + 2),
            Wrap(
              spacing: AppSpacing.sm + 2,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...extraControls,
                if (hasActiveFilters && onReset != null)
                  _ResetFilterButton(onTap: onReset!),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChipPill<T> extends StatelessWidget {
  const _FilterChipPill({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final MarketFilterOption<T> option;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final activeAccent = option.accentColor ?? AppColors.primaryDeep;
    final activeBg = option.accentBg ?? AppColors.headerSurface;

    return Material(
      color: selected ? activeBg : AppColors.pageBackground,
      borderRadius: BorderRadius.circular(AppRadius.standard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        child: Container(
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(
              color: selected ? activeAccent : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (option.icon != null) ...[
                Icon(
                  option.icon,
                  size: 16,
                  color: selected ? activeAccent : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                option.label,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? activeAccent : AppColors.textBody,
                ),
              ),
              if (option.count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? activeAccent.withValues(alpha: 0.14)
                        : AppColors.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${option.count}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected ? activeAccent : AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResetFilterButton extends StatelessWidget {
  const _ResetFilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.kpiDangerBg,
      borderRadius: BorderRadius.circular(AppRadius.standard),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        child: Container(
          constraints: const BoxConstraints(minHeight: 38),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.standard),
            border: Border.all(color: AppColors.dangerBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.filter_alt_off_rounded,
                size: 15,
                color: AppColors.kpiDanger,
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('Reset'),
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.kpiDanger,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
