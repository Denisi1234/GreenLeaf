import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum AppUpdateCheckResult {
  upToDate,
  downloading,
  installing,
  unavailable,
}

/// Checks Google Play In-App Updates silently on Android so users receive
/// background updates without visiting the Play Store app.
class AppUpdateService with WidgetsBindingObserver {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  static const MethodChannel _channel = MethodChannel('trackmauzo/app_update');
  static const Duration _checkCooldown = Duration(hours: 6);

  final ValueNotifier<bool> updateDownloaded = ValueNotifier<bool>(false);

  @visibleForTesting
  bool allowPlatformOverride = false;

  bool _initialized = false;
  DateTime? _lastCheckedAt;

  void initialize() {
    if (!_initialized) {
      _channel.setMethodCallHandler(_handleNativeCall);
      if (!kIsWeb && (Platform.isAndroid || allowPlatformOverride)) {
        WidgetsBinding.instance.addObserver(this);
      }
      _initialized = true;
    }
    unawaited(checkForAutoUpdate());
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onUpdateDownloaded') {
      updateDownloaded.value = true;
    }
    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && updateDownloaded.value) {
      unawaited(completeUpdate());
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(checkForAutoUpdate());
    }
  }

  Future<AppUpdateCheckResult> checkForAutoUpdate({
    bool forceImmediate = false,
    bool bypassThrottle = false,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !allowPlatformOverride)) {
      return AppUpdateCheckResult.unavailable;
    }
    final now = DateTime.now();
    if (!bypassThrottle &&
        _lastCheckedAt != null &&
        now.difference(_lastCheckedAt!) < _checkCooldown) {
      return AppUpdateCheckResult.upToDate;
    }
    _lastCheckedAt = now;

    try {
      final result = await _channel.invokeMethod<String>(
        'checkAndStartAutoUpdate',
        <String, Object?>{'forceImmediate': forceImmediate},
      );
      return switch (result) {
        'up_to_date' => AppUpdateCheckResult.upToDate,
        'flexible_started' => AppUpdateCheckResult.downloading,
        'immediate_started' || 'installing' => AppUpdateCheckResult.installing,
        _ => AppUpdateCheckResult.unavailable,
      };
    } on MissingPluginException {
      return AppUpdateCheckResult.unavailable;
    } on PlatformException {
      return AppUpdateCheckResult.unavailable;
    } catch (_) {
      return AppUpdateCheckResult.unavailable;
    }
  }

  Future<bool> completeUpdate() async {
    if (kIsWeb || (!Platform.isAndroid && !allowPlatformOverride)) {
      return false;
    }
    try {
      final ok = await _channel.invokeMethod<bool>('completeUpdate') ?? false;
      if (ok) {
        updateDownloaded.value = false;
      }
      return ok;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _lastCheckedAt = null;
    updateDownloaded.value = false;
    allowPlatformOverride = false;
    _initialized = false;
  }
}
