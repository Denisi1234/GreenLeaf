import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client for triggering real OTP SMS via backend or directly via NextSMS.
class BackendSmsService {
  // Configured gateway credentials
  static const String nextSmsEndpoint =
      'https://messaging-service.co.tz/api/sms/v1/text/single';
  static const String username = 'dm328432.14a';
  static const String password = 'Mahenge2004#';
  static const String senderId = 'POS';
  static const String email = 'dm328432@gmail.com';

  /// Format phone to standard Tanzanian format (255XXXXXXXXX)
  static String formatPhone(String rawPhone) {
    var digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = '255${digits.substring(1)}';
    } else if (digits.length == 9) {
      digits = '255$digits';
    }
    return digits;
  }

  /// Sends a real SMS via NextSMS gateway.
  static Future<bool> sendNextSms({
    required String recipientPhone,
    required String text,
  }) async {
    try {
      final phone = formatPhone(recipientPhone);
      final basicAuth = base64Encode(utf8.encode('$username:$password'));

      final response = await http
          .post(
            Uri.parse(nextSmsEndpoint),
            headers: {
              'Authorization': 'Basic $basicAuth',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'from': senderId,
              'to': phone,
              'text': text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// Sends a 6-digit verification code.
  static Future<bool> sendOtp({
    required String recipientPhone,
    required String code,
  }) async {
    final message =
        'Namba yako ya uthibitisho ya TrackMauzo (OTP) ni $code. Usitoe namba hii kwa mtu yeyote.';
    return sendNextSms(recipientPhone: recipientPhone, text: message);
  }
}
