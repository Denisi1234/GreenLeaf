import '../widgets/app_design.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import 'auth_shell.dart';

enum _ResetStep {
  enterPhone,
  enterOtp,
  newPassword,
  success,
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.onBackToSignIn,
  });

  final VoidCallback onBackToSignIn;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  _ResetStep _step = _ResetStep.enterPhone;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  String? _backendResetToken;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  void _startResendTimer() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  Future<void> _requestOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty || rawPhone.replaceAll(RegExp(r'\D'), '').length < 8) {
      setState(() => _error = 'Weka namba sahihi ya simu');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final store = context.read<PosLocalStore>();

    // OTPs must always be issued and verified by the backend so the client
    // never holds or trusts a code it generated itself.
    final api = store.cloudApi;
    if (api == null) {
      setState(() {
        _busy = false;
        _error = 'Kuweka upya nenosiri kunahitaji muunganisho wa mtandao.';
      });
      return;
    }

    bool sent = false;
    try {
      final res = await api.sendOtp(rawPhone);
      sent = (res['data'] as Map)['sent'] == true;
    } catch (_) {
      sent = false;
    }

    if (!mounted) return;
    setState(() => _busy = false);

    if (sent) {
      _startResendTimer();
      setState(() {
        _step = _ResetStep.enterOtp;
        _error = null;
      });
    } else {
      setState(() {
        _error =
            'Imeshindwa kutuma SMS. Hakikisha salio au namba ya simu ipo sawa.';
      });
    }
  }

  Future<void> _verifyOtpCode() async {
    final inputOtp = _otpController.text.trim();
    if (inputOtp.length != 6) {
      setState(() => _error = 'Ingiza namba ya uthibitisho yenye tarakimu 6');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final store = context.read<PosLocalStore>();
    final api = store.cloudApi;
    String? resetToken;

    if (api != null) {
      try {
        resetToken = await api.verifyOtp(
          _phoneController.text.trim(),
          inputOtp,
        );
      } catch (_) {
        resetToken = null;
      }
    }

    if (!mounted) return;
    setState(() => _busy = false);

    if (resetToken != null && resetToken.isNotEmpty) {
      _backendResetToken = resetToken;
      setState(() {
        _step = _ResetStep.newPassword;
        _error = null;
      });
    } else {
      setState(() {
        _error = api == null
            ? 'Uthibitisho unahitaji muunganisho wa intaneti.'
            : 'Namba ya uthibitisho si sahihi';
      });
    }
  }

  Future<void> _saveNewPassword() async {
    final newPass = _passwordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.length < 6) {
      setState(() => _error = 'Nenosiri lazima liwe na herufi zisizopungua 6');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _error = 'Nenosiri hazifanani');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final store = context.read<PosLocalStore>();
    final rawPhone = _phoneController.text.trim();
    final api = store.cloudApi;
    final resetToken = _backendResetToken;

    bool ok = false;
    if (api != null && resetToken != null) {
      try {
        ok = await api.resetPasswordWithOtp(
          phone: rawPhone,
          resetToken: resetToken,
          newPassword: newPass,
        );
      } catch (_) {
        ok = false;
      }
    }

    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      setState(() => _step = _ResetStep.success);
    } else {
      final strings = AppStrings.of(store.languageCode);
      setState(() {
        _error = store.lastAuthError == 'user_not_found'
            ? strings.userNotFound
            : strings.loginFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final isSwahili = strings.isSwahili;

    if (_step == _ResetStep.success) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.surfaceSecondary,
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.ink,
                size: 44,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSwahili ? 'Imekamilika!' : 'Password Updated!',
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            strings.passwordResetSuccess,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14.5,
              height: 1.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 32),
          AuthSubmitButton(
            label: strings.backToSignIn,
            onPressed: widget.onBackToSignIn,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _step == _ResetStep.enterOtp
              ? (isSwahili ? 'Thibitisha Namba' : 'Verify Code')
              : strings.resetPassword,
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _step == _ResetStep.enterOtp
              ? (isSwahili
                  ? 'Tumetuma namba ya siri kwa SMS kwenda ${_phoneController.text}. Weka namba hiyo hapa.'
                  : 'We have sent an SMS verification code to ${_phoneController.text}.')
              : _step == _ResetStep.newPassword
                  ? (isSwahili
                      ? 'Weka nenosiri lako jipya na uthibitishe.'
                      : 'Set your new password to access your account.')
                  : strings.resetPasswordSubtitle,
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

        // STEP 1: Enter Phone Number
        if (_step == _ResetStep.enterPhone) ...[
          AuthFieldLabel(text: strings.phoneNumber),
          TextFormField(
            controller: _phoneController,
            enabled: !_busy,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
            ],
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            onChanged: (_) => _clearError(),
            onFieldSubmitted: (_) => _requestOtp(),
            decoration: InputDecoration(
              hintText: strings.enterPhoneNumber,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 26),
          AuthSubmitButton(
            label: isSwahili ? 'Tuma Namba ya Uthibitisho' : 'Send Verification Code',
            busy: _busy,
            onPressed: _requestOtp,
          ),
        ],

        // STEP 2: Enter 6-digit OTP
        if (_step == _ResetStep.enterOtp) ...[
          AuthFieldLabel(
            text: isSwahili ? 'Namba ya Uthibitisho' : '6-Digit Code',
          ),
          TextFormField(
            controller: _otpController,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
              color: AppColors.ink,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => _clearError(),
            onFieldSubmitted: (_) => _verifyOtpCode(),
            decoration: const InputDecoration(
              hintText: '------',
              prefixIcon: Icon(Icons.mark_email_read_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _step = _ResetStep.enterPhone;
                    _otpController.clear();
                  });
                },
                child: Text(
                  isSwahili ? 'Badili Namba' : 'Change Phone',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              TextButton(
                onPressed:
                    (_resendCountdown == 0 && !_busy) ? _requestOtp : null,
                child: Text(
                  _resendCountdown > 0
                      ? (isSwahili
                          ? 'Tuma tena ($_resendCountdown s)'
                          : 'Resend in $_resendCountdown s')
                      : (isSwahili ? 'Tuma Tena SMS' : 'Resend OTP'),
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _resendCountdown > 0
                        ? AppColors.textLight
                        : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AuthSubmitButton(
            label: isSwahili ? 'Thibitisha OTP' : 'Verify Code',
            busy: _busy,
            onPressed: _verifyOtpCode,
          ),
        ],

        // STEP 3: Enter New Password
        if (_step == _ResetStep.newPassword) ...[
          AuthFieldLabel(text: strings.newPassword),
          TextFormField(
            controller: _passwordController,
            enabled: !_busy,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _clearError(),
            decoration: InputDecoration(
              hintText: strings.enterNewPassword,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuthFieldLabel(text: strings.confirmPassword),
          TextFormField(
            controller: _confirmPasswordController,
            enabled: !_busy,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onChanged: (_) => _clearError(),
            onFieldSubmitted: (_) => _saveNewPassword(),
            decoration: InputDecoration(
              hintText: strings.enterConfirmPassword,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          AuthSubmitButton(
            label: strings.resetPassword,
            busy: _busy,
            onPressed: _saveNewPassword,
          ),
        ],

        const SizedBox(height: 20),
        AuthFooter(
          question: isSwahili
              ? 'Unakumbuka nenosiri lako?'
              : 'Remember your password?',
          actionLabel: strings.signIn,
          onAction: widget.onBackToSignIn,
          enabled: !_busy,
        ),
      ],
    );
  }
}
