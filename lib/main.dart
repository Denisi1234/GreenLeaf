import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'service/pos_local_store.dart';
import 'service/app_notification_service.dart';
import 'app.dart';
import 'ui/widgets/app_design.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppNotificationService.instance.initialize();
  final store = PosLocalStore();
  runApp(
    ChangeNotifierProvider.value(
      value: store,
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
  late final Future<void> _initialization = widget.store.initialize();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _BootstrapScreen(),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _BootstrapErrorScreen(
              error: snapshot.error,
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
  });

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 44,
              ),
              const SizedBox(height: 12),
              const Text(
                'TrackMauzo haikuweza kuanza',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'Hitilafu isiyojulikana wakati wa kuanza',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
