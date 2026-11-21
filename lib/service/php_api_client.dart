import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiException implements Exception {
  const ApiException(this.message, this.status);
  final String message;
  final int status;

  @override
  String toString() => message;
}

class PhpApiClient {
  static const String defaultBaseUrl = String.fromEnvironment(
    'TRACKMAUZO_API_URL',
    defaultValue: 'https://api.azagroup.co.tz/api',
  );

  PhpApiClient([String? baseUrl])
      : baseUrl = _normalizeBaseUrl(
          baseUrl != null && baseUrl.isNotEmpty ? baseUrl : defaultBaseUrl,
        );

  static String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim().replaceFirst(RegExp(r'/+$'), '');
    if (trimmed.endsWith('/api')) return trimmed;
    return '$trimmed/api';
  }

  final String baseUrl;
  final http.Client _http = http.Client();
  final Map<String, int> _versions = {};
  final Map<String, String> _uploads = {};
  Future<void> _pending = Future.value();
  String? _token;
  Map<String, dynamic> user = {};
  void Function()? onSignedOut;

  /// Fail-fast circuit breaker so an unreachable server never hangs the POS.
  static const Duration defaultTimeout = Duration(seconds: 10);
  int _consecutiveFailures = 0;
  DateTime? _circuitOpenUntil;

  bool get isCircuitOpen =>
      _circuitOpenUntil != null && DateTime.now().isBefore(_circuitOpenUntil!);

  void resetCircuit() {
    _consecutiveFailures = 0;
    _circuitOpenUntil = null;
  }

  String? get token => _token;

  void restoreSession({
    required String token,
    required Map<String, dynamic> user,
  }) {
    _token = token;
    this.user = Map<String, dynamic>.from(user);
  }

  bool get isOwner => user['role'] == 'owner';
  bool can(String permission) =>
      isOwner || ((user['permissions'] as List?) ?? []).contains(permission);

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? versionResource,
    String? idempotencyKey,
    bool bypassCircuit = false,
  }) {
    if (!bypassCircuit && isCircuitOpen) {
      return Future<Map<String, dynamic>>.error(
        const ApiException(
          'Server temporarily unreachable. Working offline.',
          503,
        ),
      );
    }
    final operation = _pending.then((_) async {
      final request = http.Request(method, Uri.parse('$baseUrl/$path'));
      request.headers['Content-Type'] = 'application/json';
      if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
      if (versionResource != null) {
        request.headers['If-Match'] = '${_versions[versionResource] ?? 0}';
      }
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        request.headers['X-Idempotency-Key'] = idempotencyKey;
      }
      if (body != null) request.body = jsonEncode(body);
      final http.Response response;
      try {
        response = await http.Response.fromStream(
          await _http.send(request).timeout(defaultTimeout),
        ).timeout(defaultTimeout);
        resetCircuit();
      } catch (e) {
        _consecutiveFailures++;
        if (_consecutiveFailures >= 3) {
          _circuitOpenUntil = DateTime.now().add(const Duration(seconds: 30));
        }
        rethrow;
      }
      Map<String, dynamic> result;
      try {
        result = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw ApiException(
            'The server returned an invalid response.', response.statusCode);
      }
      if (response.statusCode >= 400) {
        if (response.statusCode == 401 && _token != null) {
          _token = null;
          onSignedOut?.call();
        }
        throw ApiException(result['error'] as String? ?? 'Request failed.',
            response.statusCode);
      }
      if (result['version'] is int) {
        _versions[path.split('/').first] = result['version'] as int;
      }
      if (result['versions'] is Map) {
        _versions.addAll(Map<String, int>.from(result['versions'] as Map));
      }
      return result;
    });
    _pending = operation.then<void>((_) {}, onError: (Object error) {});
    return operation;
  }

  Future<void> authenticate({
    required String email,
    required String password,
    required bool register,
    String name = '',
    String storeName = '',
    String? otpToken,
  }) async {
    final result = await request(
      'POST',
      register ? 'auth/register' : 'auth/login',
      body: {
        'email': email,
        'password': password,
        'name': name,
        'store_name': storeName,
        if (otpToken != null && otpToken.isNotEmpty) 'otp_token': otpToken,
      },
    );
    final data = result['data'] as Map<String, dynamic>;
    _token = data['token'] as String;
    user = data['user'] as Map<String, dynamic>;
  }

  Future<List<Map<String, Object?>>> rows(String resource) async {
    final result = await request('GET', resource);
    return (result['data'] as List)
        .map((row) => Map<String, Object?>.from(row as Map))
        .toList();
  }

  Future<void> replace(
    String resource,
    List<Map<String, Object?>> items, {
    String? idempotencyKey,
  }) async {
    await request(
      'PUT',
      resource,
      body: {'items': items},
      versionResource: resource,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> put(
    String resource,
    String id,
    Map<String, Object?> row, {
    String? idempotencyKey,
  }) async {
    await request(
      'PUT',
      '$resource/${Uri.encodeComponent(id)}',
      body: row,
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> delete(
    String resource,
    String id, {
    String? idempotencyKey,
  }) async {
    await request(
      'DELETE',
      '$resource/${Uri.encodeComponent(id)}',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> logout() async {
    try {
      await request('POST', 'auth/logout');
    } finally {
      _token = null;
      onSignedOut?.call();
    }
  }

  Future<Map<String, dynamic>> sendOtp(String phone, {String? purpose}) async {
    return request('POST', 'auth/otp/send', body: {
      'phone': phone,
      if (purpose != null && purpose.isNotEmpty) 'purpose': purpose,
    });
  }

  Future<String> verifyOtp(String phone, String code) async {
    final res = await request('POST', 'auth/otp/verify', body: {
      'phone': phone,
      'code': code,
    });
    return (res['data'] as Map)['reset_token'] as String;
  }

  Future<bool> resetPasswordWithOtp({
    required String phone,
    required String resetToken,
    required String newPassword,
  }) async {
    final res = await request('POST', 'auth/reset-password', body: {
      'phone': phone,
      'reset_token': resetToken,
      'new_password': newPassword,
    });
    return (res['data'] as Map)['success'] == true;
  }

  Future<bool> sendSms({
    required String phone,
    required String text,
  }) async {
    final res = await request('POST', 'sms/send', body: {
      'phone': phone,
      'text': text,
    });
    return (res['data'] as Map)['sent'] == true;
  }

  Map<String, String> imageHeaders(String url) =>
      url.startsWith('$baseUrl/uploads/') && _token != null
          ? {'Authorization': 'Bearer $_token'}
          : {};

  Future<String?> uploadImage(String? path) async {
    if (path == null || path.isEmpty || path.startsWith('$baseUrl/uploads/')) {
      return path;
    }
    if (_uploads.containsKey(path)) {
      return _uploads[path];
    }
    final bytes = await XFile(path).readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      throw const ApiException('Choose an image smaller than 2 MB.', 422);
    }
    final result = await request('POST', 'uploads',
        body: {'content': base64Encode(bytes)});
    final id = (result['data'] as Map)['id'];
    final url = '$baseUrl/uploads/$id';
    _uploads[path] = url;
    return url;
  }

  void close() => _http.close();
}
