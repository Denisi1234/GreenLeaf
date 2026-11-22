import 'package:flutter/material.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../../service/pos_local_store.dart';
import '../../widgets/app_design.dart';
import '../../widgets/market_shared_widgets.dart';
import 'staff_details_sections.dart';

class ManageStaffSheet {
  static void show(
      BuildContext context, PosLocalStore store, StaffRoleData role) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) =>
          _ManageStaffSheetContent(role: role, store: store),
    );
  }
}

class _ManageStaffSheetContent extends StatelessWidget {
  const _ManageStaffSheetContent({required this.role, required this.store});

  final StaffRoleData role;
  final PosLocalStore store;

  void _showMoveDialog(BuildContext context, StaffMemberData staff) {
    final availableRoles =
        store.staffRoles.where((r) => r.id != staff.roleId).toList();
    if (availableRoles.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppCorners.control),
        title: Text(
          context.tr('Move {p0}', args: {'p0': staff.name}),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableRoles
              .map(
                (targetRole) => ListTile(
                  title: Text(targetRole.title),
                  subtitle: Text(targetRole.subtitle),
                  onTap: () async {
                    await store
                        .saveStaffMember(staff.copyWith(roleId: targetRole.id));
                    if (context.mounted) {
                      Navigator.of(dialogContext).pop();
                      showMarketNotice(
                        context,
                        title: context.tr('Staff Moved'),
                        message: context.tr('{p0} moved to {p1}',
                            args: {'p0': staff.name, 'p1': targetRole.title}),
                      );
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignedStaff =
        store.staffMembers.where((s) => s.roleId == role.id).toList();
    final otherStaff =
        store.staffMembers.where((s) => s.roleId != role.id).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppCorners.control,
      ),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppCorners.control,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Staff in {p0} ({p1})',
                  args: {'p0': role.title, 'p1': assignedStaff.length}),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink),
            ),
            const SizedBox(height: 12),
            if (assignedStaff.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  context.tr('No staff assigned to this role yet.'),
                  style: TextStyle(color: AppColors.textMuted),
                ),
              )
            else
              ...assignedStaff.map(
                (staff) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StaffTile(
                    staff: staff,
                    onMove: () => _showMoveDialog(context, staff),
                    onDelete: () => store.deleteStaffMember(staff.id),
                  ),
                ),
              ),
            if (otherStaff.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                context
                    .tr('Other Staff ({p0})', args: {'p0': otherStaff.length}),
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink),
              ),
              const SizedBox(height: 10),
              ...otherStaff.map(
                (staff) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StaffTile(
                    staff: staff,
                    onMove: () => _showMoveDialog(context, staff),
                    onDelete: () => store.deleteStaffMember(staff.id),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.staff,
    required this.onMove,
    required this.onDelete,
  });

  final StaffMemberData staff;
  final VoidCallback onMove;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(10),
      borderColor: AppColors.border,
      radius: AppRadius.standard,
      showShadow: true,
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: avatarColorForName(staff.name),
            child: Text(
              staff.initials,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
                Text(
                  staff.phone.isNotEmpty ? staff.phone : staff.email,
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon:
                Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
            shape:
                const RoundedRectangleBorder(borderRadius: AppCorners.control),
            onSelected: (val) {
              if (val == 'move') {
                onMove();
              } else if (val == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                  value: 'move',
                  child: Text(context.tr('Move to another role'))),
              PopupMenuItem(
                  value: 'delete', child: Text(context.tr('Remove staff'))),
            ],
          ),
        ],
      ),
    );
  }
}
