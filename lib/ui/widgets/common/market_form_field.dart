import 'package:flutter/material.dart';

import '../app_design.dart';

/// Standard professional text form field shared across the entire application.
/// Ensures consistent borders, labels, padding, typography, prefix/suffix icons,
/// and error/focus states.
class MarketFormField extends StatelessWidget {
  const MarketFormField({
    super.key,
    this.label,
    this.isRequired = false,
    this.labelAction,
    required this.hintText,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.prefixText,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.radius = 0,
    this.fillColor = AppColors.surface,
    this.enabled = true,
  });

  final String? label;
  final bool isRequired;
  final Widget? labelAction;
  final String hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final int maxLines;
  final Widget? prefixIcon;
  final String? prefixText;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final double radius;
  final Color fillColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  text: label!,
                  style: AppTypography.label,
                  children: [
                    if (isRequired)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              if (labelAction != null) labelAction!,
            ],
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          readOnly: readOnly,
          enabled: enabled,
          onTap: onTap,
          style: AppTypography.bodyMain.copyWith(
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.textMain : AppColors.textMuted,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyMain.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
            ),
            prefixText: prefixText,
            prefixStyle: AppTypography.bodyMain.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
            filled: true,
            fillColor: enabled ? fillColor : AppColors.surfaceSecondary,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            prefixIcon: prefixIcon,
            prefixIconConstraints: prefixIcon != null
                ? const BoxConstraints(minWidth: 44, minHeight: 44)
                : const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffixIcon,
            suffixIconConstraints: suffixIcon != null
                ? const BoxConstraints(minWidth: 44, minHeight: 44)
                : const BoxConstraints(minWidth: 0, minHeight: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
            errorStyle: AppTypography.helperText.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Standard dropdown field matching MarketFormField styling.
class MarketDropdownField<T> extends StatelessWidget {
  const MarketDropdownField({
    super.key,
    this.label,
    this.isRequired = false,
    this.labelAction,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
    this.prefixIcon,
    this.radius = 0,
    this.fillColor = AppColors.surface,
  });

  final String? label;
  final bool isRequired;
  final Widget? labelAction;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;
  final Widget? prefixIcon;
  final double radius;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  text: label!,
                  style: AppTypography.label,
                  children: [
                    if (isRequired)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              if (labelAction != null) labelAction!,
            ],
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(radius),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
              hint: hintText != null
                  ? Text(
                      hintText!,
                      style: AppTypography.bodyMain.copyWith(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
