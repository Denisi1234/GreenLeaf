import 'package:track_mauzo/l10n/app_localization.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import '../../widgets/app_image.dart';
import '../../widgets/market_shared_widgets.dart';
import 'staff_models.dart';

class StaffStatCard extends StatelessWidget {
  const StaffStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      borderColor: AppColors.border,
      radius: 0,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.h3.copyWith(fontSize: 22, letterSpacing: -0.4),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.helperText.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class StaffTile extends StatelessWidget {
  const StaffTile({
    super.key,
    required this.strings,
    required this.member,
    required this.role,
    required this.onTap,
    required this.onMenu,
  });

  final AppStrings strings;
  final StaffMemberData member;
  final StaffRoleData? role;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (member.jobTitle.isNotEmpty) member.jobTitle,
      if (member.department.isNotEmpty) member.department,
      if (member.jobTitle.isEmpty && member.department.isEmpty && role != null)
        role!.title,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: MarketSurfaceCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        borderColor: AppColors.border,
        radius: 0,
        showShadow: false,
        child: Row(
          children: [
            StaffAvatar(member: member, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMain.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      StaffStatusPill(status: member.status, strings: strings),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.isEmpty ? context.tr('No role assigned') : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (role != null) ...[
                        StaffMiniTag(label: role!.title),
                        const SizedBox(width: 6),
                      ],
                      if (member.employeeNumber.isNotEmpty)
                        StaffMiniTag(
                          label: '#${member.employeeNumber}',
                          muted: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onMenu,
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textMuted,
              ),
              tooltip: context.tr('Staff actions'),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffAvatar extends StatelessWidget {
  const StaffAvatar({super.key, required this.member, required this.radius});

  final StaffMemberData member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = member.avatarPath;
    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColorForStaffName(member.name),
      backgroundImage:
          path == null || path.isEmpty ? null : appImageProvider(context, path),
      child: path == null || path.isEmpty
          ? Text(
              member.initials,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class StaffStatusPill extends StatelessWidget {
  const StaffStatusPill({super.key, required this.status, required this.strings});

  final StaffStatus status;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      StaffStatus.active => AppColors.success,
      StaffStatus.onLeave => AppColors.warning,
      StaffStatus.inactive => AppColors.textMuted,
    };
    final background = switch (status) {
      StaffStatus.active => AppColors.successLight,
      StaffStatus.onLeave => AppColors.warningLight,
      StaffStatus.inactive => AppColors.surfaceSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        status.localized(strings.isSwahili),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class StaffMiniTag extends StatelessWidget {
  const StaffMiniTag({super.key, required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: const BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: muted ? AppColors.textMuted : AppColors.primaryDeep,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StaffRoleTile extends StatelessWidget {
  const StaffRoleTile({
    super.key,
    required this.strings,
    required this.role,
    required this.staffCount,
    required this.onTap,
  });

  final AppStrings strings;
  final StaffRoleData role;
  final int staffCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: MarketSurfaceCard(
        padding: const EdgeInsets.all(14),
        borderColor: AppColors.border,
        radius: 0,
        showShadow: false,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.title,
                    style: AppTypography.bodyMain.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    staffDual(
                        strings,
                        '${role.permissions.length} permissions · $staffCount staff',
                        '${role.permissions.length} ruhusa · $staffCount wafanyakazi'),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

class StaffEmptyState extends StatelessWidget {
  const StaffEmptyState({
    super.key,
    required this.strings,
    required this.hasFilters,
    required this.onReset,
    required this.onAdd,
  });

  final AppStrings strings;
  final bool hasFilters;
  final VoidCallback onReset;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(24),
      borderColor: AppColors.border,
      radius: 0,
      showShadow: false,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(
              hasFilters ? Icons.search_off_rounded : Icons.groups_2_outlined,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? staffDual(strings, 'No staff found',
                    'Hakuna mfanyakazi aliyepatikana')
                : staffDual(strings, 'No staff yet', 'Hakuna mfanyakazi bado'),
            style: AppTypography.cardHeader,
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? staffDual(
                    strings,
                    'Try a different search or clear the filters to see more staff.',
                    'Jaribu utafutaji mwingine au futa vichujio kuona wafanyakazi zaidi.')
                : staffDual(
                    strings,
                    'Add your first team member to start assigning roles and access.',
                    'Ongeza mfanyakazi wako wa kwanza kuanza kupanga nafasi na ruhusa.'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          MarketButton(
            label: hasFilters
                ? staffDual(strings, 'Clear filters', 'Futa vichujio')
                : staffDual(strings, 'Add new staff', 'Ongeza mfanyakazi'),
            isFullWidth: false,
            icon:
                hasFilters ? Icons.filter_list_off_rounded : Icons.add_rounded,
            onTap: hasFilters ? onReset : onAdd,
          ),
        ],
      ),
    );
  }
}
