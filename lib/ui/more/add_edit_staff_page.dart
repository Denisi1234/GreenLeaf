import '../widgets/workspace_widgets.dart';
import '../widgets/app_image.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'widgets/staff_form_widgets.dart';

class AddEditStaffPage extends StatefulWidget {
  const AddEditStaffPage({
    super.key,
    this.member,
    this.roles = const <StaffRoleData>[],
    this.initialRoleId,
    this.initialFullName = '',
    this.initialPhone = '',
    this.initialEmail = '',
  });

  final StaffMemberData? member;
  final List<StaffRoleData> roles;
  final String? initialRoleId;
  final String initialFullName;
  final String initialPhone;
  final String initialEmail;

  bool get isEditing => member != null;

  @override
  State<AddEditStaffPage> createState() => _AddEditStaffPageState();
}

class _AddEditStaffPageState extends State<AddEditStaffPage> {
  static const _tabs = <String>['Basic', 'Employment', 'Login', 'Access'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  final _employeeNumberController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _departmentController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _picker = ImagePicker();

  final Map<String, String> _errors = <String, String>{};

  int _selectedTab = 0;
  String? _selectedRoleId;
  EmploymentType? _employmentType;
  StaffStatus _status = StaffStatus.active;
  String _hireDate = '';
  String? _avatarPath;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  StaffMemberData? get _member => widget.member;

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    _nameController.text = member?.name ?? widget.initialFullName;
    _phoneController.text = member?.phone ?? widget.initialPhone;
    _emailController.text = member?.email ?? widget.initialEmail;
    _addressController.text = member?.address ?? '';
    _notesController.text = member?.notes ?? '';
    _employeeNumberController.text = member?.employeeNumber ?? '';
    _jobTitleController.text = member?.jobTitle ?? '';
    _departmentController.text = member?.department ?? '';
    _hourlyRateController.text = member == null || member.hourlyRate <= 0
        ? ''
        : _trimAmount(member.hourlyRate);
    _emergencyNameController.text = member?.emergencyContactName ?? '';
    _emergencyPhoneController.text = member?.emergencyContactPhone ?? '';
    _emergencyRelationController.text = member?.emergencyContactRelation ?? '';
    _usernameController.text = member?.username ?? '';
    _employmentType = EmploymentType.fromValue(member?.employmentType);
    _status = member?.status ?? StaffStatus.active;
    _hireDate = member?.hireDate ?? '';
    _avatarPath = member?.avatarPath;

    final preferredRole = member?.roleId ?? widget.initialRoleId;
    if (preferredRole != null &&
        widget.roles.any((role) => role.id == preferredRole)) {
      _selectedRoleId = preferredRole;
    } else if (widget.roles.isNotEmpty) {
      _selectedRoleId = widget.roles.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _employeeNumberController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _hourlyRateController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  StaffRoleData? get _selectedRole {
    for (final role in widget.roles) {
      if (role.id == _selectedRoleId) return role;
    }
    return null;
  }

  void _setError(String key, String? message) {
    if (message == null) {
      _errors.remove(key);
    } else {
      _errors[key] = message;
    }
  }

  void _clearError(String key) {
    if (!_errors.containsKey(key)) return;
    setState(() => _errors.remove(key));
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (!mounted || file == null) return;
      setState(() => _avatarPath = file.path);
    } catch (_) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Image Unavailable',
        message: 'Restart the app if gallery access was just added',
        type: MarketNoticeType.warning,
      );
    }
  }

  Future<void> _pickHireDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_hireDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Select hire date',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _hireDate = picked.toIso8601String().split('T').first;
    });
  }

  int _tabForError(String key) {
    switch (key) {
      case 'employeeNumber':
      case 'hourlyRate':
        return 1;
      case 'username':
      case 'password':
      case 'confirm':
        return 2;
      case 'role':
        return 3;
      default:
        return 0;
    }
  }

  bool _validate() {
    _errors.clear();

    if (_nameController.text.trim().isEmpty) {
      _setError('name', 'Full name is required');
    }
    if (_phoneController.text.trim().isEmpty) {
      _setError('phone', 'Phone number is required');
    }

    final email = _emailController.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _setError('email', 'Enter a valid email address');
    }

    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _setError('username', 'Username is required');
    } else if (username.length < 5) {
      _setError('username', 'Username must be at least 5 characters');
    }

    final password = _passwordController.text;
    final minimumLength =
        context.read<PosLocalStore>().cloudApi == null ? 8 : 10;
    if (!widget.isEditing && password.isEmpty) {
      _setError('password', 'Password is required');
    } else if (password.isNotEmpty && password.length < minimumLength) {
      _setError(
          'password', 'Password must be at least $minimumLength characters');
    }
    if (password.isNotEmpty && _confirmPasswordController.text != password) {
      _setError('confirm', 'Passwords do not match');
    }

    final employeeNumber = _employeeNumberController.text.trim();
    if (employeeNumber.isNotEmpty) {
      final store = context.read<PosLocalStore>();
      if (store.staffEmployeeNumberExists(
        employeeNumber,
        excludingId: _member?.id,
      )) {
        _setError('employeeNumber', 'Employee number is already in use');
      }
    }

    final rateText = _hourlyRateController.text.trim().replaceAll(',', '');
    if (rateText.isNotEmpty) {
      final rate = double.tryParse(rateText);
      if (rate == null || rate < 0) {
        _setError('hourlyRate', 'Enter a valid hourly rate');
      }
    }

    if (_selectedRoleId == null) {
      _setError('role', 'Select a staff role');
    }

    final store = context.read<PosLocalStore>();
    if (username.isNotEmpty &&
        store.staffUsernameExists(username, excludingId: _member?.id)) {
      _setError('username', 'Username is already in use');
    }

    if (_errors.isNotEmpty) {
      final firstKey = _errors.keys.first;
      setState(() => _selectedTab = _tabForError(firstKey));
      showMarketNotice(
        context,
        title: 'Check the form',
        message: _errors[firstKey]!,
        type: MarketNoticeType.warning,
      );
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    final store = context.read<PosLocalStore>();
    final role = _selectedRole!;
    final rateText = _hourlyRateController.text.trim().replaceAll(',', '');
    final hourlyRate = rateText.isEmpty ? 0.0 : double.parse(rateText);
    final password = _passwordController.text;

    setState(() => _isSaving = true);

    try {
      StaffMemberData saved;
      if (_member == null) {
        saved = await store.addStaffMember(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          roleId: role.id,
          username: _usernameController.text.trim(),
          password: password,
          employeeNumber: _employeeNumberController.text.trim(),
          jobTitle: _jobTitleController.text.trim(),
          department: _departmentController.text.trim(),
          hireDate: _hireDate,
          employmentType: _employmentType?.value ?? '',
          hourlyRate: hourlyRate,
          emergencyContactName: _emergencyNameController.text.trim(),
          emergencyContactPhone: _emergencyPhoneController.text.trim(),
          emergencyContactRelation: _emergencyRelationController.text.trim(),
          address: _addressController.text.trim(),
          notes: _notesController.text.trim(),
          avatarPath: _avatarPath,
          status: _status,
        );
      } else {
        saved = await store.updateStaffMember(
          _member!.copyWith(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            roleId: role.id,
            username: _usernameController.text.trim(),
            employeeNumber: _employeeNumberController.text.trim(),
            jobTitle: _jobTitleController.text.trim(),
            department: _departmentController.text.trim(),
            hireDate: _hireDate,
            employmentType: _employmentType?.value ?? '',
            hourlyRate: hourlyRate,
            emergencyContactName: _emergencyNameController.text.trim(),
            emergencyContactPhone: _emergencyPhoneController.text.trim(),
            emergencyContactRelation: _emergencyRelationController.text.trim(),
            address: _addressController.text.trim(),
            notes: _notesController.text.trim(),
            avatarPath: _avatarPath,
            status: _status,
          ),
          newPassword: password.isEmpty ? null : password,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted) {
        showMarketNotice(context,
            title: 'Save Failed',
            message: error.toString(),
            type: MarketNoticeType.warning);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        body: ManagementViewport(
          maxWidth: 860,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                MarketPageHeader(
                  title: widget.isEditing ? 'Edit Staff' : 'Add Staff',
                  subtitle: widget.isEditing
                      ? 'Update profile, employment, and access'
                      : 'Create a professional staff profile',
                  centerTitle: false,
                  showBorder: false,
                ),
                StaffTabSelector(
                  tabs: _tabs,
                  selectedIndex: _selectedTab,
                  onSelected: (index) => setState(() => _selectedTab = index),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: KeyedSubtree(
                          key: ValueKey<int>(_selectedTab),
                          child: _buildTab(_selectedTab),
                        ),
                      ),
                    ),
                  ),
                ),
                StaffSaveBar(
                  isSaving: _isSaving,
                  isEditing: widget.isEditing,
                  onSave: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 1:
        return _buildEmploymentTab();
      case 2:
        return _buildLoginTab();
      case 3:
        return _buildAccessTab();
      default:
        return _buildBasicTab();
    }
  }

  Widget _buildBasicTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSecondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                    image: _avatarPath == null
                        ? null
                        : DecorationImage(
                            image: appImageProvider(context, _avatarPath!),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: _avatarPath == null
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 54,
                        )
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 4,
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        StaffFormSection(
          title: 'Personal Information',
          description: 'Core contact details used across the POS.',
          children: [
            StaffAppTextField(
              controller: _nameController,
              label: 'Full name',
              hint: 'e.g. Amina Joseph',
              icon: Icons.person_outline_rounded,
              errorText: _errors['name'],
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => _clearError('name'),
            ),
            StaffAppTextField(
              controller: _phoneController,
              label: 'Phone number',
              hint: 'e.g. +255 712 345 678',
              icon: Icons.call_outlined,
              keyboardType: TextInputType.phone,
              errorText: _errors['phone'],
              onChanged: (_) => _clearError('phone'),
            ),
            StaffAppTextField(
              controller: _emailController,
              label: 'Email (optional)',
              hint: 'staff@store.co.tz',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              errorText: _errors['email'],
              onChanged: (_) => _clearError('email'),
            ),
            StaffAppTextField(
              controller: _addressController,
              label: 'Address (optional)',
              hint: 'Street, city',
              icon: Icons.location_on_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 4),
            const StaffFieldLabel('Account status'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: StaffStatus.values.map((status) {
                final selected = status == _status;
                return StaffFormChoicePill(
                  label: status.label,
                  selected: selected,
                  onTap: () => setState(() => _status = status),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            StaffAppTextField(
              controller: _notesController,
              label: 'Notes (optional)',
              hint: 'Internal notes about this staff member',
              icon: Icons.sticky_note_2_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmploymentTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffFormSection(
          title: 'Employment Details',
          description: 'HR information kept private to store administrators.',
          children: [
            StaffAppTextField(
              controller: _employeeNumberController,
              label: 'Employee number (optional)',
              hint: 'e.g. EMP-0042',
              icon: Icons.badge_outlined,
              errorText: _errors['employeeNumber'],
              onChanged: (_) => _clearError('employeeNumber'),
            ),
            StaffAppTextField(
              controller: _jobTitleController,
              label: 'Job title',
              hint: 'e.g. Head Cashier',
              icon: Icons.work_outline_rounded,
              textCapitalization: TextCapitalization.words,
            ),
            StaffAppTextField(
              controller: _departmentController,
              label: 'Department',
              hint: 'e.g. Front counter',
              icon: Icons.apartment_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            const StaffFieldLabel('Hire date'),
            const SizedBox(height: 10),
            StaffDateField(
              value: _hireDate,
              onTap: _pickHireDate,
              onClear: _hireDate.isEmpty
                  ? null
                  : () => setState(() => _hireDate = ''),
            ),
            const SizedBox(height: 18),
            StaffAppDropdown<EmploymentType>(
              label: 'Employment type',
              value: _employmentType,
              hint: 'Select employment type',
              items: EmploymentType.values
                  .map(
                    (type) => DropdownMenuItem<EmploymentType>(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _employmentType = value),
            ),
            StaffAppTextField(
              controller: _hourlyRateController,
              label: 'Hourly rate (TSh)',
              hint: '0',
              icon: Icons.payments_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              errorText: _errors['hourlyRate'],
              onChanged: (_) => _clearError('hourlyRate'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StaffFormSection(
          title: 'Emergency Contact',
          description: 'Who to reach if something happens at work.',
          children: [
            StaffAppTextField(
              controller: _emergencyNameController,
              label: 'Contact name',
              hint: 'Full name',
              icon: Icons.contact_emergency_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            StaffAppTextField(
              controller: _emergencyPhoneController,
              label: 'Contact phone',
              hint: 'Phone number',
              icon: Icons.phone_in_talk_outlined,
              keyboardType: TextInputType.phone,
            ),
            StaffAppTextField(
              controller: _emergencyRelationController,
              label: 'Relationship',
              hint: 'e.g. Spouse, Sibling',
              icon: Icons.people_outline_rounded,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffFormSection(
          title: 'Login Credentials',
          description: widget.isEditing
              ? 'Leave the password blank to keep the current one.'
              : 'Required for staff to sign in at the register.',
          children: [
            StaffAppTextField(
              controller: _usernameController,
              label: 'Username',
              hint: 'At least 5 characters',
              icon: Icons.alternate_email_rounded,
              errorText: _errors['username'],
              onChanged: (_) => _clearError('username'),
            ),
            StaffAppTextField(
              controller: _passwordController,
              label: widget.isEditing ? 'New password (optional)' : 'Password',
              hint: 'At least 8 characters',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              errorText: _errors['password'],
              onChanged: (_) => _clearError('password'),
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
            StaffAppTextField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              hint: 'Repeat the password',
              icon: Icons.lock_reset_rounded,
              obscureText: _obscureConfirm,
              errorText: _errors['confirm'],
              onChanged: (_) => _clearError('confirm'),
              suffix: IconButton(
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const StaffInfoCard(
          icon: Icons.shield_outlined,
          title: 'Secure by design',
          message:
              'Passwords are salted and hashed before they are saved. Only the staff member should know their own password.',
        ),
      ],
    );
  }

  Widget _buildAccessTab() {
    final role = _selectedRole;
    final permissions = role?.permissions ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StaffFormSection(
          title: 'Role & Permissions',
          description:
              'Permissions are managed by role so access stays consistent across the team.',
          children: [
            StaffAppDropdown<String>(
              label: 'Assigned role',
              value: _selectedRoleId,
              hint: 'Select a role',
              errorText: _errors['role'],
              items: widget.roles
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(item.title),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                _clearError('role');
                setState(() => _selectedRoleId = value);
              },
            ),
            if (role != null) ...[
              const SizedBox(height: 6),
              Text(
                role.subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 18),
            const StaffFieldLabel('Inherited permissions'),
            const SizedBox(height: 10),
            if (permissions.isEmpty)
              const StaffInfoCard(
                icon: Icons.info_outline_rounded,
                title: 'No permissions yet',
                message:
                    'This role has no permissions. Open role details to grant access.',
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
        const StaffInfoCard(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Least privilege',
          message:
              'Grant only what each role needs. Access changes apply instantly to every staff member in the role.',
        ),
      ],
    );
  }

  static String _trimAmount(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}
