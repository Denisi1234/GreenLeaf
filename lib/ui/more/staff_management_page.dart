import '../widgets/workspace_widgets.dart';
import '../widgets/app_image.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'add_edit_staff_page.dart';
import 'role_details_page.dart';
import 'staff_member_details_page.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final _searchController = TextEditingController();
  _StatusFilter _statusFilter = _StatusFilter.all;
  String? _roleFilterId;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StaffMemberData> _visibleStaff(PosLocalStore store) {
    Iterable<StaffMemberData> result = store.staffMembers;

    result = switch (_statusFilter) {
      _StatusFilter.all => result,
      _StatusFilter.active =>
        result.where((staff) => staff.status == StaffStatus.active),
      _StatusFilter.onLeave =>
        result.where((staff) => staff.status == StaffStatus.onLeave),
      _StatusFilter.inactive =>
        result.where((staff) => staff.status == StaffStatus.inactive),
    };

    final roleId = _roleFilterId;
    if (roleId != null) {
      result = result.where((staff) => staff.roleId == roleId);
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((staff) {
        return staff.name.toLowerCase().contains(query) ||
            staff.email.toLowerCase().contains(query) ||
            staff.phone.toLowerCase().contains(query) ||
            staff.username.toLowerCase().contains(query) ||
            staff.employeeNumber.toLowerCase().contains(query) ||
            staff.jobTitle.toLowerCase().contains(query) ||
            staff.department.toLowerCase().contains(query);
      });
    }

    final list = result.toList(growable: false);
    list.sort((a, b) {
      final rank = a.status.index.compareTo(b.status.index);
      if (rank != 0) return rank;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Future<void> _openAddStaff(PosLocalStore store) async {
    final saved = await Navigator.of(context).push<StaffMemberData>(
      MaterialPageRoute<StaffMemberData>(
        builder: (context) => AddEditStaffPage(roles: store.staffRoles),
      ),
    );
    if (!mounted || saved == null) return;
    final role = store.staffRoleById(saved.roleId);
    final strings = AppStrings.of(store.languageCode);
    showMarketNotice(
      context,
      title: _dual(strings, 'Staff Added', 'Mfanyakazi Amepangwa'),
      message: _dual(
          strings,
          '${saved.name} was added as ${role?.title ?? 'staff'}.',
          '${saved.name} ameongezwa kama ${role?.title ?? 'mfanyakazi'}.'),
    );
  }

  Future<void> _openEditStaff(
      PosLocalStore store, StaffMemberData member) async {
    final saved = await Navigator.of(context).push<StaffMemberData>(
      MaterialPageRoute<StaffMemberData>(
        builder: (context) => AddEditStaffPage(
          member: member,
          roles: store.staffRoles,
        ),
      ),
    );
    if (!mounted || saved == null) return;
    final strings = AppStrings.of(store.languageCode);
    showMarketNotice(
      context,
      title: _dual(strings, 'Staff Updated', 'Mfanyakazi Amesasishwa'),
      message: _dual(strings, '${saved.name} was updated successfully.',
          '${saved.name} amesasishwa kwa mafanikio.'),
    );
  }

  void _openDetails(StaffMemberData member) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => StaffMemberDetailsPage(staffId: member.id),
      ),
    );
  }

  Future<void> _setStatus(
    PosLocalStore store,
    StaffMemberData member,
    StaffStatus status,
  ) async {
    await store.setStaffStatus(member.id, status);
    if (!mounted) return;
    final strings = AppStrings.of(store.languageCode);
    showMarketNotice(
      context,
      title: _dual(strings, 'Status Updated', 'Hali Imesasishwa'),
      message: _dual(
          strings,
          '${member.name} is now ${status.label.toLowerCase()}.',
          '${member.name} sasa ni ${status.label.toLowerCase()}.'),
    );
  }

  Future<void> _confirmDelete(
    PosLocalStore store,
    StaffMemberData member,
  ) async {
    final strings = AppStrings.of(store.languageCode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_dual(strings, 'Remove staff member', 'Ondoa Mfanyakazi')),
        content: Text(
          _dual(
              strings,
              'Remove ${member.name} from this store? This cannot be undone.',
              'Ondoa ${member.name} kwenye duka hili? Hili haliwezi kutenduliwa.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(_dual(strings, 'Remove', 'Ondoa')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await store.deleteStaffMember(member.id);
    if (!mounted) return;
    showMarketNotice(
      context,
      title: _dual(strings, 'Staff Removed', 'Mfanyakazi Ameondolewa'),
      message: _dual(strings, '${member.name} was removed from the team.',
          '${member.name} ameondolewa kwenye timu.'),
      type: MarketNoticeType.warning,
    );
  }

  void _showActions(PosLocalStore store, StaffMemberData member) {
    final strings = AppStrings.of(store.languageCode);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final role = store.staffRoleById(member.roleId);
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.zero,
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StaffAvatar(member: member, radius: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: AppTypography.cardHeader,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${role?.title ?? 'No role'} · ${member.jobTitle.isEmpty ? member.status.label : member.jobTitle}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(status: member.status, strings: strings),
                  ],
                ),
                const SizedBox(height: 16),
                _SheetAction(
                  icon: Icons.badge_outlined,
                  label: _dual(
                      strings, 'View full profile', 'Tazama wasifu kamili'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openDetails(member);
                  },
                ),
                _SheetAction(
                  icon: Icons.edit_outlined,
                  label: _dual(strings, 'Edit staff details',
                      'Hariri maelezo ya mfanyakazi'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openEditStaff(store, member);
                  },
                ),
                _SheetAction(
                  icon: Icons.manage_accounts_outlined,
                  label: _dual(strings, 'Open assigned role',
                      'Fungua nafasi iliyopangwa'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openRole(role);
                  },
                ),
                const Divider(height: 24, color: AppColors.divider),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    _dual(strings, 'SET STATUS', 'WEKA HALI'),
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: StaffStatus.values.map((status) {
                    final selected = member.status == status;
                    return _ChoicePill(
                      label: status.localized(strings.isSwahili),
                      selected: selected,
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        if (!selected) _setStatus(store, member, status);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                _SheetAction(
                  icon: Icons.delete_outline_rounded,
                  label:
                      _dual(strings, 'Remove staff member', 'Ondoa mfanyakazi'),
                  isDestructive: true,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _confirmDelete(store, member);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openRole(StaffRoleData? role) {
    if (role == null) {
      final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
      showMarketNotice(
        context,
        title: _dual(strings, 'Role Missing', 'Nafasi Inakosekana'),
        message: _dual(strings, 'This staff member has no role assigned yet.',
            'Mfanyakazi huyu hana nafasi iliyopangwa bado.'),
        type: MarketNoticeType.warning,
      );
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => RoleDetailsPage(roleId: role.id),
      ),
    );
  }

  Future<void> _showRolesSheet(PosLocalStore store) async {
    final strings = AppStrings.of(store.languageCode);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.62,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, controller) {
            final roles = store.staffRoles;
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.zero,
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                _dual(strings, 'Roles & Access',
                                    'Nafasi na Ruhusa'),
                                style: AppTypography.h3),
                            const SizedBox(height: 2),
                            Text(
                              _dual(
                                  strings,
                                  'Permissions apply to every staff member in a role.',
                                  'Ruhusa zinatumika kwa kila mfanyakazi mwenye nafasi hiyo.'),
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _createRole(store);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                _dual(strings, 'New', 'Mpya'),
                                style: const TextStyle(
                                  color: AppColors.primaryDeep,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...roles.map(
                    (role) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RoleTile(
                        strings: strings,
                        role: role,
                        staffCount: store.staffMembersForRole(role.id).length,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _openRole(role);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createRole(PosLocalStore store) async {
    final strings = AppStrings.of(store.languageCode);
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_dual(strings, 'New role', 'Nafasi mpya')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                  labelText: _dual(strings, 'Role name', 'Jina la nafasi')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subtitleController,
              decoration: InputDecoration(
                  labelText:
                      _dual(strings, 'Short description', 'Maelezo mafupi')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(strings.create),
          ),
        ],
      ),
    );

    if (created != true || !mounted) {
      titleController.dispose();
      subtitleController.dispose();
      return;
    }

    final role = await store.saveStaffRole(
      StaffRoleData(
        id: 'role-${DateTime.now().millisecondsSinceEpoch}',
        title: titleController.text.trim(),
        subtitle: subtitleController.text.trim().isEmpty
            ? 'Custom access role'
            : subtitleController.text.trim(),
        permissions: const <String>[],
        sortOrder: store.staffRoles.length,
      ),
    );
    titleController.dispose();
    subtitleController.dispose();
    if (!mounted) return;
    _openRole(role);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final staff = _visibleStaff(store);
    final allStaff = store.staffMembers;
    final activeCount =
        allStaff.where((member) => member.status == StaffStatus.active).length;
    final onLeaveCount =
        allStaff.where((member) => member.status == StaffStatus.onLeave).length;
    final selectedRole =
        _roleFilterId == null ? null : store.staffRoleById(_roleFilterId!);
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
        floatingActionButton: Material(
          color: AppColors.primary,
          borderRadius: BorderRadius.zero,
          child: InkWell(
            borderRadius: BorderRadius.zero,
            splashColor: AppColors.primaryDeep.withValues(alpha: 0.3),
            highlightColor: Colors.transparent,
            onTap: () => _openAddStaff(store),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_alt_1_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    strings.addStaff,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: ManagementViewport(
            maxWidth: 1280,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  MarketPageHeader(
                    title: strings.staffManagementTitle,
                    subtitle: _dual(
                        strings,
                        '$activeCount active · ${allStaff.length} total · ${store.staffRoles.length} roles',
                        '$activeCount hai · ${allStaff.length} jumla · ${store.staffRoles.length} nafasi'),
                    centerTitle: false,
                    showBorder: false,
                    actions: [
                      IconButton(
                        tooltip: _dual(
                            strings, 'Roles and access', 'Nafasi na ruhusa'),
                        onPressed: () => _showRolesSheet(store),
                        icon: const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 96),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: _dual(strings, 'Total', 'Jumla'),
                                value: '${allStaff.length}',
                                icon: Icons.groups_2_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                label: _dual(strings, 'Active', 'Hai'),
                                value: '$activeCount',
                                icon: Icons.check_circle_outline_rounded,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                label: _dual(strings, 'On leave', 'Likizo'),
                                value: '$onLeaveCount',
                                icon: Icons.event_busy_outlined,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        MarketSearchField(
                          controller: _searchController,
                          hintText: _dual(
                              strings,
                              'Search name, role, phone, ID',
                              'Tafuta jina, nafasi, simu, kitambulisho'),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ..._StatusFilter.values.map(
                                (filter) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _ChoicePill(
                                    label: filter.localized(strings),
                                    selected: _statusFilter == filter,
                                    onTap: () =>
                                        setState(() => _statusFilter = filter),
                                  ),
                                ),
                              ),
                              _RoleFilterChip(
                                store: store,
                                selectedRole: selectedRole,
                                onSelected: (roleId) =>
                                    setState(() => _roleFilterId = roleId),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(
                              _dual(strings, 'Staff Directory',
                                  'Orodha ya Wafanyakazi'),
                              style: AppTypography.sectionHeader,
                            ),
                            const Spacer(),
                            Text(
                              _dual(strings, '${staff.length} shown',
                                  '${staff.length} wanaonyeshwa'),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (staff.isEmpty)
                          _EmptyState(
                            strings: strings,
                            hasFilters: _hasFilters,
                            onReset: _resetFilters,
                            onAdd: () => _openAddStaff(store),
                          )
                        else
                          WorkspaceRegister(
                              columns: [
                                DataColumn(
                                    label: Text(_dual(strings, 'Staff member',
                                        'Mfanyakazi'))),
                                DataColumn(
                                    label:
                                        Text(_dual(strings, 'Role', 'Jukumu'))),
                                DataColumn(
                                    label:
                                        Text(_dual(strings, 'Phone', 'Simu'))),
                                DataColumn(
                                    label: Text(
                                        _dual(strings, 'Email', 'Barua pepe'))),
                                DataColumn(
                                    label:
                                        Text(_dual(strings, 'Status', 'Hali'))),
                                const DataColumn(label: Text('')),
                              ],
                              rows: staff
                                  .map((member) => DataRow(cells: [
                                        DataCell(
                                            ConstrainedBox(
                                                constraints:
                                                    const BoxConstraints(
                                                        maxWidth: 220),
                                                child: Text(member.name,
                                                    overflow:
                                                        TextOverflow.ellipsis)),
                                            onTap: () => _openDetails(member)),
                                        DataCell(Text(store
                                                .staffRoleById(member.roleId)
                                                ?.title ??
                                            '—')),
                                        DataCell(Text(member.phone)),
                                        DataCell(Text(member.email)),
                                        DataCell(WorkspaceStatus(
                                            label: member.status
                                                .localized(strings.isSwahili),
                                            color: member.isActive
                                                ? AppColors.successDeep
                                                : AppColors.textMuted)),
                                        DataCell(IconButton(
                                            tooltip: _dual(
                                                strings,
                                                'Staff actions',
                                                'Vitendo vya mfanyakazi'),
                                            onPressed: () =>
                                                _showActions(store, member),
                                            icon: const Icon(
                                                Icons.more_horiz_rounded))),
                                      ]))
                                  .toList(),
                              mobile: Column(children: [
                                ...staff.map(
                                  (member) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _StaffTile(
                                      strings: strings,
                                      member: member,
                                      role: store.staffRoleById(member.roleId),
                                      onTap: () => _openDetails(member),
                                      onMenu: () => _showActions(store, member),
                                    ),
                                  ),
                                )
                              ])),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }

  bool get _hasFilters =>
      _statusFilter != _StatusFilter.all ||
      _roleFilterId != null ||
      _searchQuery.trim().isNotEmpty;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _statusFilter = _StatusFilter.all;
      _roleFilterId = null;
      _searchQuery = '';
    });
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      borderColor: const Color(0xFFD6E4F0),
      radius: 10,
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.h3.copyWith(fontSize: 22, letterSpacing: -0.4),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.helperText.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.strings,
    required this.member,
    required this.role,
    required this.onTap,
    required this.onMenu,
  });

  final AppStrings strings;
  final StaffMemberData member;
  final StaffRoleData? role;
  final VoidCallback onTap;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (member.jobTitle.isNotEmpty) member.jobTitle,
      if (member.department.isNotEmpty) member.department,
      if (member.jobTitle.isEmpty && member.department.isEmpty && role != null)
        role!.title,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: MarketSurfaceCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        borderColor: const Color(0xFFD6E4F0),
        radius: 10,
        showShadow: true,
        child: Row(
          children: [
            _StaffAvatar(member: member, radius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMain.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusPill(status: member.status, strings: strings),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle.isEmpty ? 'No role assigned' : subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (role != null) ...[
                        _MiniTag(label: role!.title),
                        const SizedBox(width: 6),
                      ],
                      if (member.employeeNumber.isNotEmpty)
                        _MiniTag(
                          label: '#${member.employeeNumber}',
                          muted: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onMenu,
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textMuted,
              ),
              tooltip: 'Staff actions',
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffAvatar extends StatelessWidget {
  const _StaffAvatar({required this.member, required this.radius});

  final StaffMemberData member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final path = member.avatarPath;
    return CircleAvatar(
      radius: radius,
      backgroundColor: _avatarColorForName(member.name),
      backgroundImage:
          path == null || path.isEmpty ? null : appImageProvider(context, path),
      child: path == null || path.isEmpty
          ? Text(
              member.initials,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.strings});

  final StaffStatus status;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      StaffStatus.active => AppColors.success,
      StaffStatus.onLeave => AppColors.warning,
      StaffStatus.inactive => AppColors.textMuted,
    };
    final background = switch (status) {
      StaffStatus.active => AppColors.successLight,
      StaffStatus.onLeave => AppColors.warningLight,
      StaffStatus.inactive => AppColors.surfaceSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.localized(strings.isSwahili),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: muted ? AppColors.textMuted : AppColors.primaryDeep,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({
    required this.store,
    required this.selectedRole,
    required this.onSelected,
  });

  final PosLocalStore store;
  final StaffRoleData? selectedRole;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(store.languageCode);
    final label =
        selectedRole?.title ?? _dual(strings, 'All roles', 'Nafasi zote');
    return PopupMenuButton<String>(
      tooltip: _dual(strings, 'Filter by role', 'Chuja kwa nafasi'),
      onSelected: (value) => onSelected(value == '__all__' ? null : value),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: '__all__',
          child: Text(_dual(strings, 'All roles', 'Nafasi zote')),
        ),
        ...store.staffRoles.map(
          (role) => PopupMenuItem<String>(
            value: role.id,
            child: Text(role.title),
          ),
        ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color:
              selectedRole == null ? AppColors.surface : AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selectedRole == null
                ? AppColors.border
                : AppColors.primary.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_outlined,
              size: 16,
              color: selectedRole == null
                  ? AppColors.textMuted
                  : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selectedRole == null
                    ? AppColors.textMuted
                    : AppColors.primaryDeep,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.28)
                : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primaryDeep : AppColors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.danger : AppColors.textMain;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.strings,
    required this.role,
    required this.staffCount,
    required this.onTap,
  });

  final AppStrings strings;
  final StaffRoleData role;
  final int staffCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: MarketSurfaceCard(
        padding: const EdgeInsets.all(14),
        borderColor: const Color(0xFFD6E4F0),
        radius: 10,
        showShadow: true,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.title,
                    style: AppTypography.bodyMain.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dual(
                        strings,
                        '${role.permissions.length} permissions · $staffCount staff',
                        '${role.permissions.length} ruhusa · $staffCount wafanyakazi'),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.strings,
    required this.hasFilters,
    required this.onReset,
    required this.onAdd,
  });

  final AppStrings strings;
  final bool hasFilters;
  final VoidCallback onReset;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return MarketSurfaceCard(
      padding: const EdgeInsets.all(24),
      borderColor: const Color(0xFFD6E4F0),
      radius: 10,
      showShadow: true,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.zero,
            ),
            child: Icon(
              hasFilters ? Icons.search_off_rounded : Icons.groups_2_outlined,
              color: AppColors.primary,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? _dual(strings, 'No staff found',
                    'Hakuna mfanyakazi aliyepatikana')
                : _dual(strings, 'No staff yet', 'Hakuna mfanyakazi bado'),
            style: AppTypography.cardHeader,
          ),
          const SizedBox(height: 6),
          Text(
            hasFilters
                ? _dual(
                    strings,
                    'Try a different search or clear the filters to see more staff.',
                    'Jaribu utafutaji mwingine au futa vichujio kuona wafanyakazi zaidi.')
                : _dual(
                    strings,
                    'Add your first team member to start assigning roles and access.',
                    'Ongeza mfanyakazi wako wa kwanza kuanza kupanga nafasi na ruhusa.'),
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          MarketButton(
            label: hasFilters
                ? _dual(strings, 'Clear filters', 'Futa vichujio')
                : _dual(strings, 'Add new staff', 'Ongeza mfanyakazi'),
            isFullWidth: false,
            icon:
                hasFilters ? Icons.filter_list_off_rounded : Icons.add_rounded,
            onTap: hasFilters ? onReset : onAdd,
          ),
        ],
      ),
    );
  }
}

enum _StatusFilter {
  all('All', 'Zote'),
  active('Active', 'Hai'),
  onLeave('On Leave', 'Likizo'),
  inactive('Inactive', 'Hafifu');

  const _StatusFilter(this.label, this.swahiliLabel);

  final String label;
  final String swahiliLabel;

  String localized(AppStrings strings) =>
      strings.isSwahili ? swahiliLabel : label;
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
