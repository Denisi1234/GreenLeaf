import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';

class StaffMemberDetailsPage extends StatelessWidget {
  const StaffMemberDetailsPage({super.key, required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final staff = store.staffMembers.firstWhere(
      (member) => member.id == staffId,
      orElse: () => throw Exception('Staff member not found'),
    );
    final role = store.staffRoleById(staff.roleId);

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
                      'Staff Details',
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  children: [
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: _avatarColorForName(staff.name),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                staff.initials,
                                style: const TextStyle(
                                  color: Color(0xFF1F2A44),
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      staff.name,
                      style: const TextStyle(
                        color: Color(0xFF1F2A44),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (role != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role.title,
                          style: const TextStyle(
                            color: Color(0xFF2B5FCE),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                    _DetailSection(
                      title: 'Contact Information',
                      children: [
                        _DetailRow(
                          label: 'Email',
                          value: staff.email,
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Phone',
                          value: staff.phone,
                          icon: Icons.phone_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _DetailSection(
                      title: 'Role Information',
                      children: [
                        if (role != null) ...[
                          _DetailRow(
                            label: 'Role',
                            value: role.title,
                            icon: Icons.shield_outlined,
                          ),
                          const SizedBox(height: 16),
                          _DetailRow(
                            label: 'Description',
                            value: role.subtitle,
                            icon: Icons.description_outlined,
                          ),
                          const SizedBox(height: 16),
                          _DetailRow(
                            label: 'Permissions',
                            value: '${role.permissions.length} permissions assigned',
                            icon: Icons.security_outlined,
                          ),
                        ] else
                          const _DetailRow(
                            label: 'Role',
                            value: 'No role assigned',
                            icon: Icons.error_outline,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _DetailSection(
                      title: 'System Information',
                      children: [
                        _DetailRow(
                          label: 'Staff ID',
                          value: staff.id,
                          icon: Icons.fingerprint_outlined,
                        ),
                        const SizedBox(height: 16),
                        _DetailRow(
                          label: 'Joined Date',
                          value: _formatDate(staff.createdAt),
                          icon: Icons.calendar_today_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final monthNames = <String>[
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
      return '${monthNames[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E5EC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1F2A44),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2B5FCE),
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1F2A44),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
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
