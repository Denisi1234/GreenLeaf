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
  int _step = 0; // 0: onboarding, 1: login, 2: register, 3: reset_password

  VoidCallback? get _onBack {
    switch (_step) {
      case 1:
        return () => setState(() => _step = 0);
      case 2:
      case 3:
        return () => setState(() => _step = 1);
      default:
        return null;
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return OnboardingPage(
          onGetStarted: () => setState(() => _step = 2),
          onSignIn: () => setState(() => _step = 1),
        );
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
      default:
        return ResetPasswordPage(
          onBackToSignIn: () => setState(() => _step = 1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);

    if (!store.isLoggedIn) {
      if (_step == 0) {
        return OnboardingPage(
          onGetStarted: () => setState(() => _step = 2),
          onSignIn: () => setState(() => _step = 1),
        );
      }

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
