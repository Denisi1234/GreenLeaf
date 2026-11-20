import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted SHA-256 credential helpers shared by local and cloud sign-in flows.
class StaffCredentials {
  const StaffCredentials._();

  static ({String hash, String salt}) hashPassword(String password) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt = base64UrlEncode(saltBytes);
    final digest = sha256.convert(utf8.encode('$salt:$password')).toString();
    return (hash: digest, salt: salt);
  }

  static bool verifyPassword(
    String password, {
    required String salt,
    required String hash,
  }) {
    final digest = sha256.convert(utf8.encode('$salt:$password')).toString();
    return digest == hash;
  }
}
