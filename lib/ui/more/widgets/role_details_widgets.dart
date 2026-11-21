import 'package:flutter/material.dart';
import 'package:track_mauzo/l10n/app_localization.dart';

import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import '../../../service/models/staff_models.dart';
import 'staff_details_sections.dart';
import 'staff_models.dart';

class PermissionData {
  const PermissionData({
    required this.name,
    required this.label,
  });

  final String name;
  final String label;
}

class RolePermissionTile extends StatelessWidget {
  const RolePermissionTile({
    super.key,
    required this.data,
    required this.granted,
    required this.readOnly,
    required this.onChanged,
  });

  final PermissionData data;
  final bool granted;
  final bool readOnly;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: readOnly ? null : () => onChanged(!granted),
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: granted,
              onChanged: readOnly ? null : onChanged,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  data.label,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AssignedStaffTile extends StatelessWidget {
  const AssignedStaffTile({super.key, required this.data});

  final StaffMemberData data;

  @override
  Widget build(BuildContext context) {
    final avatarColor = avatarColorForName(data.name);
    return MarketSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      borderColor: AppColors.border,
      radius: 0,
      showShadow: false,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: avatarColor,
            child: Text(
              data.initials,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (data.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    data.email,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
                if (data.phone.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    data.phone,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
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

class RolePermissionNote extends StatelessWidget {
  const RolePermissionNote({super.key});

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: const Color(0xFFF7FAFF),
      borderColor: AppColors.border,
      radius: 0,
      showShadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2FE),
              borderRadius: BorderRadius.zero,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('Changes to permissions will apply immediately to all staff assigned to this role.'),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
