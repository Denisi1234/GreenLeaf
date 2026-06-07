import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_edit_staff_page.dart';

class RoleDetailsPage extends StatefulWidget {
  const RoleDetailsPage({super.key, required this.roleId});

  final String roleId;

  @override
  State<RoleDetailsPage> createState() => _RoleDetailsPageState();
}

class _RoleDetailsPageState extends State<RoleDetailsPage> {
  static const List<String> _permissionCatalog = <String>[
    'View Sales',
    'View Reports',
    'Process Returns',
    'Discounts',
    'Manage Inventory',
    'Manage Staff',
    'Manage Payments',
    'System Settings',
  ];

  Future<void> _showManageStaff(StaffRoleData role) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManageStaffSheet(role: role),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final role = store.staffRoleById(widget.roleId);

    if (role == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Role Not Found')),
        body: const Center(child: Text('The selected role does not exist.')),
      );
    }

    final assignedStaff = store.staffMembersForRole(role.id);
    final checkedPermissions = role.permissions.toSet();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            MarketPageHeader(
              title: role.title,
              subtitle: role.subtitle,
              showBorder: false,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text(
                        'Permissions',
                        style: TextStyle(
                          color: Color(0xFF1F2A44),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _permissionCatalog.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 38,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        final permission = _permissionCatalog[index];
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
                            'Assigned Staff (${assignedStaff.length})',
                            style: const TextStyle(
                              color: Color(0xFF1F2A44),
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showManageStaff(role),
                          child: const Text(
                            'Manage',
                            style: TextStyle(
                              color: Color(0xFF2B5FCE),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (assignedStaff.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE4EBF7)),
                        ),
                        child: const Text(
                          'No staff assigned to this role yet.',
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
      ),
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
      default:
        return const _PermissionData(
            'System Settings', Icons.settings_outlined);
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
              activeColor: const Color(0xFF2B5FCE),
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
                  color: Color(0xFF2A3144),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: avatarColor,
            child: Text(
              data.initials,
              style: const TextStyle(
                color: Color(0xFF1F2A44),
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
                    color: Color(0xFF1F2A44),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4EBF7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF2B5FCE),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Changes to permissions will apply to all staff assigned to this role.',
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
        title: 'No Other Roles',
        message: 'Create another role before moving staff.',
        type: MarketNoticeType.warning,
      );
      return;
    }

    var selectedRoleId = otherRoles.first.id;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Move Staff Member'),
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
                decoration: const InputDecoration(labelText: 'Target role'),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await store.updateStaffMemberRole(staff.id, selectedRoleId);
                if (context.mounted) {
                  Navigator.of(dialogContext).pop();
                  showMarketNotice(
                    context,
                    title: 'Staff Updated',
                    message: '${staff.name} was moved to another role.',
                  );
                }
              },
              child: const Text('Move'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addStaff(BuildContext context) async {
    final store = context.read<PosLocalStore>();
    final result = await Navigator.of(context).push<StaffFormResult>(
      MaterialPageRoute<StaffFormResult>(
        builder: (context) => AddEditStaffPage(
          availableRoles: store.staffRoles.map((role) => role.title).toList(),
          initialRole: role.title,
        ),
      ),
    );
    if (result == null || !context.mounted) return;

    final selectedRole = store.staffRoleByTitle(result.role);
    if (selectedRole == null) {
      showMarketNotice(
        context,
        title: 'Role Missing',
        message: 'The selected role no longer exists.',
        type: MarketNoticeType.warning,
      );
      return;
    }

    await store.addStaffMember(
      name: result.fullName,
      email:
          '${result.fullName.toLowerCase().replaceAll(' ', '.')}@example.com',
      phone: result.phone,
      roleId: selectedRole.id,
    );
    if (!context.mounted) return;
    showMarketNotice(
      context,
      title: 'Staff Added',
      message: '${result.fullName} was added to ${selectedRole.title}.',
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
                    color: const Color(0xFFD9DEE8),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${role.title} Staff',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2A44),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add staff members to this role or move existing staff between roles.',
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
                  label: const Text('Add Staff to Role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B5FCE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Assigned Staff',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2A44),
                ),
              ),
              const SizedBox(height: 10),
              if (assignedStaff.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE4E8EF)),
                  ),
                  child: const Text(
                    'No staff assigned to this role yet.',
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
                            title: 'Staff Removed',
                            message: '${staff.name} was removed from staff.',
                          );
                        }
                      },
                    ),
                  ),
                ),
              if (otherStaff.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Other Staff (${otherStaff.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2A44),
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
                            title: 'Staff Removed',
                            message: '${staff.name} was removed from staff.',
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
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: avatarColor,
            child: Text(
              staff.initials,
              style: const TextStyle(
                color: Color(0xFF1F2A44),
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
                    color: Color(0xFF1F2A44),
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
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'move',
                child: Text('Move to another role'),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text('Remove staff'),
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
    Color(0xFFD9E8F7),
    Color(0xFFE5F4D8),
    Color(0xFFFDE8D7),
    Color(0xFFE7E2FB),
  ];
  final index = name.hashCode.abs() % colors.length;
  return colors[index];
}
