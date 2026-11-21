import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Stores sensitive session secrets (like bearer tokens) in Android Keystore
/// AES-256-GCM on mobile, with an in-memory fallback when no platform channel
/// is registered (desktop / headless unit tests).
class SecureTokenStorage {
  SecureTokenStorage({Map<String, String>? memoryStore})
      : _memoryOverride = memoryStore;

  static const MethodChannel _channel =
      MethodChannel('trackmauzo/secure_storage');

  static SecureTokenStorage instance = SecureTokenStorage();

  final Map<String, String>? _memoryOverride;
  final Map<String, String> _fallbackMemory = <String, String>{};

  static void useMemoryStoreForTests([Map<String, String>? backing]) {
    instance = SecureTokenStorage(
      memoryStore: backing ?? <String, String>{},
    );
  }

  static void resetForTests() {
    instance = SecureTokenStorage();
  }

  Future<void> write(String key, String value) async {
    final override = _memoryOverride;
    if (override != null) {
      override[key] = value;
      return;
    }
    try {
      await _channel.invokeMethod<bool>(
        'write',
        <String, Object?>{'key': key, 'value': value},
      );
    } on MissingPluginException {
      _fallbackMemory[key] = value;
    } on FlutterError {
      _fallbackMemory[key] = value;
    }
  }

  Future<String?> read(String key) async {
    final override = _memoryOverride;
    if (override != null) return override[key];
    try {
      return await _channel.invokeMethod<String>(
        'read',
        <String, Object?>{'key': key},
      );
    } on MissingPluginException {
      return _fallbackMemory[key];
    } on FlutterError {
      return _fallbackMemory[key];
    }
  }

  Future<void> delete(String key) async {
    final override = _memoryOverride;
    if (override != null) {
      override.remove(key);
      return;
    }
    try {
      await _channel.invokeMethod<bool>(
        'delete',
        <String, Object?>{'key': key},
      );
    } on MissingPluginException {
      _fallbackMemory.remove(key);
    } on FlutterError {
      _fallbackMemory.remove(key);
    }
  }
}
