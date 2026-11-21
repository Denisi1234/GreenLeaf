import 'package:flutter/material.dart';
import 'package:track_mauzo/l10n/app_localization.dart';
import '../../../service/models/staff_models.dart';

import '../../widgets/app_design.dart';
import '../../widgets/app_image.dart';
import 'staff_form_widgets.dart';

class StaffBasicInfoTab extends StatelessWidget {
  const StaffBasicInfoTab({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    required this.addressController,
    required this.notesController,
    required this.avatarPath,
    required this.status,
    required this.errors,
    required this.onPickAvatar,
    required this.onClearError,
    required this.onStatusChanged,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController notesController;
  final String? avatarPath;
  final StaffStatus status;
  final Map<String, String> errors;
  final VoidCallback onPickAvatar;
  final ValueChanged<String> onClearError;
  final ValueChanged<StaffStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: onPickAvatar,
                child: Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                    image: avatarPath == null
                        ? null
                        : DecorationImage(
                            image: appImageProvider(context, avatarPath!),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: avatarPath == null
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 50,
                        )
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 4,
                child: GestureDetector(
                  onTap: onPickAvatar,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        StaffFormSection(
          title: context.tr('Personal Information'),
          description: context.tr('Core contact details used across the POS.'),
          children: [
            StaffAppTextField(
              controller: nameController,
              label: context.tr('Full name'),
              hint: context.tr('e.g. Amina Joseph'),
              icon: Icons.person_outline_rounded,
              errorText: errors['name'],
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => onClearError('name'),
            ),
            StaffAppTextField(
              controller: phoneController,
              label: context.tr('Phone number'),
              hint: 'e.g. +255 712 345 678',
              icon: Icons.call_outlined,
              keyboardType: TextInputType.phone,
              errorText: errors['phone'],
              onChanged: (_) => onClearError('phone'),
            ),
            StaffAppTextField(
              controller: emailController,
              label: context.tr('Email (optional)'),
              hint: context.tr('staff@store.co.tz'),
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              errorText: errors['email'],
              onChanged: (_) => onClearError('email'),
            ),
            StaffAppTextField(
              controller: addressController,
              label: context.tr('Address (optional)'),
              hint: context.tr('Street, city'),
              icon: Icons.location_on_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 4),
            const StaffFieldLabel('Account status'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: StaffStatus.values.map((s) {
                return StaffFormChoicePill(
                  label: s.label,
                  selected: s == status,
                  onTap: () => onStatusChanged(s),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            StaffAppTextField(
              controller: notesController,
              label: context.tr('Notes (optional)'),
              hint: context.tr('Internal notes about this staff member'),
              icon: Icons.sticky_note_2_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ],
    );
  }
}

class StaffEmploymentTab extends StatelessWidget {
  const StaffEmploymentTab({
    super.key,
    required this.employeeNumberController,
    required this.jobTitleController,
    required this.departmentController,
    required this.hourlyRateController,
    required this.emergencyNameController,
    required this.emergencyPhoneController,
    required this.emergencyRelationController,
    required this.employmentType,
    required this.hireDate,
    required this.errors,
    required this.onPickHireDate,
    required this.onClearHireDate,
    required this.onEmploymentTypeChanged,
    required this.onClearError,
  });

  final TextEditingController employeeNumberController;
  final TextEditingController jobTitleController;
  final TextEditingController departmentController;
  final TextEditingController hourlyRateController;
  final TextEditingController emergencyNameController;
  final TextEditingController emergencyPhoneController;
  final TextEditingController emergencyRelationController;
  final EmploymentType? employmentType;
  final String hireDate;
  final Map<String, String> errors;
  final VoidCallback onPickHireDate;
  final VoidCallback onClearHireDate;
  final ValueChanged<EmploymentType?> onEmploymentTypeChanged;
  final ValueChanged<String> onClearError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffFormSection(
          title: context.tr('Job Details'),
          description: context.tr('Role placement and business identifiers.'),
          children: [
            StaffAppTextField(
              controller: employeeNumberController,
              label: context.tr('Employee number'),
              hint: context.tr('e.g. EMP-042'),
              icon: Icons.badge_outlined,
              errorText: errors['employeeNumber'],
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => onClearError('employeeNumber'),
            ),
            StaffAppTextField(
              controller: jobTitleController,
              label: context.tr('Job title'),
              hint: context.tr('e.g. Head Cashier'),
              icon: Icons.work_outline_rounded,
              textCapitalization: TextCapitalization.words,
            ),
            StaffAppTextField(
              controller: departmentController,
              label: context.tr('Department'),
              hint: context.tr('e.g. Front counter'),
              icon: Icons.apartment_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            const StaffFieldLabel('Hire date'),
            const SizedBox(height: 10),
            StaffDateField(
              value: hireDate,
              onTap: onPickHireDate,
              onClear: hireDate.isEmpty ? null : onClearHireDate,
            ),
            const SizedBox(height: 18),
            StaffAppDropdown<EmploymentType>(
              label: context.tr('Employment type'),
              value: employmentType,
              hint: context.tr('Select employment type'),
              items: EmploymentType.values
                  .map(
                    (type) => DropdownMenuItem<EmploymentType>(
                      value: type,
                      child: Text(context.tr(type.label)),
                    ),
                  )
                  .toList(),
              onChanged: onEmploymentTypeChanged,
            ),
            StaffAppTextField(
              controller: hourlyRateController,
              label: context.tr('Hourly rate (TSh)'),
              hint: '0',
              icon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              errorText: errors['hourlyRate'],
              onChanged: (_) => onClearError('hourlyRate'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StaffFormSection(
          title: context.tr('Emergency Contact'),
          description: context.tr('Who to reach if something happens at work.'),
          children: [
            StaffAppTextField(
              controller: emergencyNameController,
              label: context.tr('Contact name'),
              hint: context.tr('Full name'),
              icon: Icons.contact_emergency_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            StaffAppTextField(
              controller: emergencyPhoneController,
              label: context.tr('Contact phone'),
              hint: context.tr('Phone number'),
              icon: Icons.phone_in_talk_outlined,
              keyboardType: TextInputType.phone,
            ),
            StaffAppTextField(
              controller: emergencyRelationController,
              label: context.tr('Relationship'),
              hint: context.tr('e.g. Spouse, Sibling'),
              icon: Icons.people_outline_rounded,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ],
    );
  }
}

class StaffLoginTab extends StatelessWidget {
  const StaffLoginTab({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.isEditing,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.errors,
    required this.onToggleObscurePassword,
    required this.onToggleObscureConfirm,
    required this.onClearError,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool isEditing;
  final bool obscurePassword;
  final bool obscureConfirm;
  final Map<String, String> errors;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onToggleObscureConfirm;
  final ValueChanged<String> onClearError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffFormSection(
          title: context.tr('Login Credentials'),
          description: isEditing
              ? context.tr('Leave the password blank to keep the current one.')
              : context.tr('Required for staff to sign in at the register.'),
          children: [
            StaffAppTextField(
              controller: usernameController,
              label: context.tr('Username'),
              hint: context.tr('At least 5 characters'),
              icon: Icons.alternate_email_rounded,
              errorText: errors['username'],
              onChanged: (_) => onClearError('username'),
            ),
            StaffAppTextField(
              controller: passwordController,
              label: isEditing ? context.tr('New password (optional)') : context.tr('Password'),
              hint: context.tr('At least 8 characters'),
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              errorText: errors['password'],
              onChanged: (_) => onClearError('password'),
              suffix: IconButton(
                onPressed: onToggleObscurePassword,
                icon: Icon(
                  obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
            StaffAppTextField(
              controller: confirmPasswordController,
              label: context.tr('Confirm password'),
              hint: context.tr('Repeat the password'),
              icon: Icons.lock_reset_rounded,
              obscureText: obscureConfirm,
              errorText: errors['confirm'],
              onChanged: (_) => onClearError('confirm'),
              suffix: IconButton(
                onPressed: onToggleObscureConfirm,
                icon: Icon(
                  obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StaffInfoCard(
          icon: Icons.shield_outlined,
          title: context.tr('Secure by design'),
          message: context.tr(
            'Passwords are salted and hashed before they are saved. Only the staff member should know their own password.',
          ),
        ),
      ],
    );
  }
}

class StaffAccessTab extends StatelessWidget {
  const StaffAccessTab({
    super.key,
    required this.roles,
    required this.selectedRoleId,
    required this.selectedRole,
    required this.errors,
    required this.onRoleChanged,
  });

  final List<StaffRoleData> roles;
  final String? selectedRoleId;
  final StaffRoleData? selectedRole;
  final Map<String, String> errors;
  final ValueChanged<String?> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final permissions = selectedRole?.permissions ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffFormSection(
          title: context.tr('Role & Permissions'),
          description: context.tr(
            'Permissions are managed by role so access stays consistent across the team.',
          ),
          children: [
            StaffAppDropdown<String>(
              label: context.tr('Assigned role'),
              value: selectedRoleId,
              hint: context.tr('Select a role'),
              errorText: errors['role'],
              items: roles
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(item.title),
                    ),
                  )
                  .toList(),
              onChanged: onRoleChanged,
            ),
            if (selectedRole != null) ...[
              const SizedBox(height: 6),
              Text(
                selectedRole!.subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 18),
            const StaffFieldLabel('Inherited permissions'),
            const SizedBox(height: 10),
            if (permissions.isEmpty)
              StaffInfoCard(
                icon: Icons.info_outline_rounded,
                title: context.tr('No permissions yet'),
                message: context.tr(
                  'This role has no permissions. Open role details to grant access.',
                ),
              )
            else
              ...permissions.map(
                (permission) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: StaffPermissionRow(label: permission),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        StaffInfoCard(
          icon: Icons.admin_panel_settings_outlined,
          title: context.tr('Least privilege'),
          message: context.tr(
            'Grant only what each role needs. Access changes apply instantly to every staff member in the role.',
          ),
        ),
      ],
    );
  }
}
