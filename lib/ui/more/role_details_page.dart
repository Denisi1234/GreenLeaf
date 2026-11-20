import 'package:track_mauzo/l10n/app_localization.dart';
import '../widgets/workspace_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_edit_staff_page.dart';

class RoleDetailsPage extends StatefulWidget {
  const RoleDetailsPage({super.key, required this.roleId});

  final String roleId;

  @override
  State<RoleDetailsPage> createState() => _RoleDetailsPageState();
}

class _RoleDetailsPageState extends State<RoleDetailsPage> {
  Future<void> _showManageStaff(StaffRoleData role) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManageStaffSheet(role: role),
    );
  }

  Future<void> _renameRole(StaffRoleData role) async {
    final store = context.read<PosLocalStore>();
    final titleController = TextEditingController(text: role.title);
    final subtitleController = TextEditingController(text: role.subtitle);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:  Text(context.tr('Edit role')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration:  InputDecoration(labelText: context.tr('Role name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subtitleController,
              decoration:  InputDecoration(labelText: context.tr('Description')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child:  Text(context.tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop(true);
            },
            child:  Text(context.tr('Save')),
          ),
        ],
      ),
    );

    if (saved == true) {
      await store.saveStaffRole(
        role.copyWith(
          title: titleController.text.trim(),
          subtitle: subtitleController.text.trim(),
        ),
      );
    }
    titleController.dispose();
    subtitleController.dispose();
  }

  Future<void> _deleteRole(StaffRoleData role) async {
    final store = context.read<PosLocalStore>();
    if (store.staffMembersForRole(role.id).isNotEmpty) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: context.tr('Role In Use'),
        message: context.tr('Move staff to another role before deleting this one.'),
        type: MarketNoticeType.warning,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:  Text(context.tr('Delete role')),
        content:
            Text(context.tr('Delete the "{p0}" role? This cannot be undone.', args: {'p0': role.title})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child:  Text(context.tr('Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child:  Text(context.tr('Delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await store.deleteStaffRole(role.id);
    if (!mounted) return;
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
                      child: Text(context.tr('The selected role does not exist.')),
                    ),
                  ),
                ],
              ),
            )),
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
                      onSelected: (value) {
                        if (value == 'rename') _renameRole(role);
                        if (value == 'delete') _deleteRole(role);
                      },
                      itemBuilder: (context) =>  [
                        PopupMenuItem<String>(
                          value: 'rename',
                          child: Text(context.tr('Edit role details')),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(
                            context.tr('Delete role'),
                            style: TextStyle(color: AppColors.danger),
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
                         Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Text(
                            context.tr('Permissions'),
                            style: TextStyle(
                              color: Color(0xFF111111),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
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
                            return _PermissionTile(
                              data: _permissionData(permission),
                              checked: checkedPermissions.contains(permission),
                              onChanged: (value) {
                                final current = role.permissions.toSet();
                                if (value ?? false) {
                                  current.add(permission);
                                } else {
                                  current.remove(permission);
                                }
                                context
                                    .read<PosLocalStore>()
                                    .updateStaffRolePermissions(
                                      role.id,
                                      current.toList(),
                                    );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        Container(height: 1, color: const Color(0xFFE7EAF0)),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.tr('Assigned Staff ({p0})', args: {'p0': assignedStaff.length}),
                                style: const TextStyle(
                                  color: Color(0xFF111111),
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showManageStaff(role),
                              child:  Text(
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
                            padding: EdgeInsets.all(14),
                            backgroundColor: Color(0xFFF7FAFF),
                            borderColor: Color(0xFFF3F4F6),
                            radius: 8,
                            child: Text(
                              context.tr('No staff assigned to this role yet.'),
                              style: TextStyle(
                                color: Color(0xFF5C667A),
                                fontSize: 13.5,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        else
                          ...assignedStaff.map(
                            (staff) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AssignedStaffTile(data: staff),
                            ),
                          ),
                        const SizedBox(height: 2),
                        const _PermissionNote(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }

  _PermissionData _permissionData(String label) {
    switch (label) {
      case 'View Sales':
        return const _PermissionData('View Sales', Icons.sell_outlined);
      case 'View Reports':
        return const _PermissionData(
            'View Reports', Icons.description_outlined);
      case 'Process Returns':
        return const _PermissionData(
          'Process Returns',
          Icons.shopping_cart_outlined,
        );
      case 'Discounts':
        return const _PermissionData('Discounts', Icons.local_offer_outlined);
      case 'Manage Inventory':
        return const _PermissionData(
          'Manage Inventory',
          Icons.inventory_2_outlined,
        );
      case 'Manage Staff':
        return const _PermissionData('Manage Staff', Icons.groups_outlined);
      case 'Manage Payments':
        return const _PermissionData(
          'Manage Payments',
          Icons.credit_card_outlined,
        );
      case 'System Settings':
        return const _PermissionData(
            'System Settings', Icons.settings_outlined);
      default:
        return _PermissionData(label, Icons.verified_user_outlined);
    }
  }
}

class _PermissionData {
  const _PermissionData(this.label, this.icon);

  final String label;
  final IconData icon;
}

// Re-using widgets from staff_management_page.dart
class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.data,
    required this.checked,
    required this.onChanged,
  });

  final _PermissionData data;
  final bool checked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(!checked),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(-3, -2),
            child: Checkbox(
              value: checked,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(color: Color(0xFFC5CAD3), width: 1.2),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 1),
          Icon(data.icon, color: const Color(0xFF818899), size: 22),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                data.label,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 14.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedStaffTile extends StatelessWidget {
  const _AssignedStaffTile({required this.data});

  final StaffMemberData data;

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColorForName(data.name);
    return MarketSurfaceCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      borderColor: const Color(0xFFF3F4F6),
      radius: 8,
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: avatarColor,
            child: Text(
              data.initials,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 15.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.email,
                  style: const TextStyle(
                    color: Color(0xFF717B8C),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.phone,
                  style: const TextStyle(
                    color: Color(0xFF8A93A7),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.more_vert_rounded,
            color: Color(0xFF7A8393),
          ),
        ],
      ),
    );
  }
}

class _PermissionNote extends StatelessWidget {
  const _PermissionNote();

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(14),
      backgroundColor: const Color(0xFFF7FAFF),
      borderColor: const Color(0xFFF3F4F6),
      radius: 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
           Expanded(
            child: Text(
              context.tr('Changes to permissions will apply to all staff assigned to this role.'),
              style: TextStyle(
                color: Color(0xFF5C667A),
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManageStaffSheet extends StatelessWidget {
  const _ManageStaffSheet({required this.role});

  final StaffRoleData role;

  Future<void> _showMoveDialog(
    BuildContext context,
    PosLocalStore store,
    StaffMemberData staff,
  ) async {
    final otherRoles =
        store.staffRoles.where((item) => item.id != role.id).toList();
    if (otherRoles.isEmpty) {
      showMarketNotice(
        context,
        title: context.tr('No Other Roles'),
        message: context.tr('Create another role before moving staff.'),
        type: MarketNoticeType.warning,
      );
      return;
    }

    var selectedRoleId = otherRoles.first.id;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:  Text(context.tr('Move Staff Member')),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButtonFormField<String>(
                initialValue: selectedRoleId,
                items: otherRoles
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item.id,
                        child: Text(item.title),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedRoleId = value;
                  });
                },
                decoration:  InputDecoration(labelText: context.tr('Target role')),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:  Text(context.tr('Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                await store.updateStaffMemberRole(staff.id, selectedRoleId);
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  showMarketNotice(
                    context,
                    title: context.tr('Staff Updated'),
                    message: context.tr('{p0} was moved to another role.', args: {'p0': staff.name}),
                  );
                }
              },
              child:  Text(context.tr('Move')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addStaff(BuildContext context) async {
    final store = context.read<PosLocalStore>();
    final result = await Navigator.of(context).push<StaffMemberData>(
      MaterialPageRoute<StaffMemberData>(
        builder: (context) => AddEditStaffPage(
          roles: store.staffRoles,
          initialRoleId: role.id,
        ),
      ),
    );
    if (result == null || !context.mounted) return;

    showMarketNotice(
      context,
      title: context.tr('Staff Added'),
      message: context.tr('{p0} was added to {p1}.title.', args: {'p0': result.name, 'p1': role}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final assignedStaff = store.staffMembersForRole(role.id);
    final otherStaff =
        store.staffMembers.where((staff) => staff.roleId != role.id).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr('{p0} Staff', args: {'p0': role.title}),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('Add staff members to this role or move existing staff between roles.'),
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF6B7280).withValues(alpha: 0.96),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addStaff(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label:  Text(context.tr('Add Staff to Role')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
               Text(
                context.tr('Assigned Staff'),
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 10),
              if (assignedStaff.isEmpty)
                 MarketSurfaceCard(
                  padding: EdgeInsets.all(16),
                  backgroundColor: Color(0xFFF8FAFD),
                  borderColor: Color(0xFFE4E8EF),
                  radius: 8,
                  child: Text(
                    context.tr('No staff assigned to this role yet.'),
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                )
              else
                ...assignedStaff.map(
                  (staff) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StaffMemberTile(
                      staff: staff,
                      onMove: () {
                        _showMoveDialog(context, store, staff);
                      },
                      onDelete: () async {
                        await store.deleteStaffMember(staff.id);
                        if (context.mounted) {
                          showMarketNotice(
                            context,
                            title: context.tr('Staff Removed'),
                            message: context.tr('{p0} was removed from staff.', args: {'p0': staff.name}),
                          );
                        }
                      },
                    ),
                  ),
                ),
              if (otherStaff.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  context.tr('Other Staff ({p0})', args: {'p0': otherStaff.length}),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 10),
                ...otherStaff.map(
                  (staff) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StaffMemberTile(
                      staff: staff,
                      onMove: () {
                        _showMoveDialog(context, store, staff);
                      },
                      onDelete: () async {
                        await store.deleteStaffMember(staff.id);
                        if (context.mounted) {
                          showMarketNotice(
                            context,
                            title: context.tr('Staff Removed'),
                            message: context.tr('{p0} was removed from staff.', args: {'p0': staff.name}),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StaffMemberTile extends StatelessWidget {
  const _StaffMemberTile({
    required this.staff,
    required this.onMove,
    required this.onDelete,
  });

  final StaffMemberData staff;
  final VoidCallback onMove;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColorForName(staff.name);
    return MarketSurfaceCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      borderColor: const Color(0xFFF3F4F6),
      radius: 8,
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: avatarColor,
            child: Text(
              staff.initials,
              style: const TextStyle(
                color: Color(0xFF111111),
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: const TextStyle(
                    color: Color(0xFF111111),
                    fontSize: 15.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  staff.email,
                  style: const TextStyle(
                    color: Color(0xFF717B8C),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  staff.phone,
                  style: const TextStyle(
                    color: Color(0xFF8A93A7),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFF7A8393),
            ),
            onSelected: (value) {
              if (value == 'move') {
                onMove();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) =>  [
              PopupMenuItem<String>(
                value: 'move',
                child: Text(context.tr('Move to another role')),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(context.tr('Remove staff')),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
