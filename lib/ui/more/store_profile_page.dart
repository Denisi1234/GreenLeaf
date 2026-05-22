import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

class StoreProfilePage extends StatefulWidget {
  const StoreProfilePage({super.key});

  @override
  State<StoreProfilePage> createState() => _StoreProfilePageState();
}

class _StoreProfilePageState extends State<StoreProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _picker = ImagePicker();

  static const _categories = <String>[
    'Retail',
    'Restaurant',
    'Pharmacy',
    'Electronics',
    'Warehouse',
    'Supermarket',
  ];

  String? _selectedCategory = 'Retail';
  bool _isSaving = false;
  XFile? _logoFile;
  String? _initialLogoPath;
  bool _loadedProfile = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedProfile) return;

    final profile = context.read<PosLocalStore>().profile;
    _storeNameController.text = profile.storeName;
    _contactController.text = profile.contactNumber;
    _emailController.text = profile.emailAddress;
    _addressController.text = profile.physicalAddress;
    _selectedCategory =
        profile.businessCategory.isEmpty ? null : profile.businessCategory;
    _initialLogoPath = profile.logoPath;
    _loadedProfile = true;
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (!mounted || file == null) return;
      setState(() {
        _logoFile = file;
      });
      showMarketNotice(
        context,
        title: 'Logo Added',
        message: 'Store logo is ready to save',
      );
    } catch (_) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Logo Unavailable',
        message: 'Restart the app if image access was just enabled',
        type: MarketNoticeType.warning,
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      if (_selectedCategory == null) {
        showMarketNotice(
          context,
          title: 'Category Required',
          message: 'Select a business category before saving',
          type: MarketNoticeType.warning,
        );
      }
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final store = context.read<PosLocalStore>();
    final navigator = Navigator.of(context);
    final currentProfile = store.profile;
    final memberSince = currentProfile.memberSince.isEmpty
        ? _formatToday()
        : currentProfile.memberSince;
    await store.updateProfile(
      currentProfile.copyWith(
        storeName: _storeNameController.text.trim(),
        businessCategory: _selectedCategory!,
        contactNumber: _contactController.text.trim(),
        emailAddress: _emailController.text.trim(),
        physicalAddress: _addressController.text.trim(),
        memberSince: memberSince,
        logoPath: _logoFile?.path ?? _initialLogoPath,
      ),
    );

    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final logoPath = _logoFile?.path ?? _initialLogoPath;
    final baseTheme = Theme.of(context);
    final interTheme = baseTheme.copyWith(
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.ink,
                          size: 22,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Store Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.pageBackground,
                            borderRadius: BorderRadius.circular(AppRadius.rounded),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: logoPath == null
                                      ? const Icon(
                                          Icons.storefront_outlined,
                                          color: AppColors.ink,
                                          size: 28,
                                        )
                                      : Image.file(
                                          File(logoPath),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Keep your store information up to date.',
                                        style: TextStyle(
                                          color: AppColors.ink,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.1,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'This information will be used for receipts and business records.',
                                        style: TextStyle(
                                          color: AppColors.mutedText,
                                          fontSize: 12,
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _StoreField(
                          label: 'Store Name',
                          hint: 'Enter store name',
                          controller: _storeNameController,
                          icon: Icons.storefront_outlined,
                          requiredField: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Store name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _DropdownField(
                          label: 'Business Category',
                          hint: 'Select business category',
                          icon: Icons.local_offer_outlined,
                          value: _selectedCategory,
                          items: _categories,
                          requiredField: true,
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _StoreField(
                          label: 'Contact Number',
                          hint: 'Enter contact number',
                          controller: _contactController,
                          icon: Icons.call_outlined,
                          requiredField: true,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Contact number is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _StoreField(
                          label: 'Email Address',
                          hint: 'Enter email address',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email address is required';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _StoreField(
                          label: 'Physical Address',
                          hint: 'Enter complete physical address',
                          controller: _addressController,
                          icon: Icons.location_on_outlined,
                          requiredField: true,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Physical address is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Upload Store Logo',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickLogo,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppRadius.rounded),
                              border: Border.all(
                                color: AppColors.border,
                                style: BorderStyle.solid,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.pageBackground,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(
                                    Icons.cloud_upload_outlined,
                                    color: AppColors.ink,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap to upload logo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Recommended size: 512 x 512 px\nJPG, PNG up to 2MB',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 11,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        MarketButton(
                          label: _isSaving ? 'Saving...' : 'Save Changes',
                          icon: _isSaving
                              ? Icons.hourglass_top_rounded
                              : Icons.save_outlined,
                          onTap: _isSaving ? () {} : _saveProfile,
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
    );
  }
}

class _StoreField extends StatelessWidget {
  const _StoreField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.requiredField = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool requiredField;
  final TextInputType? keyboardType;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
            children: [
              TextSpan(text: label),
              if (requiredField)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.rounded),
            border: Border.all(color: AppColors.border),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.mutedText,
                size: 20,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _formatToday() {
  const monthNames = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final now = DateTime.now();
  return '${monthNames[now.month - 1]} ${now.day}, ${now.year}';
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.requiredField = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
            children: [
              TextSpan(text: label),
              if (requiredField)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.rounded),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(AppRadius.rounded),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.mutedText,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.mutedText,
                size: 20,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            items: items
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
