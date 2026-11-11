import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'settings_layout.dart';

class StoreProfilePage extends StatelessWidget {
  const StoreProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context.watch<PosLocalStore>().languageCode);
    return Theme(
      data: settingsTheme(Theme.of(context)),
      child: Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: SafeArea(
          child: Column(
            children: [
              MarketPageHeader(
                title: strings.storeProfile,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        StoreProfileForm(
                            onSaved: () => Navigator.of(context).pop()),
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

class StoreProfileForm extends StatefulWidget {
  const StoreProfileForm({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  State<StoreProfileForm> createState() => _StoreProfileFormState();
}

class _StoreProfileFormState extends State<StoreProfileForm> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _storeName = TextEditingController();
  final _contact = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  AppProfileData? _loadedProfile;
  XFile? _logoFile;
  bool _saving = false;

  @override
  void dispose() {
    _storeName.dispose();
    _contact.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _pickLogo(AppStrings strings) async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (!mounted || file == null) return;
      setState(() => _logoFile = file);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.logoUnavailable)),
      );
    }
  }

  Future<void> _save(PosLocalStore store, AppStrings strings) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      final profile = store.profile;
      await store.updateProfile(
        profile.copyWith(
          storeName: _storeName.text.trim(),
          contactNumber: _contact.text.trim(),
          emailAddress: _email.text.trim(),
          physicalAddress: _address.text.trim(),
          memberSince: profile.memberSince.isEmpty
              ? DateFormat('MMM d, yyyy', 'en').format(DateTime.now())
              : profile.memberSince,
          logoPath: _logoFile?.path,
        ),
      );
      if (!mounted) return;
      _logoFile = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.settingsSaved)),
      );
      widget.onSaved?.call();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.settingsSaveFailed)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    if (!store.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final profile = store.profile;
    if (_loadedProfile != profile) {
      _loadedProfile = profile;
      _storeName.text = profile.storeName;
      _contact.text = profile.contactNumber;
      _email.text = profile.emailAddress;
      _address.text = profile.physicalAddress;
    }

    final strings = AppStrings.of(store.languageCode);
    final logoPath = _logoFile?.path ?? profile.logoPath;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsField(
            label: strings.storeName,
            child: TextFormField(
              controller: _storeName,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              validator: (value) => value == null || value.trim().isEmpty
                  ? strings.storeNameRequired
                  : null,
            ),
          ),
          SettingsField(
            label: strings.storeLogo,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (logoPath != null && logoPath.isNotEmpty)
                    _LogoPreview(path: logoPath),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : () => _pickLogo(strings),
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: Text(strings.chooseLogo),
                  ),
                ],
              ),
            ),
          ),
          SettingsField(
            label: strings.businessAddress,
            child: TextFormField(
              controller: _address,
              enabled: !_saving,
              minLines: 2,
              maxLines: 3,
              validator: (value) => value == null || value.trim().isEmpty
                  ? strings.addressRequired
                  : null,
            ),
          ),
          SettingsField(
            label: strings.emailAddress,
            child: TextFormField(
              controller: _email,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return strings.emailRequired;
                if (!_emailPattern.hasMatch(email)) return strings.invalidEmail;
                return null;
              },
            ),
          ),
          SettingsField(
            label: strings.phoneNumber,
            child: TextFormField(
              controller: _contact,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              validator: (value) => value == null || value.trim().isEmpty
                  ? strings.phoneRequired
                  : null,
            ),
          ),
          SettingsSaveButton(
            label: _saving ? strings.saving : strings.save,
            onPressed: _saving ? null : () => _save(store, strings),
          ),
        ],
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object> image;
    if (kIsWeb) {
      image = NetworkImage(path);
    } else {
      image = FileImage(File(path));
    }
    return Image(
      image: image,
      width: 52,
      height: 52,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.storefront_outlined),
    );
  }
}
