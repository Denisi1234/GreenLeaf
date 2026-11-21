import 'package:flutter/material.dart';
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
  // 3: reset password.
  int _step = 1;
  bool _wasLoggedIn = false;

  VoidCallback? get _onBack {
    switch (_step) {
      case 1:
        return null;
      case 2:
      case 3:
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

    // Always land on the sign-in screen after a logout, even if the user was
    // last on the register or reset-password step.
    if (_wasLoggedIn && !authState.isLoggedIn) {
      _step = 1;
    }
    _wasLoggedIn = authState.isLoggedIn;

    // Show onboarding only on first launch. After that, skip straight to
    // login/register regardless of auth state.
    if (!authState.hasCompletedOnboarding) {
      return OnboardingPage(
        onGetStarted: () {
          store.markOnboardingComplete();
          setState(() => _step = 2);
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
