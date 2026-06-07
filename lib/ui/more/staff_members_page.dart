import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../service/pos_local_store.dart';
import '../widgets/market_shared_widgets.dart';
import 'staff_member_details_page.dart';

class StaffMembersPage extends StatelessWidget {
  const StaffMembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final staffMembers = store.staffMembers;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const MarketPageHeader(
              title: 'All Staff Members',
              subtitle: 'View and manage all staff members across different roles.',
              showBorder: false,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Column(
                  children: [
                    if (staffMembers.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE1E5EC)),
                        ),
                        child: const Text(
                          'No staff members added yet.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14.5,
                            height: 1.35,
                          ),
                        ),
                      )
                    else
                      ...staffMembers.map(
                        (staff) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StaffMemberTile(
                            staff: staff,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => StaffMemberDetailsPage(
                                    staffId: staff.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
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
}

class _StaffMemberTile extends StatelessWidget {
  const _StaffMemberTile({
    required this.staff,
    required this.onTap,
  });

  final StaffMemberData staff;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColorForName(staff.name);
    final store = context.read<PosLocalStore>();
    final role = store.staffRoleById(staff.roleId);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
                  if (role != null)
                    Text(
                      role.title,
                      style: const TextStyle(
                        color: Color(0xFF717B8C),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    staff.email,
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
              Icons.arrow_forward_ios_rounded,
              color: Color(0xFF7A8393),
              size: 18,
            ),
          ],
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

