import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_edit_staff_page.dart';
import 'role_details_page.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  _StaffStatusFilter _statusFilter = _StaffStatusFilter.all;
  String _searchQuery = '';

  Future<void> _openAddStaff(BuildContext context, PosLocalStore store) async {
    final roles = store.staffRoles.map((role) => role.title).toList();
    final result = await Navigator.of(context).push<StaffFormResult>(
      MaterialPageRoute<StaffFormResult>(
        builder: (context) => AddEditStaffPage(availableRoles: roles),
      ),
    );

    if (!mounted || result == null) return;
    if (!context.mounted) return;

    final selectedRole = store.staffRoleByTitle(result.role);
    if (selectedRole == null) {
      showMarketNotice(
        context,
        title: 'Role Missing',
        message: 'The selected staff role no longer exists.',
        type: MarketNoticeType.warning,
      );
      return;
    }

    final emailHandle = result.fullName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'\.+'), '.')
        .replaceAll(RegExp(r'^\.|\.$'), '');
    final email =
        emailHandle.isEmpty ? 'staff@store.local' : '$emailHandle@store.local';

    await store.addStaffMember(
      name: result.fullName,
      email: email,
      phone: result.phone,
      roleId: selectedRole.id,
    );

    if (!mounted || !context.mounted) return;

    showMarketNotice(
      context,
      title: 'Staff Added',
      message: '${result.fullName} was added to ${selectedRole.title}.',
    );
  }

  Future<void> _openEditStaff(
    BuildContext context,
    PosLocalStore store,
    _StaffCardData staff,
  ) async {
    final member = store.staffMembers.firstWhere(
      (item) => item.id == staff.id,
      orElse: () => StaffMemberData(
        id: staff.id,
        name: staff.name,
        email: staff.email,
        phone: staff.phone,
        roleId: staff.roleId,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    final roles = store.staffRoles.map((role) => role.title).toList();
    final result = await Navigator.of(context).push<StaffFormResult>(
      MaterialPageRoute<StaffFormResult>(
        builder: (context) => AddEditStaffPage(
          staffId: member.id,
          availableRoles: roles,
          initialRole: store.staffRoleById(member.roleId)?.title,
          initialFullName: member.name,
          initialPhone: member.phone,
        ),
      ),
    );

    if (!context.mounted || result == null) return;

    final selectedRole = store.staffRoleByTitle(result.role);
    if (selectedRole == null) {
      showMarketNotice(
        context,
        title: 'Role Missing',
        message: 'The selected staff role no longer exists.',
        type: MarketNoticeType.warning,
      );
      return;
    }

    await store.saveStaffMember(
      member.copyWith(
        name: result.fullName,
        phone: result.phone,
        roleId: selectedRole.id,
      ),
    );

    if (!context.mounted) return;
    showMarketNotice(
      context,
      title: 'Staff Updated',
      message: '${result.fullName} was updated successfully.',
    );
  }

  Future<void> _openManageRoles(
    BuildContext context,
    PosLocalStore store,
    _StaffCardData staff,
  ) async {
    if (staff.roleId.isEmpty) {
      showMarketNotice(
        context,
        title: 'Role Missing',
        message: 'This staff member does not have a role assigned yet.',
        type: MarketNoticeType.warning,
      );
      return;
    }

    final role = store.staffRoleById(staff.roleId);
    if (role == null) {
      showMarketNotice(
        context,
        title: 'Role Missing',
        message: 'The selected staff role no longer exists.',
        type: MarketNoticeType.warning,
      );
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => RoleDetailsPage(roleId: role.id),
      ),
    );
  }

  Future<void> _openViewActivity(
    BuildContext context,
    PosLocalStore store,
    _StaffCardData staff,
  ) async {
    final member = store.staffMembers.firstWhere(
      (item) => item.id == staff.id,
      orElse: () => StaffMemberData(
        id: staff.id,
        name: staff.name,
        email: staff.email,
        phone: staff.phone,
        roleId: staff.roleId,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    final role = store.staffRoleById(member.roleId);

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => StaffActivityPage(
          staff: member,
          role: role,
        ),
      ),
    );
  }

  Future<void> _openSearchSheet(BuildContext context) async {
    final controller = TextEditingController(text: _searchQuery);

    final nextQuery = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Search staff',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      MarketSearchField(
                        controller: controller,
                        hintText: 'Search by name, role, email, or phone',
                        onChanged: (_) => setSheetState(() {}),
                        onClear: () {
                          controller.clear();
                          setSheetState(() {});
                        },
                        backgroundColor: const Color(0xFFF8FAFC),
                        borderColor: const Color(0xFFE5EAF2),
                        showShadow: false,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: MarketButton(
                              label: 'Cancel',
                              isPrimary: false,
                              onTap: () => Navigator.of(sheetContext).pop(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MarketButton(
                              label: 'Apply',
                              onTap: () {
                                Navigator.of(sheetContext)
                                    .pop(controller.text.trim());
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || nextQuery == null) return;
    setState(() => _searchQuery = nextQuery);
  }

  Future<void> _openFilterSheet(BuildContext context) async {
    final nextFilter = await showModalBottomSheet<_StaffStatusFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        var selected = _statusFilter;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Filter staff',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _StaffStatusFilter.values.map((item) {
                        final isSelected = item == selected;
                        return InkWell(
                          onTap: () {
                            setSheetState(() => selected = item);
                          },
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : const Color(0xFFF8FAFC),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.22)
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryDeep
                                    : AppColors.textMuted,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MarketButton(
                            label: 'Reset',
                            isPrimary: false,
                            onTap: () => Navigator.of(sheetContext)
                                .pop(_StaffStatusFilter.all),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MarketButton(
                            label: 'Apply',
                            onTap: () =>
                                Navigator.of(sheetContext).pop(selected),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || nextFilter == null) return;
    setState(() => _statusFilter = nextFilter);
  }

  Future<void> _showStaffActionsSheet(
    BuildContext context,
    _StaffCardData staff,
    PosLocalStore store,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final role = store.staffRoleById(staff.roleId);

        return DraggableScrollableSheet(
          initialChildSize: 0.42,
          minChildSize: 0.32,
          maxChildSize: 0.72,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: _avatarColorForName(staff.name),
                          child: Text(
                            staff.initials,
                            style: const TextStyle(
                              color: Color(0xFF24324A),
                              fontSize: 18,
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
                                  color: AppColors.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                role?.title ?? staff.role,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(sheetContext).pop(),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textMuted,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ActionCard(
                          icon: Icons.edit_outlined,
                          iconColor: AppColors.primary,
                          label: 'Edit Details',
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _openEditStaff(context, store, staff);
                          },
                        ),
                        _ActionCard(
                          icon: Icons.manage_accounts_outlined,
                          iconColor: const Color(0xFF6951D6),
                          label: 'Manage Roles',
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _openManageRoles(context, store, staff);
                          },
                        ),
                        _ActionCard(
                          icon: Icons.timeline_outlined,
                          iconColor: const Color(0xFF52A04D),
                          label: 'View Activity',
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _openViewActivity(context, store, staff);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<_StaffCardData> _buildStaffCards(PosLocalStore store) {
    final members = store.staffMembers;
    return members.asMap().entries.map((entry) {
      final index = entry.key;
      final member = entry.value;
      final role = store.staffRoleById(member.roleId);
      return _StaffCardData(
        id: member.id,
        name: member.name,
        roleId: member.roleId,
        role: role?.title ?? 'Staff Member',
        email: member.email,
        phone: member.phone,
        status: _statusForIndex(index),
        initials: member.initials,
      );
    }).toList();
  }

  List<_StaffCardData> _applyFilters(List<_StaffCardData> items) {
    Iterable<_StaffCardData> result = items;

    if (_statusFilter != _StaffStatusFilter.all) {
      result = result.where((item) => item.status == _statusFilter);
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.role.toLowerCase().contains(query) ||
            item.email.toLowerCase().contains(query) ||
            item.phone.toLowerCase().contains(query);
      });
    }

    return result.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final staffCards = _applyFilters(_buildStaffCards(store));
    final baseTheme = Theme.of(context);
    final manropeTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: manropeTheme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.white,
          centerTitle: false,
          titleSpacing: 20,
          title: const Text(
            'Staff Management',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => _openSearchSheet(context),
              tooltip: 'Search staff',
              icon: const Icon(
                Icons.search_rounded,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AddStaffBanner(
                      onTap: () => _openAddStaff(context, store),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Staff List',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _FilterButton(
                          onTap: () => _openFilterSheet(context),
                          label: _statusFilter.label,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (staffCards.isEmpty)
                      _EmptyStateCard(
                        hasFilters: _searchQuery.trim().isNotEmpty ||
                            _statusFilter != _StaffStatusFilter.all,
                        onAddTap: () => _openAddStaff(context, store),
                        onClearFilters: () {
                          setState(() {
                            _searchQuery = '';
                            _statusFilter = _StaffStatusFilter.all;
                          });
                        },
                      )
                    else
                      ...staffCards.map(
                        (staff) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StaffCard(
                            data: staff,
                            onTap: () => _showStaffActionsSheet(
                              context,
                              staff,
                              store,
                            ),
                          ),
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

class _AddStaffBanner extends StatelessWidget {
  const _AddStaffBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 140,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6FA8FF), Color(0xFF4F7EE8)],
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: Color(0xFF356FE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 62,
                  ),
                ),
                const SizedBox(width: 22),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Staff',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Create a new staff profile',
                        style: TextStyle(
                          color: Color(0xE6F5F8FF),
                          fontSize: 14.5,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5FA),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.filter_alt_outlined,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryDeep,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.data,
    required this.onTap,
  });

  final _StaffCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: MarketSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        borderColor: const Color(0xFFE7EBF2),
        radius: 16,
        backgroundColor: Colors.white,
        showShadow: false,
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: _avatarColorForName(data.name),
              child: Text(
                data.initials,
                style: const TextStyle(
                  color: Color(0xFF213045),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF7B8598),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFCFE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EAF0)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF475063),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.hasFilters,
    required this.onAddTap,
    required this.onClearFilters,
  });

  final bool hasFilters;
  final VoidCallback onAddTap;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final title = hasFilters ? 'No staff found' : 'No staff yet';
    final message = hasFilters
        ? 'Try another search or clear the current filter to see more staff.'
        : 'Add your first team member and they will show up here right away.';
    final actionLabel = hasFilters ? 'Clear Filters' : 'Add New Staff';
    final action = hasFilters ? onClearFilters : onAddTap;

    return MarketSurfaceCard(
      padding: const EdgeInsets.all(22),
      borderColor: const Color(0xFFE9EDF3),
      radius: 18,
      backgroundColor: Colors.white,
      showShadow: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              color: AppColors.primary,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13.8,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          MarketButton(
            label: actionLabel,
            onTap: action,
            isFullWidth: false,
            icon:
                hasFilters ? Icons.filter_list_off_rounded : Icons.add_rounded,
          ),
        ],
      ),
    );
  }
}

class StaffActivityPage extends StatelessWidget {
  const StaffActivityPage({
    super.key,
    required this.staff,
    required this.role,
  });

  final StaffMemberData staff;
  final StaffRoleData? role;

  @override
  Widget build(BuildContext context) {
    final joinedDate = _formatDate(staff.createdAt);
    final roleTitle = role?.title ?? 'No role assigned';
    final roleSubtitle =
        role?.subtitle ?? 'Assign a role to unlock permissions.';
    final permissionCount = role?.permissions.length ?? 0;
    final baseTheme = Theme.of(context);
    final manropeTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: manropeTheme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              const MarketPageHeader(
                title: 'Staff Activity',
                showBorder: false,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarketSurfaceCard(
                        padding: const EdgeInsets.all(18),
                        backgroundColor: Colors.white,
                        borderColor: const Color(0xFFE8EBF0),
                        radius: 18,
                        showShadow: false,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: _avatarColorForName(staff.name),
                              child: Text(
                                staff.initials,
                                style: const TextStyle(
                                  color: Color(0xFF213045),
                                  fontSize: 18,
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
                                      color: AppColors.ink,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    roleTitle,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    staff.email,
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Recent Activity',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActivityTile(
                        icon: Icons.person_add_alt_1_rounded,
                        iconColor: AppColors.primary,
                        iconBackground: AppColors.primaryLight,
                        title: 'Profile created',
                        subtitle: 'Added to the system on $joinedDate',
                      ),
                      const SizedBox(height: 10),
                      _ActivityTile(
                        icon: Icons.shield_outlined,
                        iconColor: const Color(0xFF6951D6),
                        iconBackground: const Color(0xFFF0EBFF),
                        title: 'Role assigned',
                        subtitle: '$roleTitle - $roleSubtitle',
                      ),
                      const SizedBox(height: 10),
                      _ActivityTile(
                        icon: Icons.security_outlined,
                        iconColor: const Color(0xFF52A04D),
                        iconBackground: const Color(0xFFEAF7F1),
                        title: 'Permission access',
                        subtitle: permissionCount == 0
                            ? 'No permissions assigned'
                            : '$permissionCount permissions available',
                      ),
                      const SizedBox(height: 10),
                      _ActivityTile(
                        icon: Icons.contact_page_outlined,
                        iconColor: const Color(0xFFF97316),
                        iconBackground: const Color(0xFFFFF3E8),
                        title: 'Contact details',
                        subtitle: 'Phone ${staff.phone}',
                      ),
                      const SizedBox(height: 18),
                      MarketButton(
                        label: 'Edit Staff Details',
                        onTap: () => Navigator.of(context).pop(),
                        icon: Icons.edit_outlined,
                      ),
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

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      borderColor: const Color(0xFFE8EBF0),
      radius: 16,
      showShadow: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(String dateString) {
  try {
    final date = DateTime.parse(dateString);
    const monthNames = <String>[
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
  } catch (_) {
    return dateString;
  }
}

class _StaffCardData {
  const _StaffCardData({
    required this.id,
    required this.name,
    required this.roleId,
    required this.role,
    required this.email,
    required this.phone,
    required this.status,
    required this.initials,
  });

  final String id;
  final String name;
  final String roleId;
  final String role;
  final String email;
  final String phone;
  final _StaffStatusFilter status;
  final String initials;

  _StaffCardData copyWith({
    String? id,
    String? name,
    String? roleId,
    String? role,
    String? email,
    String? phone,
    _StaffStatusFilter? status,
    String? initials,
  }) {
    return _StaffCardData(
      id: id ?? this.id,
      name: name ?? this.name,
      roleId: roleId ?? this.roleId,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      initials: initials ?? this.initials,
    );
  }
}

enum _StaffStatusFilter {
  all,
  active,
  away,
  inactive;

  String get label {
    switch (this) {
      case _StaffStatusFilter.all:
        return 'Filter';
      case _StaffStatusFilter.active:
        return 'Active';
      case _StaffStatusFilter.away:
        return 'Away';
      case _StaffStatusFilter.inactive:
        return 'Inactive';
    }
  }
}

_StaffStatusFilter _statusForIndex(int index) {
  switch (index % 3) {
    case 0:
      return _StaffStatusFilter.active;
    case 1:
      return _StaffStatusFilter.away;
    default:
      return _StaffStatusFilter.inactive;
  }
}

Color _avatarColorForName(String name) {
  const colors = <Color>[
    Color(0xFFF1D7CF),
    Color(0xFFD7E7F7),
    Color(0xFFDFF1D4),
    Color(0xFFFBE4D3),
    Color(0xFFE4E0FA),
  ];
  final index = name.hashCode.abs() % colors.length;
  return colors[index];
}
