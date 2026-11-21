import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Salted PBKDF2-HMAC-SHA256 (with legacy salted SHA-256 verification) helpers
/// shared by local and cloud sign-in flows.
class StaffCredentials {
  const StaffCredentials._();

  static const String _schemePrefix = 'pbkdf2_sha256';
  static const int defaultIterations = 50000;
  static const int _derivedKeyLength = 32;

  static ({String hash, String salt}) hashPassword(String password) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    final salt = base64UrlEncode(saltBytes);
    final derived = _pbkdf2Sha256(
      utf8.encode(password),
      utf8.encode(salt),
      defaultIterations,
      _derivedKeyLength,
    );
    final encoded = '$_schemePrefix\$$defaultIterations\$${base64UrlEncode(derived)}';
    return (hash: encoded, salt: salt);
  }

  static bool verifyPassword(
    String password, {
    required String salt,
    required String hash,
  }) {
    if (hash.startsWith('$_schemePrefix\$')) {
      final parts = hash.split('\$');
      if (parts.length != 3) return false;
      final iterations = int.tryParse(parts[1]);
      if (iterations == null || iterations <= 0) return false;
      final derived = _pbkdf2Sha256(
        utf8.encode(password),
        utf8.encode(salt),
        iterations,
        _derivedKeyLength,
      );
      return _constantTimeEquals(base64UrlEncode(derived), parts[2]);
    }
    final legacyDigest = sha256.convert(utf8.encode('$salt:$password')).toString();
    return _constantTimeEquals(legacyDigest, hash);
  }

  static Uint8List _pbkdf2Sha256(
    List<int> passwordBytes,
    List<int> saltBytes,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, passwordBytes);
    const hashLen = 32;
    final blocks = (keyLength + hashLen - 1) ~/ hashLen;
    final output = Uint8List(keyLength);
    final blockIndexBytes = Uint8List(4);
    final blockIndexView = ByteData.sublistView(blockIndexBytes);

    var offset = 0;
    for (var block = 1; block <= blocks; block++) {
      blockIndexView.setUint32(0, block, Endian.big);
      final initialInput = Uint8List(saltBytes.length + 4)
        ..setAll(0, saltBytes)
        ..setAll(saltBytes.length, blockIndexBytes);
      var u = Uint8List.fromList(hmac.convert(initialInput).bytes);
      final t = Uint8List.fromList(u);

      for (var i = 1; i < iterations; i++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var j = 0; j < hashLen; j++) {
          t[j] ^= u[j];
        }
      }

      final copyLen =
          (keyLength - offset) < hashLen ? (keyLength - offset) : hashLen;
      output.setRange(offset, offset + copyLen, t);
      offset += copyLen;
    }
    return output;
  }

  static bool _constantTimeEquals(String a, String b) {
    final aUnits = a.codeUnits;
    final bUnits = b.codeUnits;
    var diff = aUnits.length ^ bUnits.length;
    final maxLen =
        aUnits.length > bUnits.length ? aUnits.length : bUnits.length;
    for (var i = 0; i < maxLen; i++) {
      final ca = i < aUnits.length ? aUnits[i] : 0;
      final cb = i < bUnits.length ? bUnits[i] : 0;
      diff |= ca ^ cb;
    }
    return diff == 0;
  }
}
