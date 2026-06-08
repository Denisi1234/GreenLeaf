// ignore_for_file: unused_element
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
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static const _categories = <String>[
    'Retail',
    'Restaurant',
    'Pharmacy',
    'Electronics',
    'Warehouse',
    'Supermarket',
  ];

  String? _selectedCategory;
  bool _isSaving = false;
  XFile? _logoFile;
  String? _initialLogoPath;
  String? _loadedProfileSignature;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.read<PosLocalStore>().profile;
    final profileSignature = _profileSignature(profile);
    if (_loadedProfileSignature == profileSignature) return;

    _storeNameController.text = profile.storeName;
    _contactController.text = profile.contactNumber;
    _emailController.text = profile.emailAddress;
    _addressController.text = profile.physicalAddress;
    _selectedCategory =
        profile.businessCategory.isEmpty ? null : profile.businessCategory;
    _initialLogoPath = profile.logoPath;
    _loadedProfileSignature = profileSignature;
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

    try {
      final store = context.read<PosLocalStore>();
      final navigator = Navigator.of(context);
      final currentProfile = store.profile;
      final memberSince = currentProfile.memberSince.isEmpty
          ? _formatToday()
          : currentProfile.memberSince;
      final previousLogoPath = _initialLogoPath;
      final nextLogoPath = _logoFile?.path ?? _initialLogoPath;

      await store.updateProfile(
        currentProfile.copyWith(
          storeName: _storeNameController.text.trim(),
          businessCategory: _selectedCategory!,
          contactNumber: _contactController.text.trim(),
          emailAddress: _emailController.text.trim(),
          physicalAddress: _addressController.text.trim(),
          memberSince: memberSince,
          logoPath: nextLogoPath,
        ),
      );

      if (_logoFile != null &&
          previousLogoPath != null &&
          previousLogoPath != nextLogoPath) {
        final previousFile = File(previousLogoPath);
        if (await previousFile.exists()) {
          await previousFile.delete();
        }
      }

      if (!mounted) return;
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      showMarketNotice(
        context,
        title: 'Save Failed',
        message: 'Store profile could not be saved. Please try again.',
        type: MarketNoticeType.warning,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
                const SliverToBoxAdapter(
                  child: MarketPageHeader(
                    title: 'Store Profile',
                    showBackButton: true,
                    centerTitle: true,
                    titleSize: 19,
                    titleWeight: FontWeight.w600,
                    transparent: false,
                    showBorder: true,
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email address is required';
                            }
                            if (!_emailPattern.hasMatch(value.trim())) {
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
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    child: MarketButton(
                      label: _isSaving ? 'Saving...' : 'Save Changes',
                      icon: _isSaving
                          ? Icons.hourglass_top_rounded
                          : Icons.save_outlined,
                      onTap: _isSaving ? () {} : _saveProfile,
                      color: AppColors.primary,
                      height: 74,
                      radius: 4,
                      iconSize: 28,
                      fontSize: 17.5,
                      fontWeight: FontWeight.w700,
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.ink,
          ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPickLogo,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: logoPath == null
                      ? const Icon(
                          Icons.storefront_outlined,
                          color: AppColors.primary,
                          size: 30,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap to upload or replace.',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 14,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12.5,
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
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            color: Color(0xFF33363F),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF8A93A7),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF5B8CFF),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.92),
            enabledBorder: _storeFieldBorder(),
            focusedBorder: _storeFieldBorder(
              color: const Color(0xFF5B8CFF),
              width: 1.2,
            ),
            errorBorder: _storeFieldBorder(
              color: const Color(0xFFEF4444),
              width: 1.1,
            ),
            focusedErrorBorder: _storeFieldBorder(
              color: const Color(0xFFEF4444),
              width: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatToday() {
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
  final now = DateTime.now();
  return '${monthNames[now.month - 1]} ${now.day}, ${now.year}';
}

String _profileSignature(AppProfileData profile) {
  return [
    profile.storeName,
    profile.ownerName,
    profile.roleTitle,
    profile.businessCategory,
    profile.contactNumber,
    profile.emailAddress,
    profile.physicalAddress,
    profile.memberSince,
    profile.taxId,
    profile.weekdayOpen,
    profile.weekdayClose,
    profile.saturdayOpen,
    profile.saturdayClose,
    profile.sundaySchedule,
    profile.open24Hours ? '1' : '0',
    profile.logoPath ?? '',
  ].join('|');
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
  });

  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool requiredField;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12.5,
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
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(8),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF5B8CFF),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF8A93A7),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF5B8CFF),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.92),
            enabledBorder: _storeFieldBorder(),
            focusedBorder: _storeFieldBorder(
              color: const Color(0xFF5B8CFF),
              width: 1.2,
            ),
            errorBorder: _storeFieldBorder(
              color: const Color(0xFFEF4444),
              width: 1.1,
            ),
            focusedErrorBorder: _storeFieldBorder(
              color: const Color(0xFFEF4444),
              width: 1.1,
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xFF33363F),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

OutlineInputBorder _storeFieldBorder({
  Color color = const Color(0xFFE7EAF0),
  double width = 1,
}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color, width: width),
  );
}
