import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'widgets/manage_staff_sheet.dart';
import 'widgets/role_details_widgets.dart';

class RoleDetailsPage extends StatefulWidget {
  const RoleDetailsPage({super.key, required this.roleId});

  final String roleId;

  @override
  State<RoleDetailsPage> createState() => _RoleDetailsPageState();
}

class _RoleDetailsPageState extends State<RoleDetailsPage> {
  Future<void> _renameRole(StaffRoleData role) async {
    final store = context.read<PosLocalStore>();
    final titleController = TextEditingController(text: role.title);
    final subtitleController = TextEditingController(text: role.subtitle);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.modal),
        ),
        title: Text(context.tr('Edit role')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: context.tr('Role name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subtitleController,
              decoration: InputDecoration(labelText: context.tr('Description')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.kpiDangerBg,
              foregroundColor: AppColors.kpiDanger,
              shape: const RoundedRectangleBorder(
                borderRadius: AppCorners.control,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              context.tr('Cancel'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              side: BorderSide.none,
              shape: const RoundedRectangleBorder(
                borderRadius: AppCorners.control,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              context.tr('Save'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    final updatedTitle = titleController.text.trim();
    final updatedSubtitle = subtitleController.text.trim();
    titleController.dispose();
    subtitleController.dispose();

    if (saved == true) {
      await store.saveStaffRole(
        role.copyWith(
          title: updatedTitle,
          subtitle: updatedSubtitle,
        ),
      );
      if (!mounted) return;
      showMarketNotice(
        context,
        title: context.tr('Role Updated'),
        message: context
            .tr('{p0} role details updated.', args: {'p0': updatedTitle}),
        type: MarketNoticeType.success,
      );
    }
  }

  Future<void> _deleteRole(StaffRoleData role) async {
    final store = context.read<PosLocalStore>();
    if (store.staffMembersForRole(role.id).isNotEmpty) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: context.tr('Role In Use'),
        message:
            context.tr('Move staff to another role before deleting this one.'),
        type: MarketNoticeType.warning,
      );
      return;
    }

    final confirmed = await showMarketConfirmDialog(
      context,
      title: context.tr('Delete role'),
      message: context.tr(
        'Delete the "{p0}" role? This cannot be undone.',
        args: {'p0': role.title},
      ),
      confirmLabel: context.tr('Delete'),
      cancelLabel: context.tr('Cancel'),
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );

    if (!confirmed || !mounted) return;
    await store.deleteStaffRole(role.id);
    if (!mounted) return;
    showMarketNotice(
      context,
      title: context.tr('Role Deleted'),
      message:
          context.tr('{p0} role has been removed.', args: {'p0': role.title}),
      type: MarketNoticeType.success,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final role = store.staffRoleById(widget.roleId);

    if (role == null) {
      return Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: context.tr('Role Not Found'),
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Center(
                    child:
                        Text(context.tr('The selected role does not exist.')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final assignedStaff = store.staffMembersForRole(role.id);
    final checkedPermissions = role.permissions.toSet();
    final permissionCatalog = store.staffPermissionCatalog;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
        maxWidth: 1280,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              MarketPageHeader(
                title: role.title,
                subtitle: role.subtitle,
                showBorder: false,
                actions: [
                  PopupMenuButton<String>(
                    tooltip: context.tr('Role actions'),
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppCorners.control),
                    onSelected: (value) {
                      if (value == 'rename') _renameRole(role);
                      if (value == 'delete') _deleteRole(role);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'rename',
                        child: Text(context.tr('Edit role details')),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(
                          context.tr('Delete role'),
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Permissions'),
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: permissionCatalog.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 38,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          final permission = permissionCatalog[index];
                          return RolePermissionTile(
                            data: PermissionData(
                                name: permission, label: permission),
                            granted: checkedPermissions.contains(permission),
                            readOnly: role.isOwnerAdmin,
                            onChanged: (value) {
                              final current = role.permissions.toSet();
                              if (value ?? false) {
                                current.add(permission);
                              } else {
                                current.remove(permission);
                              }
                              store.updateStaffRolePermissions(
                                  role.id, current.toList());
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr('Assigned Staff ({p0})',
                                  args: {'p0': assignedStaff.length}),
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                ManageStaffSheet.show(context, store, role),
                            child: Text(
                              context.tr('Manage'),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (assignedStaff.isEmpty)
                        MarketSurfaceCard(
                          padding: const EdgeInsets.all(14),
                          backgroundColor: AppColors.pageBackground,
                          borderColor: AppColors.border,
                          radius: AppRadius.input,
                          showShadow: false,
                          child: Text(
                            context.tr('No staff assigned to this role yet.'),
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        ...assignedStaff.map(
                          (staff) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AssignedStaffTile(data: staff),
                          ),
                        ),
                      const SizedBox(height: 14),
                      const RolePermissionNote(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
