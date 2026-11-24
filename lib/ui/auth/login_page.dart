import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
import '../widgets/market_shared_widgets.dart';
import 'auth_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onRegisterTap,
    this.onForgotPasswordTap,
  });

  final VoidCallback onRegisterTap;
  final VoidCallback? onForgotPasswordTap;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final store = context.read<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);
    final ok = await store.login(
      _phoneController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      showMarketNotice(
        context,
        title: strings.isSwahili ? 'Karibu tena' : 'Signed in',
        message: strings.isSwahili
            ? 'Umeingia kwenye akaunti yako kwa mafanikio.'
            : 'Welcome back to Aza POS.',
        type: MarketNoticeType.success,
      );
      return;
    }

    final errorMessage = store.lastAuthError == 'user_not_found'
        ? strings.userNotFound
        : strings.loginFailed;
    showMarketNotice(
      context,
      title: strings.isSwahili ? 'Imeshindwa kuingia' : 'Sign in failed',
      message: errorMessage,
      type: MarketNoticeType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<PosLocalStore>();
    final strings = AppStrings.of(store.languageCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.welcomeBack,
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
              ? 'Ingiza namba yako ya simu na nenosiri ili uendelee.'
              : 'Enter your phone number and password to access your shop.',
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
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A staff member may use the username assigned in Staff setup,
                // their phone number, or their email address.
                AuthFieldLabel(
                  text: strings.isSwahili
                      ? 'Simu, jina la mtumiaji, au barua pepe'
                      : 'Phone, username, or email',
                ),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_busy,
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9@._+\-\s]')),
                  ],
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.username],
                  onChanged: (_) => _clearError(),
                  decoration: InputDecoration(
                    hintText: strings.isSwahili
                        ? 'Weka simu, jina la mtumiaji, au barua pepe'
                        : 'Enter phone, username, or email',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    final v = (value ?? '').trim();
                    if (v.isEmpty) {
                      return strings.isSwahili
                          ? 'Weka simu, jina la mtumiaji, au barua pepe'
                          : 'Enter your phone, username, or email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AuthFieldLabel(text: strings.password),
                    if (widget.onForgotPasswordTap != null)
                      TextButton(
                        onPressed: widget.onForgotPasswordTap,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        child: Text(
                          strings.forgotPassword,
                          style: GoogleFonts.manrope(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDeep,
                          ),
                        ),
                      ),
                  ],
                ),
                TextFormField(
                  controller: _passwordController,
                  enabled: !_busy,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onChanged: (_) => _clearError(),
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    hintText: strings.enterPassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: _busy
                          ? null
                          : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) return strings.passwordRequired;
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Sign In Button
                AuthSubmitButton(
                  label: strings.signIn,
                  busy: _busy,
                  onPressed: _signIn,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        AuthFooter(
          question: strings.noAccount,
          actionLabel: strings.createOne,
          onAction: widget.onRegisterTap,
          enabled: !_busy,
        ),
      ],
    );
  }
}
