import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../shell/app_shell.dart';
import '../widgets/app_design.dart';
import '../widgets/capability_provider.dart';
import 'auth_shell.dart';
import 'login_page.dart';
import 'onboarding_page.dart';
import 'register_page.dart';
import 'reset_password_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // 0: login (onboarding is handled separately), 1: login, 2: register,
  // 3: reset password, 4: first-time owner setup.
  int _step = 1;
  bool _wasLoggedIn = false;

  VoidCallback? get _onBack {
    switch (_step) {
      case 1:
        return null;
      case 2:
      case 3:
      case 4:
        return () => setState(() => _step = 1);
      default:
        return null;
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return LoginPage(
          onRegisterTap: () => setState(() => _step = 2),
          onForgotPasswordTap: () => setState(() => _step = 3),
        );
      case 2:
        return RegisterPage(
          onSignInTap: () => setState(() => _step = 1),
        );
      case 3:
        return ResetPasswordPage(
          onBackToSignIn: () => setState(() => _step = 1),
        );
      case 4:
        return FirstOwnerSetupPage(
          onComplete: () => setState(() => _step = 1),
          onSignIn: () => setState(() => _step = 1),
        );
      default:
        return LoginPage(
          onRegisterTap: () => setState(() => _step = 2),
          onForgotPasswordTap: () => setState(() => _step = 3),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.select<
        PosLocalStore,
        ({
          bool isLoggedIn,
          bool hasCompletedOnboarding,
          String languageCode,
        })>(
      (s) => (
        isLoggedIn: s.isLoggedIn,
        hasCompletedOnboarding: s.hasCompletedOnboarding,
        languageCode: s.languageCode,
      ),
    );
    final store = context.read<PosLocalStore>();
    final strings = AppStrings.of(authState.languageCode);

    if (_wasLoggedIn && !authState.isLoggedIn) {
      _step = 1;
    }
    _wasLoggedIn = authState.isLoggedIn;

    if (!authState.hasCompletedOnboarding) {
      return OnboardingPage(
        onGetStarted: () async {
          store.markOnboardingComplete();
          if (store.staffMembers.isEmpty) {
            setState(() => _step = 4);
          } else {
            setState(() => _step = 2);
          }
        },
        onSignIn: () {
          store.markOnboardingComplete();
          setState(() => _step = 1);
        },
      );
    }

    if (!authState.isLoggedIn) {
      return AuthShell(
        strings: strings,
        onBack: _onBack,
        showMobileBrand: true,
        child: AnimatedSwitcher(
          duration: AppDurations.normal,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: _buildStep(),
          ),
        ),
      );
    }

    return CapabilityProvider(
      capabilities: store.activeCapabilities,
      child: const AppShell(),
    );
  }
}

/// First-time owner setup: the first person to open the app becomes the
/// store owner/admin by default. No OTP required for local-only setup.
class FirstOwnerSetupPage extends StatefulWidget {
  const FirstOwnerSetupPage({
    super.key,
    required this.onComplete,
    required this.onSignIn,
  });

  final VoidCallback onComplete;
  final VoidCallback onSignIn;

  @override
  State<FirstOwnerSetupPage> createState() => _FirstOwnerSetupPageState();
}

class _FirstOwnerSetupPageState extends State<FirstOwnerSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createOwner() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final store = context.read<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);

    try {
      final ok = await store.register(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      setState(() => _busy = false);

      if (ok) {
        widget.onComplete();
      } else {
        setState(() => _error = store.lastAuthError ?? strings.loginFailed);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = strings.isSwahili
            ? 'Hakuna muunganisho wa intaneti. Tafadhali jaribu tena.'
            : 'No internet connection. Please check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.isSwahili ? 'Weka Akaunti ya Mwenyeji' : 'Set Up Owner Account',
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
              ? 'Mwanzo mwingine ukiwa na app hii utawa mwenyeji wa duka.'
              : 'The first person to open this app becomes the store owner.'
              '\nEnter your details to create the owner account.',
          style: GoogleFonts.manrope(
            fontSize: 14.5,
            height: 1.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 26),
        if (_error != null) ...[
          AuthErrorBanner(message: _error!),
          const SizedBox(height: 18),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthFieldLabel(text: strings.fullName),
              TextFormField(
                controller: _nameController,
                enabled: !_busy,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: InputDecoration(
                  hintText: strings.enterFullName,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? strings.staffNameRequired
                    : null,
              ),
              const SizedBox(height: 16),
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
              AuthFieldLabel(text: strings.password),
              TextFormField(
                controller: _passwordController,
                enabled: !_busy,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _createOwner(),
                decoration: InputDecoration(
                  hintText: strings.enterPassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
                validator: (value) {
                  if ((value ?? '').isEmpty) return strings.passwordRequired;
                  if (value!.length < 6) return strings.passwordMinLength;
                  return null;
                },
              ),
              const SizedBox(height: 26),
              AuthSubmitButton(
                label: strings.isSwahili
                    ? 'Funga Akaunti ya Mwenyeji'
                    : 'Create Owner Account',
                busy: _busy,
                onPressed: _createOwner,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        AuthFooter(
          question: strings.alreadyHaveAccount,
          actionLabel: strings.signIn,
          onAction: widget.onSignIn,
          enabled: !_busy,
        ),
      ],
    );
  }
}
