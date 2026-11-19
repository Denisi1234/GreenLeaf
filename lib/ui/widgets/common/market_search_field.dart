import 'package:flutter/material.dart';

import '../app_design.dart';

/// Standard professional search bar shared across the entire application.
/// Ensures consistent height, padding, search icon, clear button,
/// optional scanner trigger, and focus styling.
class MarketSearchField extends StatelessWidget {
  const MarketSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.onClear,
    this.onScanTap,
    this.height = 46,
    this.radius = 0, // Crisp modern flat design
    this.backgroundColor = Colors.white,
    this.borderColor = AppColors.border,
    this.iconColor = AppColors.textMuted,
    this.hintColor = AppColors.textLight,
    this.textColor = AppColors.textMain,
    this.leadingIcon = Icons.search_rounded,
    this.paddingHorizontal = AppSpacing.sm,
    this.iconSize = 20,
    this.showShadow = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onScanTap;
  final double height;
  final double radius;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color hintColor;
  final Color textColor;
  final IconData leadingIcon;
  final double paddingHorizontal;
  final double iconSize;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasValue = value.text.isNotEmpty;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor),
            boxShadow: showShadow ? AppShadows.soft : null,
          ),
          child: Row(
            children: [
              SizedBox(width: paddingHorizontal),
              Icon(
                leadingIcon,
                size: iconSize,
                color: iconColor,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  textAlignVertical: TextAlignVertical.center,
                  style: AppTypography.bodyMain.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: hintText,
                    hintStyle: AppTypography.bodyMain.copyWith(
                      color: hintColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              if (hasValue && onClear != null)
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(
                    Icons.cancel_rounded,
                    size: 19,
                    color: AppColors.textLight,
                  ),
                  tooltip: 'Clear search',
                  splashRadius: 18,
                ),
              if (onScanTap != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    onPressed: onScanTap,
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Scan barcode',
                    splashRadius: 18,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
