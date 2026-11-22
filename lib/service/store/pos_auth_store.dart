part of '../pos_local_store.dart';

/// Sign-in, registration and password flows for [PosLocalStore].
mixin PosAuthStore on ChangeNotifier {
  PosLocalDatabase get _database;
  PosHybridDatabase? get _cloudApi;
  set _cloudApi(PosHybridDatabase? value);
  List<StaffMemberData> get _staffMembers;
  bool get _isInitialized;
  String get _activeStoreId;
  String? get currentUserId;
  Future<void> refreshFromServer();
  String? get _currentUserId;
  set _currentUserId(String? value);
  String? get _lastAuthError;
  set _lastAuthError(String? value);
  set _isLoggedIn(bool value);
  PhpApiClient? get cloudApi;
  Map<String, Object?> _staffMemberToMap(StaffMemberData staff);
  List<StaffRoleData> get _staffRoles;
  StaffMemberData? get currentUser;
  AppProfileData get profile;
  Future<StaffMemberData> addStaffMember({
    required String name,
    required String email,
    required String phone,
    required String roleId,
    String username = '',
    String? password,
    String employeeNumber = '',
    String jobTitle = '',
    String department = '',
    String hireDate = '',
    String employmentType = '',
    double hourlyRate = 0,
    String emergencyContactName = '',
    String emergencyContactPhone = '',
    String emergencyContactRelation = '',
    String address = '',
    String notes = '',
    String? avatarPath,
    StaffStatus status = StaffStatus.active,
  });
  Future<StaffMemberData> saveStaffMember(StaffMemberData staff,
      {String? cloudPassword});
  ({String hash, String salt}) _hashPassword(String password);
  bool get _disposed;
  Future<void> reloadFromLocal();

  bool _verifyPassword(String password, String salt, String hash) {
    return StaffCredentials.verifyPassword(password, salt: salt, hash: hash);
  }

    Future<bool> login(String identifier, String password) async {
      _lastAuthError = null;
      final trimmed = identifier.trim().replaceAll(RegExp(r'\s+'), '');
      if (trimmed.isEmpty || password.isEmpty) {
        _lastAuthError = 'missing_credentials';
        return false;
      }

      StaffMemberData? member;
      for (final staff in _staffMembers) {
        final staffPhone = staff.phone.trim().replaceAll(RegExp(r'\s+'), '');
        final staffUser = staff.username.trim().replaceAll(RegExp(r'\s+'), '');
        if (staffPhone.isNotEmpty &&
            (staffPhone == trimmed ||
                staffPhone.endsWith(trimmed) ||
                trimmed.endsWith(staffPhone))) {
          member = staff;
          break;
        }
        if (staffUser.isNotEmpty &&
            staffUser.toLowerCase() == trimmed.toLowerCase()) {
          member = staff;
          break;
        }
      }

      if (member == null) {
        // If user is not yet in local SQLite (e.g. freshly installed app or new device),
        // attempt online authentication with the server first.
        final api = cloudApi;
        if (api != null) {
          try {
            await api.authenticate(
              email: trimmed,
              password: password,
              register: false,
            );
            await _database.saveSyncSession(
              endpoint: api.baseUrl,
              token: api.token ?? '',
              user: api.user,
            );
            await refreshFromServer();

            // After refreshing from server, verify user now exists locally
            for (final staff in _staffMembers) {
              final staffPhone = staff.phone.trim().replaceAll(RegExp(r'\s+'), '');
              final staffUser = staff.username.trim().replaceAll(RegExp(r'\s+'), '');
              if ((staffPhone.isNotEmpty && (staffPhone == trimmed || staffPhone.endsWith(trimmed) || trimmed.endsWith(staffPhone))) ||
                  (staffUser.isNotEmpty && staffUser.toLowerCase() == trimmed.toLowerCase())) {
                member = staff;
                break;
              }
            }

            if (member != null) {
              _isLoggedIn = true;
              _currentUserId = member.id;
              notifyListeners();
              return true;
            }
          } on ApiException catch (error) {
            if (error.status == 401) {
              _lastAuthError = 'invalid_password';
            } else {
              _lastAuthError = error.message;
            }
            return false;
          } catch (_) {}
        }

        _lastAuthError = 'user_not_found';
        return false;
      }

      if (!member.hasLogin || !member.isActive) {
        _lastAuthError = 'account_inactive';
        return false;
      }

      final valid =
          _verifyPassword(password, member.passwordSalt, member.passwordHash);
      if (!valid) {
        _lastAuthError = 'invalid_password';
        return false;
      }

      if (!member.passwordHash.startsWith(r'pbkdf2_sha256$')) {
        final upgradedCredentials = _hashPassword(password);
        final upgradedMember = member.copyWith(
          passwordHash: upgradedCredentials.hash,
          passwordSalt: upgradedCredentials.salt,
          updatedAt: DateTime.now().toIso8601String(),
        );
        final memberIndex =
            _staffMembers.indexWhere((s) => s.id == upgradedMember.id);
        if (memberIndex != -1) {
          _staffMembers[memberIndex] = upgradedMember;
        }
        await _database.saveStaffMember({
          ..._staffMemberToMap(upgradedMember),
          'store_id': _activeStoreId,
        });
      }

      _isLoggedIn = true;
      _currentUserId = member.id;

      // When a cloud API is available, authenticate with the server so the
      // session token is refreshed and data is pulled from the shared backend.
      // This is what makes the same credentials work across different devices.
      final api = cloudApi;
      if (api != null) {
        final loginIdentifier = member.username.trim().isNotEmpty
            ? member.username.trim()
            : member.phone.trim().replaceAll(RegExp(r'\s+'), '');
        try {
          await api.authenticate(
            email: loginIdentifier,
            password: password,
            register: false,
          );
          // Persist the session so the next app launch restores cloud mode
          // and syncs automatically without requiring the user to log in again.
          await _database.saveSyncSession(
            endpoint: api.baseUrl,
            token: api.token ?? '',
            user: api.user,
          );
          // Pull the latest data from the shared server so a different device
          // that made changes shows up immediately after login.
          await refreshFromServer();
        } on ApiException catch (error) {
          if (error.status == 401) {
            _isLoggedIn = false;
            _currentUserId = null;
            _lastAuthError = 'invalid_password';
            notifyListeners();
            return false;
          }
          // Network or server errors: keep the local session so the till
          // still works, but surface the problem for retry.
          _lastAuthError = error.message;
        }
      }

      notifyListeners();
      return true;
    }

    /// Live server-first registration for the business owner using a verified
    /// backend OTP token. Never creates a local-only account if the server fails.
    Future<bool> registerLive({
      required String name,
      required String phone,
      required String password,
      required String otpToken,
      String storeName = '',
    }) async {
      _lastAuthError = null;
      final cleanPhone = phone.trim().replaceAll(RegExp(r'\s+'), '');
      if (cleanPhone.isEmpty) {
        _lastAuthError = 'phone_required';
        return false;
      }
      if (password.length < 6) {
        _lastAuthError = 'invalid_password';
        return false;
      }
      if (otpToken.trim().isEmpty) {
        _lastAuthError = 'otp_required';
        return false;
      }

      var api = cloudApi;
      if (api == null) {
        api = PhpApiClient();
        _cloudApi = PosHybridDatabase(api);
      }

      try {
        await api.authenticate(
          email: cleanPhone,
          password: password,
          register: true,
          name: name.trim(),
          storeName: storeName.trim(),
          otpToken: otpToken.trim(),
        );
        await _database.saveSyncSession(
          endpoint: api.baseUrl,
          token: api.token ?? '',
          user: api.user,
        );
        if (_cloudApi != null) {
          _cloudApi!.storeId = _activeStoreId;
          _cloudApi!.onSynced = () {
            if (!_disposed && _isInitialized) {
              reloadFromLocal();
            }
          };
          _cloudApi!.startAutoSync();
        }
        await refreshFromServer();

        // Cache local password hash on the server-created owner staff record so
        // offline re-login works if the shop later loses internet connectivity.
        final serverUserId = api.user['id'] as String?;
        final expectedStaffId =
            serverUserId != null ? 'staff-$serverUserId' : null;
        StaffMemberData? ownerMember;
        for (final staff in _staffMembers) {
          if ((expectedStaffId != null && staff.id == expectedStaffId) ||
              staff.phone.trim().replaceAll(RegExp(r'\s+'), '').endsWith(
                  cleanPhone.length > 9
                      ? cleanPhone.substring(cleanPhone.length - 9)
                      : cleanPhone)) {
            ownerMember = staff;
            break;
          }
        }
        if (ownerMember != null) {
          final credentials = _hashPassword(password);
          final updatedOwner = ownerMember.copyWith(
            passwordHash: credentials.hash,
            passwordSalt: credentials.salt,
            updatedAt: DateTime.now().toIso8601String(),
          );
          final idx = _staffMembers.indexWhere((s) => s.id == updatedOwner.id);
          if (idx != -1) {
            _staffMembers[idx] = updatedOwner;
            await _database.saveStaffMember({
              ..._staffMemberToMap(updatedOwner),
              'store_id': _activeStoreId,
            });
          }
          _currentUserId = updatedOwner.id;
        } else {
          _currentUserId = serverUserId;
        }

        _isLoggedIn = true;
        notifyListeners();
        return true;
      } on ApiException catch (error) {
        if (error.status == 409) {
          _lastAuthError = 'phone_taken';
        } else {
          _lastAuthError = error.message;
        }
        return false;
      } catch (_) {
        _lastAuthError =
            'Imeshindwa kuwasiliana na seva. Hakikisha una intaneti na ujaribu tena.';
        return false;
      }
    }

    Future<bool> register({
      required String name,
      required String phone,
      required String password,
      String? email,
      String? roleId,
      String? username,
    }) async {
      _lastAuthError = null;
      final cleanPhone = phone.trim().replaceAll(RegExp(r'\s+'), '');
      if (cleanPhone.isEmpty) {
        _lastAuthError = 'phone_required';
        return false;
      }
      if (password.length < 6) {
        _lastAuthError = 'invalid_password';
        return false;
      }

      // Check if phone already registered
      for (final staff in _staffMembers) {
        final existingPhone = staff.phone.trim().replaceAll(RegExp(r'\s+'), '');
        if (existingPhone.isNotEmpty && existingPhone == cleanPhone) {
          _lastAuthError = 'phone_taken';
          return false;
        }
      }

      // Auto-assign owner role if available or first role
      final chosenRoleId = roleId ??
          (_staffRoles.any((r) => r.id == 'owner')
              ? 'owner'
              : (_staffRoles.isNotEmpty ? _staffRoles.first.id : 'owner'));

      final generatedUsername = (username != null && username.trim().isNotEmpty)
          ? username.trim()
          : cleanPhone;

      await addStaffMember(
        name: name.trim(),
        email: email?.trim() ?? '',
        phone: cleanPhone,
        roleId: chosenRoleId,
        username: generatedUsername,
        password: password,
      );

      final ok = await login(cleanPhone, password);
      if (!ok && _lastAuthError == null) _lastAuthError = 'login_failed';
      return ok;
    }

    Future<bool> changeCurrentUserPassword({
      required String currentPassword,
      required String newPassword,
    }) async {
      _lastAuthError = null;
      if (newPassword.length < 6) {
        _lastAuthError = 'password_too_short';
        return false;
      }

      StaffMemberData? member;
      final activeId = _currentUserId ?? currentUserId;
      if (activeId != null) {
        for (final staff in _staffMembers) {
          if (staff.id == activeId) {
            member = staff;
            break;
          }
        }
      }
      if (member == null) {
        final phone = profile.contactNumber.trim().replaceAll(RegExp(r'\s+'), '');
        if (phone.isNotEmpty) {
          for (final staff in _staffMembers) {
            final staffPhone = staff.phone.trim().replaceAll(RegExp(r'\s+'), '');
            if (staffPhone.isNotEmpty &&
                (staffPhone == phone ||
                    staffPhone.endsWith(phone) ||
                    phone.endsWith(staffPhone))) {
              member = staff;
              break;
            }
          }
        }
      }

      if (member == null || !member.hasPassword) {
        _lastAuthError = 'user_not_found';
        return false;
      }
      if (!_verifyPassword(
        currentPassword,
        member.passwordSalt,
        member.passwordHash,
      )) {
        _lastAuthError = 'current_password_incorrect';
        return false;
      }

      final credentials = _hashPassword(newPassword);
      final updated = member.copyWith(
        passwordHash: credentials.hash,
        passwordSalt: credentials.salt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await saveStaffMember(updated, cloudPassword: newPassword);
      notifyListeners();
      return true;
    }

    Future<bool> resetPassword({
      required String phone,
      required String newPassword,
    }) async {
      _lastAuthError = null;
      final cleanPhone = phone.trim().replaceAll(RegExp(r'\s+'), '');
      if (cleanPhone.isEmpty) {
        _lastAuthError = 'phone_required';
        return false;
      }
      if (newPassword.length < 6) {
        _lastAuthError = 'invalid_password';
        return false;
      }

      StaffMemberData? member;
      int index = -1;
      for (int i = 0; i < _staffMembers.length; i++) {
        final staffPhone =
            _staffMembers[i].phone.trim().replaceAll(RegExp(r'\s+'), '');
        if (staffPhone.isNotEmpty &&
            (staffPhone == cleanPhone ||
                staffPhone.endsWith(cleanPhone) ||
                cleanPhone.endsWith(staffPhone))) {
          member = _staffMembers[i];
          index = i;
          break;
        }
      }

      if (member == null || index == -1) {
        _lastAuthError = 'user_not_found';
        return false;
      }

      final credentials = _hashPassword(newPassword);
      final updated = member.copyWith(
        passwordHash: credentials.hash,
        passwordSalt: credentials.salt,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await saveStaffMember(updated);

      // If cloud API is enabled, also update cloud password
      if (cloudApi != null) {
        try {
          await cloudApi!.put('staff', updated.id, _staffMemberToMap(updated));
        } catch (_) {}
      }

      notifyListeners();
      return true;
    }

    Future<void> logout() async {
      // Flush any pending outbox writes to the server BEFORE clearing session
      // so logging out never loses unsynced sales or inventory updates.
      final hybrid = _cloudApi;
      if (hybrid != null) {
        try {
          await hybrid.retryFailed();
          await hybrid.syncNow(pull: false);
        } catch (_) {}
      }
      final api = cloudApi;
      if (api != null) {
        try {
          await api.logout();
        } catch (_) {
          // Signing out must also work while the device is offline.
        }
      }
      await _database.clearSyncSession();
      final previousBaseUrl = api?.baseUrl;
      _cloudApi?.dispose();
      _cloudApi = PosHybridDatabase(PhpApiClient(previousBaseUrl));
      _isLoggedIn = false;
      _currentUserId = null;
      _lastAuthError = null;
      notifyListeners();
    }
}
