import 'dart:async';
import '../widgets/workspace_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../models/customer_data.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

const List<String> kCustomerTagOptions = <String>[
  'VIP',
  'Wholesale',
  'Retail',
  'Credit',
];

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

class CreateCustomerPage extends StatefulWidget {
  const CreateCustomerPage({super.key, this.existing});

  final CustomerData? existing;

  @override
  State<CreateCustomerPage> createState() => _CreateCustomerPageState();
}

class _CreateCustomerPageState extends State<CreateCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late Set<String> _tags;
  bool _isSaving = false;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final customer = widget.existing;
    _nameController = TextEditingController(text: customer?.name ?? '');
    _phoneController = TextEditingController(text: customer?.phone ?? '');
    _emailController = TextEditingController(text: customer?.email ?? '');
    _addressController = TextEditingController(text: customer?.address ?? '');
    _tags = <String>{...?customer?.tags};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
  }

  Future<void> _saveCustomer() async {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    if (!_formKey.currentState!.validate()) {
      showMarketNotice(
        context,
        title: _dual(strings, 'Check the form', 'Kagua fomu'),
        message: _dual(strings, 'Complete the customer details before saving',
            'Kamilisha maelezo ya mteja kabla ya kuhifadhi'),
        type: MarketNoticeType.warning,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final store = context.read<PosLocalStore>();
    final existing = widget.existing;
    final customer = (existing ??
            CustomerData(
              id: 'CUST-${DateTime.now().millisecondsSinceEpoch}',
              name: '',
              phone: '',
            ))
        .copyWith(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      tags: _tags.toList(growable: false),
    );

    try {
      if (existing == null) {
        await store.addCustomer(customer);
      } else {
        await store.updateCustomer(customer);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    if (!mounted) return;

    showMarketNotice(
      context,
      title: _isEdit
          ? _dual(strings, 'Customer updated', 'Mteja amesasishwa')
          : _dual(strings, 'Customer saved', 'Mteja amehifadhiwa'),
      message: _dual(
        strings,
        '${customer.name} has been ${_isEdit ? 'updated' : 'added'}.',
        '${customer.name} ${_isEdit ? 'amesasishwa' : 'ameongezwa'}.',
      ),
    );
    Navigator.of(context).pop(customer.name);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context.watch<PosLocalStore>().languageCode);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 860,
          child: SafeArea(
            child: Column(
              children: [
                MarketPageHeader(
                  title: _isEdit
                      ? _dual(strings, 'Edit Customer', 'Hariri Mteja')
                      : _dual(strings, 'Create Customer', 'Ongeza Mteja'),
                  subtitle: _dual(strings, 'Contact and loyalty details',
                      'Maelezo ya mawasiliano na uaminifu'),
                  showBorder: false,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MarketSectionHeader(
                            title: _dual(strings, 'Customer details',
                                'Maelezo ya mteja'),
                            trailing: const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 10),
                          _CustomerField(
                            label: _dual(
                                strings, 'Customer name', 'Jina la mteja'),
                            hint: _dual(strings, 'Enter customer name',
                                'Weka jina la mteja'),
                            controller: _nameController,
                            icon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? _dual(
                                        strings,
                                        'Customer name is required',
                                        'Jina la mteja linahitajika')
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          _CustomerField(
                            label:
                                _dual(strings, 'Phone number', 'Namba ya simu'),
                            hint: _dual(strings, 'Enter phone number',
                                'Weka namba ya simu'),
                            controller: _phoneController,
                            icon: Icons.call_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? _dual(strings, 'Phone number is required',
                                        'Namba ya simu inahitajika')
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          _CustomerField(
                            label: _dual(strings, 'Email', 'Barua pepe'),
                            hint: _dual(strings, 'Optional email address',
                                'Barua pepe (si lazima)'),
                            controller: _emailController,
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final email = (value ?? '').trim();
                              if (email.isEmpty) return null;
                              final valid =
                                  RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$')
                                      .hasMatch(email);
                              return valid
                                  ? null
                                  : _dual(
                                      strings,
                                      'Enter a valid email address',
                                      'Weka barua pepe sahihi');
                            },
                          ),
                          const SizedBox(height: 14),
                          _CustomerField(
                            label: _dual(strings, 'Address', 'Anwani'),
                            hint: _dual(strings, 'Optional physical address',
                                'Anwani (si lazima)'),
                            controller: _addressController,
                            icon: Icons.location_on_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _dual(strings, 'Tags', 'Lebo'),
                            style: AppTypography.label,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final tag in kCustomerTagOptions)
                                _TagChip(
                                  label: tag,
                                  selected: _tags.contains(tag),
                                  onTap: () => _toggleTag(tag),
                                ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          _SaveButton(
                            saving: _isSaving,
                            label: _isSaving
                                ? _dual(strings, 'Saving...', 'Inahifadhi...')
                                : _isEdit
                                    ? _dual(strings, 'Save changes',
                                        'Hifadhi mabadiliko')
                                    : _dual(strings, 'Create customer',
                                        'Unda mteja'),
                            onTap: _isSaving ? null : _saveCustomer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded,
                  size: 13, color: AppColors.primaryDeep),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.helperText.copyWith(
                color: selected ? AppColors.primaryDeep : AppColors.textBody,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton(
      {required this.saving, required this.label, required this.onTap});
  final bool saving;
  final String label;
  final FutureOr<void> Function()? onTap;
  @override
  Widget build(BuildContext context) => MarketButton(
        label: label,
        onTap: saving ? null : onTap,
        icon: Icons.check_rounded,
        color: AppColors.successDeep,
        height: 52,
      );
}

class _CustomerField extends StatelessWidget {
  const _CustomerField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          style: AppTypography.bodyMain,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTypography.bodyMain.copyWith(color: AppColors.textLight),
            prefixIcon: Icon(icon, color: AppColors.textLight, size: 20),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.danger, width: 1.5),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
