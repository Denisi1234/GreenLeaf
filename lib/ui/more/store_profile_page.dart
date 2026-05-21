import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../service/pos_local_store.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1F5FD7),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Store Profile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9F0FF),
                                borderRadius: BorderRadius.circular(74),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(74),
                                child: logoPath == null
                                    ? const Icon(
                                        Icons.storefront_outlined,
                                        color: Color(0xFF1F5FD7),
                                        size: 40,
                                      )
                                    : Image.file(
                                        File(logoPath),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Keep your store information up to date.',
                                      style: TextStyle(
                                        color: Color(0xFF202938),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'This information will be used for receipts and business records.',
                                      style: TextStyle(
                                        color: Color(0xFF6F7887),
                                        fontSize: 13.5,
                                        height: 1.35,
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
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 14),
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
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Upload Store Logo',
                          style: TextStyle(
                            color: Color(0xFF202938),
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickLogo,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 26,
                            horizontal: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF5A86D8),
                              style: BorderStyle.solid,
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9F0FF),
                                  borderRadius: BorderRadius.circular(58),
                                ),
                                child: const Icon(
                                  Icons.cloud_upload_outlined,
                                  color: Color(0xFF1F5FD7),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tap to upload logo',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF1F5FD7),
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Recommended size: 512 x 512 px\nJPG, PNG up to 2MB',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF6F7887),
                                  fontSize: 12.8,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
              color: Color(0xFF202938),
              fontSize: 14.4,
              fontWeight: FontWeight.w700,
            ),
            children: [
              TextSpan(text: label),
              if (requiredField)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFE53935)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD0D6E0)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(
              color: Color(0xFF202938),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF6F7887),
                size: 22,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9AA3B2),
                fontSize: 14.5,
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
              color: Color(0xFF202938),
              fontSize: 14.4,
              fontWeight: FontWeight.w700,
            ),
            children: [
              TextSpan(text: label),
              if (requiredField)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFE53935)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD0D6E0)),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            borderRadius: BorderRadius.circular(8),
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6F7887),
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFF6F7887),
                size: 22,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9AA3B2),
                fontSize: 14.5,
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
                        color: Color(0xFF202938),
                        fontSize: 14.8,
                        fontWeight: FontWeight.w600,
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
