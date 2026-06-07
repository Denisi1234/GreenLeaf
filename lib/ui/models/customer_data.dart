/// Customer profile data model.
/// Stores customer information, contact details, loyalty metrics, and tags.
class CustomerData {
  /// Creates a customer with required minimal fields.
  /// [id] must be unique across all customers.
  /// [createdAt] defaults to current time if not provided.
  /// [totalOrders] and [totalSpent] track customer purchase history.
  CustomerData({
    required this.id,
    required this.name,
    this.email = '',
    required this.phone,
    this.address = '',
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.debitBalance = 0,
    DateTime? createdAt,
    this.tags = const <String>[],
  })  : createdAt = createdAt ?? DateTime.now(),
        _initials = _computeInitials(name);

  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final int totalOrders;
  final double totalSpent;
  final double debitBalance;
  final DateTime createdAt;
  final List<String> tags;
  final String _initials;

  String get initials => _initials;

  static String _computeInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'CT';
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  CustomerData copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    int? totalOrders,
    double? totalSpent,
    double? debitBalance,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return CustomerData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      debitBalance: debitBalance ?? this.debitBalance,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }
}
