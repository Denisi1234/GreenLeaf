import 'dart:convert';

/// Representation of an active subscription plan
class StoreSubscription {
  final String planId; // 'stores_2' or 'stores_5'
  final String planName;
  final int maxStores;
  final double priceTzs;
  final String billingCycle; // 'monthly'
  final String? orderId;
  final String? phoneNumber;
  final DateTime subscribedAt;
  final DateTime expiresAt;
  final bool isActive;

  const StoreSubscription({
    required this.planId,
    required this.planName,
    required this.maxStores,
    required this.priceTzs,
    this.billingCycle = 'monthly',
    this.orderId,
    this.phoneNumber,
    required this.subscribedAt,
    required this.expiresAt,
    this.isActive = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;

  int get daysRemaining {
    final diff = expiresAt.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Default free tier (1 store limit)
  factory StoreSubscription.free() {
    return StoreSubscription(
      planId: 'free',
      planName: 'Free Trial (1 Store)',
      maxStores: 1,
      priceTzs: 0,
      subscribedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 3650)), // Effectively unlimited free 1 store
      isActive: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'planName': planName,
        'maxStores': maxStores,
        'priceTzs': priceTzs,
        'billingCycle': billingCycle,
        'orderId': orderId,
        'phoneNumber': phoneNumber,
        'subscribedAt': subscribedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isActive': isActive,
      };

  factory StoreSubscription.fromJson(Map<String, dynamic> json) {
    return StoreSubscription(
      planId: json['planId'] as String? ?? 'free',
      planName: json['planName'] as String? ?? 'Free Trial (1 Store)',
      maxStores: (json['maxStores'] as num?)?.toInt() ?? 1,
      priceTzs: (json['priceTzs'] as num?)?.toDouble() ?? 0.0,
      billingCycle: json['billingCycle'] as String? ?? 'monthly',
      orderId: json['orderId'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      subscribedAt: json['subscribedAt'] != null
          ? DateTime.tryParse(json['subscribedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['isActive'] == true,
    );
  }
}
