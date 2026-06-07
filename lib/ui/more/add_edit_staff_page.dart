import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/market_shared_widgets.dart';

class StaffFormResult {
  const StaffFormResult({
    required this.fullName,
    required this.phone,
    required this.role,
    this.avatarPath,
  });

  final String fullName;
  final String phone;
  final String role;
  final String? avatarPath;
}

class AddEditStaffPage extends StatefulWidget {
  const AddEditStaffPage({
    super.key,
    this.availableRoles = const <String>[],
    this.initialRole,
  });

  final List<String> availableRoles;
  final String? initialRole;

  @override
  State<AddEditStaffPage> createState() => _AddEditStaffPageState();
}

class _AddEditStaffPageState extends State<AddEditStaffPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _picker = ImagePicker();

  String? _selectedRole;
  bool _obscurePassword = true;
  XFile? _avatarFile;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final roles = widget.availableRoles;
    if (widget.initialRole != null && roles.contains(widget.initialRole)) {
      _selectedRole = widget.initialRole;
    } else if (roles.isNotEmpty) {
      _selectedRole = roles.first;
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );

      if (!mounted || file == null) {
        return;
      }

      setState(() {
        _avatarFile = file;
      });

      showMarketNotice(
        context,
        title: 'Photo Added',
        message: 'Staff profile image is ready to save',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      showMarketNotice(
        context,
        title: 'Image Unavailable',
        message: 'Restart the app if gallery access was just added',
        type: MarketNoticeType.warning,
      );
    }
  }

  Future<void> _saveStaff() async {
    final role = _selectedRole;
    if (!_formKey.currentState!.validate() || role == null) {
      if (role == null) {
        showMarketNotice(
          context,
          title: 'Role Required',
          message: 'Select a staff role before saving',
          type: MarketNoticeType.warning,
        );
      }
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) {
      return;
    }

    showMarketNotice(
      context,
      title: 'Staff Saved',
      message: '${_nameController.text.trim()} was saved as $role',
    );

    Navigator.of(context).pop(
      StaffFormResult(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: role,
        avatarPath: _avatarFile?.path,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: BackdropGlow()),
            Column(
              children: [
                const MarketPageHeader(title: 'Add / Edit Staff'),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                GestureDetector(
                                  onTap: _pickAvatar,
                                  child: Container(
                                    width: 156,
                                    height: 156,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF0FF),
                                      shape: BoxShape.circle,
                                      image: _avatarFile == null
                                          ? null
                                          : DecorationImage(
                                              image: FileImage(
                                                File(_avatarFile!.path),
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    child: _avatarFile == null
                                        ? const Icon(
                                            Icons.person,
                                            color: Color(0xFF2B6FF3),
                                            size: 78,
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  right: -4,
                                  bottom: 12,
                                  child: GestureDetector(
                                    onTap: _pickAvatar,
                                    child: Container(
                                      width: 54,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFE4E7EC),
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x12000000),
                                            blurRadius: 12,
                                            offset: Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.photo_camera_outlined,
                                        color: Color(0xFF6B7280),
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          const _StaffFieldLabel('Full Name'),
                          const SizedBox(height: 10),
                          _StaffInputField(
                            controller: _nameController,
                            hintText: 'Enter full name',
                            prefixIcon: Icons.person_outline_rounded,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Full name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          const _StaffFieldLabel('Phone'),
                          const SizedBox(height: 10),
                          _StaffInputField(
                            controller: _phoneController,
                            hintText: 'Enter phone number',
                            prefixIcon: Icons.call_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Phone number is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          const _StaffFieldLabel('Assign Role'),
                          const SizedBox(height: 10),
                          _StaffDropdownField(
                            value: _selectedRole,
                            hintText: 'Select a role',
                            prefixIcon: Icons.shield_outlined,
                            items: widget.availableRoles,
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          const Row(
                            children: [
                              _StaffFieldLabel('Set Password'),
                              SizedBox(width: 8),
                              Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF7B8494),
                                size: 22,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _StaffInputField(
                            controller: _passwordController,
                            hintText: 'Enter password',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            suffix: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF7B8494),
                                size: 26,
                              ),
                            ),
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) {
                                return 'Password is required';
                              }
                              if (password.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Password must be at least 6 characters long.',
                            style: TextStyle(
                              color: Color(0xFF7B8494),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 28),
                          GestureDetector(
                            onTap: _isSaving ? null : _saveStaff,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 180),
                              opacity: _isSaving ? 0.78 : 1,
                              child: Container(
                                height: 74,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF1562E8),
                                      Color(0xFF2B6FF3),
                                    ],
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x291562E8),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isSaving
                                          ? Icons.hourglass_top_rounded
                                          : Icons.save_outlined,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isSaving ? 'Saving...' : 'Save Staff',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffFieldLabel extends StatelessWidget {
  const _StaffFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontSize: 16.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StaffInputField extends StatelessWidget {
  const _StaffInputField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      style: const TextStyle(
        color: Color(0xFF202938),
        fontSize: 15.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFFA3ACB9),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF667085), size: 28),
        suffixIcon: suffix == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 14),
                child: suffix,
              ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 22,
        ),
        filled: true,
        fillColor: Colors.white,
        border: _staffInputBorder(),
        enabledBorder: _staffInputBorder(),
        focusedBorder: _staffInputBorder(const Color(0xFFB7C7EA)),
        errorBorder: _staffInputBorder(const Color(0xFFE26B6B)),
        focusedErrorBorder: _staffInputBorder(const Color(0xFFE26B6B)),
        errorStyle: const TextStyle(
          color: Color(0xFFD9485F),
          fontSize: 12.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StaffDropdownField extends StatelessWidget {
  const _StaffDropdownField({
    required this.value,
    required this.hintText,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final String hintText;
  final IconData prefixIcon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDDE2EA)),
      ),
      child: Row(
        children: [
          Icon(prefixIcon, color: const Color(0xFF667085), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(
                  hintText,
                  style: const TextStyle(
                    color: Color(0xFFA3ACB9),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF667085),
                  size: 28,
                ),
                isExpanded: true,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(4),
                style: const TextStyle(
                  color: Color(0xFF202938),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                ),
                items: items
                    .map(
                      (role) => DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      ),
                    )
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

OutlineInputBorder _staffInputBorder([Color color = const Color(0xFFDDE2EA)]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: BorderSide(color: color),
  );
}
