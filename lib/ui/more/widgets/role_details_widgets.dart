import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import '../../../service/models/staff_models.dart';
import 'staff_details_sections.dart';

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
      radius: AppRadius.standard,
      showShadow: true,
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
      backgroundColor: AppColors.surface,
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.kpiSkyBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.kpiSky,
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
