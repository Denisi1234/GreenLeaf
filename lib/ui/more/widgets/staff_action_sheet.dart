import 'package:flutter/material.dart';

import '../../../l10n/app_strings.dart';
import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import 'staff_cards.dart';
import 'staff_filter_actions.dart';
import 'staff_models.dart';

class StaffActionSheet {
  const StaffActionSheet._();

  static void show({
    required BuildContext context,
    required PosLocalStore store,
    required StaffMemberData member,
    required VoidCallback onViewDetails,
    required VoidCallback onEditStaff,
    required VoidCallback onOpenRole,
    required ValueChanged<StaffStatus> onSetStatus,
    required VoidCallback onDelete,
  }) {
    final strings = AppStrings.of(store.languageCode);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final role = store.staffRoleById(member.roleId);
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    StaffAvatar(member: member, radius: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: AppTypography.cardHeader,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${role?.title ?? 'No role'} · ${member.jobTitle.isEmpty ? member.status.label : member.jobTitle}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    StaffStatusPill(status: member.status, strings: strings),
                  ],
                ),
                const SizedBox(height: 16),
                StaffSheetAction(
                  icon: Icons.badge_outlined,
                  label: staffDual(
                      strings, 'View full profile', 'Tazama wasifu kamili'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onViewDetails();
                  },
                ),
                StaffSheetAction(
                  icon: Icons.edit_outlined,
                  label: staffDual(strings, 'Edit staff details',
                      'Hariri maelezo ya mfanyakazi'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onEditStaff();
                  },
                ),
                StaffSheetAction(
                  icon: Icons.manage_accounts_outlined,
                  label: staffDual(strings, 'Open assigned role',
                      'Fungua nafasi iliyopangwa'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onOpenRole();
                  },
                ),
                const Divider(height: 24, color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    staffDual(strings, 'SET STATUS', 'WEKA HALI'),
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: StaffStatus.values.map((status) {
                    final selected = member.status == status;
                    return StaffChoicePill(
                      label: status.localized(strings.isSwahili),
                      selected: selected,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        if (!selected) onSetStatus(status);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                StaffSheetAction(
                  icon: Icons.delete_outline_rounded,
                  label: staffDual(
                      strings, 'Remove staff member', 'Ondoa mfanyakazi'),
                  isDestructive: true,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> showRolesSheet({
    required BuildContext context,
    required PosLocalStore store,
    required VoidCallback onCreateRole,
    required ValueChanged<StaffRoleData> onOpenRole,
  }) async {
    final strings = AppStrings.of(store.languageCode);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, controller) {
            final roles = store.staffRoles;
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.zero,
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staffDual(strings, 'Roles & Access',
                                  'Nafasi na Ruhusa'),
                              style: AppTypography.h3,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              staffDual(
                                  strings,
                                  'Permissions apply to every staff member in a role.',
                                  'Ruhusa zinatumika kwa kila mfanyakazi mwenye nafasi hiyo.'),
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          onCreateRole();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                staffDual(strings, 'New', 'Mpya'),
                                style: const TextStyle(
                                  color: AppColors.primaryDeep,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...roles.map(
                    (role) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: StaffRoleTile(
                        strings: strings,
                        role: role,
                        staffCount: store.staffMembersForRole(role.id).length,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          onOpenRole(role);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
