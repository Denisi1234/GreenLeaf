import '../widgets/workspace_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';

String _dual(AppStrings strings, String english, String swahili) =>
    strings.isSwahili ? swahili : english;

enum _Strength { empty, weak, fair, strong }

extension on _Strength {
  String label(AppStrings strings) => switch (this) {
        _Strength.empty => '',
        _Strength.weak => _dual(strings, 'Weak', 'Dhaifu'),
        _Strength.fair => _dual(strings, 'Fair', 'Wastani'),
        _Strength.strong => _dual(strings, 'Strong', 'Imara'),
      };

  Color get color => switch (this) {
        _Strength.empty => AppColors.border,
        _Strength.weak => AppColors.danger,
        _Strength.fair => AppColors.warning,
        _Strength.strong => AppColors.success,
      };

  double get level => switch (this) {
        _Strength.empty => 0,
        _Strength.weak => 0.34,
        _Strength.fair => 0.67,
        _Strength.strong => 1,
      };
}

/// Full-page password change flow (Settings ▸ Account ▸ Change password).
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNext = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  static const int _minLength = 6;

  _Strength get _strength {
    final value = _next.text;
    if (value.isEmpty) return _Strength.empty;
    var score = 0;
    if (value.length >= _minLength) score++;
    if (value.length >= 10) score++;
    if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    if (score <= 2) return _Strength.weak;
    if (score <= 3) return _Strength.fair;
    return _Strength.strong;
  }

  bool get _hasMinLength => _next.text.length >= _minLength;
  bool get _hasLetter => RegExp(r'[A-Za-z]').hasMatch(_next.text);
  bool get _hasNumber => RegExp(r'\d').hasMatch(_next.text);
  bool get _matches => _next.text.isNotEmpty && _next.text == _confirm.text;
  bool get _differsFromCurrent =>
      _next.text.isNotEmpty && _next.text != _current.text;

  Future<void> _submit() async {
    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    if (!_formKey.currentState!.validate()) return;
    if (!_differsFromCurrent) {
      setState(() {
        _error = _dual(strings, 'Choose a password you have not used here',
            'Chagua nenosiri ambalo hukutumia hapa');
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    final store = context.read<PosLocalStore>();
    bool ok;
    try {
      ok = await store.changeCurrentUserPassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString();
      });
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (!ok) {
      final message = switch (store.lastAuthError) {
        'current_password_incorrect' => _dual(strings,
            'Current password is incorrect', 'Nenosiri la sasa si sahihi'),
        'password_too_short' => _dual(
            strings,
            'Password must be at least $_minLength characters',
            'Nenosiri liwe na herufi $_minLength au zaidi'),
        'user_not_found' => _dual(
            strings,
            'No local account was found for this session',
            'Hakuna akaunti ya ndani kwa kikao hiki'),
        _ => _dual(strings, 'Could not update password',
            'Imeshindikana kubadilisha nenosiri'),
      };
      setState(() => _error = message);
      return;
    }

    showMarketNotice(
      context,
      title: _dual(strings, 'Password updated', 'Nenosiri limebadilishwa'),
      message: _dual(
        strings,
        'Use your new password the next time you sign in.',
        'Tumia nenosiri jipya utakapoingia tena.',
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context.watch<PosLocalStore>().languageCode);
    final strength = _strength;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: ManagementViewport(
          maxWidth: 860,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                MarketPageHeader(
                  title:
                      _dual(strings, 'Change password', 'Badilisha nenosiri'),
                  subtitle: _dual(
                    strings,
                    'Keep your shop account secure',
                    'Linda akaunti ya duka lako',
                  ),
                  showBorder: false,
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
                      children: [
                        MarketSurfaceCard(
                          padding: const EdgeInsets.all(16),
                          borderColor: AppColors.border,
                          radius: AppRadius.standard,
                          showShadow: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: AppColors.surfaceSecondary,
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: AppColors.primary,
                                        size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _dual(strings, 'Account security',
                                          'Usalama wa akaunti'),
                                      style: AppTypography.bodyMain.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _PasswordField(
                                label: _dual(strings, 'Current password',
                                    'Nenosiri la sasa'),
                                hint: _dual(
                                    strings,
                                    'Enter your current password',
                                    'Weka nenosiri lako la sasa'),
                                controller: _current,
                                obscure: _obscureCurrent,
                                onToggle: () => setState(
                                    () => _obscureCurrent = !_obscureCurrent),
                                enabled: !_saving,
                                strings: strings,
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? _dual(
                                            strings,
                                            'Current password is required',
                                            'Nenosiri la sasa linahitajika')
                                        : null,
                              ),
                              const SizedBox(height: 14),
                              _PasswordField(
                                label: _dual(
                                    strings, 'New password', 'Nenosiri jipya'),
                                hint: _dual(
                                    strings,
                                    'At least $_minLength characters',
                                    'Herufi $_minLength au zaidi'),
                                controller: _next,
                                obscure: _obscureNext,
                                onToggle: () => setState(
                                    () => _obscureNext = !_obscureNext),
                                enabled: !_saving,
                                strings: strings,
                                onChanged: () {
                                  setState(() {});
                                  if (_error != null) {
                                    setState(() => _error = null);
                                  }
                                },
                                validator: (value) {
                                  final text = value ?? '';
                                  if (text.isEmpty) {
                                    return _dual(
                                        strings,
                                        'New password is required',
                                        'Nenosiri jipya linahitajika');
                                  }
                                  if (text.length < _minLength) {
                                    return _dual(
                                        strings,
                                        'Use at least $_minLength characters',
                                        'Tumia herufi $_minLength au zaidi');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _StrengthMeter(
                                strength: strength,
                                strings: strings,
                              ),
                              const SizedBox(height: 14),
                              _PasswordField(
                                label: _dual(strings, 'Confirm new password',
                                    'Rudia nenosiri jipya'),
                                hint: _dual(strings, 'Repeat the new password',
                                    'Rudia nenosiri jipya'),
                                controller: _confirm,
                                obscure: _obscureConfirm,
                                onToggle: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                enabled: !_saving,
                                strings: strings,
                                onChanged: () {
                                  setState(() {});
                                  if (_error != null) {
                                    setState(() => _error = null);
                                  }
                                },
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return _dual(
                                        strings,
                                        'Confirm your new password',
                                        'Thibitisha nenosiri jipya');
                                  }
                                  if (value != _next.text) {
                                    return _dual(
                                        strings,
                                        'Passwords do not match',
                                        'Manenosiri hayafanani');
                                  }
                                  return null;
                                },
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerLight,
                                    borderRadius: BorderRadius.zero,
                                    border: Border.all(
                                      color: AppColors.danger
                                          .withValues(alpha: 0.16),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.error_outline_rounded,
                                          color: AppColors.danger, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style:
                                              AppTypography.bodySmall.copyWith(
                                            color: AppColors.dangerDeep,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        MarketSurfaceCard(
                          padding: const EdgeInsets.all(16),
                          borderColor: AppColors.border,
                          radius: AppRadius.standard,
                          showShadow: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dual(strings, 'Password requirements',
                                    'Masharti ya nenosiri'),
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _RequirementRow(
                                label: _dual(
                                    strings,
                                    'At least $_minLength characters',
                                    'Herufi $_minLength au zaidi'),
                                met: _hasMinLength,
                                strings: strings,
                              ),
                              _RequirementRow(
                                label: _dual(
                                    strings, 'Contains a letter', 'Ina herufi'),
                                met: _hasLetter,
                                strings: strings,
                              ),
                              _RequirementRow(
                                label: _dual(
                                    strings, 'Contains a number', 'Ina namba'),
                                met: _hasNumber,
                                strings: strings,
                              ),
                              _RequirementRow(
                                label: _dual(strings, 'Passwords match',
                                    'Manenosiri yanafanana'),
                                met: _matches,
                                strings: strings,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _SaveButton(
                          saving: _saving,
                          label: _saving
                              ? _dual(strings, 'Updating...', 'Inasasisha...')
                              : _dual(strings, 'Update password',
                                  'Sasisha nenosiri'),
                          onTap: _saving ? null : _submit,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _dual(
                            strings,
                            'You stay signed in on this device after changing your password.',
                            'Utabaki umeingia kwenye kifaa hiki baada ya kubadilisha nenosiri.',
                          ),
                          textAlign: TextAlign.center,
                          style: AppTypography.helperText.copyWith(
                            color: AppColors.textMuted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.strength, required this.strings});

  final _Strength strength;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var index = 0; index < 3; index++) ...[
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: strength.level > index / 3
                        ? strength.color
                        : AppColors.surfaceHover,
                    borderRadius: BorderRadius.zero,
                  ),
                ),
              ),
              if (index < 2) const SizedBox(width: 4),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          strength == _Strength.empty
              ? _dual(strings, 'Start typing to check strength',
                  'Anza kuandika kuangalia nguvu')
              : '${_dual(strings, 'Strength', 'Nguvu')}: ${strength.label(strings)}',
          style: AppTypography.helperText.copyWith(
            color: strength == _Strength.empty
                ? AppColors.textMuted
                : strength.color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.label,
    required this.met,
    required this.strings,
  });

  final String label;
  final bool met;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.success : AppColors.textLight;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.helperText.copyWith(
                color: met ? AppColors.textBody : AppColors.textMuted,
                fontWeight: met ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.enabled,
    required this.strings,
    required this.validator,
    this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final bool enabled;
  final AppStrings strings;
  final FormFieldValidator<String> validator;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          enabled: enabled,
          validator: validator,
          onChanged: (_) => onChanged?.call(),
          style: AppTypography.bodyMain,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                AppTypography.bodyMain.copyWith(color: AppColors.textLight),
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: AppColors.textLight, size: 20),
            suffixIcon: IconButton(
              tooltip: obscure
                  ? _dual(strings, 'Show', 'Onyesha')
                  : _dual(strings, 'Hide', 'Ficha'),
              onPressed: enabled ? onToggle : null,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: AppColors.pageBackground,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.saving,
    required this.label,
    required this.onTap,
  });

  final bool saving;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? AppColors.border : AppColors.primary,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        highlightColor: Colors.transparent,
        splashColor: AppColors.primaryDeep.withValues(alpha: 0.3),
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Center(
            child: saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_reset_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
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
