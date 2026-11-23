import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';

class StaffTabSelector extends StatelessWidget {
  const StaffTabSelector({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHover,
        borderRadius: AppCorners.control,
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : Colors.transparent,
                  borderRadius: AppCorners.control,
                  boxShadow: selected ? AppShadows.soft : null,
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color:
                        selected ? AppColors.primaryDeep : AppColors.textMuted,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class StaffFormSection extends StatelessWidget {
  const StaffFormSection({
    super.key,
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.border,
      radius: AppRadius.input,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.cardHeader),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class StaffFieldLabel extends StatelessWidget {
  const StaffFieldLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textMain,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class StaffAppTextField extends StatelessWidget {
  const StaffAppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.errorText,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? errorText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MarketFormField(
        label: label,
        hintText: hint,
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffix,
        validator: errorText != null && errorText!.isNotEmpty
            ? (_) => errorText
            : null,
      ),
    );
  }
}

class StaffAppDropdown<T> extends StatelessWidget {
  const StaffAppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffFieldLabel(label),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            initialValue: value,
            items: items,
            onChanged: onChanged,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted,
            ),
            style: AppTypography.bodyMain.copyWith(
              color: AppColors.textMain,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: AppColors.surfaceSecondary,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              errorText: errorText == null
                  ? null
                  : context.strings.message(errorText!),
              errorStyle: AppTypography.helperText.copyWith(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
              border: OutlineInputBorder(
                borderRadius: AppCorners.input,
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppCorners.input,
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppCorners.input,
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StaffDateField extends StatelessWidget {
  const StaffDateField({
    super.key,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: AppCorners.input,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceSecondary,
          borderRadius: AppCorners.input,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasValue
                    ? formatHireDate(value)
                    : context.tr('Select hire date'),
                style: AppTypography.bodyMain.copyWith(
                  color: hasValue ? AppColors.textMain : AppColors.textLight,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class StaffFormChoicePill extends StatelessWidget {
  const StaffFormChoicePill({
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
      borderRadius: AppCorners.control,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.pageBackground,
          borderRadius: AppCorners.control,
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.28)
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

class StaffPermissionRow extends StatelessWidget {
  const StaffPermissionRow({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: AppCorners.control,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 15,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StaffInfoCard extends StatelessWidget {
  const StaffInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: AppColors.surfaceSecondary,
      borderColor: AppColors.primary.withValues(alpha: 0.16),
      radius: AppRadius.input,
      showShadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: AppTypography.helperText.copyWith(
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StaffSaveBar extends StatelessWidget {
  const StaffSaveBar({
    super.key,
    required this.isSaving,
    required this.isEditing,
    required this.onSave,
  });

  final bool isSaving;
  final bool isEditing;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: MarketButton(
                label: context.tr('Cancel'),
                color: AppColors.kpiDangerBg,
                foregroundColor: AppColors.kpiDanger,
                borderColor: null,
                radius: AppRadius.input,
                height: 48,
                onTap: isSaving ? null : () => Navigator.of(context).maybePop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: MarketButton(
                label: isSaving
                    ? context.tr('Saving...')
                    : (isEditing
                        ? context.tr('Save Changes')
                        : context.tr('Create Staff')),
                icon: isSaving
                    ? Icons.hourglass_top_rounded
                    : Icons.save_outlined,
                variant: MarketButtonVariant.primary,
                borderColor: null,
                radius: AppRadius.input,
                height: 48,
                onTap: onSave ?? () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatHireDate(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
