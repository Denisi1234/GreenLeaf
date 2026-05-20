import 'package:flutter/material.dart';

import 'add_edit_staff_page.dart';
import '../widgets/market_shared_widgets.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  static const _roles = <_StaffRoleCardData>[
    _StaffRoleCardData(
      title: 'Admin',
      subtitle: 'Super full access',
      icon: Icons.workspace_premium_outlined,
      iconBackground: Color(0xFFEAF1FF),
      iconColor: Color(0xFF2B4E93),
    ),
    _StaffRoleCardData(
      title: 'Manager',
      subtitle: 'Store management access',
      icon: Icons.work_outline_rounded,
      iconBackground: Color(0xFFEAF7EE),
      iconColor: Color(0xFF2D6B42),
    ),
    _StaffRoleCardData(
      title: 'Cashier',
      subtitle: 'Limited access for front counter',
      icon: Icons.point_of_sale_outlined,
      iconBackground: Color(0xFFFFF4D9),
      iconColor: Color(0xFF8D6A12),
    ),
  ];

  static const _permissions = <_PermissionData>[
    _PermissionData('View Sales', Icons.sell_outlined),
    _PermissionData('View Reports', Icons.description_outlined),
    _PermissionData('Process Returns', Icons.shopping_cart_outlined),
    _PermissionData('Discounts', Icons.local_offer_outlined),
    _PermissionData('Manage Inventory', Icons.inventory_2_outlined),
    _PermissionData('Manage Staff', Icons.groups_outlined),
    _PermissionData('Manage Payments', Icons.credit_card_outlined),
    _PermissionData('System Settings', Icons.settings_outlined),
  ];

  static const _assignedStaff = <_AssignedStaffData>[
    _AssignedStaffData(
      name: 'Emma Johnson',
      email: 'emma.johnson@example.com',
      initials: 'EJ',
      avatarBackground: Color(0xFFF2D9D2),
    ),
    _AssignedStaffData(
      name: 'Liam Smith',
      email: 'liam.smith@example.com',
      initials: 'LS',
      avatarBackground: Color(0xFFD9E8F7),
    ),
  ];

  late final List<bool> _checkedPermissions = List<bool>.filled(
    _permissions.length,
    false,
  );

  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _checkedPermissions[0] = true;
    _checkedPermissions[1] = true;
    _checkedPermissions[2] = true;
    _checkedPermissions[4] = true;
  }

  void _toggleExpanded(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? -1 : index;
    });
  }

  void _showAddRole() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const AddEditStaffPage(),
      ),
    );
  }

  void _showManageStaff() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Staff',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2A44),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select staff members to assign to this role:',
              style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            _StaffAssignmentTile(
              name: 'Emma Johnson',
              email: 'emma.johnson@example.com',
              assigned: true,
            ),
            _StaffAssignmentTile(
              name: 'Liam Smith',
              email: 'liam.smith@example.com',
              assigned: true,
            ),
            _StaffAssignmentTile(
              name: 'Noah Williams',
              email: 'noah.williams@example.com',
              assigned: false,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B5FCE),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Update Assignments',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    for (var index = 0; index < _roles.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RoleCard(
                          data: _roles[index],
                          isExpanded: _expandedIndex == index,
                          permissions: _permissions,
                          checkedPermissions: _checkedPermissions,
                          assignedStaff: _assignedStaff,
                          onToggle: () => _toggleExpanded(index),
                          onPermissionChanged: (permissionIndex, value) {
                            setState(() {
                              _checkedPermissions[permissionIndex] = value;
                            });
                          },
                          onManageStaff: _showManageStaff,
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
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.data,
    required this.isExpanded,
    required this.permissions,
    required this.checkedPermissions,
    required this.assignedStaff,
    required this.onToggle,
    required this.onPermissionChanged,
    required this.onManageStaff,
  });

  final _StaffRoleCardData data;
  final bool isExpanded;
  final List<_PermissionData> permissions;
  final List<bool> checkedPermissions;
  final List<_AssignedStaffData> assignedStaff;
  final VoidCallback onToggle;
  final void Function(int permissionIndex, bool value) onPermissionChanged;
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
                      color: data.iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      data.icon,
                      color: data.iconColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: const TextStyle(
                            color: Color(0xFF1F2A44),
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.subtitle,
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

  final List<_PermissionData> permissions;
  final List<bool> checkedPermissions;
  final List<_AssignedStaffData> assignedStaff;
  final void Function(int permissionIndex, bool value) onPermissionChanged;
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
              return _PermissionTile(
                data: permissions[index],
                checked: checkedPermissions[index],
                onChanged: (value) {
                  onPermissionChanged(index, value ?? false);
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
                  'Assigned Staff (2)',
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

  final _AssignedStaffData data;

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: data.avatarBackground,
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

class _StaffRoleCardData {
  const _StaffRoleCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
}

class _PermissionData {
  const _PermissionData(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _AssignedStaffData {
  const _AssignedStaffData({
    required this.name,
    required this.email,
    required this.initials,
    required this.avatarBackground,
  });

  final String name;
  final String email;
  final String initials;
  final Color avatarBackground;
}

class _StaffAssignmentTile extends StatefulWidget {
  const _StaffAssignmentTile({
    required this.name,
    required this.email,
    required this.assigned,
  });

  final String name;
  final String email;
  final bool assigned;

  @override
  State<_StaffAssignmentTile> createState() => _StaffAssignmentTileState();
}

class _StaffAssignmentTileState extends State<_StaffAssignmentTile> {
  late bool _assigned = widget.assigned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2A44),
                  ),
                ),
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _assigned,
            onChanged: (value) => setState(() => _assigned = value),
            activeColor: const Color(0xFF2B5FCE),
          ),
        ],
      ),
    );
  }
}
