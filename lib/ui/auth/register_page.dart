import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:provider/provider.dart';

  import '../../l10n/app_strings.dart';
  import '../../service/pos_local_store.dart';
  import 'auth_shell.dart';

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
  bool _busy = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = AppStrings.of(
            context.read<PosLocalStore>().languageCode,
          ).passwordsDoNotMatch);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final store = context.read<PosLocalStore>();
    final ok = await store.register(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      return;
    }

    final strings = AppStrings.of(context.read<PosLocalStore>().languageCode);
    setState(() {
      if (store.lastAuthError == 'phone_taken') {
        _error = strings.phoneTaken;
      } else {
        _error = strings.loginFailed;
      }
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
          strings.createAccount,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: const Color(0xFF111111),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          strings.isSwahili
              ? 'Weka taarifa zako za msingi ili kuanza kutumia mfumo.'
              : 'Enter your basic details to set up your business account.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            height: 1.5,
            color: const Color(0xFF64748B),
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

                // 3. Password
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

                // 4. Confirm Password
                AuthFieldLabel(text: strings.confirmPassword),
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !_busy,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _clearError(),
                  onFieldSubmitted: (_) => _createAccount(),
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
                  label: strings.createAccount,
                  busy: _busy,
                  onPressed: _createAccount,
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
}
