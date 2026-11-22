import 'package:aza_pos/l10n/app_localization.dart';
import '../widgets/workspace_widgets.dart';

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
import 'widgets/staff_action_sheet.dart';
import 'widgets/staff_cards.dart';
import 'widgets/staff_filter_actions.dart';
import 'widgets/staff_kpi_metrics.dart';
import 'widgets/staff_models.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final _searchController = TextEditingController();
  StaffStatusFilter _statusFilter = StaffStatusFilter.all;
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
      StaffStatusFilter.all => result,
      StaffStatusFilter.active =>
        result.where((staff) => staff.status == StaffStatus.active),
      StaffStatusFilter.onLeave =>
        result.where((staff) => staff.status == StaffStatus.onLeave),
      StaffStatusFilter.inactive =>
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
      title: staffDual(strings, 'Staff Added', 'Mfanyakazi Amepangwa'),
      message: staffDual(
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
      title: staffDual(strings, 'Staff Updated', 'Mfanyakazi Amesasishwa'),
      message: staffDual(strings, '${saved.name} was updated successfully.',
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
      title: staffDual(strings, 'Status Updated', 'Hali Imesasishwa'),
      message: staffDual(
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
    final confirmed = await showMarketConfirmDialog(
      context,
      title: staffDual(strings, 'Remove staff member', 'Ondoa Mfanyakazi'),
      message: staffDual(
        strings,
        'Remove ${member.name} from this store? This cannot be undone.',
        'Ondoa ${member.name} kwenye duka hili? Hili haliwezi kutenduliwa.',
      ),
      confirmLabel: staffDual(strings, 'Remove', 'Ondoa'),
      cancelLabel: strings.cancel,
      isDestructive: true,
      icon: Icons.person_remove_outlined,
    );

    if (!confirmed || !mounted) return;
    await store.deleteStaffMember(member.id);
    if (!mounted) return;
    showMarketNotice(
      context,
      title: staffDual(strings, 'Staff Removed', 'Mfanyakazi Ameondolewa'),
      message: staffDual(strings, '${member.name} was removed from the team.',
          '${member.name} ameondolewa kwenye timu.'),
      type: MarketNoticeType.warning,
    );
  }

  void _showActions(PosLocalStore store, StaffMemberData member) {
    StaffActionSheet.show(
      context: context,
      store: store,
      member: member,
      onViewDetails: () => _openDetails(member),
      onEditStaff: () => _openEditStaff(store, member),
      onOpenRole: () => _openRole(store.staffRoleById(member.roleId)),
      onSetStatus: (status) => _setStatus(store, member, status),
      onDelete: () => _confirmDelete(store, member),
    );
  }

  void _openRole(StaffRoleData? role) {
    if (role == null) {
      final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
      showMarketNotice(
        context,
        title: staffDual(strings, 'Role Missing', 'Nafasi Inakosekana'),
        message: staffDual(strings, 'This staff member has no role assigned yet.',
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

  Future<void> _createRole(PosLocalStore store) async {
    final strings = AppStrings.of(store.languageCode);
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.standard),
        ),
        title: Text(staffDual(strings, 'New role', 'Nafasi mpya')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.pageBackground,
                  labelText: staffDual(strings, 'Role name', 'Jina la nafasi')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subtitleController,
              decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.pageBackground,
                  labelText:
                      staffDual(strings, 'Short description', 'Maelezo mafupi')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.surfaceSecondary,
              foregroundColor: AppColors.textBody,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: Text(
              strings.cancel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: Text(
              strings.create,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
            ? context.tr('Custom access role')
            : subtitleController.text.trim(),
        permissions: const <String>[],
        sortOrder: store.staffRoles.length,
      ),
    );
    titleController.dispose();
    subtitleController.dispose();
    if (!mounted) return;
    showMarketNotice(
      context,
      title: staffDual(strings, 'Role Created', 'Nafasi Imeundwa'),
      message: staffDual(
        strings,
        '${role.title} role created successfully.',
        'Nafasi ya ${role.title} imeundwa kwa mafanikio.',
      ),
      type: MarketNoticeType.success,
    );
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
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
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
                  subtitle: staffDual(
                      strings,
                      '$activeCount active · ${allStaff.length} total · ${store.staffRoles.length} roles',
                      '$activeCount hai · ${allStaff.length} jumla · ${store.staffRoles.length} nafasi'),
                  centerTitle: false,
                  showBorder: false,
                  actions: [
                    IconButton(
                      tooltip: staffDual(
                          strings, 'Roles and access', 'Nafasi na ruhusa'),
                      onPressed: () => StaffActionSheet.showRolesSheet(
                        context: context,
                        store: store,
                        onCreateRole: () => _createRole(store),
                        onOpenRole: _openRole,
                      ),
                      icon: Icon(
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
                      StaffKpiMetrics(
                        totalStaff: allStaff.length,
                        activeStaff: activeCount,
                        onLeaveStaff: onLeaveCount,
                        rolesCount: store.staffRoles.length,
                        isSwahili: strings.isSwahili,
                      ),
                      const SizedBox(height: 16),
                      MarketSearchField(
                        controller: _searchController,
                        hintText: staffDual(
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
                            ...StaffStatusFilter.values.map(
                              (filter) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: StaffChoicePill(
                                  label: filter.localized(strings),
                                  selected: _statusFilter == filter,
                                  onTap: () =>
                                      setState(() => _statusFilter = filter),
                                ),
                              ),
                            ),
                            StaffRoleFilterChip(
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
                            staffDual(strings, 'Staff Directory',
                                'Orodha ya Wafanyakazi'),
                            style: AppTypography.sectionHeader,
                          ),
                          const Spacer(),
                          Text(
                            staffDual(strings, '${staff.length} shown',
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
                        StaffEmptyState(
                          strings: strings,
                          hasFilters: _hasFilters,
                          onReset: _resetFilters,
                          onAdd: () => _openAddStaff(store),
                        )
                      else
                        WorkspaceRegister(
                          columns: [
                            DataColumn(
                                label: Text(staffDual(strings, 'Staff member',
                                    'Mfanyakazi'))),
                            DataColumn(
                                label: Text(
                                    staffDual(strings, 'Role', 'Jukumu'))),
                            DataColumn(
                                label: Text(
                                    staffDual(strings, 'Phone', 'Simu'))),
                            DataColumn(
                                label: Text(staffDual(
                                    strings, 'Email', 'Barua pepe'))),
                            DataColumn(
                                label: Text(
                                    staffDual(strings, 'Status', 'Hali'))),
                            const DataColumn(label: Text('')),
                          ],
                          rows: staff
                              .map(
                                (member) => DataRow(
                                  cells: [
                                    DataCell(
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: 220),
                                        child: Text(member.name,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                      onTap: () => _openDetails(member),
                                    ),
                                    DataCell(Text(store
                                            .staffRoleById(member.roleId)
                                            ?.title ??
                                        '—')),
                                    DataCell(Text(member.phone)),
                                    DataCell(Text(member.email)),
                                    DataCell(
                                      WorkspaceStatus(
                                        label: member.status
                                            .localized(strings.isSwahili),
                                        color: member.isActive
                                            ? AppColors.successDeep
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        tooltip: staffDual(
                                            strings,
                                            'Staff actions',
                                            'Vitendo vya mfanyakazi'),
                                        onPressed: () =>
                                            _showActions(store, member),
                                        icon: const Icon(
                                            Icons.more_horiz_rounded),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                          mobile: Column(
                            children: [
                              ...staff.map(
                                (member) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: StaffTile(
                                    strings: strings,
                                    member: member,
                                    role: store.staffRoleById(member.roleId),
                                    onTap: () => _openDetails(member),
                                    onMenu: () => _showActions(store, member),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasFilters =>
      _statusFilter != StaffStatusFilter.all ||
      _roleFilterId != null ||
      _searchQuery.trim().isNotEmpty;

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _statusFilter = StaffStatusFilter.all;
      _roleFilterId = null;
      _searchQuery = '';
    });
  }
}
