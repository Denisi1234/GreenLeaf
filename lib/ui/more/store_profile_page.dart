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
      textTheme: GoogleFonts.manropeTextTheme(baseTheme.textTheme),
      primaryTextTheme:
          GoogleFonts.manropeTextTheme(baseTheme.primaryTextTheme),
    );

    return Theme(
      data: interTheme,
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Row(
                    children: [
                      _IosNavButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Store Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: _ProfileHeaderCard(
                    logoPath: logoPath,
                    onPickLogo: _pickLogo,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: 'Business details',
                  children: [
                    _StoreField(
                      label: 'Store Name',
                      hint: 'Enter store name',
                      controller: _storeNameController,
                      icon: Icons.storefront_outlined,
                      requiredField: true,
                      dense: true,
                      borderless: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Store name is required';
                        }
                        return null;
                      },
                    ),
                    const _SectionDivider(),
                    _DropdownField(
                      label: 'Business Category',
                      hint: 'Select business category',
                      icon: Icons.local_offer_outlined,
                      value: _selectedCategory,
                      items: _categories,
                      requiredField: true,
                      dense: true,
                      borderless: true,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    const _SectionDivider(),
                    _StoreField(
                      label: 'Contact Number',
                      hint: 'Enter contact number',
                      controller: _contactController,
                      icon: Icons.call_outlined,
                      requiredField: true,
                      dense: true,
                      borderless: true,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Contact number is required';
                        }
                        return null;
                      },
                    ),
                    const _SectionDivider(),
                    _StoreField(
                      label: 'Email Address',
                      hint: 'Enter email address',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      dense: true,
                      borderless: true,
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
                    const _SectionDivider(),
                    _StoreField(
                      label: 'Physical Address',
                      hint: 'Enter complete physical address',
                      controller: _addressController,
                      icon: Icons.location_on_outlined,
                      requiredField: true,
                      dense: true,
                      borderless: true,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Physical address is required';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 22)),
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: 'Store logo',
                  children: [
                    _LogoUploadRow(
                      logoPath: logoPath,
                      onTap: _pickLogo,
                    ),
                  ],
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD94B4B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isSaving ? 'Saving...' : 'Save Changes',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
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
}

class _IosNavButton extends StatelessWidget {
  const _IosNavButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 20,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.logoPath,
    required this.onPickLogo,
  });

  final String? logoPath;
  final VoidCallback onPickLogo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickLogo,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: logoPath == null
                    ? const Icon(
                        Icons.storefront_outlined,
                        color: AppColors.ink,
                        size: 28,
                      )
                    : Image.file(
                        File(logoPath!),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Store logo',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.05,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap to upload or replace your logo.',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.02,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16),
      height: 1,
      color: const Color(0xFFF0F1F4),
    );
  }
}

class _LogoUploadRow extends StatelessWidget {
  const _LogoUploadRow({
    required this.logoPath,
    required this.onTap,
  });

  final String? logoPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: logoPath == null
                  ? const Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.ink,
                      size: 22,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        File(logoPath!),
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap to upload logo',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'PNG or JPG. Best results at 512 × 512 px.',
                    style: TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedText,
              size: 22,
            ),
          ],
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
    this.dense = false,
    this.borderless = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final bool requiredField;
  final TextInputType? keyboardType;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  final bool dense;
  final bool borderless;

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
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
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
            color: borderless ? Colors.transparent : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: borderless
                ? null
                : Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: borderless ? 4 : 14,
                vertical: borderless ? 10 : (dense ? 14 : 16),
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
                fontWeight: FontWeight.w400,
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
    this.dense = false,
    this.borderless = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool requiredField;
  final bool dense;
  final bool borderless;

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
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
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
            color: borderless ? Colors.transparent : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: borderless
                ? null
                : Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(14),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.mutedText,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: borderless ? 4 : 14,
                vertical: borderless ? 10 : (dense ? 14 : 16),
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
                        fontWeight: FontWeight.w400,
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
