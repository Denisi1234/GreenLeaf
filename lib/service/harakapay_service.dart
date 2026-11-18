import 'dart:convert';
import 'package:http/http.dart' as http;

/// Model for HarakaPay USSD Push collection response
class HarakaPayCollectResult {
  final bool success;
  final String message;
  final String? orderId;
  final double? amount;
  final double? netAmount;
  final double? fee;
  final String? error;

  const HarakaPayCollectResult({
    required this.success,
    required this.message,
    this.orderId,
    this.amount,
    this.netAmount,
    this.fee,
    this.error,
  });

  factory HarakaPayCollectResult.fromJson(Map<String, dynamic> json) {
    return HarakaPayCollectResult(
      success: json['success'] == true,
      message: json['message'] as String? ?? (json['success'] == true ? 'Success' : 'Request failed'),
      orderId: json['order_id'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      netAmount: (json['net_amount'] as num?)?.toDouble(),
      fee: (json['fee'] as num?)?.toDouble(),
      error: json['error'] as String?,
    );
  }
}

/// Model for HarakaPay status check
class HarakaPayStatusResult {
  final bool success;
  final String? orderId;
  final String status; // 'pending', 'completed', 'failed'
  final double? amount;
  final String? completedAt;
  final String? error;

  const HarakaPayStatusResult({
    required this.success,
    this.orderId,
    required this.status,
    this.amount,
    this.completedAt,
    this.error,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isPending => status.toLowerCase() == 'pending' || status.toLowerCase() == 'processing';

  factory HarakaPayStatusResult.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>?;
    return HarakaPayStatusResult(
      success: json['success'] == true,
      orderId: payment?['order_id'] as String?,
      status: payment?['status'] as String? ?? (json['success'] == true ? 'pending' : 'failed'),
      amount: (payment?['amount'] as num?)?.toDouble(),
      completedAt: payment?['completed_at'] as String?,
      error: json['error'] as String?,
    );
  }
}

/// Real Mobile Money USSD Push Integration Service via HarakaPay
class HarakaPayService {
  HarakaPayService._();
  static final HarakaPayService instance = HarakaPayService._();

  static const String baseUrl = 'https://harakapay.net';
  static const String defaultApiKey = 'hpk_9e6e55ad375f9ef180d97e417d7f961f38af993f832d7aa2';

  String _apiKey = defaultApiKey;

  void setApiKey(String key) {
    if (key.trim().isNotEmpty) {
      _apiKey = key.trim();
    }
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-API-Key': _apiKey,
      };

  /// Clean Tanzanian phone number to standard format (e.g. 07XXXXXXXX or 06XXXXXXXX)
  String formatPhoneNumber(String phone) {
    var clean = phone.trim().replaceAll(RegExp(r'[\s\-\+]'), '');
    if (clean.startsWith('255')) {
      clean = '0${clean.substring(3)}';
    }
    return clean;
  }

  /// Trigger real mobile money USSD prompt on the user's phone (M-Pesa, Tigo Pesa, Airtel Money, HaloPesa)
  Future<HarakaPayCollectResult> triggerUssdPush({
    required String phone,
    required double amount,
    required String description,
  }) async {
    final cleanPhone = formatPhoneNumber(phone);
    if (cleanPhone.length != 10 || !cleanPhone.startsWith('0')) {
      return const HarakaPayCollectResult(
        success: false,
        message: 'Invalid phone number. Please enter a valid number (e.g., 0712345678).',
        error: 'invalid_phone',
      );
    }

    try {
      final uri = Uri.parse('$baseUrl/api/v1/collect');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'phone': cleanPhone,
          'amount': amount.round(),
          'description': description,
        }),
      );

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return HarakaPayCollectResult.fromJson(decoded);
    } catch (e) {
      return HarakaPayCollectResult(
        success: false,
        message: 'Network error communicating with payment gateway: $e',
        error: e.toString(),
      );
    }
  }

  /// Poll or query live transaction status by order_id
  Future<HarakaPayStatusResult> checkStatus(String orderId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/status/$orderId');
      final response = await http.get(uri, headers: _headers);
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return HarakaPayStatusResult.fromJson(decoded);
    } catch (e) {
      return HarakaPayStatusResult(
        success: false,
        status: 'error',
        error: e.toString(),
      );
    }
  }

  /// Check merchant wallet & float balance
  Future<Map<String, dynamic>?> getBalance() async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/balance');
      final response = await http.get(uri, headers: _headers);
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
