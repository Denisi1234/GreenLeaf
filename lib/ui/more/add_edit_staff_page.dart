import 'package:track_mauzo/l10n/app_localization.dart';
import '../widgets/workspace_widgets.dart';
import '../widgets/app_image.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'widgets/staff_credentials_share_dialog.dart';
import 'widgets/staff_form_widgets.dart';
import 'widgets/staff_form_tabs.dart';


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
        title: context.tr('Image Unavailable'),
        message: context.tr('Restart the app if gallery access was just added'),
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
      _setError('name', context.tr('Full name is required'));
    }
    if (_phoneController.text.trim().isEmpty) {
      _setError('phone', context.tr('Phone number is required'));
    }

    final email = _emailController.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _setError('email', context.tr('Enter a valid email address'));
    }

    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _setError('username', context.tr('Username is required'));
    } else if (username.length < 5) {
      _setError('username', context.tr('Username must be at least 5 characters'));
    }

    final password = _passwordController.text;
    final minimumLength =
        context.read<PosLocalStore>().cloudApi == null ? 8 : 10;
    if (!widget.isEditing && password.isEmpty) {
      _setError('password', context.tr('Password is required'));
    } else if (password.isNotEmpty && password.length < minimumLength) {
      _setError(
          'password', context.tr('Password must be at least {p0} characters', args: {'p0': minimumLength}));
    }
    if (password.isNotEmpty && _confirmPasswordController.text != password) {
      _setError('confirm', context.tr('Passwords do not match'));
    }

    final employeeNumber = _employeeNumberController.text.trim();
    if (employeeNumber.isNotEmpty) {
      final store = context.read<PosLocalStore>();
      if (store.staffEmployeeNumberExists(
        employeeNumber,
        excludingId: _member?.id,
      )) {
        _setError('employeeNumber', context.tr('Employee number is already in use'));
      }
    }

    final rateText = _hourlyRateController.text.trim().replaceAll(',', '');
    if (rateText.isNotEmpty) {
      final rate = double.tryParse(rateText);
      if (rate == null || rate < 0) {
        _setError('hourlyRate', context.tr('Enter a valid hourly rate'));
      }
    }

    if (_selectedRoleId == null) {
      _setError('role', context.tr('Select a staff role'));
    }

    final store = context.read<PosLocalStore>();
    if (username.isNotEmpty &&
        store.staffUsernameExists(username, excludingId: _member?.id)) {
      _setError('username', context.tr('Username is already in use'));
    }

    if (_errors.isNotEmpty) {
      final firstKey = _errors.keys.first;
      setState(() => _selectedTab = _tabForError(firstKey));
      showMarketNotice(
        context,
        title: context.tr('Check the form'),
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
      if (password.isNotEmpty && _phoneController.text.trim().isNotEmpty) {
        final sw = store.languageCode.trim().toLowerCase() == 'sw';
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => StaffCredentialsShareDialog(
            staffName: saved.name,
            username: saved.username,
            password: password,
            phone: saved.phone,
            roleTitle: role.title,
            storeName: store.activeStoreName,
            isSwahili: sw,
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (mounted) {
        showMarketNotice(context,
            title: context.tr('Save Failed'),
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
                  title: widget.isEditing ? context.tr('Edit Staff') : context.tr('Add Staff'),
                  subtitle: widget.isEditing
                      ? context.tr('Update profile, employment, and access')
                      : context.tr('Create a professional staff profile'),
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
        return StaffEmploymentTab(
          employeeNumberController: _employeeNumberController,
          jobTitleController: _jobTitleController,
          departmentController: _departmentController,
          hourlyRateController: _hourlyRateController,
          emergencyNameController: _emergencyNameController,
          emergencyPhoneController: _emergencyPhoneController,
          emergencyRelationController: _emergencyRelationController,
          employmentType: _employmentType,
          hireDate: _hireDate,
          errors: _errors,
          onPickHireDate: _pickHireDate,
          onClearHireDate: () => setState(() => _hireDate = ''),
          onEmploymentTypeChanged: (type) => setState(() => _employmentType = type),
          onClearError: (field) => setState(() => _errors.remove(field)),
        );
      case 2:
        return StaffLoginTab(
          usernameController: _usernameController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          isEditing: widget.isEditing,
          obscurePassword: _obscurePassword,
          obscureConfirm: _obscureConfirm,
          errors: _errors,
          onToggleObscurePassword: () => setState(() => _obscurePassword = !_obscurePassword),
          onToggleObscureConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
          onClearError: (field) => setState(() => _errors.remove(field)),
        );
      case 3:
        return StaffAccessTab(
          roles: widget.roles,
          selectedRoleId: _selectedRoleId,
          selectedRole: _selectedRole,
          errors: _errors,
          onRoleChanged: (roleId) => setState(() => _selectedRoleId = roleId),
        );
      default:
        return StaffBasicInfoTab(
          nameController: _nameController,
          phoneController: _phoneController,
          emailController: _emailController,
          addressController: _addressController,
          notesController: _notesController,
          avatarPath: _avatarPath,
          status: _status,
          errors: _errors,
          onPickAvatar: _pickAvatar,
          onClearError: (field) => setState(() => _errors.remove(field)),
          onStatusChanged: (status) => setState(() => _status = status),
        );
    }
  }

  static String _trimAmount(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}
