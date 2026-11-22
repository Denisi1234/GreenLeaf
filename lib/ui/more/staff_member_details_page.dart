import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:aza_pos/l10n/app_localization.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import '../widgets/workspace_widgets.dart';
import 'add_edit_staff_page.dart';
import 'role_details_page.dart';
import 'widgets/staff_details_sections.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

String _formatDate(String isoString) {
  if (isoString.isEmpty) return '—';
  try {
    final parsed = DateTime.parse(isoString).toLocal();
    final months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  } catch (_) {
    return isoString;
  }
}

class StaffMemberDetailsPage extends StatelessWidget {
  const StaffMemberDetailsPage({super.key, required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    StaffMemberData? selected;
    for (final item in store.staffMembers) {
      if (item.id == staffId) {
        selected = item;
        break;
      }
    }

    final baseTheme = Theme.of(context);
    final manropeTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    if (selected == null) {
      return Theme(
        data: manropeTheme,
        child: Scaffold(
          backgroundColor: AppColors.pageBackground,
          body: ManagementViewport(
            maxWidth: 1280,
            child: SafeArea(
              child: Column(
                children: [
                  MarketPageHeader(
                    title: _dual(strings, 'Staff Profile', 'Wasifu wa Mfanyakazi'),
                    centerTitle: false,
                    showBorder: false,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _dual(strings, 'This staff member no longer exists.', 'Mfanyakazi huyu hayupo tena.'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final member = selected;
    final role = store.staffRoleById(member.roleId);

    return Theme(
      data: manropeTheme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: ManagementViewport(
          maxWidth: 1280,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                MarketPageHeader(
                  title: _dual(strings, 'Staff Profile', 'Wasifu wa Mfanyakazi'),
                  subtitle: member.name,
                  centerTitle: false,
                  showBorder: false,
                  actions: [
                    IconButton(
                      tooltip: _dual(strings, 'Edit staff', 'Hariri mfanyakazi'),
                      onPressed: () => _openEdit(context, store, member),
                      icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
                    ),
                    IconButton(
                      tooltip: _dual(strings, 'Role and permissions', 'Nafasi na ruhusa'),
                      onPressed: () => _openRole(context, role, strings),
                      icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.ink),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
                    children: [
                      StaffProfileHero(member: member, role: role, strings: strings),
                      const SizedBox(height: 14),
                      StaffInfoSection(
                        title: context.tr('Contact Information'),
                        rows: [
                          StaffInfoRowData(
                            label: context.tr('Phone'),
                            value: member.phone.isEmpty ? '—' : member.phone,
                            icon: Icons.phone_outlined,
                          ),
                          StaffInfoRowData(
                            label: context.tr('Email'),
                            value: member.email.isEmpty ? '—' : member.email,
                            icon: Icons.mail_outline_rounded,
                          ),
                          StaffInfoRowData(
                            label: context.tr('Address'),
                            value: member.address.isEmpty ? '—' : member.address,
                            icon: Icons.location_on_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      StaffInfoSection(
                        title: context.tr('Employment Details'),
                        rows: [
                          StaffInfoRowData(
                            label: context.tr('Employee ID'),
                            value: member.employeeNumber.isEmpty ? '—' : member.employeeNumber,
                            icon: Icons.badge_outlined,
                          ),
                          StaffInfoRowData(
                            label: context.tr('Job Title'),
                            value: member.jobTitle.isEmpty ? '—' : member.jobTitle,
                            icon: Icons.work_outline_rounded,
                          ),
                          StaffInfoRowData(
                            label: context.tr('Department'),
                            value: member.department.isEmpty ? '—' : member.department,
                            icon: Icons.apartment_outlined,
                          ),
                          StaffInfoRowData(
                            label: context.tr('Hire Date'),
                            value: _formatDate(member.hireDate),
                            icon: Icons.event_available_outlined,
                          ),
                          StaffInfoRowData(
                            label: context.tr('Employment Type'),
                            value: member.employmentType.isEmpty
                                ? context.tr('Full-time')
                                : context.tr(EmploymentType.fromValue(member.employmentType)?.label ?? 'Full-time'),
                            icon: Icons.schedule_rounded,
                          ),
                          StaffInfoRowData(
                            label: context.tr('Hourly Rate'),
                            value: member.hourlyRate <= 0
                                ? '—'
                                : 'TSh ${member.hourlyRate.toStringAsFixed(0)}',
                            icon: Icons.payments_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      StaffInfoSection(
                        title: context.tr('Emergency Contact'),
                        rows: [
                          StaffInfoRowData(
                            label: context.tr('Contact Name'),
                            value: member.emergencyContactName.isEmpty ? '—' : member.emergencyContactName,
                            icon: Icons.person_outline_rounded,
                          ),
                          StaffInfoRowData(
                            label: context.tr('Contact Phone'),
                            value: member.emergencyContactPhone.isEmpty ? '—' : member.emergencyContactPhone,
                            icon: Icons.call_outlined,
                          ),
                          StaffInfoRowData(
                            label: context.tr('Relationship'),
                            value: member.emergencyContactRelation.isEmpty ? '—' : member.emergencyContactRelation,
                            icon: Icons.people_outline_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      StaffAccessSection(
                        role: role,
                        allPermissions: store.staffPermissionCatalog,
                      ),
                      const SizedBox(height: 14),
                      StaffInfoSection(
                        title: context.tr('Account & History'),
                        rows: [
                          StaffInfoRowData(
                            label: context.tr('Joined'),
                            value: _formatDate(member.createdAt),
                            icon: Icons.login_rounded,
                          ),
                          StaffInfoRowData(
                            label: context.tr('Last updated'),
                            value: member.updatedAt.isEmpty
                                ? _formatDate(member.createdAt)
                                : _formatDate(member.updatedAt),
                            icon: Icons.update_rounded,
                          ),
                          StaffInfoRowData(
                            label: context.tr('Staff ID'),
                            value: member.id,
                            icon: Icons.fingerprint_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      MarketButton(
                        label: _dual(strings, 'Edit Staff Profile', 'Hariri Wasifu wa Mfanyakazi'),
                        icon: Icons.edit_outlined,
                        radius: 0,
                        onTap: () => _openEdit(context, store, member),
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

  static void _openRole(BuildContext context, StaffRoleData? role, AppStrings strings) {
    if (role == null) {
      showMarketNotice(
        context,
        title: _dual(strings, 'Role Missing', 'Nafasi Inakosekana'),
        message: _dual(strings, 'This staff member has no assigned role.', 'Mfanyakazi huyu hana nafasi iliyopangwa.'),
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

  static Future<void> _openEdit(BuildContext context, PosLocalStore store, StaffMemberData member) async {
    final saved = await Navigator.of(context).push<StaffMemberData>(
      MaterialPageRoute<StaffMemberData>(
        builder: (context) => AddEditStaffPage(
          member: member,
          roles: store.staffRoles,
        ),
      ),
    );
    if (saved == null || !context.mounted) return;
    showMarketNotice(
      context,
      title: context.tr('Staff Updated'),
      message: context.tr('{p0} was updated successfully.', args: {'p0': saved.name}),
    );
  }
}
