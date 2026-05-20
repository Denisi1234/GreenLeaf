import 'package:flutter/material.dart';
import 'dart:io';

import 'add_edit_staff_page.dart';
import '../widgets/market_shared_widgets.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  late final List<_UserItem> _users = [
    const _UserItem(
      fullName: 'Admin User',
      username: 'admin',
      role: 'Administrator',
      isActive: true,
      badgeBg: Color(0xFFE8F0FF),
      badgeText: Color(0xFF2B6FF3),
    ),
    const _UserItem(
      fullName: 'Jane Smith',
      username: 'janesmith',
      role: 'Cashier',
      isActive: true,
      badgeBg: Color(0xFFE6F8EF),
      badgeText: Color(0xFF1D8E63),
    ),
    const _UserItem(
      fullName: 'Michael Thomas',
      username: 'michaelthomas',
      role: 'Cashier',
      isActive: true,
      badgeBg: Color(0xFFFFF6D9),
      badgeText: Color(0xFFC99500),
    ),
    const _UserItem(
      fullName: 'Sarah Reyes',
      username: 'sarahreyes',
      role: 'Sales Associate',
      isActive: false,
      badgeBg: Color(0xFFF1E7FF),
      badgeText: Color(0xFF8A47D8),
    ),
    const _UserItem(
      fullName: 'David Wilson',
      username: 'davidwilson',
      role: 'Manager',
      isActive: true,
      badgeBg: Color(0xFFFFE9E9),
      badgeText: Color(0xFFD24B3F),
    ),
    const _UserItem(
      fullName: 'Lisa Martin',
      username: 'lisamartin',
      role: 'Cashier',
      isActive: true,
      badgeBg: Color(0xFFE8EEFF),
      badgeText: Color(0xFF2B6FF3),
    ),
    const _UserItem(
      fullName: 'Robert Brown',
      username: 'robertbrown',
      role: 'Sales Associate',
      isActive: false,
      badgeBg: Color(0xFFFFEDE2),
      badgeText: Color(0xFFE56D18),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: BackdropGlow()),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF202938),
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'User Management',
                          style: TextStyle(
                            color: Color(0xFF202938),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 108),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage system users and their access',
                          style: TextStyle(
                            color: Color(0xFF7B8494),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          children: [
                            Expanded(child: _UserSearchBar()),
                            SizedBox(width: 12),
                            _UsersFilterButton(),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Row(
                          children: [
                            Expanded(
                              child: _UsersChip(label: 'All Roles'),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _UsersChip(label: 'All Statuses'),
                            ),
                            SizedBox(width: 16),
                            Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFF2B6FF3),
                              size: 22,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Clear Filters',
                              style: TextStyle(
                                color: Color(0xFF2B6FF3),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ..._users.map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _UserCard(user: user),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 92,
              child: GestureDetector(
                onTap: () async {
                  final createdStaff =
                      await Navigator.of(context).push<StaffFormResult>(
                    MaterialPageRoute<StaffFormResult>(
                      builder: (context) => const AddEditStaffPage(),
                    ),
                  );

                  if (createdStaff != null && context.mounted) {
                    setState(() {
                      _users.insert(0, _UserItem.fromFormResult(createdStaff));
                    });
                    showMarketNotice(
                      context,
                      title: 'Staff Added',
                      message: '${createdStaff.fullName} is now in user management',
                    );
                  }
                },
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3C86FF), Color(0xFF2B6FF3)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x332B6FF3),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSearchBar extends StatelessWidget {
  const _UserSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE3E7ED)),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: Color(0xFF98A1AF), size: 30),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search users...',
              style: TextStyle(
                color: Color(0xFFB0B7C3),
                fontSize: 13.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersFilterButton extends StatelessWidget {
  const _UsersFilterButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE3E7ED)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_alt_outlined, color: Color(0xFF202938), size: 24),
          SizedBox(width: 10),
          Text(
            'Filter',
            style: TextStyle(
              color: Color(0xFF202938),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersChip extends StatelessWidget {
  const _UsersChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF5B6474),
                fontSize: 13.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF697180),
            size: 22,
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final _UserItem user;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        user.isActive ? const Color(0xFF2FA45B) : const Color(0xFFD79B12);
    final statusBg =
        user.isActive ? const Color(0xFFEAF8EE) : const Color(0xFFFFF6DD);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE7EBF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          user.avatarPath == null
              ? Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: user.badgeBg,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: Text(
                      user.initials,
                      style: TextStyle(
                        color: user.badgeText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              : Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    image: DecorationImage(
                      image: FileImage(File(user.avatarPath!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    color: Color(0xFF202938),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    color: Color(0xFF6F7887),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.role,
                  style: const TextStyle(
                    color: Color(0xFF97A0AF),
                    fontSize: 12.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  user.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.more_vert_rounded,
            color: Color(0xFF6F7887),
            size: 26,
          ),
        ],
      ),
    );
  }
}

class _UserItem {
  const _UserItem(
      {required this.fullName,
      required this.username,
      required this.role,
      required this.isActive,
      required this.badgeBg,
      required this.badgeText,
      this.avatarPath});

  factory _UserItem.fromFormResult(StaffFormResult result) {
    final trimmedName = result.fullName.trim();
    final username = trimmedName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final colors = _badgeColorsForRole(result.role);

    return _UserItem(
      fullName: trimmedName,
      username: username.isEmpty ? 'staff' : username,
      role: result.role,
      isActive: true,
      badgeBg: colors.$1,
      badgeText: colors.$2,
      avatarPath: result.avatarPath,
    );
  }

  final String fullName;
  final String username;
  final String role;
  final bool isActive;
  final Color badgeBg;
  final Color badgeText;
  final String? avatarPath;

  String get initials {
    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'ST';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  static (Color, Color) _badgeColorsForRole(String role) {
    switch (role) {
      case 'Administrator':
        return (const Color(0xFFE8F0FF), const Color(0xFF2B6FF3));
      case 'Manager':
        return (const Color(0xFFFFE9E9), const Color(0xFFD24B3F));
      case 'Cashier':
        return (const Color(0xFFE6F8EF), const Color(0xFF1D8E63));
      case 'Sales Associate':
        return (const Color(0xFFF1E7FF), const Color(0xFF8A47D8));
      default:
        return (const Color(0xFFE8EEFF), const Color(0xFF2B6FF3));
    }
  }
}
