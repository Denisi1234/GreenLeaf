import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../service/pos_local_store.dart';
import '../widgets/app_design.dart';
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
    final ok = await store.login(
      _phoneController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) return;

    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    setState(() {
      _error = store.lastAuthError == 'user_not_found'
          ? strings.userNotFound
          : strings.loginFailed;
    });
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
          style: GoogleFonts.plusJakartaSans(
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
          style: GoogleFonts.plusJakartaSans(
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
                // Phone Number Field
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
                      GestureDetector(
                        onTap: widget.onForgotPasswordTap,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            strings.forgotPassword,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
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
