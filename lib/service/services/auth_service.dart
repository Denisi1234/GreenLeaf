import 'package:flutter/foundation.dart';
import '../models/staff_models.dart';
import '../pos_local_store.dart';

/// Focused, injectable Authentication Service.
///
/// Can be injected directly via `Provider<AuthService>` or accessed through `store.authService`.
class AuthService extends ChangeNotifier {
  AuthService(this._store) {
    _store.addListener(_onStoreUpdate);
  }

  final PosLocalStore _store;

  void _onStoreUpdate() {
    notifyListeners();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreUpdate);
    super.dispose();
  }

  bool get isLoggedIn => _store.isLoggedIn;
  String? get currentUserId => _store.currentUserId;
  StaffMemberData? get currentUser => _store.currentUser;
  String? get lastAuthError => _store.lastAuthError;

  Future<bool> signIn(String username, String password) =>
      _store.signIn(username, password);

  Future<void> signOut() => _store.signOut();

  Future<bool> signUp({
    required String name,
    required String email,
    required String phone,
    required String username,
    required String password,
    String? businessCategory,
    String? customCategoryName,
  }) =>
      _store.signUp(
        name: name,
        email: email,
        phone: phone,
        username: username,
        password: password,
        businessCategory: businessCategory,
        customCategoryName: customCategoryName,
      );

  bool can(String permission) => _store.can(permission);
  bool canAccessRoute(String route) => _store.canAccessRoute(route);
}
