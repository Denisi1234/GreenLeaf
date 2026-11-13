import pathlib

path = pathlib.Path(r"lib\ui\auth\cloud_bootstrap.dart")
text = path.read_text(encoding="utf-8")

old = r"""import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../service/php_api_client.dart';
import '../../service/pos_hybrid_database.dart';
import '../../service/pos_local_database.dart';
import '../../service/pos_local_store.dart';
import '../more/settings_layout.dart';
import '../widgets/app_theme.dart';

class CloudBootstrap extends StatefulWidget {
  const CloudBootstrap({super.key});

  @override
  State<CloudBootstrap> createState() => _CloudBootstrapState();
}

class _CloudBootstrapState extends State<CloudBootstrap>
    with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final _endpoint = TextEditingController(
    text: const String.fromEnvironment('TRACKMAUZO_API_URL',
        defaultValue: 'http://127.0.0.1:8080/api'),
  );
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _shop = TextEditingController();
  PosLocalStore? _store;
  PhpApiClient? _api;
  PosHybridDatabase? _hybrid;
  bool _register = false;
  bool _busy = false;
  bool _restoring = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endpoint.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _shop.dispose();
    _hybrid?.dispose();
    _store?.dispose();
    _api?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final hybrid = _hybrid;
      if (hybrid != null) unawaited(hybrid.syncNow(pull: true));
    }
  }

  Future<void> _restoreSession() async {
    PosHybridDatabase? hybrid;
    PosLocalStore? store;
    PhpApiClient? api;
    try {
      final session = await PosLocalDatabase.instance.loadSyncSession();
      if (session == null) return;
      final endpoint = (session['endpoint'] as String?)?.trim() ?? '';
      final token = session['token'] as String? ?? '';
      if (endpoint.isEmpty || token.isEmpty) {
        await PosLocalDatabase.instance.clearSyncSession();
        return;
      }
      final user = jsonDecode(session['user_json'] as String? ?? '{}');
      if (user is! Map) {
        await PosLocalDatabase.instance.clearSyncSession();
        return;
      }
      api = PhpApiClient(endpoint)
        ..restoreSession(
          token: token,
          user: Map<String, dynamic>.from(user),
        );
      hybrid = PosHybridDatabase(api);
      await hybrid.prepare();
      store = PosLocalStore(database: hybrid);
      await store.initialize();
      if (!mounted) {
        hybrid.dispose();
        store.dispose();
        api.close();
        return;
      }
      final activeStore = store;
      final activeHybrid = hybrid;
      hybrid.onSynced = () => unawaited(activeStore.refreshFromServer());
      hybrid.startAutoSync();
      _endpoint.text = endpoint;
      setState(() {
        _store = activeStore;
        _api = api;
        _hybrid = activeHybrid;
      });
      _bindSignedOut(api);
      unawaited(hybrid.syncNow(pull: true));
    } catch (_) {
      hybrid?.dispose();
      store?.dispose();
      api?.close();
      await PosLocalDatabase.instance.clearSyncSession();
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  void _bindSignedOut(PhpApiClient api) {
    api.onSignedOut = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _api != api) return;
        _hybrid?.dispose();
        final oldStore = _store;
        setState(() {
          _store = null;
          _api = null;
          _hybrid = null;
          _error = null;
        });
        oldStore?.dispose();
        api.close();
        unawaited(PosLocalDatabase.instance.clearSyncSession());
      });
      WidgetsBinding.instance.scheduleFrame();
    };
  }

  Future<void> _connect() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = PhpApiClient(_endpoint.text.trim());
    PosLocalStore? store;
    PosHybridDatabase? hybrid;
    try {
      await api.authenticate(
        email: _email.text.trim(),
        password: _password.text,
        register: _register,
        name: _name.text.trim(),
        storeName: _shop.text.trim(),
      );
      if (mounted && _register) setState(() => _register = false);
      await PosLocalDatabase.instance.saveSyncSession(
        endpoint: api.baseUrl,
        token: api.token ?? '',
        user: api.user,
      );
      hybrid = PosHybridDatabase(api);
      await hybrid.prepare();
      try {
        await hybrid.hydrate();
      } catch (_) {
        // Local data is still usable; the background sync will retry.
      }
      store = PosLocalStore(database: hybrid);
      await store.initialize();
      if (!mounted) {
        hybrid.dispose();
        store.dispose();
        api.close();
        return;
      }
      final activeStore = store;
      final activeHybrid = hybrid;
      activeHybrid.onSynced = () => unawaited(activeStore.refreshFromServer());
      setState(() {
        _store = activeStore;
        _api = api;
        _hybrid = activeHybrid;
      });
      _bindSignedOut(api);
      activeHybrid.startAutoSync();
      unawaited(activeHybrid.syncNow(pull: true));
      _password.clear();
    } catch (error) {
      hybrid?.dispose();
      store?.dispose();
      api.close();
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(height: 16),
                Text('Opening your shop…'),
              ],
            ),
          ),
        ),
      );
    }
    if (_store != null) {
      return ChangeNotifierProvider<PosLocalStore>.value(
        value: _store!,
        child: const App(),
      );
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: settingsTheme(buildOsposTheme(ThemeData.light().textTheme)),
      home: Scaffold(
        appBar: AppBar(title: const Text('TrackMauzo')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                          _register
                              ? 'Create your business account'
                              : 'Sign in to your business',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      const Text(
                          'Access your shared products, sales, customers, and settings.'),
                      const SizedBox(height: 24),
                      if (_register) ...[
                        _field(_name, 'Your name'),
                        _field(_shop, 'Business name'),
                      ],
                      _field(_email, 'Email', type: TextInputType.emailAddress),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TextFormField(
                          controller: _password,
                          enabled: !_busy,
                          obscureText: true,
                          decoration:
                              const InputDecoration(labelText: 'Password'),
                          validator: (value) => (value ?? '').isEmpty
                              ? 'Enter your password.'
                              : (_register &&
                                      (value!.length < 10 || value.length > 72)
                                  ? 'Use 10 to 72 characters.'
                                  : null),
                        ),
                      ),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Server connection'),
                        children: [
                          TextFormField(
                            controller: _endpoint,
                            enabled: !_busy,
                            decoration:
                                const InputDecoration(labelText: 'API address'),
                            validator: (value) {
                              final uri = Uri.tryParse(value?.trim() ?? '');
                              return uri == null ||
                                      !['http', 'https'].contains(uri.scheme) ||
                                      uri.host.isEmpty
                                  ? 'Enter the server API address.'
                                  : null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red)),
                        ),
                      FilledButton(
                        onPressed: _busy ? null : _connect,
                        child: Text(_busy
                            ? 'Connecting…'
                            : (_register ? 'Create account' : 'Sign in')),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _register = !_register;
                                  _error = null;
                                }),
                        child: Text(_register
                            ? 'Already have an account? Sign in'
                            : 'Create a business account'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: !_busy,
        keyboardType: type,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            (value ?? '').trim().isEmpty ? 'Enter $label.' : null,
      ),
    );
  }
}
"""

new = r"""import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../service/php_api_client.dart';
import '../../service/pos_hybrid_database.dart';
import '../../service/pos_local_database.dart';
import '../../service/pos_local_store.dart';
import '../more/settings_layout.dart';
import '../widgets/app_design.dart';
import '../widgets/app_theme.dart';

class CloudBootstrap extends StatefulWidget {
  const CloudBootstrap({super.key});

  @override
  State<CloudBootstrap> createState() => _CloudBootstrapState();
}

class _CloudBootstrapState extends State<CloudBootstrap>
    with WidgetsBindingObserver {
  final _form = GlobalKey<FormState>();
  final _endpoint = TextEditingController(
    text: const String.fromEnvironment(
      'TRACKMAUZO_API_URL',
      defaultValue: 'http://127.0.0.1:8080/api',
    ),
  );
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _shop = TextEditingController();
  PosLocalStore? _store;
  PhpApiClient? _api;
  PosHybridDatabase? _hybrid;
  bool _register = false;
  bool _busy = false;
  bool _restoring = true;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _endpoint.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _shop.dispose();
    _hybrid?.dispose();
    _store?.dispose();
    _api?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final hybrid = _hybrid;
      if (hybrid != null) unawaited(hybrid.syncNow(pull: true));
    }
  }

  void _setMode(bool register) {
    if (_busy || _register == register) return;
    setState(() {
      _register = register;
      _error = null;
    });
  }

  Future<void> _restoreSession() async {
    PosHybridDatabase? hybrid;
    PosLocalStore? store;
    PhpApiClient? api;
    try {
      final session = await PosLocalDatabase.instance.loadSyncSession();
      if (session == null) return;
      final endpoint = (session['endpoint'] as String?)?.trim() ?? '';
      final token = session['token'] as String? ?? '';
      if (endpoint.isEmpty || token.isEmpty) {
        await PosLocalDatabase.instance.clearSyncSession();
        return;
      }
      final user = jsonDecode(session['user_json'] as String? ?? '{}');
      if (user is! Map) {
        await PosLocalDatabase.instance.clearSyncSession();
        return;
      }
      api = PhpApiClient(endpoint)
        ..restoreSession(
          token: token,
          user: Map<String, dynamic>.from(user),
        );
      hybrid = PosHybridDatabase(api);
      await hybrid.prepare();
      store = PosLocalStore(database: hybrid);
      await store.initialize();
      if (!mounted) {
        hybrid.dispose();
        store.dispose();
        api.close();
        return;
      }
      final activeStore = store;
      final activeHybrid = hybrid;
      hybrid.onSynced = () => unawaited(activeStore.refreshFromServer());
      hybrid.startAutoSync();
      _endpoint.text = endpoint;
      setState(() {
        _store = activeStore;
        _api = api;
        _hybrid = activeHybrid;
      });
      _bindSignedOut(api);
      unawaited(hybrid.syncNow(pull: true));
    } catch (_) {
      hybrid?.dispose();
      store?.dispose();
      api?.close();
      await PosLocalDatabase.instance.clearSyncSession();
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  void _bindSignedOut(PhpApiClient api) {
    api.onSignedOut = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _api != api) return;
        _hybrid?.dispose();
        final oldStore = _store;
        setState(() {
          _store = null;
          _api = null;
          _hybrid = null;
          _error = null;
        });
        oldStore?.dispose();
        api.close();
        unawaited(PosLocalDatabase.instance.clearSyncSession());
      });
      WidgetsBinding.instance.scheduleFrame();
    };
  }

  Future<void> _connect() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = PhpApiClient(_endpoint.text.trim());
    PosLocalStore? store;
    PosHybridDatabase? hybrid;
    try {
      await api.authenticate(
        email: _email.text.trim(),
        password: _password.text,
        register: _register,
        name: _name.text.trim(),
        storeName: _shop.text.trim(),
      );
      if (mounted && _register) setState(() => _register = false);
      await PosLocalDatabase.instance.saveSyncSession(
        endpoint: api.baseUrl,
        token: api.token ?? '',
        user: api.user,
      );
      hybrid = PosHybridDatabase(api);
      await hybrid.prepare();
      try {
        await hybrid.hydrate();
      } catch (_) {
        // Local data is still usable; the background sync will retry.
      }
      store = PosLocalStore(database: hybrid);
      await store.initialize();
      if (!mounted) {
        hybrid.dispose();
        store.dispose();
        api.close();
        return;
      }
      final activeStore = store;
      final activeHybrid = hybrid;
      activeHybrid.onSynced = () => unawaited(activeStore.refreshFromServer());
      setState(() {
        _store = activeStore;
        _api = api;
        _hybrid = activeHybrid;
      });
      _bindSignedOut(api);
      activeHybrid.startAutoSync();
      unawaited(activeHybrid.syncNow(pull: true));
      _password.clear();
    } catch (error) {
      hybrid?.dispose();
      store?.dispose();
      api.close();
      if (mounted) setState(() => _error = _friendlyError(error.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(String raw) {
    final message = raw.replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    if (message.isEmpty) return 'Something went wrong. Please try again.';
    return message;
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: settingsTheme(buildOsposTheme(ThemeData.light().textTheme)),
        home: const Scaffold(
          backgroundColor: Color(0xFFF5F5F7),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Opening your shop…',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6E6E73),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_store != null) {
      return ChangeNotifierProvider<PosLocalStore>.value(
        value: _store!,
        child: const App(),
      );
    }
    final theme = settingsTheme(buildOsposTheme(ThemeData.light().textTheme));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: AutofillGroup(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        _buildHeader(context),
                        const SizedBox(height: 28),
                        AnimatedSwitcher(
                          duration: AppDurations.normal,
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: _buildCard(context),
                        ),
                        const SizedBox(height: 20),
                        _buildModeSwitch(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E5EA)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.storefront_rounded,
            size: 30,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _register ? 'Create your account' : 'Sign in',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
                color: AppColors.ink,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _register
              ? 'Set up your business to access products, sales, and settings from anywhere.'
              : 'Welcome back. Sign in to continue to your business.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.45,
                color: const Color(0xFF6E6E73),
              ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      key: ValueKey(_register),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8E8ED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            _ErrorBanner(message: _error!),
            const SizedBox(height: 16),
          ],
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                _buildField(
                  controller: _name,
                  label: 'Your name',
                  hint: 'Full name',
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (value) =>
                      _register && (value ?? '').trim().isEmpty
                          ? 'Enter your name.'
                          : null,
                ),
                const SizedBox(height: 14),
                _buildField(
                  controller: _shop,
                  label: 'Business name',
                  hint: 'Shop or business name',
                  icon: Icons.store_outlined,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.organizationName],
                  validator: (value) =>
                      _register && (value ?? '').trim().isEmpty
                          ? 'Enter your business name.'
                          : null,
                ),
                const SizedBox(height: 14),
              ],
            ),
            crossFadeState: _register
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppDurations.normal,
            sizeCurve: Curves.easeOutCubic,
          ),
          _buildField(
            controller: _email,
            label: 'Email',
            hint: 'name@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (value) {
              final v = (value ?? '').trim();
              if (v.isEmpty) return 'Enter your email address.';
              if (!v.contains('@') || !v.contains('.')) {
                return 'Enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _password,
            enabled: !_busy,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: [
              _register ? AutofillHints.newPassword : AutofillHints.password,
            ],
            onFieldSubmitted: (_) => _connect(),
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: _register ? 'At least 10 characters' : 'Your password',
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
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              ),
            ),
            validator: (value) {
              final v = value ?? '';
              if (v.isEmpty) return 'Enter your password.';
              if (_register && (v.length < 10 || v.length > 72)) {
                return 'Use 10 to 72 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: _busy ? null : _connect,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E5EA),
                disabledForegroundColor: const Color(0xFF8E8E93),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              child: AnimatedSwitcher(
                duration: AppDurations.fast,
                child: _busy
                    ? const SizedBox(
                        key: ValueKey('busy'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _register ? 'Create Account' : 'Continue',
                        key: ValueKey(_register),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _ServerSection(
            controller: _endpoint,
            enabled: !_busy,
          ),
        ],
      ),
    );
  }

  Widget _buildModeSwitch(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          _register ? 'Already have an account?' : 'New to TrackMauzo?',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6E6E73),
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: _busy ? null : () => _setMode(!_register),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: Text(_register ? 'Sign in' : 'Create an account'),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    List<String>? autofillHints,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_busy,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppColors.danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFB42318),
                fontSize: 13.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerSection extends StatefulWidget {
  const _ServerSection({
    required this.controller,
    required this.enabled,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  State<_ServerSection> createState() => _ServerSectionState();
}

class _ServerSectionState extends State<_ServerSection> {
  String _hostLabel() {
    final uri = Uri.tryParse(widget.controller.text.trim());
    if (uri == null || uri.host.isEmpty) return 'Server';
    return uri.host;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        minTileHeight: 44,
        iconColor: const Color(0xFF8E8E93),
        collapsedIconColor: const Color(0xFF8E8E93),
        title: Row(
          children: [
            const Icon(
              Icons.dns_outlined,
              size: 18,
              color: Color(0xFF8E8E93),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Server · ${_hostLabel()}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6E6E73),
                ),
              ),
            ),
          ],
        ),
        children: [
          const SizedBox(height: 4),
          TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.url],
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'API address',
              hintText: 'https://your-server.example/api',
              prefixIcon: Icon(Icons.link_rounded),
            ),
            validator: (value) {
              final uri = Uri.tryParse(value?.trim() ?? '');
              if (uri == null ||
                  !['http', 'https'].contains(uri.scheme) ||
                  uri.host.isEmpty) {
                return 'Enter a valid server API address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Use HTTPS for deployed servers. Android emulators use 10.0.2.2 for a local host.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: Color(0xFF8E8E93),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
"""

if old not in text:
    print("NOTFOUND")
    exit(1)
text = text.replace(old, new)
path.write_text(text, encoding="utf-8")
print("OK")
