import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/market_shared_widgets.dart';
import 'staff_members_page.dart'; // New import for StaffMembersPage
import 'role_details_page.dart'; // New import for RoleDetailsPage

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {

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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const StaffMembersPage(),
                    ),
                  );
                },
                child: Container(
                  height: 62,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFD9DEE8)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups_outlined,
                          color: Color(0xFF1D2944), size: 29),
                      SizedBox(width: 12),
                      Text(
                        'View All Staff',
                        style: TextStyle(
                          color: Color(0xFF1D2944),
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
                            assignedStaffCount:
                                store.staffMembersForRole(roles[index].id).length,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) =>
                                      RoleDetailsPage(roleId: roles[index].id),
                                ),
                              );
                            },
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
    required this.assignedStaffCount,
    required this.onTap,
  });

  final StaffRoleData role;
  final _StaffRoleVisual visual;
  final int assignedStaffCount;
  final VoidCallback onTap;

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
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
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
                      '${role.subtitle} • $assignedStaffCount Staff',
                      style: const TextStyle(
                        color: Color(0xFF697385),
                        fontSize: 13.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFF2A3650),
                size: 20,
              ),
            ],
          ),
        ),
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

class _AddRoleSheet extends StatefulWidget {
  const _AddRoleSheet({required this.permissionCatalog});

  final List<String> permissionCatalog;

  @override
  State<_AddRoleSheet> createState() => _AddRoleSheetState();
}

class _AddRoleSheetState extends State<_AddRoleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final Set<String> _selectedPermissions = <String>{};

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _saveRole() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPermissions.isEmpty) {
      showMarketNotice(
        context,
        title: 'Permissions Required',
        message: 'Select at least one permission for this role.',
        type: MarketNoticeType.warning,
      );
      return;
    }

    final store = context.read<PosLocalStore>();
    final role = StaffRoleData(
      id: 'role-${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      permissions: _selectedPermissions.toList(),
      sortOrder: store.staffRoles.length,
    );

    await store.saveStaffRole(role);
    if (!mounted) return;

    showMarketNotice(
      context,
      title: 'Role Created',
      message: '${role.title} has been added successfully.',
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
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
              const Text(
                'Add New Role',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2A44),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new staff role and assign permissions.',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF6B7280).withValues(alpha: 0.96),
                ),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Role Title',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2A44),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Role title is required';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'e.g., Supervisor',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2A44),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _subtitleController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: 'e.g., Oversees daily operations',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Permissions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2A44),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.permissionCatalog.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 38,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        final permission = widget.permissionCatalog[index];
                        final isSelected = _selectedPermissions.contains(permission);
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedPermissions.remove(permission);
                              } else {
                                _selectedPermissions.add(permission);
                              }
                            });
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Transform.translate(
                                offset: const Offset(-3, -2),
                                child: Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value ?? false) {
                                        _selectedPermissions.add(permission);
                                      } else {
                                        _selectedPermissions.remove(permission);
                                      }
                                    });
                                  },
                                  activeColor: const Color(0xFF2B5FCE),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: const BorderSide(
                                      color: Color(0xFFC5CAD3), width: 1.2),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                              const SizedBox(width: 1),
                              Icon(
                                _permissionIcon(permission),
                                color: const Color(0xFF818899),
                                size: 22,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: Text(
                                    permission,
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
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveRole,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B5FCE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Create Role',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _permissionIcon(String permission) {
    switch (permission) {
      case 'View Sales':
        return Icons.sell_outlined;
      case 'View Reports':
        return Icons.description_outlined;
      case 'Process Returns':
        return Icons.shopping_cart_outlined;
      case 'Discounts':
        return Icons.local_offer_outlined;
      case 'Manage Inventory':
        return Icons.inventory_2_outlined;
      case 'Manage Staff':
        return Icons.groups_outlined;
      case 'Manage Payments':
        return Icons.credit_card_outlined;
      case 'System Settings':
        return Icons.settings_outlined;
      default:
        return Icons.check_circle_outline;
    }
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
