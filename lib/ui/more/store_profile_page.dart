import 'dart:io';

import 'package:aza_pos/l10n/app_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/app_theme_palette.dart';
import '../widgets/common/market_loading_view.dart';
import 'settings_layout.dart';

/// Clean, native Android/iOS business profile form supporting all app themes.
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
  final _owner = TextEditingController();
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
    _owner.dispose();
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
    _owner.text = profile.ownerName;
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
      showSettingsResult(context, strings.logoUnavailable, error: true);
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
          ownerName: _owner.text.trim(),
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
      showSettingsResult(context, strings.settingsSaved);
      widget.onSaved?.call();
    } catch (_) {
      if (!mounted) return;
      showSettingsResult(context, strings.settingsSaveFailed, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _inputDecoration(
    AppThemePalette palette, {
    String? hint,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: palette.textMuted, fontSize: 14),
      filled: true,
      fillColor: palette.pageBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final palette = AppThemePalette.of(context);

    if (!store.isInitialized) {
      return Scaffold(
        backgroundColor: palette.pageBackground,
        body: MarketLoadingView(
          message: context.tr('Loading Store Profile…'),
        ),
      );
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
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 32),
        children: [
          // 1. Business Details
          _GroupLabel(t('BUSINESS DETAILS', 'TAARIFA ZA BIASHARA'), palette),
          _NativeCard(
            palette: palette,
            children: [
              // Clean native logo picker row
              InkWell(
                onTap: _saving ? null : () => _pickLogo(strings),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      _LogoAvatar(path: logoPath, palette: palette),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.storeLogo,
                              style: AppTypography.bodyMain.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: palette.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              strings.chooseLogo,
                              style: AppTypography.caption.copyWith(
                                color: palette.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: palette.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, indent: 16, color: palette.divider),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FieldLabel('${strings.storeName} *', palette),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _storeName,
                      enabled: !_saving,
                      style: TextStyle(color: palette.ink, fontSize: 15),
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(palette),
                      onChanged: (_) => _markDirty(),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? strings.storeNameRequired
                              : null,
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel('${strings.businessAddress} *', palette),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _address,
                      enabled: !_saving,
                      style: TextStyle(color: palette.ink, fontSize: 15),
                      minLines: 2,
                      maxLines: 3,
                      decoration: _inputDecoration(palette),
                      onChanged: (_) => _markDirty(),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? strings.addressRequired
                              : null,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // 2. Contact
          _GroupLabel(t('CONTACT', 'MAWASILIANO'), palette),
          _NativeCard(
            palette: palette,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FieldLabel('${strings.phoneNumber} *', palette),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _contact,
                      enabled: !_saving,
                      style: TextStyle(color: palette.ink, fontSize: 15),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(palette),
                      onChanged: (_) => _markDirty(),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? strings.phoneRequired
                              : null,
                    ),
                    const SizedBox(height: 14),
                    _FieldLabel(strings.emailAddress, palette),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _email,
                      enabled: !_saving,
                      style: TextStyle(color: palette.ink, fontSize: 15),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _inputDecoration(palette),
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
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // 3. Owner
          _GroupLabel(t('OWNER', 'MMILIKI'), palette),
          _NativeCard(
            palette: palette,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FieldLabel(t('Owner name', 'Jina la mmiliki'), palette),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _owner,
                      enabled: !_saving,
                      style: TextStyle(color: palette.ink, fontSize: 15),
                      textCapitalization: TextCapitalization.words,
                      decoration: _inputDecoration(palette),
                      onChanged: (_) => _markDirty(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (widget.showOperations) ...[
            const SizedBox(height: 22),
            if (_dirty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  t(
                    'You have unsaved changes',
                    'Una mabadiliko ambayo hayajahifadhiwa',
                  ),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.warningDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : () => _save(store, strings),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                child: Text(
                  _saving
                      ? t('Saving...', 'Inahifadhi...')
                      : t('Save changes', 'Hifadhi mabadiliko'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text, this.palette);
  final String text;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
      child: Text(
        text,
        style: AppTypography.label.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: palette.textMuted,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, this.palette);
  final String text;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        color: palette.textMuted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _NativeCard extends StatelessWidget {
  const _NativeCard({required this.palette, required this.children});
  final AppThemePalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.standard),
        border: Border.all(color: palette.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(children: children),
      ),
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar({required this.path, required this.palette});

  final String? path;
  final AppThemePalette palette;

  @override
  Widget build(BuildContext context) {
    final hasLogo = path != null && path!.isNotEmpty;
    final ImageProvider<Object>? image = hasLogo
        ? (kIsWeb ? NetworkImage(path!) : FileImage(File(path!)))
            as ImageProvider<Object>
        : null;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: palette.surfaceSecondary,
        shape: BoxShape.circle,
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: image != null
          ? Image(
              image: image,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.storefront_outlined,
                size: 22,
                color: palette.textMuted,
              ),
            )
          : Icon(
              Icons.storefront_outlined,
              size: 22,
              color: palette.textMuted,
            ),
    );
  }
}
