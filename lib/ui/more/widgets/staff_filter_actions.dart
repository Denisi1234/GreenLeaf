import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import 'staff_models.dart';

class StaffRoleFilterChip extends StatelessWidget {
  const StaffRoleFilterChip({
    super.key,
    required this.store,
    required this.selectedRole,
    required this.onSelected,
  });

  final PosLocalStore store;
  final StaffRoleData? selectedRole;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(store.languageCode);
    final label =
        selectedRole?.title ?? staffDual(strings, 'All roles', 'Nafasi zote');
    return PopupMenuButton<String>(
      tooltip: staffDual(strings, 'Filter by role', 'Chuja kwa nafasi'),
      onSelected: (value) => onSelected(value == '__all__' ? null : value),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: '__all__',
          child: Text(staffDual(strings, 'All roles', 'Nafasi zote')),
        ),
        ...store.staffRoles.map(
          (role) => PopupMenuItem<String>(
            value: role.id,
            child: Text(role.title),
          ),
        ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selectedRole == null ? AppColors.surface : AppColors.primary,
          borderRadius: AppCorners.control,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_outlined,
              size: 16,
              color: selectedRole == null ? AppColors.textMuted : Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color:
                    selectedRole == null ? AppColors.textMuted : Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: selectedRole == null ? AppColors.textMuted : Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class StaffChoicePill extends StatelessWidget {
  const StaffChoicePill({
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
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: AppCorners.control,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class StaffSheetAction extends StatelessWidget {
  const StaffSheetAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.danger : AppColors.textMain;
    return InkWell(
      onTap: onTap,
      borderRadius: AppCorners.control,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
