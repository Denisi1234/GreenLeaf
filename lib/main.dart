import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'service/pos_local_store.dart';
import 'service/app_notification_service.dart';
import 'app.dart';
import 'ui/widgets/app_design.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await AppNotificationService.instance.initialize();
  final store = PosLocalStore();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: store),
        ChangeNotifierProvider.value(value: store.authService),
        ChangeNotifierProvider.value(value: store.salesService),
        ChangeNotifierProvider.value(value: store.inventoryService),
        ChangeNotifierProvider.value(value: store.accountingService),
      ],
      child: AppBootstrapper(store: store),
    ),
  );
}

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({
    super.key,
    required this.store,
  });

  final PosLocalStore store;

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  late Future<void> _initialization = widget.store.initialize();

  void _retry() {
    setState(() {
      _initialization = widget.store.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            locale: Locale(widget.store.languageCode),
            supportedLocales: const [Locale('sw'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            debugShowCheckedModeBanner: false,
            home: const _BootstrapScreen(),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            locale: Locale(widget.store.languageCode),
            supportedLocales: const [Locale('sw'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            debugShowCheckedModeBanner: false,
            home: _BootstrapErrorScreen(
              error: snapshot.error,
              isSwahili: widget.store.languageCode == 'sw',
              onRetry: _retry,
            ),
          );
        }

        return const App();
      },
    );
  }
}

class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/app_logo.png',
              width: 88,
              height: 88,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aza POS',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'POINT OF SALE',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootstrapErrorScreen extends StatelessWidget {
  const _BootstrapErrorScreen({
    required this.error,
    required this.isSwahili,
    required this.onRetry,
  });

  final Object? error;
  final bool isSwahili;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.standard),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.danger,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSwahili
                        ? 'Aza POS haikuweza kuanza'
                        : 'Aza POS could not start',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error?.toString() ??
                        (isSwahili
                            ? 'Hitilafu isiyojulikana wakati wa kuanza'
                            : 'Unknown error during startup'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(160, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      isSwahili ? 'Jaribu tena' : 'Try again',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
