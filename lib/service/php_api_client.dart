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
  PhpApiClient(String baseUrl)
      : baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), '');

  final String baseUrl;
  final http.Client _http = http.Client();
  final Map<String, int> _versions = {};
  final Map<String, String> _uploads = {};
  Future<void> _pending = Future.value();
  String? _token;
  Map<String, dynamic> user = {};
  void Function()? onSignedOut;

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
  }) {
    final operation = _pending.then((_) async {
      final request = http.Request(method, Uri.parse('$baseUrl/$path'));
      request.headers['Content-Type'] = 'application/json';
      if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
      if (versionResource != null) {
        request.headers['If-Match'] = '${_versions[versionResource] ?? 0}';
      }
      if (body != null) request.body = jsonEncode(body);
      final response = await http.Response.fromStream(
        await _http.send(request).timeout(const Duration(seconds: 25)),
      ).timeout(const Duration(seconds: 25));
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
  }) async {
    final result = await request(
      'POST',
      register ? 'auth/register' : 'auth/login',
      body: {
        'email': email,
        'password': password,
        'name': name,
        'store_name': storeName
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
      String resource, List<Map<String, Object?>> items) async {
    await request('PUT', resource,
        body: {'items': items}, versionResource: resource);
  }

  Future<void> put(String resource, String id, Map<String, Object?> row) async {
    await request('PUT', '$resource/${Uri.encodeComponent(id)}', body: row);
  }

  Future<void> delete(String resource, String id) async {
    await request('DELETE', '$resource/${Uri.encodeComponent(id)}');
  }

  Future<void> logout() async {
    try {
      await request('POST', 'auth/logout');
    } finally {
      _token = null;
      onSignedOut?.call();
    }
  }

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    return request('POST', 'auth/otp/send', body: {'phone': phone});
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
