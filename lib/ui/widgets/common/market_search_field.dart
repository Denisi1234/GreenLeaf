import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../app_design.dart';

/// Standard professional search bar shared across the entire application.
/// Ensures consistent height, padding, search icon, clear button,
/// optional scanner trigger, and focus styling.
class MarketSearchField extends StatelessWidget {
  const MarketSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.hintText,
    required this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onScanTap,
    this.height = 48,
    this.radius = AppRadius.input,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.hintColor,
    this.textColor,
    this.leadingIcon = Icons.search_rounded,
    this.paddingHorizontal = AppSpacing.sm,
    this.iconSize = 20,
    this.showShadow = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onScanTap;
  final double height;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final Color? hintColor;
  final Color? textColor;
  final IconData leadingIcon;
  final double paddingHorizontal;
  final double iconSize;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.surface;
    final bc = borderColor ?? AppColors.border;
    final ic = iconColor ?? AppColors.textMuted;
    final hc = hintColor ?? AppColors.textLight;
    final tc = textColor ?? AppColors.textMain;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasValue = value.text.isNotEmpty;

        return Focus(
          child: Builder(builder: (context) {
            final focused = Focus.of(context).hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: height < AppSpacing.touchTarget
                  ? AppSpacing.touchTarget
                  : height,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                    color: focused ? AppColors.primary : bc,
                    width: focused ? 2 : 1),
                boxShadow: showShadow ? AppShadows.soft : null,
              ),
              child: Row(
                children: [
                  SizedBox(width: paddingHorizontal),
                  Icon(
                    leadingIcon,
                    size: iconSize,
                    color: ic,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      textInputAction: TextInputAction.search,
                      textAlignVertical: TextAlignVertical.center,
                      style: AppTypography.bodyMain.copyWith(
                        color: tc,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: hintText,
                        hintStyle: AppTypography.bodyMain.copyWith(
                          color: hc,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (hasValue && onClear != null)
                    IconButton(
                      onPressed: onClear,
                      icon: Icon(
                        Icons.cancel_rounded,
                        size: 19,
                        color: AppColors.textLight,
                      ),
                      tooltip: context.tr('Clear search'),
                      splashRadius: 18,
                    ),
                  if (onScanTap != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: IconButton(
                        onPressed: onScanTap,
                        icon: Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        tooltip: context.tr('Scan barcode'),
                        splashRadius: 18,
                      ),
                    ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
