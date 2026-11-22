import '../widgets/app_design.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/php_api_client.dart';
import '../../service/pos_local_store.dart';
import '../widgets/market_shared_widgets.dart';
import 'auth_shell.dart';

enum _RegisterStep {
  details,
  verifyOtp,
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.onSignInTap,
  });

  final VoidCallback onSignInTap;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  _RegisterStep _step = _RegisterStep.details;
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _showError(String message, AppStrings strings) {
    setState(() {
      _busy = false;
      _error = message;
    });
    showMarketNotice(
      context,
      title: strings.isSwahili ? 'Usajili umeshindwa' : 'Registration failed',
      message: message,
      type: MarketNoticeType.error,
    );
  }

  String _friendlyApiError(ApiException e, AppStrings strings) {
    final sw = strings.isSwahili;
    switch (e.status) {
      case 409:
        return strings.phoneTaken;
      case 429:
        return sw
            ? 'Majaribio mengi sana. Tafadhali subiri dakika chache na ujaribu tena.'
            : 'Too many attempts. Please wait a few minutes and try again.';
      case 401:
      case 404:
        return sw
            ? 'Namba ya uthibitisho imeisha muda. Bonyeza kutuma namba mpya.'
            : 'Verification code has expired. Tap resend to get a new code.';
      case 422:
        if (_step == _RegisterStep.verifyOtp) {
          return sw
              ? 'Namba ya uthibitisho si sahihi. Hakikisha na ujaribu tena.'
              : 'Incorrect verification code. Please check and try again.';
        }
        return sw
            ? 'Tafadhali hakikisha taarifa zako zote ni sahihi.'
            : 'Please check that your details are entered correctly.';
      case 502:
      case 503:
        return sw
            ? 'Huduma haipatikani kwa sasa. Tafadhali jaribu tena baada ya muda mfupi.'
            : 'Service is temporarily unavailable. Please try again in a moment.';
      default:
        return sw
            ? 'Imeshindwa kukamilisha usajili. Tafadhali jaribu tena.'
            : 'Could not complete registration. Please try again.';
    }
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  Future<void> _requestRegistrationOtp() async {
    final store = context.read<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);

    if (_step == _RegisterStep.details) {
      if (!_formKey.currentState!.validate()) return;
      if (_passwordController.text != _confirmPasswordController.text) {
        _showError(strings.passwordsDoNotMatch, strings);
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final api = store.cloudApi;

    if (api == null) {
      _showError(
        strings.isSwahili
            ? 'Usajili unahitaji muunganisho wa intaneti.'
            : 'Registration requires an internet connection.',
        strings,
      );
      return;
    }

    try {
      final res = await api.sendOtp(
        _phoneController.text.trim(),
        purpose: 'register',
      );
      final sent = (res['data'] as Map?)?['sent'] == true;
      if (!mounted) return;
      setState(() => _busy = false);

      if (sent) {
        _startResendTimer();
        setState(() {
          _step = _RegisterStep.verifyOtp;
          _error = null;
        });
        showMarketNotice(
          context,
          title: strings.isSwahili ? 'Namba imetumwa' : 'Verification code sent',
          message: strings.isSwahili
              ? 'Angalia SMS yako kwa namba ya uthibitisho yenye tarakimu 6.'
              : 'Check your SMS for the 6-digit verification code.',
          type: MarketNoticeType.success,
        );
      } else {
        _showError(
          strings.isSwahili
              ? 'Imeshindwa kutuma namba ya uthibitisho. Hakikisha namba yako ya simu.'
              : 'Could not send the verification code. Please check your phone number.',
          strings,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(_friendlyApiError(e, strings), strings);
    } catch (_) {
      if (!mounted) return;
      _showError(
        strings.isSwahili
            ? 'Hakuna muunganisho wa intaneti. Tafadhali jaribu tena.'
            : 'No internet connection. Please check your connection and try again.',
        strings,
      );
    }
  }

  Future<void> _verifyAndRegister() async {
    final store = context.read<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final code = _otpController.text.trim();

    if (code.length != 6) {
      _showError(
        strings.isSwahili
            ? 'Ingiza namba ya uthibitisho yenye tarakimu 6.'
            : 'Enter the 6-digit verification code.',
        strings,
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final api = store.cloudApi;
    if (api == null) {
      _showError(
        strings.isSwahili
            ? 'Usajili unahitaji muunganisho wa intaneti.'
            : 'Registration requires an internet connection.',
        strings,
      );
      return;
    }

    try {
      final otpToken = await api.verifyOtp(
        _phoneController.text.trim(),
        code,
      );

      final ok = await store.registerLive(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        otpToken: otpToken,
      );

      if (!mounted) return;
      setState(() => _busy = false);

      if (ok) {
        showMarketNotice(
          context,
          title: strings.isSwahili ? 'Akaunti imeundwa' : 'Account created',
          message: strings.isSwahili
              ? 'Karibu Aza POS! Akaunti yako iko tayari.'
              : 'Welcome to Aza POS! Your account is ready.',
          type: MarketNoticeType.success,
        );
        return;
      }

      _showError(
        store.lastAuthError == 'phone_taken'
            ? strings.phoneTaken
            : (store.lastAuthError ?? strings.loginFailed),
        strings,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(_friendlyApiError(e, strings), strings);
    } catch (_) {
      if (!mounted) return;
      _showError(
        strings.isSwahili
            ? 'Imeshindwa kuthibitisha namba. Hakikisha una intaneti na ujaribu tena.'
            : 'Could not verify the code. Check your internet connection and try again.',
        strings,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);

    if (_step == _RegisterStep.verifyOtp) {
      return _buildOtpStep(strings);
    }
    return _buildDetailsStep(strings);
  }

  Widget _buildDetailsStep(AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.createAccount,
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.isSwahili
              ? 'Fungua akaunti ya duka lako. Tutakutumia namba ya uthibitisho yenye tarakimu 6 kwa SMS.'
              : 'Create your shop account. We will send a 6-digit verification code by SMS.',
          style: GoogleFonts.manrope(
            fontSize: 14.5,
            height: 1.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        if (_error != null) ...[
          AuthErrorBanner(message: _error!),
          const SizedBox(height: 18),
        ],
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Full Name
                AuthFieldLabel(text: strings.fullName),
                TextFormField(
                  controller: _nameController,
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  onChanged: (_) => _clearError(),
                  decoration: InputDecoration(
                    hintText: strings.enterFullName,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? strings.staffNameRequired
                      : null,
                ),
                const SizedBox(height: 16),

                // 2. Phone Number
                AuthFieldLabel(text: strings.phoneNumber),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_busy,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                  ],
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  onChanged: (_) => _clearError(),
                  decoration: InputDecoration(
                    hintText: strings.enterPhoneNumber,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) return strings.phoneRequired;
                    if (v.replaceAll(RegExp(r'\D'), '').length < 8) {
                      return strings.phoneRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. Password
                AuthFieldLabel(text: strings.password),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_busy,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => _clearError(),
                  decoration: InputDecoration(
                    hintText: strings.enterPassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: _busy
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) return strings.passwordRequired;
                    if (value!.length < 6) return strings.passwordMinLength;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 5. Confirm Password
                AuthFieldLabel(text: strings.confirmPassword),
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !_busy,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _clearError(),
                  onFieldSubmitted: (_) => _requestRegistrationOtp(),
                  decoration: InputDecoration(
                    hintText: strings.enterConfirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: _busy
                          ? null
                          : () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) return strings.passwordRequired;
                    if (value != _passwordController.text) {
                      return strings.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 26),

                // Submit Button
                AuthSubmitButton(
                  label: strings.isSwahili
                      ? 'Endelea na Tuma Namba'
                      : 'Continue & Send Code',
                  busy: _busy,
                  onPressed: _requestRegistrationOtp,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        AuthFooter(
          question: strings.alreadyHaveAccount,
          actionLabel: strings.signIn,
          onAction: widget.onSignInTap,
          enabled: !_busy,
        ),
      ],
    );
  }

  Widget _buildOtpStep(AppStrings strings) {
    final phoneDisplay = _phoneController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.isSwahili ? 'Thibitisha Namba ya Simu' : 'Verify Phone Number',
          style: GoogleFonts.manrope(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.isSwahili
              ? 'Ingiza namba ya uthibitisho yenye tarakimu 6 iliyotumwa kwa SMS kwenda $phoneDisplay.'
              : 'Enter the 6-digit verification code sent via SMS to $phoneDisplay.',
          style: GoogleFonts.manrope(
            fontSize: 14.5,
            height: 1.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        if (_error != null) ...[
          AuthErrorBanner(message: _error!),
          const SizedBox(height: 18),
        ],
        AuthFieldLabel(
          text: strings.isSwahili
              ? 'Namba ya Uthibitisho'
              : 'Verification Code',
        ),
        TextFormField(
          controller: _otpController,
          enabled: !_busy,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => _clearError(),
          onFieldSubmitted: (_) => _verifyAndRegister(),
          style: GoogleFonts.manrope(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 10,
            color: AppColors.ink,
          ),
          decoration: const InputDecoration(
            hintText: '000000',
            counterText: '',
          ),
        ),
        const SizedBox(height: 22),
        AuthSubmitButton(
          label: strings.isSwahili
              ? 'Thibitisha na Fungua Akaunti'
              : 'Verify & Create Account',
          busy: _busy,
          onPressed: _verifyAndRegister,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _step = _RegisterStep.details;
                          _otpController.clear();
                          _error = null;
                        }),
                child: Text(
                  strings.isSwahili ? 'Badili namba' : 'Change number',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            Flexible(
              child: TextButton(
                onPressed: (_busy || _resendCountdown > 0)
                    ? null
                    : _requestRegistrationOtp,
                child: Text(
                  _resendCountdown > 0
                      ? (strings.isSwahili
                          ? 'Tuma tena (${_resendCountdown}s)'
                          : 'Resend (${_resendCountdown}s)')
                      : (strings.isSwahili ? 'Tuma OTP tena' : 'Resend OTP'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
