import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/market_shared_widgets.dart';

class StoreFormResult {
  const StoreFormResult({
    required this.name,
    required this.category,
    required this.address,
    required this.contactNumber,
    required this.taxId,
    required this.weekdayOpen,
    required this.weekdayClose,
    required this.saturdayOpen,
    required this.saturdayClose,
    required this.sundaySchedule,
    required this.open24Hours,
    this.logoPath,
  });

  final String name;
  final String category;
  final String address;
  final String contactNumber;
  final String taxId;
  final String weekdayOpen;
  final String weekdayClose;
  final String saturdayOpen;
  final String saturdayClose;
  final String sundaySchedule;
  final bool open24Hours;
  final String? logoPath;
}

class AddEditStorePage extends StatefulWidget {
  const AddEditStorePage({
    super.key,
    this.initialStore,
  });

  final StoreFormResult? initialStore;

  @override
  State<AddEditStorePage> createState() => _AddEditStorePageState();
}

class _AddEditStorePageState extends State<AddEditStorePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _picker = ImagePicker();

  static const _categories = [
    'Retail',
    'Restaurant',
    'Pharmacy',
    'Electronics',
    'Warehouse',
    'Supermarket',
  ];

  String? _selectedCategory;
  String _weekdayOpen = '09:00 AM';
  String _weekdayClose = '09:00 PM';
  String _saturdayOpen = '10:00 AM';
  String _saturdayClose = '08:00 PM';
  String _sundaySchedule = 'Closed';
  bool _open24Hours = false;
  bool _isSaving = false;
  XFile? _logoFile;
  String? _initialLogoPath;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStore;
    if (initial != null) {
      _nameController.text = initial.name;
      _addressController.text = initial.address;
      _contactController.text = initial.contactNumber;
      _taxIdController.text = initial.taxId;
      _selectedCategory = initial.category;
      _weekdayOpen = initial.weekdayOpen == 'Open 24 Hours'
          ? '09:00 AM'
          : initial.weekdayOpen;
      _weekdayClose = initial.weekdayClose == 'Open 24 Hours'
          ? '09:00 PM'
          : initial.weekdayClose;
      _saturdayOpen = initial.saturdayOpen == 'Open 24 Hours'
          ? '10:00 AM'
          : initial.saturdayOpen;
      _saturdayClose = initial.saturdayClose == 'Open 24 Hours'
          ? '08:00 PM'
          : initial.saturdayClose;
      _sundaySchedule = initial.sundaySchedule;
      _open24Hours = initial.open24Hours;
      _initialLogoPath = initial.logoPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (!mounted || file == null) {
        return;
      }
      setState(() {
        _logoFile = file;
        _initialLogoPath = null;
      });
      showMarketNotice(
        context,
        title: 'Logo Added',
        message: 'Store logo is ready to save',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      showMarketNotice(
        context,
        title: 'Logo Unavailable',
        message: 'Restart the app if image access was just enabled',
        type: MarketNoticeType.warning,
      );
    }
  }

  Future<void> _saveStore() async {
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

    setState(() {
      _isSaving = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(
      StoreFormResult(
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        address: _addressController.text.trim(),
        contactNumber: _contactController.text.trim(),
        taxId: _taxIdController.text.trim(),
        weekdayOpen: _open24Hours ? 'Open 24 Hours' : _weekdayOpen,
        weekdayClose: _open24Hours ? 'Open 24 Hours' : _weekdayClose,
        saturdayOpen: _open24Hours ? 'Open 24 Hours' : _saturdayOpen,
        saturdayClose: _open24Hours ? 'Open 24 Hours' : _saturdayClose,
        sundaySchedule: _open24Hours ? 'Open 24 Hours' : _sundaySchedule,
        open24Hours: _open24Hours,
        logoPath: _logoFile?.path ?? _initialLogoPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _logoFile?.path ?? _initialLogoPath;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: Column(
          children: [
            const MarketPageHeader(title: 'Add/Edit Store'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      MarketSurfaceCard(
                        padding: const EdgeInsets.all(18),
                        backgroundColor: Colors.white,
                        borderColor: const Color(0xFFE2E7EF),
                        radius: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Store Logo',
                              style: TextStyle(
                                color: Color(0xFF21395F),
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 118,
                                      height: 118,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF0FF),
                                        shape: BoxShape.circle,
                                        image: imagePath == null
                                            ? null
                                            : DecorationImage(
                                                image:
                                                    FileImage(File(imagePath)),
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                      child: imagePath == null
                                          ? const Icon(
                                              Icons.storefront_outlined,
                                              color: Color(0xFF1562E8),
                                              size: 62,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      right: -2,
                                      bottom: 6,
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF1562E8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 26),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Upload Store Logo',
                                        style: TextStyle(
                                          color: Color(0xFF21395F),
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'JPG, PNG up to 2MB',
                                        style: TextStyle(
                                          color: Color(0xFF7B8494),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      OutlinedButton.icon(
                                        onPressed: _pickLogo,
                                        icon: const Icon(
                                          Icons.upload_outlined,
                                          color: Color(0xFF1562E8),
                                        ),
                                        label: const Text(
                                          'Upload Logo',
                                          style: TextStyle(
                                            color: Color(0xFF1562E8),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 56),
                                          side: const BorderSide(
                                              color: Color(0xFF1562E8)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      MarketSurfaceCard(
                        padding: const EdgeInsets.all(18),
                        backgroundColor: Colors.white,
                        borderColor: Colors.transparent,
                        radius: 4,
                        child: Column(
                          children: [
                            _StoreFormRow(
                              icon: Icons.storefront_outlined,
                              label: 'Store Name',
                              child: _StoreTextField(
                                controller: _nameController,
                                hintText: 'Enter store name',
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'Store name is required'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _StoreFormRow(
                              icon: Icons.sell_outlined,
                              label: 'Business Category',
                              child: _StoreDropdownField<String>(
                                value: _selectedCategory,
                                hintText: 'Select category',
                                items: _categories,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategory = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 14),
                            _StoreFormRow(
                              icon: Icons.location_on_outlined,
                              label: 'Address',
                              child: _StoreTextField(
                                controller: _addressController,
                                hintText: 'Enter store address',
                                maxLines: 2,
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'Address is required'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _StoreFormRow(
                              icon: Icons.call_outlined,
                              label: 'Contact Number',
                              child: _StoreTextField(
                                controller: _contactController,
                                hintText: 'Enter contact number',
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'Contact number is required'
                                        : null,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _StoreFormRow(
                              icon: Icons.description_outlined,
                              label: 'Tax ID',
                              child: _StoreTextField(
                                controller: _taxIdController,
                                hintText: 'Enter tax ID (e.g., 12-3456789)',
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'Tax ID is required'
                                        : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _isSaving ? null : _saveStore,
                        child: Container(
                          height: 74,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1562E8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isSaving
                                    ? Icons.hourglass_top_rounded
                                    : Icons.save_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Save Store',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class _StoreFormRow extends StatelessWidget {
  const _StoreFormRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 226,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF1562E8), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF21395F),
                      fontSize: 15.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _StoreTextField extends StatelessWidget {
  const _StoreTextField({
    required this.controller,
    required this.hintText,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        color: Color(0xFF21395F),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF9AA4B3),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: _storeBorder(),
        enabledBorder: _storeBorder(),
        focusedBorder: _storeBorder(const Color(0xFFB7C7EA)),
        errorBorder: _storeBorder(const Color(0xFFE26B6B)),
        focusedErrorBorder: _storeBorder(const Color(0xFFE26B6B)),
        errorStyle: const TextStyle(
          color: Color(0xFFD9485F),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StoreDropdownField<T> extends StatelessWidget {
  const _StoreDropdownField({
    this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
  });

  final T? value;
  final List<T> items;
  final ValueChanged<T?>? onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDDE2EA)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: hintText == null
              ? null
              : Text(
                  hintText!,
                  style: const TextStyle(
                    color: Color(0xFF9AA4B3),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF5B6474),
            size: 26,
          ),
          style: const TextStyle(
            color: Color(0xFF21395F),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(item.toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

OutlineInputBorder _storeBorder([Color color = const Color(0xFFDDE2EA)]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: BorderSide(color: color),
  );
}
