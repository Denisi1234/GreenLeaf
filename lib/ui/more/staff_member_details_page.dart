import 'package:track_mauzo/l10n/app_localization.dart';
import '../widgets/workspace_widgets.dart';
import '../widgets/app_image.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_edit_staff_page.dart';
import 'role_details_page.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

class StaffMemberDetailsPage extends StatelessWidget {
  const StaffMemberDetailsPage({super.key, required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    StaffMemberData? selected;
    for (final item in store.staffMembers) {
      if (item.id == staffId) {
        selected = item;
        break;
      }
    }

    final baseTheme = Theme.of(context);
    final manropeTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    if (selected == null) {
      return Theme(
        data: manropeTheme,
        child: Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: ManagementViewport(
              maxWidth: 1280,
              child: SafeArea(
                child: Column(
                  children: [
                    MarketPageHeader(
                      title: _dual(
                          strings, 'Staff Profile', 'Wasifu wa Mfanyakazi'),
                      centerTitle: false,
                      showBorder: false,
                    ),
                    Expanded(
                      child: Center(
                        child: Text(_dual(
                            strings,
                            'This staff member no longer exists.',
                            'Mfanyakazi huyu hayupo tena.')),
                      ),
                    ),
                  ],
                ),
              )),
        ),
      );
    }

    final member = selected;
    final role = store.staffRoleById(member.roleId);
    final permissions = role?.permissions ?? const <String>[];

    return Theme(
      data: manropeTheme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: ManagementViewport(
            maxWidth: 1280,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  MarketPageHeader(
                    title:
                        _dual(strings, 'Staff Profile', 'Wasifu wa Mfanyakazi'),
                    subtitle: member.name,
                    centerTitle: false,
                    showBorder: false,
                    actions: [
                      IconButton(
                        tooltip:
                            _dual(strings, 'Edit staff', 'Hariri mfanyakazi'),
                        onPressed: () async {
                          final saved =
                              await Navigator.of(context).push<StaffMemberData>(
                            MaterialPageRoute<StaffMemberData>(
                              builder: (context) => AddEditStaffPage(
                                member: member,
                                roles: store.staffRoles,
                              ),
                            ),
                          );
                          if (saved == null || !context.mounted) return;
                          showMarketNotice(
                            context,
                            title: context.tr('Staff Updated'),
                            message: context.tr('{p0} was updated successfully.', args: {'p0': saved.name}),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.ink),
                      ),
                      PopupMenuButton<String>(
                        tooltip: context.tr('More actions'),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title:  Text(context.tr('Remove staff member')),
                                content: Text(
                                  context.tr('Remove {p0} from this store? This cannot be undone.', args: {'p0': member.name}),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(false),
                                    child:  Text(context.tr('Cancel')),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                    ),
                                    child:  Text(context.tr('Remove')),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed != true || !context.mounted) return;
                            await store.deleteStaffMember(member.id);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            return;
                          }
                          final status = StaffStatus.values.firstWhere(
                            (item) => item.value == value,
                          );
                          await store.setStaffStatus(member.id, status);
                          if (!context.mounted) return;
                          showMarketNotice(
                            context,
                            title: context.tr('Status Updated'),
                            message:
                                context.tr('{p0} is now {p1}.', args: {'p0': member.name, 'p1': context.tr(status.label).toLowerCase()}),
                          );
                        },
                        itemBuilder: (context) => [
                           PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              context.tr('SET STATUS'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                          ...StaffStatus.values.map(
                            (status) => PopupMenuItem<String>(
                              value: status.value,
                              child: Row(
                                children: [
                                  Icon(
                                    member.status == status
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    size: 18,
                                    color: member.status == status
                                        ? AppColors.primary
                                        : AppColors.textLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(context.tr(status.label)),
                                ],
                              ),
                            ),
                          ),
                          const PopupMenuDivider(),
                           PopupMenuItem<String>(
                            value: 'delete',
                            child: Text(
                              context.tr('Remove staff member'),
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      children: [
                        _ProfileHero(
                            member: member,
                            role: role,
                            strings: AppStrings.of(store.languageCode)),
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: _dual(strings, 'Contact Information',
                              'Taarifa za Mawasiliano'),
                          icon: Icons.contact_phone_outlined,
                          rows: [
                            _InfoRowData(
                              label: _dual(strings, 'Phone', 'Simu'),
                              value: member.phone,
                              icon: Icons.call_outlined,
                            ),
                            _InfoRowData(
                              label: _dual(strings, 'Email', 'Baruapepe'),
                              value: member.email.isEmpty
                                  ? _dual(
                                      strings, 'Not provided', 'Haijatolewa')
                                  : member.email,
                              icon: Icons.mail_outline_rounded,
                            ),
                            _InfoRowData(
                              label: _dual(strings, 'Address', 'Anwani'),
                              value: member.address.isEmpty
                                  ? _dual(
                                      strings, 'Not provided', 'Haijatolewa')
                                  : member.address,
                              icon: Icons.location_on_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InfoSection(
                          title: _dual(strings, 'Employment', 'Ajira'),
                          icon: Icons.work_outline_rounded,
                          rows: [
                            _InfoRowData(
                              label: context.tr('Employee number'),
                              value: member.employeeNumber.isEmpty
                                  ? 'Not assigned'
                                  : member.employeeNumber,
                              icon: Icons.badge_outlined,
                            ),
                            _InfoRowData(
                              label: context.tr('Job title'),
                              value: member.jobTitle.isEmpty
                                  ? 'Not set'
                                  : member.jobTitle,
                              icon: Icons.workspace_premium_outlined,
                            ),
                            _InfoRowData(
                              label: context.tr('Department'),
                              value: member.department.isEmpty
                                  ? 'Not set'
                                  : member.department,
                              icon: Icons.apartment_outlined,
                            ),
                            _InfoRowData(
                              label: context.tr('Employment type'),
                              value: EmploymentType.fromValue(
                                          member.employmentType)
                                      ?.label ??
                                  'Not set',
                              icon: Icons.assignment_ind_outlined,
                            ),
                            _InfoRowData(
                              label: context.tr('Hire date'),
                              value: member.hireDate.isEmpty
                                  ? 'Not set'
                                  : _formatDate(member.hireDate),
                              icon: Icons.calendar_today_outlined,
                            ),
                            _InfoRowData(
                              label: context.tr('Hourly rate'),
                              value: member.hourlyRate <= 0
                                  ? 'Not set'
                                  : 'TSh ${member.hourlyRate.toStringAsFixed(0)}',
                              icon: Icons.payments_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _AccessSection(
                          member: member,
                          role: role,
                          permissions: permissions,
                          onOpenRole: role == null
                              ? null
                              : () => Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (context) =>
                                          RoleDetailsPage(roleId: role.id),
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 12),
                        _InfoSection(
                          title: _dual(strings, 'Emergency Contact',
                              'Mawasiliano ya Dharura'),
                          icon: Icons.emergency_outlined,
                          rows: [
                            _InfoRowData(
                              label: context.tr('Name'),
                              value: member.emergencyContactName.isEmpty
                                  ? 'Not provided'
                                  : member.emergencyContactName,
                              icon: Icons.person_outline_rounded,
                            ),
                            _InfoRowData(
                              label: context.tr('Phone'),
                              value: member.emergencyContactPhone.isEmpty
                                  ? 'Not provided'
                                  : member.emergencyContactPhone,
                              icon: Icons.phone_in_talk_outlined,
                            ),
                            _InfoRowData(
                              label: context.tr('Relationship'),
                              value: member.emergencyContactRelation.isEmpty
                                  ? 'Not provided'
                                  : member.emergencyContactRelation,
                              icon: Icons.people_outline_rounded,
                            ),
                          ],
                        ),
                        if (member.notes.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _NotesSection(notes: member.notes),
                        ],
                        const SizedBox(height: 12),
                        _InfoSection(
                          title: _dual(strings, 'Record', 'Kumbukumbu'),
                          icon: Icons.history_rounded,
                          rows: [
                            _InfoRowData(
                              label: context.tr('Joined'),
                              value: _formatDate(member.createdAt),
                              icon: Icons.login_rounded,
                            ),
                            _InfoRowData(
                              label: context.tr('Last updated'),
                              value: member.updatedAt.isEmpty
                                  ? _formatDate(member.createdAt)
                                  : _formatDate(member.updatedAt),
                              icon: Icons.update_rounded,
                            ),
                            _InfoRowData(
                              label: context.tr('Staff ID'),
                              value: member.id,
                              icon: Icons.fingerprint_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        MarketButton(
                          label: _dual(strings, 'Edit Staff Profile',
                              'Hariri Wasifu wa Mfanyakazi'),
                          icon: Icons.edit_outlined,
                          onTap: () async {
                            final saved = await Navigator.of(context)
                                .push<StaffMemberData>(
                              MaterialPageRoute<StaffMemberData>(
                                builder: (context) => AddEditStaffPage(
                                  member: member,
                                  roles: store.staffRoles,
                                ),
                              ),
                            );
                            if (saved == null || !context.mounted) return;
                            showMarketNotice(
                              context,
                              title: context.tr('Staff Updated'),
                              message:
                                  context.tr('{p0} was updated successfully.', args: {'p0': saved.name}),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero(
      {required this.member, required this.role, required this.strings});

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
      showShadow: false,
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: _avatarColorForName(member.name),
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
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSecondary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              role?.title ?? context.tr('No role assigned'),
                              style: const TextStyle(
                                color: AppColors.primaryDeep,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(status: member.status, strings: strings),
                      ],
                    ),
                    if (member.jobTitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        member.jobTitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: context.tr('Employee No.'),
                  value: member.employeeNumber.isEmpty
                      ? '—'
                      : member.employeeNumber,
                ),
              ),
              Expanded(
                child: _HeroStat(
                  label: context.tr('Department'),
                  value: member.department.isEmpty ? '—' : member.department,
                ),
              ),
              Expanded(
                child: _HeroStat(
                  label: context.tr('Permissions'),
                  value: '${role?.permissions.length ?? 0}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMain,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.helperText.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: AppTypography.cardHeader),
            ],
          ),
          const SizedBox(height: 14),
          ...rows.asMap().entries.map((entry) {
            final row = entry.value;
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(row.icon, color: AppColors.textMuted, size: 18),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 118,
                      child: Text(
                        row.label,
                        style: AppTypography.helperText.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        row.value,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _InfoRowData {
  const _InfoRowData({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _AccessSection extends StatelessWidget {
  const _AccessSection({
    required this.member,
    required this.role,
    required this.permissions,
    required this.onOpenRole,
  });

  final StaffMemberData member;
  final StaffRoleData? role;
  final List<String> permissions;
  final VoidCallback? onOpenRole;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(context.tr('Login & Access'), style: AppTypography.cardHeader),
              ),
              if (onOpenRole != null)
                TextButton(
                  onPressed: onOpenRole,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child:  Text(context.tr('Manage role')),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AccessTile(
                  label: context.tr('Username'),
                  value: member.username.isEmpty ? 'Not set' : member.username,
                  icon: Icons.alternate_email_rounded,
                ),
              ),
              Expanded(
                child: _AccessTile(
                  label: context.tr('Password'),
                  value: member.hasPassword ? 'Set' : 'Not set',
                  icon: Icons.lock_outline_rounded,
                  valueColor: member.hasPassword
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('Permissions ({p0})', args: {'p0': permissions.length}),
            style: AppTypography.helperText.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (permissions.isEmpty)
            Text(
              context.tr('No permissions granted for this role.'),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: permissions
                  .map(
                    (permission) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        context.tr(permission),
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _AccessTile extends StatelessWidget {
  const _AccessTile({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(
              color: valueColor ?? AppColors.textMain,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.helperText.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesSection extends StatelessWidget {
  const _NotesSection({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sticky_note_2_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(context.tr('Notes'), style: AppTypography.cardHeader),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMain,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.strings});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.localized(strings.isSwahili),
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatDate(String value) {
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

Color _avatarColorForName(String name) {
  const colors = <Color>[
    Color(0xFFF2D9D2),
    Color(0xFFF3F4F6),
    Color(0xFFF3F4F6),
    Color(0xFFF3F4F6),
    Color(0xFFF3F4F6),
  ];
  final index = name.hashCode.abs() % colors.length;
  return colors[index];
}
