import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import 'settings_layout.dart';

/// Business profile form shared by the Settings page.
///
/// [showOperations] controls the save button, so the form can also be embedded
/// in surfaces that save it themselves.
class StoreProfileForm extends StatefulWidget {
  const StoreProfileForm({
    super.key,
    this.onSaved,
    this.showOperations = true,
  });

  final VoidCallback? onSaved;
  final bool showOperations;

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
  final _taxId = TextEditingController();
  final _owner = TextEditingController();
  final _role = TextEditingController();
  AppProfileData? _loadedProfile;
  XFile? _logoFile;
  bool _saving = false;
  bool _dirty = false;

  @override
  void dispose() {
    _storeName.dispose();
    _contact.dispose();
    _email.dispose();
    _address.dispose();
    _taxId.dispose();
    _owner.dispose();
    _role.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _loadProfile(AppProfileData profile) {
    _loadedProfile = profile;
    _storeName.text = profile.storeName;
    _contact.text = profile.contactNumber;
    _email.text = profile.emailAddress;
    _address.text = profile.physicalAddress;
    _taxId.text = profile.taxId;
    _owner.text = profile.ownerName;
    _role.text = profile.roleTitle;
    _dirty = false;
  }

  Future<void> _pickLogo(AppStrings strings) async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (!mounted || file == null) return;
      setState(() {
        _logoFile = file;
        _dirty = true;
      });
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
          taxId: _taxId.text.trim(),
          ownerName: _owner.text.trim(),
          roleTitle: _role.text.trim(),
          memberSince: profile.memberSince.isEmpty
              ? DateFormat('MMM d, yyyy', 'en').format(DateTime.now())
              : profile.memberSince,
          logoPath: _logoFile?.path,
        ),
      );
      if (!mounted) return;
      setState(() {
        _logoFile = null;
        _dirty = false;
      });
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
      _loadProfile(profile);
    }

    final strings = AppStrings.of(store.languageCode);
    final logoPath = _logoFile?.path ?? profile.logoPath;
    String t(String en, String sw) => settingsText(store.languageCode, en, sw);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          SettingsCard(
            icon: Icons.storefront_outlined,
            title: t('Business details', 'Taarifa za biashara'),
            description: t(
              'Shown on receipts, reports and the customer app.',
              'Huonekana kwenye risiti, ripoti na programu ya wateja.',
            ),
            children: [
              SettingsField(
                label: strings.storeName,
                required: true,
                child: TextFormField(
                  controller: _storeName,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _markDirty(),
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
                        style: OutlinedButton.styleFrom(
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: Text(strings.chooseLogo),
                      ),
                    ],
                  ),
                ),
              ),
              SettingsField(
                label: strings.businessAddress,
                required: true,
                child: TextFormField(
                  controller: _address,
                  enabled: !_saving,
                  minLines: 2,
                  maxLines: 3,
                  onChanged: (_) => _markDirty(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? strings.addressRequired
                      : null,
                ),
              ),
            ],
          ),
          SettingsCard(
            icon: Icons.contact_phone_outlined,
            title: t('Contact', 'Mawasiliano'),
            description: t(
              'How customers and suppliers reach you.',
              'Jinsi wateja na wasambazaji wanavyokufikia.',
            ),
            children: [
              SettingsField(
                label: strings.phoneNumber,
                required: true,
                child: TextFormField(
                  controller: _contact,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  onChanged: (_) => _markDirty(),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? strings.phoneRequired
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
                  onChanged: (_) => _markDirty(),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return strings.emailRequired;
                    if (!_emailPattern.hasMatch(email)) {
                      return strings.invalidEmail;
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          SettingsCard(
            icon: Icons.badge_outlined,
            title: t('Owner & registration', 'Mmiliki na usajili'),
            description: t(
              'Appears on reports and legal documents.',
              'Huonekana kwenye ripoti na nyaraka rasmi.',
            ),
            children: [
              SettingsField(
                label: t('Owner name', 'Jina la mmiliki'),
                child: TextFormField(
                  controller: _owner,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _markDirty(),
                ),
              ),
              SettingsField(
                label: t('Role / title', 'Wajibu'),
                hint: t('e.g. Owner, Manager', 'mf. Mmiliki, Meneja'),
                child: TextFormField(
                  controller: _role,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => _markDirty(),
                ),
              ),
              SettingsField(
                label: t('Tax registration (TIN)', 'Usajili wa kodi (TIN)'),
                hint: t(
                  'Printed on receipts when enabled.',
                  'Huchapishwa kwenye risiti ukipowasha.',
                ),
                child: TextFormField(
                  controller: _taxId,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _markDirty(),
                ),
              ),
            ],
          ),
          if (widget.showOperations) ...[
            Row(
              children: [
                if (_dirty)
                  Expanded(
                    child: Text(
                      t(
                        'Unsaved changes',
                        'Mabadiliko ambayo hayajahifadhiwa',
                      ),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warningDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                SettingsSaveButton(
                  label: _saving
                      ? t('Saving...', 'Inahifadhi...')
                      : (t('Save changes', 'Hifadhi mabadiliko')),
                  onPressed: _saving ? null : () => _save(store, strings),
                ),
              ],
            ),
          ],
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
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
      ),
      child: Image(
        image: image,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.storefront_outlined),
      ),
    );
  }
}
