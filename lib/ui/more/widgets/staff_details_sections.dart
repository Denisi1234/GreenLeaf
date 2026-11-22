import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../../l10n/app_strings.dart';
import '../../widgets/app_design.dart';
import '../../widgets/app_image.dart';
import '../../widgets/market_shared_widgets.dart';
import '../../../service/models/staff_models.dart';

Color avatarColorForName(String name) {
  final palette = <Color>[
    AppColors.kpiAmberBg,
    AppColors.kpiSkyBg,
    AppColors.kpiSuccessBg,
    AppColors.kpiRoseBg,
    AppColors.kpiVioletBg,
    AppColors.kpiAmberBg,
  ];
  if (name.trim().isEmpty) return palette.first;
  final code = name.codeUnits.fold<int>(0, (acc, item) => acc + item);
  return palette[code % palette.length];
}

class StaffProfileHero extends StatelessWidget {
  const StaffProfileHero({
    super.key,
    required this.member,
    required this.role,
    required this.strings,
  });

  final StaffMemberData member;
  final StaffRoleData? role;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final path = member.avatarPath;
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: true,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: avatarColorForName(member.name),
                backgroundImage: path == null || path.isEmpty
                    ? null
                    : appImageProvider(context, path),
                child: path == null || path.isEmpty
                    ? Text(
                        member.initials,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: AppTypography.h3.copyWith(fontSize: 21),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        StaffStatusPill(status: member.status, strings: strings),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Text(
                            role?.title ?? 'No Role',
                            style: AppTypography.helperText.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StaffHeroStat(
                  label: context.tr('Role'),
                  value: role?.title ?? context.tr('Unassigned'),
                  icon: Icons.shield_outlined,
                ),
              ),
              Expanded(
                child: StaffHeroStat(
                  label: context.tr('Access'),
                  value: role?.isOwnerAdmin == true
                      ? context.tr('Full owner')
                      : '${role?.permissions.length ?? 0} ${context.tr('grants')}',
                  icon: Icons.lock_open_rounded,
                ),
              ),
              Expanded(
                child: StaffHeroStat(
                  label: context.tr('Login ID'),
                  value: member.username.isEmpty ? context.tr('None') : member.username,
                  icon: Icons.alternate_email_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StaffHeroStat extends StatelessWidget {
  const StaffHeroStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(label, style: AppTypography.helperText),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class StaffInfoSection extends StatelessWidget {
  const StaffInfoSection({
    super.key,
    required this.title,
    required this.rows,
  });

  final String title;
  final List<StaffInfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyMain.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 18, color: AppColors.borderLight),
            Row(
              children: [
                Icon(rows[i].icon, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rows[i].label, style: AppTypography.helperText),
                      const SizedBox(height: 2),
                      Text(
                        rows[i].value,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class StaffInfoRowData {
  const StaffInfoRowData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class StaffAccessSection extends StatelessWidget {
  const StaffAccessSection({
    super.key,
    required this.role,
    required this.allPermissions,
  });

  final StaffRoleData? role;
  final List<String> allPermissions;

  @override
  Widget build(BuildContext context) {
    final permissions = role?.permissions ?? const <String>[];
    final isOwner = role?.isOwnerAdmin ?? false;

    return MarketSurfaceCard(
      padding: const EdgeInsets.all(18),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Permissions & Capability'),
                  style: AppTypography.bodyMain.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (isOwner)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    context.tr('Full access'),
                    style: AppTypography.helperText.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final permission in allPermissions)
                StaffAccessTile(
                  permission: permission,
                  granted: isOwner || permissions.contains(permission),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class StaffAccessTile extends StatelessWidget {
  const StaffAccessTile({
    super.key,
    required this.permission,
    required this.granted,
  });

  final String permission;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: granted ? AppColors.successLight : AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: granted
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            granted ? Icons.check_circle_outline_rounded : Icons.lock_outline_rounded,
            size: 14,
            color: granted ? AppColors.successDeep : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            permission,
            style: AppTypography.helperText.copyWith(
              color: granted ? AppColors.successDeep : AppColors.textMuted,
              fontWeight: granted ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class StaffStatusPill extends StatelessWidget {
  const StaffStatusPill({
    super.key,
    required this.status,
    required this.strings,
  });

  final StaffStatus status;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (status) {
      StaffStatus.active => (
          AppColors.successLight,
          AppColors.successDeep,
          AppColors.success.withValues(alpha: 0.3)
        ),
      StaffStatus.onLeave => (
          AppColors.warningLight,
          AppColors.warningDeep,
          AppColors.warning.withValues(alpha: 0.3)
        ),
      StaffStatus.inactive => (
          AppColors.surfaceSecondary,
          AppColors.textMuted,
          AppColors.border
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: border),
      ),
      child: Text(
        status.localized(strings.isSwahili),
        style: AppTypography.helperText.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
