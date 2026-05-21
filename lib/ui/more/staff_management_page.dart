import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_edit_staff_page.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  String? _expandedRoleId;

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

  void _toggleExpanded(String roleId) {
    setState(() {
      _expandedRoleId = _expandedRoleId == roleId ? null : roleId;
    });
  }

  void _showAddRole() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddRoleSheet(
        permissionCatalog: _permissionCatalog,
      ),
    );
  }

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
    final roles = store.staffRoles;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
              child: Row(
                children: [
                  _HeaderIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Staff Roles & Permissions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1F2A44),
                        fontSize: 21.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Text(
                'Manage roles, set permissions, and assign staff to control access across your POS.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF6B7280).withValues(alpha: 0.96),
                  fontSize: 14.8,
                  height: 1.38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: GestureDetector(
                onTap: _showAddRole,
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF356BD8), Color(0xFF2B5FCE)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22356BD8),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 29),
                      SizedBox(width: 12),
                      Text(
                        'Add New Role',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Column(
                  children: [
                    if (roles.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE1E5EC)),
                        ),
                        child: const Text(
                          'No roles available yet. Add a role to start managing permissions.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14.5,
                            height: 1.35,
                          ),
                        ),
                      )
                    else
                      for (var index = 0; index < roles.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RoleCard(
                            role: roles[index],
                            visual: _visualForRole(roles[index]),
                            isExpanded: _expandedRoleId == roles[index].id,
                            permissions: roles[index].permissions,
                            checkedPermissions:
                                roles[index].permissions.toSet(),
                            assignedStaff: store.staffMembersForRole(
                              roles[index].id,
                            ),
                            onToggle: () => _toggleExpanded(roles[index].id),
                            onPermissionChanged: (permission, value) {
                              final current = roles[index].permissions.toSet();
                              if (value) {
                                current.add(permission);
                              } else {
                                current.remove(permission);
                              }
                              context
                                  .read<PosLocalStore>()
                                  .updateStaffRolePermissions(
                                    roles[index].id,
                                    current.toList(),
                                  );
                            },
                            onManageStaff: () => _showManageStaff(roles[index]),
                          ),
                        ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StaffRoleVisual _visualForRole(StaffRoleData role) {
    switch (role.title.toLowerCase()) {
      case 'admin':
        return const _StaffRoleVisual(
          icon: Icons.workspace_premium_outlined,
          background: Color(0xFFEAF1FF),
          color: Color(0xFF2B4E93),
        );
      case 'manager':
        return const _StaffRoleVisual(
          icon: Icons.work_outline_rounded,
          background: Color(0xFFEAF7EE),
          color: Color(0xFF2D6B42),
        );
      case 'cashier':
        return const _StaffRoleVisual(
          icon: Icons.point_of_sale_outlined,
          background: Color(0xFFFFF4D9),
          color: Color(0xFF8D6A12),
        );
      default:
        return const _StaffRoleVisual(
          icon: Icons.groups_outlined,
          background: Color(0xFFEFEAFF),
          color: Color(0xFF5A4DB2),
        );
    }
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.visual,
    required this.isExpanded,
    required this.permissions,
    required this.checkedPermissions,
    required this.assignedStaff,
    required this.onToggle,
    required this.onPermissionChanged,
    required this.onManageStaff,
  });

  final StaffRoleData role;
  final _StaffRoleVisual visual;
  final bool isExpanded;
  final List<String> permissions;
  final Set<String> checkedPermissions;
  final List<StaffMemberData> assignedStaff;
  final VoidCallback onToggle;
  final void Function(String permission, bool value) onPermissionChanged;
  final VoidCallback onManageStaff;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E5EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: visual.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(visual.icon, color: visual.color, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.title,
                          style: const TextStyle(
                            color: Color(0xFF1F2A44),
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          role.subtitle,
                          style: const TextStyle(
                            color: Color(0xFF697385),
                            fontSize: 13.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: const Color(0xFF2A3650),
                    size: 31,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _ExpandedRoleContent(
              permissions: permissions,
              checkedPermissions: checkedPermissions,
              assignedStaff: assignedStaff,
              onPermissionChanged: onPermissionChanged,
              onManageStaff: onManageStaff,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _ExpandedRoleContent extends StatelessWidget {
  const _ExpandedRoleContent({
    required this.permissions,
    required this.checkedPermissions,
    required this.assignedStaff,
    required this.onPermissionChanged,
    required this.onManageStaff,
  });

  final List<String> permissions;
  final Set<String> checkedPermissions;
  final List<StaffMemberData> assignedStaff;
  final void Function(String permission, bool value) onPermissionChanged;
  final VoidCallback onManageStaff;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
            itemCount: permissions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 38,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final permission = permissions[index];
              return _PermissionTile(
                data: _permissionData(permission),
                checked: checkedPermissions.contains(permission),
                onChanged: (value) {
                  onPermissionChanged(permission, value ?? false);
                },
              );
            },
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: const Color(0xFFE7EAF0)),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Assigned Staff',
                  style: TextStyle(
                    color: Color(0xFF1F2A44),
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onManageStaff,
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
                'No staff assigned yet.',
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD9DEE8)),
          color: Colors.white.withValues(alpha: 0.92),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF1D2944),
          size: 24,
        ),
      ),
    );
  }
}

class _AddRoleSheet extends StatefulWidget {
  const _AddRoleSheet({required this.permissionCatalog});

  final List<String> permissionCatalog;

  @override
  State<_AddRoleSheet> createState() => _AddRoleSheetState();
}

class _AddRoleSheetState extends State<_AddRoleSheet> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final Set<String> _selectedPermissions = <String>{};
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _saveRole() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showMarketNotice(
        context,
        title: 'Role Required',
        message: 'Enter a role name before saving.',
        type: MarketNoticeType.warning,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    final store = context.read<PosLocalStore>();
    await store.saveStaffRole(
      StaffRoleData(
        id: 'role-${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        subtitle: _subtitleController.text.trim().isEmpty
            ? 'Custom role'
            : _subtitleController.text.trim(),
        permissions: _selectedPermissions.isEmpty
            ? widget.permissionCatalog.take(1).toList()
            : _selectedPermissions.toList(),
        sortOrder: store.staffRoles.length,
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    showMarketNotice(
      context,
      title: 'Role Saved',
      message: '$title was added to staff roles.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
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
              const Text(
                'Add New Role',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2A44),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Role Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _subtitleController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Permissions',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2A44),
                ),
              ),
              const SizedBox(height: 10),
              ...widget.permissionCatalog.map(
                (permission) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selectedPermissions.contains(permission),
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _selectedPermissions.add(permission);
                      } else {
                        _selectedPermissions.remove(permission);
                      }
                    });
                  },
                  title: Text(permission),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveRole,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2B5FCE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(_saving ? 'Saving...' : 'Save Role'),
                ),
              ),
            ],
          ),
        );
      },
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
                      onMove: () => _showMoveDialog(context, store, staff),
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
                      onMove: () => _showMoveDialog(context, store, staff),
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

class _StaffRoleVisual {
  const _StaffRoleVisual({
    required this.icon,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final Color background;
  final Color color;
}

class _PermissionData {
  const _PermissionData(this.label, this.icon);

  final String label;
  final IconData icon;
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
